-- =====================================================================
-- Stanke · 03_procedimientos_triggers.sql
-- Se ejecuta completo después de 01_create.sql y 02_datos.sql.
--
-- Triggers (reglas marcadas como trigger en la Entrega 1)
--   RN-12  BEFORE INSERT compra     · solo se compran juegos publicados
--   RN-13  BEFORE INSERT compra     · no se compra un juego que ya se posee
--   RN-14  AFTER  INSERT compra     · la compra agrega el juego a la biblioteca
--   RN-15  BEFORE INSERT/UPDATE resena · solo se reseñan juegos de la biblioteca
--   RN-16  AFTER  UPDATE precio     · todo cambio de precio queda en historial_precio
--
-- Casos de uso (requerimientos marcados con procedimiento o transacción)
--   RF-03  pr_publicar_videojuego
--   RF-06  pr_comprar_videojuego
--   RF-14  pr_crear_promocion
--   RF-15  fn_reporte_ventas_desarrollador  (consulta: RETURNS TABLE)
--   RF-17  pr_reembolsar_compra
-- =====================================================================


-- =====================================================================
-- TRIGGERS
-- =====================================================================

-- ---------------------------------------------------------------------
-- RN-12 · Solo se pueden comprar videojuegos en estado publicado (BEFORE)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_rn12_compra_solo_publicados()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    v_titulo VARCHAR(200);
    v_estado VARCHAR(20);
BEGIN
    SELECT titulo, estado INTO v_titulo, v_estado
      FROM videojuego
     WHERE id = NEW.videojuego_id;

    -- Si el videojuego no existe, la llave foránea lanzará su propio error.
    IF FOUND AND v_estado <> 'publicado' THEN
        RAISE EXCEPTION 'No se puede comprar "%" (videojuego %): su estado es % y solo se venden videojuegos publicados',
              v_titulo, NEW.videojuego_id, v_estado
              USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
END; $$;

CREATE OR REPLACE TRIGGER trg_rn12_compra_solo_publicados
BEFORE INSERT ON compra
FOR EACH ROW EXECUTE FUNCTION fn_rn12_compra_solo_publicados();

-- ---------------------------------------------------------------------
-- RN-13 · Un jugador no puede comprar un juego que ya está en su biblioteca (BEFORE)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_rn13_compra_no_duplicada()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF EXISTS (SELECT 1
                 FROM biblioteca
                WHERE usuario_id = NEW.usuario_id
                  AND videojuego_id = NEW.videojuego_id) THEN
        RAISE EXCEPTION 'El usuario % ya tiene el videojuego % en su biblioteca: no puede comprarlo de nuevo',
              NEW.usuario_id, NEW.videojuego_id
              USING ERRCODE = 'unique_violation';
    END IF;
    RETURN NEW;
END; $$;

CREATE OR REPLACE TRIGGER trg_rn13_compra_no_duplicada
BEFORE INSERT ON compra
FOR EACH ROW EXECUTE FUNCTION fn_rn13_compra_no_duplicada();

-- ---------------------------------------------------------------------
-- RN-14 · Al registrarse una compra, el juego se agrega a la biblioteca (AFTER)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_rn14_compra_a_biblioteca()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO biblioteca (usuario_id, videojuego_id, fecha_adquisicion)
    VALUES (NEW.usuario_id, NEW.videojuego_id, NEW.fecha);
    RETURN NEW;
END; $$;

CREATE OR REPLACE TRIGGER trg_rn14_compra_a_biblioteca
AFTER INSERT ON compra
FOR EACH ROW
WHEN (NEW.estado = 'completada')
EXECUTE FUNCTION fn_rn14_compra_a_biblioteca();

-- ---------------------------------------------------------------------
-- RN-15 · Un jugador solo puede reseñar un juego de su biblioteca (BEFORE)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_rn15_resena_solo_propios()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1
                     FROM biblioteca
                    WHERE usuario_id = NEW.usuario_id
                      AND videojuego_id = NEW.videojuego_id) THEN
        RAISE EXCEPTION 'El usuario % no puede reseñar el videojuego % porque no está en su biblioteca',
              NEW.usuario_id, NEW.videojuego_id
              USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
END; $$;

