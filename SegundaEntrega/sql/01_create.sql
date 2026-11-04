-- =====================================================================
-- Stanke - Plataforma de gestión y distribución digital de videojuegos
-- 01_create.sql  ·  Creación de tablas, llaves y restricciones
-- PostgreSQL 14 o superior (probado en PostgreSQL 18)
--
-- Las reglas de negocio declarativas (RN-01 a RN-11) se señalan con un
-- comentario -- RN-xx en la línea que las implementa.
-- Las reglas RN-12 a RN-16 necesitan triggers y están en
-- 03_procedimientos_triggers.sql.
-- =====================================================================

DROP TABLE IF EXISTS historial_precio      CASCADE;
DROP TABLE IF EXISTS promocion_videojuego  CASCADE;
DROP TABLE IF EXISTS promocion             CASCADE;
DROP TABLE IF EXISTS amistad               CASCADE;
DROP TABLE IF EXISTS resena                CASCADE;
DROP TABLE IF EXISTS lista_deseos          CASCADE;
DROP TABLE IF EXISTS biblioteca            CASCADE;
DROP TABLE IF EXISTS compra                CASCADE;
DROP TABLE IF EXISTS imagen_videojuego     CASCADE;
DROP TABLE IF EXISTS videojuego_genero     CASCADE;
DROP TABLE IF EXISTS genero                CASCADE;
DROP TABLE IF EXISTS videojuego            CASCADE;
DROP TABLE IF EXISTS desarrollador         CASCADE;
DROP TABLE IF EXISTS usuario               CASCADE;

-- ---------------------------------------------------------------------
-- Usuarios de la plataforma (jugadores, desarrolladores y administradores)
-- ---------------------------------------------------------------------
CREATE TABLE usuario (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,           -- RN-01
    nombre          VARCHAR(120) NOT NULL,
    correo          VARCHAR(254) NOT NULL,
    contrasena_hash VARCHAR(255) NOT NULL,
    rol             VARCHAR(20)  NOT NULL,
    estado          VARCHAR(20)  NOT NULL DEFAULT 'activo',
    fecha_registro  TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    saldo           NUMERIC(12,2) NOT NULL DEFAULT 0,
    CONSTRAINT uq_usuario_correo  UNIQUE (correo),                              -- RN-02
    CONSTRAINT ck_usuario_rol     CHECK (rol IN ('jugador', 'desarrollador', 'administrador')), -- RN-03
    CONSTRAINT ck_usuario_estado  CHECK (estado IN ('activo', 'suspendido')),
    CONSTRAINT ck_usuario_saldo   CHECK (saldo >= 0)                            -- RN-04
);

-- ---------------------------------------------------------------------
-- Perfil de desarrollador / publicador (1:1 con un usuario)
-- ---------------------------------------------------------------------
CREATE TABLE desarrollador (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,               -- RN-01
    usuario_id  BIGINT       NOT NULL,
    nombre      VARCHAR(150) NOT NULL,
    pais        VARCHAR(100) NOT NULL,
    sitio_web   TEXT,
    CONSTRAINT uq_desarrollador_usuario UNIQUE (usuario_id),
    CONSTRAINT fk_desarrollador_usuario
        FOREIGN KEY (usuario_id) REFERENCES usuario(id) ON DELETE RESTRICT
);

-- ---------------------------------------------------------------------
-- Catálogo de videojuegos
-- ---------------------------------------------------------------------
CREATE TABLE videojuego (
    id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,         -- RN-01
    desarrollador_id  BIGINT        NOT NULL,                                   -- RN-06
    titulo            VARCHAR(200)  NOT NULL,
    descripcion       TEXT,
    precio            NUMERIC(12,2) NOT NULL DEFAULT 0,
    fecha_lanzamiento DATE,
    estado            VARCHAR(20)   NOT NULL DEFAULT 'pendiente',               -- RN-07 (inicia en pendiente)
    CONSTRAINT ck_videojuego_precio CHECK (precio >= 0),                        -- RN-05
    CONSTRAINT ck_videojuego_estado
        CHECK (estado IN ('pendiente', 'publicado', 'retirado')),               -- RN-07
    CONSTRAINT uq_videojuego_titulo_desarrollador UNIQUE (desarrollador_id, titulo),
    CONSTRAINT fk_videojuego_desarrollador                                      -- RN-06
        FOREIGN KEY (desarrollador_id) REFERENCES desarrollador(id) ON DELETE RESTRICT
);

