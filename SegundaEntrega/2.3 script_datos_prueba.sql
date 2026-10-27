-- Stanke - 02_datos.sql
-- PostgreSQL
-- Inserción de datos iniciales representativos y realistas

-- 1. USUARIOS (10 registros: jugadores, desarrolladores y administrador)
INSERT INTO usuario (nombre, correo, contrasena_hash, rol, estado, saldo) VALUES
('Carlos Pérez', 'carlos.perez@email.com', '$2a$12$e8Vx1...hash_jugador_1', 'jugador', 'activo', 150.00),
('Ana Gómez', 'ana.gomez@email.com', '$2a$12$e8Vx1...hash_jugador_2', 'jugador', 'activo', 300.50),
('PixelArt Studios', 'contacto@pixelartgames.com', '$2a$12$e8Vx1...hash_dev_1', 'desarrollador', 'activo', 1200.00),
('CyberShark Games', 'info@cybershark.com', '$2a$12$e8Vx1...hash_dev_2', 'desarrollador', 'activo', 5400.00),
('Luis Torres', 'luis.torres@email.com', '$2a$12$e8Vx1...hash_jugador_3', 'jugador', 'activo', 45.00),
('Sofía Martínez', 'sofia.martinez@email.com', '$2a$12$e8Vx1...hash_jugador_4', 'jugador', 'activo', 89.90),
('Admin Sistema', 'admin@stanke.com', '$2a$12$e8Vx1...hash_admin', 'administrador', 'activo', 0.00),
('IndieForge Entertainment', 'soporte@indieforge.com', '$2a$12$e8Vx1...hash_dev_3', 'desarrollador', 'activo', 300.00),
('Apex Interactive', 'contact@apexinteractive.com', '$2a$12$e8Vx1...hash_dev_4', 'desarrollador', 'activo', 850.00),
('Nebula Soft', 'hello@nebulasoft.com', '$2a$12$e8Vx1...hash_dev_5', 'desarrollador', 'activo', 410.00);

-- 2. DESARROLLADORES (5 registros vinculados a usuarios desarrolladores)
INSERT INTO desarrollador (usuario_id, nombre, pais, sitio_web) VALUES
(3, 'PixelArt Studios', 'España', 'https://pixelartgames.example.com'),
(4, 'CyberShark Games', 'Estados Unidos', 'https://cybershark.example.com'),
(8, 'IndieForge Entertainment', 'Argentina', 'https://indieforge.example.com'),
(9, 'Apex Interactive', 'México', 'https://apexinteractive.example.com'),
(10, 'Nebula Soft', 'Colombia', 'https://nebulasoft.example.com');

-- 3. VIDEOJUEGOS (6 registros)
INSERT INTO videojuego (desarrollador_id, titulo, descripcion, precio, fecha_lanzamiento, estado) VALUES
(1, 'Chronos Odyssey', 'Un RPG de acción ambientado en un mundo que se desmorona por anomalías temporales.', 39.99, '2024-05-12', 'publicado'),
(2, 'Neon Cyberpunk Runner', 'Juego de carreras y parkour rápido en una ciudad distópica iluminada por luces de neón.', 19.99, '2025-01-15', 'publicado'),
(3, 'The Last Alchemist', 'Aventura de puzles y alquimia basada en la exploración de mazmorras antiguas.', 14.99, '2023-11-20', 'publicado'),
(4, 'Galactic Wars Online', 'Estrategia espacial multijugador masiva en línea con comercio y diplomacia estelar.', 49.99, '2025-06-10', 'publicado'),
(5, 'Echoes of the Deep', 'Terror psicológico submarino en las profundidades inexploradas del abismo oceánico.', 24.99, '2025-09-05', 'publicado'),
(1, 'Pixel Dungeon Tactics', 'Estrategia por turnos con estética retro de 16 bits y combates tácticos complejos.', 9.99, '2026-02-14', 'publicado');