CREATE OR REPLACE TRIGGER trg_rn15_resena_solo_propios
BEFORE INSERT OR UPDATE OF usuario_id, videojuego_id ON resena
FOR EACH ROW EXECUTE FUNCTION fn_rn15_resena_solo_propios();

-- ---------------------------------------------------------------------
-- RN-16 · Todo cambio de precio queda registrado en historial_precio (AFTER)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_rn16_historial_precio()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO historial_precio (videojuego_id, precio_anterior, precio_nuevo)
    VALUES (NEW.id, OLD.precio, NEW.precio);
    RETURN NEW;
END; $$;

CREATE OR REPLACE TRIGGER trg_rn16_historial_precio
AFTER UPDATE OF precio ON videojuego
FOR EACH ROW
WHEN (OLD.precio IS DISTINCT FROM NEW.precio)
EXECUTE FUNCTION fn_rn16_historial_precio();


-- =====================================================================
-- PROCEDIMIENTOS Y FUNCIONES
-- =====================================================================

-- ---------------------------------------------------------------------
-- RF-03 · Publicar (registrar) un videojuego con sus géneros e imágenes
--         en una sola operación. El juego queda en estado 'pendiente'
--         (RN-07) hasta que un administrador lo apruebe (RF-13).
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE pr_publicar_videojuego(
    p_desarrollador_id  BIGINT,
    p_titulo            VARCHAR,
    p_descripcion       TEXT,
    p_precio            NUMERIC,
    p_fecha_lanzamiento DATE,
    p_generos           BIGINT[],
    p_imagenes          TEXT[],
    INOUT p_videojuego_id BIGINT DEFAULT NULL
)
LANGUAGE plpgsql AS $$
DECLARE
    v_estado_cuenta VARCHAR(20);
    v_genero        BIGINT;
BEGIN
    -- El desarrollador existe y su cuenta está activa
    SELECT u.estado INTO v_estado_cuenta
      FROM desarrollador d
      JOIN usuario u ON u.id = d.usuario_id
     WHERE d.id = p_desarrollador_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El desarrollador % no existe', p_desarrollador_id;
    END IF;
    IF v_estado_cuenta <> 'activo' THEN
        RAISE EXCEPTION 'La cuenta del desarrollador % está suspendida: no puede publicar videojuegos',
              p_desarrollador_id;
    END IF;

    -- Datos del videojuego
    IF p_titulo IS NULL OR btrim(p_titulo) = '' THEN
        RAISE EXCEPTION 'El título del videojuego es obligatorio';
    END IF;
    IF EXISTS (SELECT 1 FROM videojuego
                WHERE desarrollador_id = p_desarrollador_id
                  AND lower(titulo) = lower(btrim(p_titulo))) THEN
        RAISE EXCEPTION 'El desarrollador % ya tiene un videojuego llamado "%"',
              p_desarrollador_id, btrim(p_titulo);
    END IF;
    IF p_precio IS NULL OR p_precio < 0 THEN
        RAISE EXCEPTION 'El precio debe ser mayor o igual a cero: se recibió %', p_precio;
    END IF;

    -- Géneros: al menos uno y todos existentes
    IF p_generos IS NULL OR cardinality(p_generos) = 0 THEN
        RAISE EXCEPTION 'El videojuego "%" debe tener al menos un género', btrim(p_titulo);
    END IF;
    SELECT g.id_buscado INTO v_genero
      FROM unnest(p_generos) AS g(id_buscado)
     WHERE NOT EXISTS (SELECT 1 FROM genero WHERE id = g.id_buscado)
     LIMIT 1;
    IF FOUND THEN
        RAISE EXCEPTION 'El género % no existe', v_genero;
    END IF;

    -- Imágenes: opcionales, pero ninguna URL puede venir vacía
    IF p_imagenes IS NOT NULL
       AND EXISTS (SELECT 1 FROM unnest(p_imagenes) AS i(url)
                    WHERE i.url IS NULL OR btrim(i.url) = '') THEN
        RAISE EXCEPTION 'Las imágenes del videojuego "%" no pueden tener URL vacía', btrim(p_titulo);
    END IF;

    -- Inserciones (todas o ninguna)
    INSERT INTO videojuego (desarrollador_id, titulo, descripcion, precio, fecha_lanzamiento)
    VALUES (p_desarrollador_id, btrim(p_titulo), p_descripcion, p_precio, p_fecha_lanzamiento)
    RETURNING id INTO p_videojuego_id;            -- estado = 'pendiente' por DEFAULT (RN-07)

    INSERT INTO videojuego_genero (videojuego_id, genero_id)
    SELECT DISTINCT p_videojuego_id, g
      FROM unnest(p_generos) AS g;

    IF p_imagenes IS NOT NULL THEN
        INSERT INTO imagen_videojuego (videojuego_id, url, orden)
        SELECT p_videojuego_id, btrim(i.url), i.orden
          FROM unnest(p_imagenes) WITH ORDINALITY AS i(url, orden);
    END IF;

    RAISE NOTICE 'Videojuego % "%" registrado en estado pendiente con % género(s) y % imagen(es)',
          p_videojuego_id, btrim(p_titulo),
          (SELECT count(DISTINCT g) FROM unnest(p_generos) AS g),
          coalesce(cardinality(p_imagenes), 0);