CREATE TABLE genero (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,               -- RN-01
    nombre      VARCHAR(80) NOT NULL,
    descripcion TEXT,
    CONSTRAINT uq_genero_nombre UNIQUE (nombre)
);

-- Relación N:M entre videojuego y género
CREATE TABLE videojuego_genero (
    videojuego_id BIGINT NOT NULL,
    genero_id     BIGINT NOT NULL,
    CONSTRAINT pk_videojuego_genero PRIMARY KEY (videojuego_id, genero_id),
    CONSTRAINT fk_videojuego_genero_videojuego
        FOREIGN KEY (videojuego_id) REFERENCES videojuego(id) ON DELETE CASCADE,
    CONSTRAINT fk_videojuego_genero_genero
        FOREIGN KEY (genero_id) REFERENCES genero(id) ON DELETE RESTRICT
);

CREATE TABLE imagen_videojuego (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    videojuego_id BIGINT  NOT NULL,
    url           TEXT    NOT NULL,
    orden         INTEGER NOT NULL DEFAULT 1,
    CONSTRAINT ck_imagen_orden CHECK (orden > 0),
    CONSTRAINT uq_imagen_videojuego_orden UNIQUE (videojuego_id, orden),
    CONSTRAINT fk_imagen_videojuego_videojuego
        FOREIGN KEY (videojuego_id) REFERENCES videojuego(id) ON DELETE CASCADE
);

-- ---------------------------------------------------------------------
-- Compras (tabla de mayor movimiento)
-- ---------------------------------------------------------------------
CREATE TABLE compra (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,             -- RN-01
    usuario_id    BIGINT        NOT NULL,
    videojuego_id BIGINT        NOT NULL,
    fecha         TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    monto         NUMERIC(12,2) NOT NULL,
    estado        VARCHAR(20)   NOT NULL DEFAULT 'completada',
    CONSTRAINT ck_compra_monto  CHECK (monto >= 0),
    CONSTRAINT ck_compra_estado CHECK (estado IN ('completada', 'reembolsada')),
    CONSTRAINT fk_compra_usuario
        FOREIGN KEY (usuario_id) REFERENCES usuario(id) ON DELETE RESTRICT,
    CONSTRAINT fk_compra_videojuego
        FOREIGN KEY (videojuego_id) REFERENCES videojuego(id) ON DELETE RESTRICT
);

-- Biblioteca: juegos que posee cada jugador (N:M usuario-videojuego)
CREATE TABLE biblioteca (
    usuario_id        BIGINT      NOT NULL,
    videojuego_id     BIGINT      NOT NULL,
    fecha_adquisicion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_biblioteca PRIMARY KEY (usuario_id, videojuego_id),
    CONSTRAINT fk_biblioteca_usuario
        FOREIGN KEY (usuario_id) REFERENCES usuario(id) ON DELETE CASCADE,
    CONSTRAINT fk_biblioteca_videojuego
        FOREIGN KEY (videojuego_id) REFERENCES videojuego(id) ON DELETE CASCADE
);

-- Lista de deseos (N:M usuario-videojuego)
CREATE TABLE lista_deseos (
    usuario_id     BIGINT      NOT NULL,
    videojuego_id  BIGINT      NOT NULL,
    fecha_agregado TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_lista_deseos PRIMARY KEY (usuario_id, videojuego_id),
    CONSTRAINT fk_lista_deseos_usuario
        FOREIGN KEY (usuario_id) REFERENCES usuario(id) ON DELETE CASCADE,
    CONSTRAINT fk_lista_deseos_videojuego
        FOREIGN KEY (videojuego_id) REFERENCES videojuego(id) ON DELETE CASCADE
);

CREATE TABLE resena (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,             -- RN-01
    usuario_id    BIGINT      NOT NULL,
    videojuego_id BIGINT      NOT NULL,
    calificacion  INTEGER     NOT NULL,
    comentario    TEXT,
    fecha         TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_resena_calificacion CHECK (calificacion BETWEEN 1 AND 5),    -- RN-08
    CONSTRAINT uq_resena_usuario_videojuego UNIQUE (usuario_id, videojuego_id), -- RN-09
    CONSTRAINT fk_resena_usuario
        FOREIGN KEY (usuario_id) REFERENCES usuario(id) ON DELETE RESTRICT,
    CONSTRAINT fk_resena_videojuego
        FOREIGN KEY (videojuego_id) REFERENCES videojuego(id) ON DELETE RESTRICT
);