-- 4. GENEROS (6 registros)
INSERT INTO genero (nombre, descripcion) VALUES
('Acción', 'Juegos enfocados en el combate rápido, reflejos y desafíos dinámicos.'),
('RPG', 'Juegos de rol donde los jugadores controlan el desarrollo y estadísticas de personajes.'),
('Estrategia', 'Juegos que requieren planificación táctica, militar o gestión de recursos.'),
('Terror', 'Juegos diseñados para asustar, generar tensión y atmósfera opresiva.'),
('Indie', 'Juegos independientes desarrollados por estudios creativos pequeños.'),
('Aventura', 'Juegos centrados en la exploración, narrativa y resolución de enigmas.');

-- 5. VIDEOJUEGO_GENERO (6 registros)
INSERT INTO videojuego_genero (videojuego_id, genero_id) VALUES
(1, 2), -- Chronos Odyssey -> RPG
(1, 6), -- Chronos Odyssey -> Aventura
(2, 1), -- Neon Cyberpunk Runner -> Acción
(3, 5), -- The Last Alchemist -> Indie
(4, 3), -- Galactic Wars Online -> Estrategia
(5, 4); -- Echoes of the Deep -> Terror

-- 6. IMAGEN_VIDEOJUEGO (6 registros)
INSERT INTO imagen_videojuego (videojuego_id, url, orden) VALUES
(1, 'https://cdn.stanke.com/games/chronos_portada.jpg', 1),
(2, 'https://cdn.stanke.com/games/neon_banner.jpg', 1),
(3, 'https://cdn.stanke.com/games/alchemist_screen1.jpg', 1),
(4, 'https://cdn.stanke.com/games/galactic_main.jpg', 1),
(5, 'https://cdn.stanke.com/games/echoes_teaser.jpg', 1),
(6, 'https://cdn.stanke.com/games/pixel_thumb.jpg', 1);

-- 7. COMPRA (22 registros - Tabla de mayor movimiento con más de 20 filas)
INSERT INTO compra (usuario_id, videojuego_id, fecha, monto, estado) VALUES
(1, 1, '2026-01-10 14:30:00+00', 39.99, 'completada'),
(1, 2, '2026-01-15 18:20:00+00', 19.99, 'completada'),
(2, 3, '2026-02-01 09:12:00+00', 14.99, 'completada'),
(2, 4, '2026-02-10 20:45:00+00', 49.99, 'completada'),
(5, 1, '2026-02-18 11:00:00+00', 39.99, 'completada'),
(5, 5, '2026-02-20 16:35:00+00', 24.99, 'completada'),
(6, 6, '2026-03-02 12:00:00+00', 9.99, 'completada'),
(1, 3, '2026-03-05 22:15:00+00', 14.99, 'completada'),
(2, 5, '2026-03-10 15:40:00+00', 24.99, 'completada'),
(5, 2, '2026-03-12 17:05:00+00', 19.99, 'reembolsada'),
(6, 1, '2026-03-15 19:30:00+00', 39.99, 'completada'),
(1, 4, '2026-03-20 10:25:00+00', 49.99, 'completada'),
(2, 6, '2026-03-22 14:50:00+00', 9.99, 'completada'),
(5, 3, '2026-03-25 08:10:00+00', 14.99, 'completada'),
(6, 2, '2026-04-01 13:40:00+00', 19.99, 'completada'),
(1, 5, '2026-04-05 16:00:00+00', 24.99, 'completada'),
(2, 1, '2026-04-08 21:10:00+00', 39.99, 'completada'),
(5, 6, '2026-04-10 11:20:00+00', 9.99, 'completada'),
(6, 4, '2026-04-12 18:00:00+00', 49.99, 'completada'),
(1, 6, '2026-04-15 09:55:00+00', 9.99, 'completada'),
(2, 2, '2026-04-18 20:30:00+00', 19.99, 'completada'),
(5, 4, '2026-04-20 14:15:00+00', 49.99, 'completada');