END; $$;

-- ---------------------------------------------------------------------
-- RF-06 · Comprar un videojuego con el saldo de la cuenta, aplicando
--         la mejor promoción vigente. La compra dispara RN-12, RN-13 y
--         RN-14 (agrega el juego a la biblioteca).
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE pr_comprar_videojuego(
    p_usuario_id    BIGINT,
    p_videojuego_id BIGINT,
    INOUT p_compra_id BIGINT DEFAULT NULL
)
LANGUAGE plpgsql AS $$
DECLARE
    v_rol        VARCHAR(20);
    v_estado_usr VARCHAR(20);
    v_saldo      NUMERIC(12,2);
    v_titulo     VARCHAR(200);
    v_precio     NUMERIC(12,2);
    v_estado_vj  VARCHAR(20);
    v_descuento  NUMERIC(5,2);
    v_monto      NUMERIC(12,2);
BEGIN
    -- 1. Bloquea la fila del jugador: dos compras simultáneas del mismo
    --    jugador se ejecutan una después de la otra.
    SELECT rol, estado, saldo INTO v_rol, v_estado_usr, v_saldo
      FROM usuario
     WHERE id = p_usuario_id
       FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El usuario % no existe', p_usuario_id;
    END IF;
    IF v_rol <> 'jugador' THEN
        RAISE EXCEPTION 'El usuario % tiene rol % y solo los jugadores pueden comprar videojuegos',
              p_usuario_id, v_rol;
    END IF;
    IF v_estado_usr <> 'activo' THEN
        RAISE EXCEPTION 'La cuenta del usuario % está suspendida: no puede comprar videojuegos',
              p_usuario_id;
    END IF;

    -- 2. Lee el videojuego y evita que cambien su precio o estado mientras dura la compra
    SELECT titulo, precio, estado INTO v_titulo, v_precio, v_estado_vj
      FROM videojuego
     WHERE id = p_videojuego_id
       FOR SHARE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El videojuego % no existe', p_videojuego_id;
    END IF;
    IF v_estado_vj <> 'publicado' THEN                                    -- RN-12
        RAISE EXCEPTION 'El videojuego "%" no está a la venta: su estado es %', v_titulo, v_estado_vj;
    END IF;
    IF EXISTS (SELECT 1 FROM biblioteca
                WHERE usuario_id = p_usuario_id
                  AND videojuego_id = p_videojuego_id) THEN               -- RN-13
        RAISE EXCEPTION 'El usuario % ya tiene "%" en su biblioteca', p_usuario_id, v_titulo;
    END IF;

    -- 3. Precio vigente: se aplica el mayor descuento de las promociones activas
    SELECT max(p.descuento) INTO v_descuento
      FROM promocion p
      JOIN promocion_videojuego pv ON pv.promocion_id = p.id
     WHERE pv.videojuego_id = p_videojuego_id
       AND now() BETWEEN p.fecha_inicio AND p.fecha_fin;

    v_monto := round(v_precio * (1 - coalesce(v_descuento, 0) / 100), 2);

    IF v_saldo < v_monto THEN                                              -- RN-04
        RAISE EXCEPTION 'Saldo insuficiente: el usuario % tiene % y "%" cuesta %',
              p_usuario_id, v_saldo, v_titulo, v_monto;
    END IF;

    -- 4. Descuenta el saldo, registra la compra y limpia la lista de deseos
    UPDATE usuario
       SET saldo = saldo - v_monto
     WHERE id = p_usuario_id;

    INSERT INTO compra (usuario_id, videojuego_id, monto)
    VALUES (p_usuario_id, p_videojuego_id, v_monto)
    RETURNING id INTO p_compra_id;          -- trg_rn14 agrega el juego a biblioteca

    DELETE FROM lista_deseos
     WHERE usuario_id = p_usuario_id
       AND videojuego_id = p_videojuego_id;

    RAISE NOTICE 'Compra % registrada: "%" por % (descuento % %%); saldo restante %',
          p_compra_id, v_titulo, v_monto, coalesce(v_descuento, 0), v_saldo - v_monto;
