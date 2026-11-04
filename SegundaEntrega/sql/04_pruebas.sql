-- =====================================================================
-- Stanke · 04_pruebas.sql
-- Pruebas de los componentes 2.3 (restricciones) y 2.4 (procedimientos
-- y triggers). Se ejecuta SENTENCIA POR SENTENCIA, en orden, sobre una
-- base recién creada con 01, 02 y 03. Las marcadas con "DEBE FALLAR"
-- terminan en error a propósito.
-- =====================================================================


-- =====================================================================
-- 2.3 PRUEBAS DE RESTRICCIONES
-- =====================================================================

-- [R1] CHECK · RN-08: la calificación debe estar entre 1 y 5 (DEBE FALLAR)
INSERT INTO resena (usuario_id, videojuego_id, calificacion, comentario)
VALUES (9, 2, 6, 'Lo mejor que he jugado en mi vida.');

-- [R2] CHECK · RN-04: el saldo nunca puede quedar negativo (DEBE FALLAR)
UPDATE usuario SET saldo = saldo - 500 WHERE id = 10;

-- [R3] CHECK · RN-05: el precio no puede ser negativo (DEBE FALLAR)
INSERT INTO videojuego (desarrollador_id, titulo, precio)
VALUES (1, 'Pixel Dungeon Tactics II', -5.00);

-- [R4] CHECK · RN-10: el descuento debe estar entre 1 y 90 (DEBE FALLAR)
INSERT INTO promocion (nombre, descuento, fecha_inicio, fecha_fin)
VALUES ('Liquidación total', 95, '2026-12-01', '2026-12-05');

-- [R5] CHECK · RN-11: nadie se envía una solicitud de amistad a sí mismo (DEBE FALLAR)
INSERT INTO amistad (usuario_solicita_id, usuario_recibe_id) VALUES (9, 9);

-- [R6] CHECK · RN-03: el rol solo puede ser jugador, desarrollador o administrador (DEBE FALLAR)
INSERT INTO usuario (nombre, correo, contrasena_hash, rol)
VALUES ('Valeria Montoya', 'valeria.montoya@gmail.com',
        '$2b$12$bQy79C9Xn/Exh16v2uXxluyqYOMV59gt8cueaLthjJ/IEByY47j16', 'moderador');

-- [R7] FOREIGN KEY · RN-06: el desarrollador debe existir (DEBE FALLAR)
INSERT INTO videojuego (desarrollador_id, titulo, precio)
VALUES (99, 'Reino Perdido', 19.99);

-- [R8] FOREIGN KEY · ON DELETE RESTRICT: no se borra un desarrollador con juegos (DEBE FALLAR)
DELETE FROM desarrollador WHERE id = 1;

-- [R9] UNIQUE · RN-02: el correo no se repite (DEBE FALLAR)
INSERT INTO usuario (nombre, correo, contrasena_hash, rol)
VALUES ('Carlos Andrés Pérez', 'carlos.perez@gmail.com',
        '$2b$12$bQy79C9Xn/Exh16v2uXxluyqYOMV59gt8cueaLthjJ/IEByY47j16', 'jugador');

-- [R10] UNIQUE · RN-09: una sola reseña por jugador y videojuego (DEBE FALLAR)
INSERT INTO resena (usuario_id, videojuego_id, calificacion, comentario)
VALUES (7, 1, 4, 'Lo volví a jugar y sigue siendo excelente.');

-- [R11] NOT NULL: la contraseña es obligatoria (DEBE FALLAR)
INSERT INTO usuario (nombre, correo, rol)
VALUES ('Valeria Montoya', 'valeria.montoya@gmail.com', 'jugador');


-- =====================================================================
-- 2.4 CASO DE USO RF-03 · Publicar un videojuego
-- =====================================================================

-- [P1] Éxito: Nebula Soft (desarrollador 5) registra un juego con 2 géneros y 2 imágenes
CALL pr_publicar_videojuego(
    5, 'Leyendas del Amazonas',
    'Aventura de supervivencia río abajo por la selva amazónica, con fauna y comunidades reales como inspiración.',
    27.99, '2027-03-15',
    ARRAY[6, 5]::BIGINT[],
    ARRAY['https://cdn.stanke.co/juegos/leyendas-del-amazonas/portada.jpg',
          'https://cdn.stanke.co/juegos/leyendas-del-amazonas/rio.jpg'],
    NULL);

SELECT v.id, v.titulo, v.precio, v.estado, d.nombre AS desarrollador
  FROM videojuego v JOIN desarrollador d ON d.id = v.desarrollador_id
 WHERE v.titulo = 'Leyendas del Amazonas';

SELECT vg.videojuego_id, g.nombre AS genero
  FROM videojuego_genero vg JOIN genero g ON g.id = vg.genero_id
 WHERE vg.videojuego_id = (SELECT id FROM videojuego WHERE titulo = 'Leyendas del Amazonas');

SELECT videojuego_id, orden, url FROM imagen_videojuego
 WHERE videojuego_id = (SELECT id FROM videojuego WHERE titulo = 'Leyendas del Amazonas')
 ORDER BY orden;

