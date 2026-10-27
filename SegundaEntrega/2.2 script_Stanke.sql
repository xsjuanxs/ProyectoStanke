-- Stanke - 01_create.sql
-- PostgreSQL
-- Las reglas RN-12 a RN-16 requieren triggers y se implementaran en otro archivo.

DROP TABLE IF EXISTS historial_precio CASCADE;
DROP TABLE IF EXISTS promocion_videojuego CASCADE;
DROP TABLE IF EXISTS promocion CASCADE;
DROP TABLE IF EXISTS amistad CASCADE;
DROP TABLE IF EXISTS resena CASCADE;
DROP TABLE IF EXISTS lista_deseos CASCADE;
DROP TABLE IF EXISTS biblioteca CASCADE;
DROP TABLE IF EXISTS compra CASCADE;
DROP TABLE IF EXISTS imagen_videojuego CASCADE;
DROP TABLE IF EXISTS videojuego_genero CASCADE;
DROP TABLE IF EXISTS genero CASCADE;
DROP TABLE IF EXISTS videojuego CASCADE;
DROP TABLE IF EXISTS desarrollador CASCADE;
DROP TABLE IF EXISTS usuario CASCADE;

CREATE TABLE usuario (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- RN-01
    nombre VARCHAR(120) NOT NULL,
    correo VARCHAR(254) NOT NULL UNIQUE, -- RN-02
    contrasena_hash VARCHAR(255) NOT NULL,
    rol VARCHAR(20) NOT NULL CHECK (rol IN ('jugador', 'desarrollador', 'administrador')), -- RN-03
    estado VARCHAR(20) NOT NULL DEFAULT 'activo'
        CHECK (estado IN ('activo', 'suspendido')),
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    saldo NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (saldo >= 0) -- RN-04
);

CREATE TABLE desarrollador (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- RN-01
    usuario_id BIGINT NOT NULL UNIQUE,
    nombre VARCHAR(150) NOT NULL,
    pais VARCHAR(100),
    sitio_web TEXT,
    -- Declaración explícita de la llave foránea
    CONSTRAINT fk_desarrollador_usuario 
        FOREIGN KEY (usuario_id) 
        REFERENCES usuario(id) 
        ON DELETE RESTRICT
);

CREATE TABLE videojuego (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- RN-01
    desarrollador_id BIGINT NOT NULL, -- RN-06
    titulo VARCHAR(200) NOT NULL,
    descripcion TEXT,
    precio NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (precio >= 0), -- RN-05
    fecha_lanzamiento DATE,
    estado VARCHAR(20) NOT NULL DEFAULT 'pendiente'
        CHECK (estado IN ('pendiente', 'publicado', 'retirado')), -- RN-07
    -- Declaración explícita de la llave foránea
    CONSTRAINT fk_videojuego_desarrollador 
        FOREIGN KEY (desarrollador_id) 
        REFERENCES desarrollador(id) 
        ON DELETE RESTRICT
);

CREATE TABLE genero (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- RN-01
    nombre VARCHAR(80) NOT NULL UNIQUE,
    descripcion TEXT
);

CREATE TABLE videojuego_genero (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    videojuego_id BIGINT NOT NULL,
    genero_id BIGINT NOT NULL,
    UNIQUE (videojuego_id, genero_id),
    -- Declaraciones explícitas de llaves foráneas
    CONSTRAINT fk_videojuego_genero_videojuego 
        FOREIGN KEY (videojuego_id) 
        REFERENCES videojuego(id) 
        ON DELETE CASCADE,
    CONSTRAINT fk_videojuego_genero_genero 
        FOREIGN KEY (genero_id) 
        REFERENCES genero(id) 
        ON DELETE RESTRICT
);

CREATE TABLE imagen_videojuego (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    videojuego_id BIGINT NOT NULL,
    url TEXT NOT NULL,
    orden INTEGER NOT NULL DEFAULT 1 CHECK (orden > 0),
    -- Declaración explícita de la llave foránea
    CONSTRAINT fk_imagen_videojuego_videojuego 
        FOREIGN KEY (videojuego_id) 
        REFERENCES videojuego(id) 
        ON DELETE CASCADE
);

CREATE TABLE compra (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- RN-01
    usuario_id BIGINT NOT NULL,
    videojuego_id BIGINT NOT NULL,
    fecha TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    monto NUMERIC(12,2) NOT NULL CHECK (monto >= 0),
    estado VARCHAR(20) NOT NULL DEFAULT 'completada'
        CHECK (estado IN ('completada', 'reembolsada')),
    -- Declaraciones explícitas de llaves foráneas
    CONSTRAINT fk_compra_usuario 
        FOREIGN KEY (usuario_id) 
        REFERENCES usuario(id) 
        ON DELETE RESTRICT,
    CONSTRAINT fk_compra_videojuego 
        FOREIGN KEY (videojuego_id) 
        REFERENCES videojuego(id) 
        ON DELETE RESTRICT
);