END; $$;

-- ---------------------------------------------------------------------
-- RF-14 · Crear una promoción con sus videojuegos en una sola operación
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE pr_crear_promocion(
    p_nombre       VARCHAR,
    p_descuento    NUMERIC,
    p_fecha_inicio TIMESTAMPTZ,
    p_fecha_fin    TIMESTAMPTZ,
    p_videojuegos  BIGINT[],
    INOUT p_promocion_id BIGINT DEFAULT NULL
)
LANGUAGE plpgsql AS $$
DECLARE
    v_juego  BIGINT;
    v_titulo VARCHAR(200);
BEGIN
    IF p_nombre IS NULL OR btrim(p_nombre) = '' THEN
        RAISE EXCEPTION 'El nombre de la promoción es obligatorio';
    END IF;
    IF p_descuento IS NULL OR p_descuento < 1 OR p_descuento > 90 THEN       -- RN-10
        RAISE EXCEPTION 'El descuento debe estar entre 1 %% y 90 %%: se recibió %', p_descuento;
    END IF;
    IF p_fecha_inicio IS NULL OR p_fecha_fin IS NULL THEN
        RAISE EXCEPTION 'La promoción "%" necesita fecha de inicio y fecha de fin', btrim(p_nombre);
    END IF;
    IF p_fecha_fin <= p_fecha_inicio THEN                                    -- RN-10
        RAISE EXCEPTION 'La fecha de fin (%) debe ser posterior a la fecha de inicio (%)',
              p_fecha_fin, p_fecha_inicio;
    END IF;
    IF p_fecha_fin <= now() THEN
        RAISE EXCEPTION 'No se puede crear la promoción "%": su fecha de fin (%) ya pasó',
              btrim(p_nombre), p_fecha_fin;
    END IF;
    IF p_videojuegos IS NULL OR cardinality(p_videojuegos) = 0 THEN
        RAISE EXCEPTION 'La promoción "%" debe aplicar al menos a un videojuego', btrim(p_nombre);
    END IF;

    -- Todos los videojuegos existen ...
    SELECT j.id_buscado INTO v_juego
      FROM unnest(p_videojuegos) AS j(id_buscado)
     WHERE NOT EXISTS (SELECT 1 FROM videojuego WHERE id = j.id_buscado)
     LIMIT 1;
    IF FOUND THEN
        RAISE EXCEPTION 'El videojuego % no existe', v_juego;
    END IF;

    -- ... y ninguno está retirado del catálogo
    SELECT v.id, v.titulo INTO v_juego, v_titulo
      FROM videojuego v
     WHERE v.id = ANY (p_videojuegos)
       AND v.estado = 'retirado'
     LIMIT 1;
    IF FOUND THEN
        RAISE EXCEPTION 'El videojuego % "%" está retirado y no puede entrar en una promoción',
              v_juego, v_titulo;
    END IF;

    INSERT INTO promocion (nombre, descuento, fecha_inicio, fecha_fin)
    VALUES (btrim(p_nombre), p_descuento, p_fecha_inicio, p_fecha_fin)
    RETURNING id INTO p_promocion_id;

    INSERT INTO promocion_videojuego (promocion_id, videojuego_id)
    SELECT DISTINCT p_promocion_id, j
      FROM unnest(p_videojuegos) AS j;

    RAISE NOTICE 'Promoción % "%" creada con % %% de descuento para % videojuego(s)',
          p_promocion_id, btrim(p_nombre), p_descuento,
          (SELECT count(DISTINCT j) FROM unnest(p_videojuegos) AS j);
END; $$;