-- [P2] Error: un género que no existe (DEBE FALLAR; no se crea nada)
CALL pr_publicar_videojuego(5, 'Ríos de Fuego', 'Plataformas en volcanes activos.',
                            15.99, '2027-05-01', ARRAY[6, 99]::BIGINT[], NULL, NULL);

-- [P3] Error: desarrollador inexistente (DEBE FALLAR)
CALL pr_publicar_videojuego(99, 'Ríos de Fuego', 'Plataformas en volcanes activos.',
                            15.99, '2027-05-01', ARRAY[6]::BIGINT[], NULL, NULL);

-- [P4] Error: título repetido para el mismo desarrollador (DEBE FALLAR)
CALL pr_publicar_videojuego(1, 'Chronos Odyssey', 'Remasterización.',
                            59.99, '2027-01-01', ARRAY[2]::BIGINT[], NULL, NULL);

-- [P5] Comprobación: los intentos fallidos no crearon videojuegos (sigue habiendo 12)
SELECT count(*) AS total_videojuegos FROM videojuego;


-- =====================================================================
-- RF-13 (apoyo) y trigger RN-16 · Cambio de precio con historial (AFTER)
-- =====================================================================

-- [T1] El administrador aprueba el juego nuevo
UPDATE videojuego SET estado = 'publicado' WHERE titulo = 'Leyendas del Amazonas';

-- [T2] El desarrollador baja el precio: el trigger registra el cambio
UPDATE videojuego SET precio = 24.99 WHERE titulo = 'Leyendas del Amazonas';

SELECT h.id, h.videojuego_id, v.titulo, h.precio_anterior, h.precio_nuevo, h.fecha_cambio
  FROM historial_precio h JOIN videojuego v ON v.id = h.videojuego_id
 WHERE v.titulo = 'Leyendas del Amazonas';

-- [T3] Un UPDATE que no cambia el precio no genera historial
UPDATE videojuego SET precio = 24.99, descripcion = descripcion WHERE titulo = 'Leyendas del Amazonas';
SELECT count(*) AS cambios_de_precio
  FROM historial_precio h JOIN videojuego v ON v.id = h.videojuego_id
 WHERE v.titulo = 'Leyendas del Amazonas';


-- =====================================================================
-- 2.4 CASO DE USO RF-14 · Crear una promoción
-- =====================================================================

-- [P6] Éxito: promoción de 30 % por 7 días para dos juegos
CALL pr_crear_promocion('Oferta Relámpago Stanke', 30, now(), now() + INTERVAL '7 days',
                        ARRAY[8, 9]::BIGINT[], NULL);

SELECT p.id, p.nombre, p.descuento, v.titulo
  FROM promocion p
  JOIN promocion_videojuego pv ON pv.promocion_id = p.id
  JOIN videojuego v ON v.id = pv.videojuego_id
 WHERE p.nombre = 'Oferta Relámpago Stanke';

-- [P7] Error: descuento fuera de rango (DEBE FALLAR)
CALL pr_crear_promocion('Mega descuento', 95, now(), now() + INTERVAL '3 days',
                        ARRAY[1]::BIGINT[], NULL);

-- [P8] Error: incluye un videojuego retirado (DEBE FALLAR)
CALL pr_crear_promocion('Clásicos de Arena', 50, now(), now() + INTERVAL '3 days',
                        ARRAY[2, 11]::BIGINT[], NULL);

-- [P9] Error: la fecha de fin es anterior a la de inicio (DEBE FALLAR)
CALL pr_crear_promocion('Semana Retro', 20, '2026-12-10', '2026-12-01',
                        ARRAY[6]::BIGINT[], NULL);


-- =====================================================================
-- 2.4 CASO DE USO RF-06 · Comprar un videojuego
--     (incluye el trigger AFTER RN-14 que agrega el juego a la biblioteca)
-- =====================================================================

-- [P10] Estado antes de la compra: saldo de Daniel Herrera (11) y su lista de deseos
SELECT id, nombre, saldo FROM usuario WHERE id = 11;
SELECT usuario_id, videojuego_id FROM lista_deseos WHERE usuario_id = 11;

-- [P11] Éxito: Daniel compra "Sombras de Cartagena" (34.99) con la promoción de 30 %
CALL pr_comprar_videojuego(11, 9, NULL);

SELECT id, nombre, saldo FROM usuario WHERE id = 11;
SELECT id, usuario_id, videojuego_id, monto, estado FROM compra WHERE usuario_id = 11 AND videojuego_id = 9;
SELECT usuario_id, videojuego_id, fecha_adquisicion FROM biblioteca WHERE usuario_id = 11 AND videojuego_id = 9;
SELECT count(*) AS sigue_en_lista_deseos FROM lista_deseos WHERE usuario_id = 11 AND videojuego_id = 9;

-- [P12] Error: saldo insuficiente (DEBE FALLAR)
CALL pr_comprar_videojuego(13, 1, NULL);