CREATE TABLE amistad (
    id                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    usuario_solicita_id BIGINT      NOT NULL,
    usuario_recibe_id   BIGINT      NOT NULL,
    estado              VARCHAR(20) NOT NULL DEFAULT 'pendiente',
    fecha               TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_amistad_estado
        CHECK (estado IN ('pendiente', 'aceptada', 'rechazada')),
    CONSTRAINT ck_amistad_distintos
        CHECK (usuario_solicita_id <> usuario_recibe_id),                       -- RN-11
    CONSTRAINT fk_amistad_usuario_solicita
        FOREIGN KEY (usuario_solicita_id) REFERENCES usuario(id) ON DELETE CASCADE,
    CONSTRAINT fk_amistad_usuario_recibe
        FOREIGN KEY (usuario_recibe_id) REFERENCES usuario(id) ON DELETE CASCADE
);
-- Una sola relación de amistad por pareja, sin importar quién la envió
CREATE UNIQUE INDEX uq_amistad_pareja
    ON amistad (LEAST(usuario_solicita_id, usuario_recibe_id),
                GREATEST(usuario_solicita_id, usuario_recibe_id));

CREATE TABLE promocion (
    id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,              -- RN-01
    nombre       VARCHAR(150) NOT NULL,
    descuento    NUMERIC(5,2) NOT NULL,
    fecha_inicio TIMESTAMPTZ  NOT NULL,
    fecha_fin    TIMESTAMPTZ  NOT NULL,
    CONSTRAINT ck_promocion_descuento CHECK (descuento BETWEEN 1 AND 90),      -- RN-10
    CONSTRAINT ck_promocion_fechas    CHECK (fecha_fin > fecha_inicio)          -- RN-10
);

-- Relación N:M entre promoción y videojuego
CREATE TABLE promocion_videojuego (
    promocion_id  BIGINT NOT NULL,
    videojuego_id BIGINT NOT NULL,
    CONSTRAINT pk_promocion_videojuego PRIMARY KEY (promocion_id, videojuego_id),
    CONSTRAINT fk_promocion_videojuego_promocion
        FOREIGN KEY (promocion_id) REFERENCES promocion(id) ON DELETE CASCADE,
    CONSTRAINT fk_promocion_videojuego_videojuego
        FOREIGN KEY (videojuego_id) REFERENCES videojuego(id) ON DELETE CASCADE
);

-- Auditoría de cambios de precio (la llena el trigger de RN-16)
CREATE TABLE historial_precio (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    videojuego_id   BIGINT        NOT NULL,
    precio_anterior NUMERIC(12,2) NOT NULL,
    precio_nuevo    NUMERIC(12,2) NOT NULL,
    fecha_cambio    TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_historial_precio_anterior CHECK (precio_anterior >= 0),
    CONSTRAINT ck_historial_precio_nuevo    CHECK (precio_nuevo >= 0),
    CONSTRAINT fk_historial_precio_videojuego
        FOREIGN KEY (videojuego_id) REFERENCES videojuego(id) ON DELETE RESTRICT
);

-- ---------------------------------------------------------------------
-- Índices de apoyo para búsquedas y reportes (RF-05, RF-15, RNF-05)
-- ---------------------------------------------------------------------
CREATE INDEX ix_videojuego_desarrollador ON videojuego (desarrollador_id);
CREATE INDEX ix_videojuego_titulo        ON videojuego (lower(titulo));
CREATE INDEX ix_videojuego_genero_genero ON videojuego_genero (genero_id);
CREATE INDEX ix_compra_usuario           ON compra (usuario_id);
CREATE INDEX ix_compra_videojuego_fecha  ON compra (videojuego_id, fecha);
CREATE INDEX ix_resena_videojuego        ON resena (videojuego_id);
CREATE INDEX ix_promocion_videojuego_vj  ON promocion_videojuego (videojuego_id);
CREATE INDEX ix_historial_precio_vj      ON historial_precio (videojuego_id);