-- ---------------------------------------------------------------------
-- RF-15 · Reporte de ventas de un desarrollador en un periodo.
--         Es una consulta que devuelve filas, por eso se implementa
--         como función RETURNS TABLE. Incluye juegos sin ventas.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_reporte_ventas_desarrollador(
    p_desarrollador_id BIGINT,
    p_desde            DATE,
    p_hasta            DATE
)
RETURNS TABLE (
    videojuego_id        BIGINT,
    titulo               VARCHAR,
    copias_vendidas      BIGINT,
    copias_reembolsadas  BIGINT,
    ingresos             NUMERIC
)
LANGUAGE plpgsql STABLE AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM desarrollador WHERE id = p_desarrollador_id) THEN
        RAISE EXCEPTION 'El desarrollador % no existe', p_desarrollador_id;
    END IF;
    IF p_desde IS NULL OR p_hasta IS NULL THEN
        RAISE EXCEPTION 'Debe indicar la fecha inicial y la fecha final del periodo';
    END IF;
    IF p_hasta < p_desde THEN
        RAISE EXCEPTION 'Periodo inválido: la fecha final (%) es anterior a la inicial (%)',
              p_hasta, p_desde;
    END IF;

    RETURN QUERY
    SELECT v.id,
           v.titulo,
           count(c.id) FILTER (WHERE c.estado = 'completada'),
           count(c.id) FILTER (WHERE c.estado = 'reembolsada'),
           coalesce(sum(c.monto) FILTER (WHERE c.estado = 'completada'), 0)::NUMERIC(12,2)
      FROM videojuego v
      LEFT JOIN compra c
             ON c.videojuego_id = v.id
            AND c.fecha >= p_desde
            AND c.fecha <  p_hasta + 1          -- incluye todo el día final
     WHERE v.desarrollador_id = p_desarrollador_id
     GROUP BY v.id, v.titulo
     ORDER BY 5 DESC, v.titulo;
END; $$;

-- ---------------------------------------------------------------------
-- RF-17 · Reembolsar una compra de menos de 14 días: devuelve el monto
--         al saldo, retira el juego de la biblioteca y marca la compra
--         como reembolsada. También elimina la reseña del jugador sobre
--         ese juego, para que siga cumpliéndose RN-15.
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE pr_reembolsar_compra(
    p_usuario_id BIGINT,
    p_compra_id  BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_dueno      BIGINT;
    v_juego      BIGINT;
    v_fecha      TIMESTAMPTZ;
    v_monto      NUMERIC(12,2);
    v_estado     VARCHAR(20);
BEGIN
    -- 1. Bloquea primero al usuario (mismo orden que la compra: usuario -> compra)
    PERFORM 1 FROM usuario WHERE id = p_usuario_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'El usuario % no existe', p_usuario_id;
    END IF;

    -- 2. Bloquea la compra para que no se pueda reembolsar dos veces
    SELECT usuario_id, videojuego_id, fecha, monto, estado
      INTO v_dueno, v_juego, v_fecha, v_monto, v_estado
      FROM compra
     WHERE id = p_compra_id
       FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La compra % no existe', p_compra_id;
    END IF;
    IF v_dueno <> p_usuario_id THEN
        RAISE EXCEPTION 'La compra % no pertenece al usuario %', p_compra_id, p_usuario_id;
    END IF;
    IF v_estado = 'reembolsada' THEN
        RAISE EXCEPTION 'La compra % ya fue reembolsada', p_compra_id;
    END IF;
    IF v_fecha < now() - INTERVAL '14 days' THEN
        RAISE EXCEPTION 'La compra % se hizo el % y ya pasaron más de 14 días: no se puede reembolsar',
              p_compra_id, to_char(v_fecha, 'YYYY-MM-DD');
    END IF;

    -- 3. Aplica el reembolso
    UPDATE usuario SET saldo = saldo + v_monto WHERE id = p_usuario_id;
    UPDATE compra  SET estado = 'reembolsada' WHERE id = p_compra_id;
    DELETE FROM resena
     WHERE usuario_id = p_usuario_id AND videojuego_id = v_juego;
    DELETE FROM biblioteca
     WHERE usuario_id = p_usuario_id AND videojuego_id = v_juego;

    RAISE NOTICE 'Compra % reembolsada: se devolvieron % al usuario %', p_compra_id, v_monto, p_usuario_id;
END; $$;