-- [P13] Error: el juego aún no está publicado (DEBE FALLAR)
CALL pr_comprar_videojuego(9, 10, NULL);

-- [P14] Error: el jugador ya tiene el juego (DEBE FALLAR)
CALL pr_comprar_videojuego(7, 1, NULL);

-- [P15] Error: cuenta suspendida (DEBE FALLAR)
CALL pr_comprar_videojuego(14, 3, NULL);

-- [P16] Comprobación: los intentos fallidos no tocaron el saldo de Mateo (13)
SELECT id, nombre, saldo FROM usuario WHERE id = 13;


-- =====================================================================
-- 2.4 CASO DE USO RF-17 · Reembolsar una compra
-- =====================================================================

-- [P17] Éxito: Daniel pide el reembolso de la compra que acaba de hacer (id 31)
CALL pr_reembolsar_compra(11, 31);

SELECT id, nombre, saldo FROM usuario WHERE id = 11;
SELECT id, videojuego_id, monto, estado FROM compra WHERE id = 31;
SELECT count(*) AS sigue_en_biblioteca FROM biblioteca WHERE usuario_id = 11 AND videojuego_id = 9;

-- [P18] Error: ya fue reembolsada (DEBE FALLAR)
CALL pr_reembolsar_compra(11, 31);

-- [P19] Error: compra de hace más de 14 días (DEBE FALLAR)
CALL pr_reembolsar_compra(7, 1);

-- [P20] Error: la compra es de otro usuario (DEBE FALLAR)
CALL pr_reembolsar_compra(7, 3);


-- =====================================================================
-- 2.4 CASO DE USO RF-15 · Reporte de ventas del desarrollador
-- =====================================================================

-- [P21] Éxito: ventas de PixelArt Studios (1) durante 2026
SELECT * FROM fn_reporte_ventas_desarrollador(1, '2026-01-01', '2026-12-31');

-- [P22] Éxito: ventas de Nebula Soft (5) en todo el periodo (incluye juegos sin ventas)
SELECT * FROM fn_reporte_ventas_desarrollador(5, '2025-01-01', '2026-12-31');

-- [P23] Error: desarrollador inexistente (DEBE FALLAR)
SELECT * FROM fn_reporte_ventas_desarrollador(99, '2026-01-01', '2026-12-31');

-- [P24] Error: periodo invertido (DEBE FALLAR)
SELECT * FROM fn_reporte_ventas_desarrollador(1, '2026-12-31', '2026-01-01');


-- =====================================================================
-- 2.4 TRIGGERS BEFORE · se prueban con INSERT directo (sin procedimiento)
-- =====================================================================

-- [T4] RN-12: no se compra un juego retirado (DEBE FALLAR)
INSERT INTO compra (usuario_id, videojuego_id, monto) VALUES (8, 11, 0.00);

-- [T5] RN-13: no se compra un juego que ya está en la biblioteca (DEBE FALLAR)
INSERT INTO compra (usuario_id, videojuego_id, monto) VALUES (7, 1, 39.99);

-- [T6] RN-15: no se reseña un juego que no se posee (DEBE FALLAR)
INSERT INTO resena (usuario_id, videojuego_id, calificacion, comentario)
VALUES (13, 1, 4, 'Me gustó mucho la historia.');

-- [T7] RN-14: un INSERT directo válido también agrega el juego a la biblioteca
INSERT INTO compra (usuario_id, videojuego_id, monto) VALUES (15, 3, 14.99);
SELECT usuario_id, videojuego_id, fecha_adquisicion FROM biblioteca WHERE usuario_id = 15 AND videojuego_id = 3;


-- =====================================================================
-- 2.5 ATOMICIDAD (RNF-04): si un paso falla, no se descuenta el saldo
-- =====================================================================

-- [A1] Saldo de Carlos (7) antes
SELECT id, nombre, saldo FROM usuario WHERE id = 7;

-- [A2] Transacción manual: descuenta y luego intenta comprar un juego que ya tiene
BEGIN;
UPDATE usuario SET saldo = saldo - 39.99 WHERE id = 7;
INSERT INTO compra (usuario_id, videojuego_id, monto) VALUES (7, 1, 39.99);  -- falla por RN-13
ROLLBACK;

-- [A3] El saldo quedó igual
SELECT id, nombre, saldo FROM usuario WHERE id = 7;


-- =====================================================================
-- 2.5 PRUEBA DE CONCURRENCIA (dos pestañas de Query Tool)
-- No se ejecuta en este archivo; se hace a mano en dos sesiones:
--
--   Sesión A                                   Sesión B
--   BEGIN;
--   CALL pr_comprar_videojuego(15, 9, NULL);
--                                              CALL pr_comprar_videojuego(15, 9, NULL);
--                                              -- queda esperando: la fila del usuario 15
--                                              -- está bloqueada por FOR UPDATE
--   COMMIT;
--                                              ERROR: El usuario 15 ya tiene
--                                              "Sombras de Cartagena" en su biblioteca
--
-- Resultado: una sola compra y un solo descuento de saldo.
-- =====================================================================