CREATE TABLE biblioteca (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    usuario_id BIGINT NOT NULL,
    videojuego_id BIGINT NOT NULL,
    fecha_adquisicion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (usuario_id, videojuego_id),
    -- Declaraciones explícitas de llaves foráneas
    CONSTRAINT fk_biblioteca_usuario 
        FOREIGN KEY (usuario_id) 
        REFERENCES usuario(id) 
        ON DELETE CASCADE,
    CONSTRAINT fk_biblioteca_videojuego 
        FOREIGN KEY (videojuego_id) 
        REFERENCES videojuego(id) 
        ON DELETE CASCADE
);

CREATE TABLE lista_deseos (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    usuario_id BIGINT NOT NULL,
    videojuego_id BIGINT NOT NULL,
    fecha_agregado TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (usuario_id, videojuego_id),
    -- Declaraciones explícitas de llaves foráneas
    CONSTRAINT fk_lista_deseos_usuario 
        FOREIGN KEY (usuario_id) 
        REFERENCES usuario(id) 
        ON DELETE CASCADE,
    CONSTRAINT fk_lista_deseos_videojuego 
        FOREIGN KEY (videojuego_id) 
        REFERENCES videojuego(id) 
        ON DELETE CASCADE
);

CREATE TABLE resena (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- RN-01
    usuario_id BIGINT NOT NULL,
    videojuego_id BIGINT NOT NULL,
    calificacion INTEGER NOT NULL CHECK (calificacion BETWEEN 1 AND 5), -- RN-08
    comentario TEXT,
    fecha TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (usuario_id, videojuego_id), -- RN-09
    -- Declaraciones explícitas de llaves foráneas
    CONSTRAINT fk_resena_usuario 
        FOREIGN KEY (usuario_id) 
        REFERENCES usuario(id) 
        ON DELETE RESTRICT,
    CONSTRAINT fk_resena_videojuego 
        FOREIGN KEY (videojuego_id) 
        REFERENCES videojuego(id) 
        ON DELETE RESTRICT
);

CREATE TABLE amistad (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    usuario_solicita_id BIGINT NOT NULL,
    usuario_recibe_id BIGINT NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'pendiente'
        CHECK (estado IN ('pendiente', 'aceptada', 'rechazada')),
    fecha TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (usuario_solicita_id <> usuario_recibe_id), -- RN-11
    -- Declaraciones explícitas de llaves foráneas
    CONSTRAINT fk_amistad_usuario_solicita 
        FOREIGN KEY (usuario_solicita_id) 
        REFERENCES usuario(id) 
        ON DELETE CASCADE,
    CONSTRAINT fk_amistad_usuario_recibe 
        FOREIGN KEY (usuario_recibe_id) 
        REFERENCES usuario(id) 
        ON DELETE CASCADE
);

CREATE TABLE promocion (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- RN-01
    nombre VARCHAR(150) NOT NULL,
    descuento NUMERIC(5,2) NOT NULL CHECK (descuento BETWEEN 1 AND 90), -- RN-10
    fecha_inicio TIMESTAMPTZ NOT NULL,
    fecha_fin TIMESTAMPTZ NOT NULL,
    CHECK (fecha_fin > fecha_inicio) -- RN-10
);

CREATE TABLE promocion_videojuego (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    promocion_id BIGINT NOT NULL,
    videojuego_id BIGINT NOT NULL,
    UNIQUE (promocion_id, videojuego_id),
    -- Declaraciones explícitas de llaves foráneas
    CONSTRAINT fk_promocion_videojuego_promocion 
        FOREIGN KEY (promocion_id) 
        REFERENCES promocion(id) 
        ON DELETE CASCADE,
    CONSTRAINT fk_promocion_videojuego_videojuego 
        FOREIGN KEY (videojuego_id) 
        REFERENCES videojuego(id) 
        ON DELETE CASCADE
);

CREATE TABLE historial_precio (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    videojuego_id BIGINT NOT NULL,
    precio_anterior NUMERIC(12,2) NOT NULL CHECK (precio_anterior >= 0),
    precio_nuevo NUMERIC(12,2) NOT NULL CHECK (precio_nuevo >= 0),
    fecha_cambio TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- Declaración explícita de la llave foránea
    CONSTRAINT fk_historial_precio_videojuego 
        FOREIGN KEY (videojuego_id) 
        REFERENCES videojuego(id) 
        ON DELETE RESTRICT
);