-- 8. BIBLIOTECA (6 registros)
INSERT INTO biblioteca (usuario_id, videojuego_id, fecha_adquisicion) VALUES
(1, 1, '2026-01-10 14:35:00+00'),
(1, 2, '2026-01-15 18:25:00+00'),
(2, 3, '2026-02-01 09:15:00+00'),
(5, 1, '2026-02-18 11:05:00+00'),
(6, 6, '2026-03-02 12:05:00+00'),
(1, 3, '2026-03-05 22:20:00+00');

-- 9. LISTA_DESEOS (6 registros)
INSERT INTO lista_deseos (usuario_id, videojuego_id, fecha_agregado) VALUES
(1, 4, '2026-01-05 10:00:00+00'),
(2, 1, '2026-01-12 11:30:00+00'),
(5, 2, '2026-02-05 15:20:00+00'),
(6, 3, '2026-02-22 17:40:00+00'),
(1, 5, '2026-03-01 09:00:00+00'),
(2, 6, '2026-03-18 12:15:00+00');

-- 10. RESENA (6 registros)
INSERT INTO resena (usuario_id, videojuego_id, calificacion, comentario, fecha) VALUES
(1, 1, 5, 'Una obra maestra absoluta, la ambientación y la narrativa temporal son excepcionales.', '2026-01-12 16:00:00+00'),
(1, 2, 4, 'Muy divertido y rápido, aunque la dificultad en las curvas cerradas es alta.', '2026-01-18 19:10:00+00'),
(2, 3, 4, 'Los puzles de alquimia te hacen pensar bastante. Excelente juego independiente.', '2026-02-03 10:20:00+00'),
(5, 1, 5, 'Increíble jugabilidad, de lo mejor que he jugado este año.', '2026-02-19 12:30:00+00'),
(6, 6, 5, 'Ideal para partidas rápidas de estrategia táctica. Muy recomendado.', '2026-03-03 14:00:00+00'),
(1, 3, 3, 'Entretenido pero corto, esperaba un poco más de profundidad en la historia.', '2026-03-06 23:00:00+00');

-- 11. AMISTAD (5 registros)
INSERT INTO amistad (usuario_solicita_id, usuario_recibe_id, estado, fecha) VALUES
(1, 2, 'aceptada', '2026-01-02 10:00:00+00'),
(2, 5, 'aceptada', '2026-01-05 14:20:00+00'),
(5, 6, 'pendiente', '2026-02-10 18:00:00+00'),
(6, 1, 'aceptada', '2026-02-15 09:10:00+00'),
(1, 5, 'rechazada', '2026-02-20 11:45:00+00');

-- 12. PROMOCION (5 registros)
INSERT INTO promocion (nombre, descuento, fecha_inicio, fecha_fin) VALUES
('Rebajas de Verano 2026', 20.00, '2026-06-01 00:00:00+00', '2026-06-15 23:59:59+00'),
('Fin de Semana Indie', 35.00, '2026-03-10 00:00:00+00', '2026-03-13 23:59:59+00'),
('Aniversario Stanke', 50.00, '2026-08-01 00:00:00+00', '2026-08-07 23:59:59+00'),
('Lanzamientos de Otoño', 15.00, '2026-09-15 00:00:00+00', '2026-09-30 23:59:59+00'),
('Cyber Monday Gaming', 60.00, '2026-11-25 00:00:00+00', '2026-11-28 23:59:59+00');

-- 13. PROMOCION_VIDEOJUEGO (5 registros)
INSERT INTO promocion_videojuego (promocion_id, videojuego_id) VALUES
(1, 1),
(1, 2),
(2, 3),
(3, 4),
(4, 5);

-- 14. HISTORIAL_PRECIO (5 registros)
INSERT INTO historial_precio (videojuego_id, precio_anterior, precio_nuevo, fecha_cambio) VALUES
(1, 49.99, 39.99, '2026-05-01 10:00:00+00'),
(2, 24.99, 19.99, '2025-06-01 10:00:00+00'),
(3, 19.99, 14.99, '2024-12-01 10:00:00+00'),
(4, 59.99, 49.99, '2026-01-10 10:00:00+00'),
(5, 29.99, 24.99, '2026-03-15 10:00:00+00');