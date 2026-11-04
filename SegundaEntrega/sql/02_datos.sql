-- =====================================================================
-- Stanke · 02_datos.sql · Datos de prueba
-- Se ejecuta completo después de 01_create.sql (y antes de 03).
--
-- Los datos son coherentes con las reglas de negocio aunque los triggers
-- todavía no existan cuando se cargan:
--   · cada compra 'completada' tiene su fila en biblioteca (RN-14);
--   · las compras reembolsadas no están en la biblioteca;
--   · las reseñas son solo de juegos que el jugador posee (RN-15);
--   · el monto de cada compra es el precio vigente en su fecha,
--     con el descuento de la promoción activa cuando aplica.
-- Los IDs se generan con IDENTITY en el orden de inserción.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. USUARIO (15): 1 administrador, 5 cuentas de estudio, 9 jugadores
--    contrasena_hash: hashes bcrypt reales (costo 12)  -- RNF-01
-- ---------------------------------------------------------------------
INSERT INTO usuario (nombre, correo, contrasena_hash, rol, estado, fecha_registro, saldo) VALUES
('Laura Castaño Méndez',     'laura.castano@stanke.co',        '$2b$12$bQy79C9Xn/Exh16v2uXxluyqYOMV59gt8cueaLthjJ/IEByY47j16', 'administrador', 'activo',     '2025-01-10 08:00:00-05',   0.00), -- 1
('PixelArt Studios',         'contacto@pixelartstudios.es',    '$2b$12$Ss53iqnK7dUMd0qXLNa.6OAxFkRRcXPK5.Juk5FzVFB0659MkWRQy', 'desarrollador', 'activo',     '2025-01-20 10:15:00-05',   0.00), -- 2
('CyberShark Games',         'info@cybersharkgames.com',       '$2b$12$wcz5xWUDD2qgEipXSZHeLOC8jI/L8/Xoex.qFkTzmiN9/Ec6vN3MG', 'desarrollador', 'activo',     '2025-02-03 14:40:00-05',   0.00), -- 3
('IndieForge Entertainment', 'soporte@indieforge.com.ar',      '$2b$12$UTDI3iq6FTl68OXoQceNqOdmoJg4cqqBgoG61iGjxVhn4IAD.0xs2', 'desarrollador', 'activo',     '2025-02-17 09:05:00-05',   0.00), -- 4
('Apex Interactive',         'contacto@apexinteractive.mx',    '$2b$12$OH51nTT4m0yxnUsWt22cYOUmG/JA3Wl0bnRsCwzjVAWsgiQn.uzwK', 'desarrollador', 'activo',     '2025-03-05 11:30:00-05',   0.00), -- 5
('Nebula Soft',              'hola@nebulasoft.co',             '$2b$12$8uB6fnltkFQUAH8lUmHUHO2sBMbDiURO946OwZmKXiq.cQcSFl6mq', 'desarrollador', 'activo',     '2025-03-21 16:20:00-05',   0.00), -- 6
('Carlos Pérez Rojas',       'carlos.perez@gmail.com',         '$2b$12$iGQbk5kfOUrvOjTlLEinXuJG4l7js3QpdxJXjJBXRKm/6Uns4Isoa', 'jugador',       'activo',     '2025-04-02 19:10:00-05',  85.50), -- 7
('Ana María Gómez',          'anamaria.gomez@hotmail.com',     '$2b$12$f0hS0h8IpbuG4oBYLXsV9esnar1JFqzciVWUwsaXFkh35VpkewZyy', 'jugador',       'activo',     '2025-04-15 20:45:00-05',  42.00), -- 8
('Luis Fernando Torres',     'lf.torres@outlook.com',          '$2b$12$m7OXWitMzO34s9SGB1mbrOdLUsrGqjdMdVLZ.LKti5y/lHsQ5.70K', 'jugador',       'activo',     '2025-05-09 12:00:00-05', 120.00), -- 9
('Sofía Martínez Díaz',      'sofia.martinez@gmail.com',       '$2b$12$WiFxHxk8blWWCvwrQZaYKeIZNtfdOYynrUlt9cQaof9UblJA5yAje', 'jugador',       'activo',     '2025-06-22 18:25:00-05',  15.30), -- 10
('Daniel Herrera Cruz',      'daniel.herrera@yahoo.com',       '$2b$12$qMQKUtei4cZA..afhM1FneshlxqHnOkWlxTahpZ2lrX21q.8nQ.7G', 'jugador',       'activo',     '2025-08-30 21:35:00-05',  60.00), -- 11
('Camila Restrepo Vélez',    'camila.restrepo@gmail.com',      '$2b$12$.wb8Un3.vdeUO36zOuD3VOyxgECfwaoKz2nptNWNkdSDhFSRzk8li', 'jugador',       'activo',     '2025-10-11 15:50:00-05', 200.00), -- 12
('Mateo Salazar Quintero',   'mateo.salazar@outlook.com',      '$2b$12$GxdcVWfmf1D/TmY4RAWQmuBm72tZLUOyfflpOwbuUXuNCjDW6m6KW', 'jugador',       'activo',     '2026-01-19 22:05:00-05',   5.25), -- 13
('Juliana Ospina Cárdenas',  'juliana.ospina@gmail.com',       '$2b$12$hapaCHh1UlhqW6rIsGY9KudPUIuvbNhUpHIXMQDYNIST96kgZgIUu', 'jugador',       'suspendido', '2026-03-07 10:40:00-05',  30.00), -- 14
('Sebastián Vargas León',    'sebastian.vargas@hotmail.com',   '$2b$12$THd/e7B6R4Nxyq77PEpbcupVyALeuVvFVgTSwmNatHsk5gcoqgldW', 'jugador',       'activo',     '2026-06-14 17:15:00-05',  75.00); -- 15

-- ---------------------------------------------------------------------
-- 2. DESARROLLADOR (5): un perfil por cada cuenta con rol desarrollador
-- ---------------------------------------------------------------------
INSERT INTO desarrollador (usuario_id, nombre, pais, sitio_web) VALUES
(2, 'PixelArt Studios',         'España',         'https://www.pixelartstudios.es'),       -- 1
(3, 'CyberShark Games',         'Estados Unidos', 'https://www.cybersharkgames.com'),      -- 2
(4, 'IndieForge Entertainment', 'Argentina',      'https://www.indieforge.com.ar'),        -- 3
(5, 'Apex Interactive',         'México',         'https://www.apexinteractive.mx'),       -- 4
(6, 'Nebula Soft',              'Colombia',       'https://www.nebulasoft.co');            -- 5

-- ---------------------------------------------------------------------
-- 3. GENERO (8)
-- ---------------------------------------------------------------------
INSERT INTO genero (nombre, descripcion) VALUES
('Acción',     'Juegos enfocados en el combate rápido, los reflejos y los desafíos dinámicos.'),          -- 1
('RPG',        'Juegos de rol en los que el jugador controla el desarrollo y las estadísticas de su personaje.'), -- 2
('Estrategia', 'Juegos que exigen planificación táctica, militar o de gestión de recursos.'),             -- 3
('Terror',     'Juegos diseñados para generar tensión, miedo y una atmósfera opresiva.'),                 -- 4
('Indie',      'Juegos independientes creados por estudios pequeños.'),                                    -- 5
('Aventura',   'Juegos centrados en la exploración, la narrativa y la resolución de enigmas.'),            -- 6
('Carreras',   'Juegos de conducción y competencia de velocidad.'),                                        -- 7
('Simulación', 'Juegos que recrean actividades reales como la agricultura, la gestión o el transporte.'); -- 8

-- ---------------------------------------------------------------------
-- 4. VIDEOJUEGO (11): 9 publicados, 1 pendiente y 1 retirado
-- ---------------------------------------------------------------------
INSERT INTO videojuego (desarrollador_id, titulo, descripcion, precio, fecha_lanzamiento, estado) VALUES
(1, 'Chronos Odyssey',         'RPG de acción ambientado en un mundo que se desmorona por anomalías temporales.',               39.99, '2024-05-12', 'publicado'), -- 1
(2, 'Neon Cyberpunk Runner',   'Carreras y parkour a toda velocidad en una ciudad distópica iluminada por neón.',               19.99, '2025-01-15', 'publicado'), -- 2
(3, 'The Last Alchemist',      'Aventura de puzles y alquimia en mazmorras antiguas.',                                           14.99, '2023-11-20', 'publicado'), -- 3
(4, 'Galactic Wars Online',    'Estrategia espacial multijugador con comercio y diplomacia entre facciones.',                   49.99, '2025-06-10', 'publicado'), -- 4
(5, 'Echoes of the Deep',      'Terror psicológico en una estación de investigación en el fondo del océano.',                   24.99, '2025-09-05', 'publicado'), -- 5
(1, 'Pixel Dungeon Tactics',   'Estrategia por turnos con estética de 16 bits y combates tácticos.',                              9.99, '2026-02-14', 'publicado'), -- 6
(3, 'Granja del Valle Andino', 'Simulador de granja en las montañas andinas: cultivos, ganado y mercados de pueblo.',           12.99, '2025-10-01', 'publicado'), -- 7
(2, 'Turbo Drift Legends',     'Carreras de derrape en circuitos urbanos de todo el mundo.',                                     29.99, '2026-04-20', 'publicado'), -- 8
(5, 'Sombras de Cartagena',    'Aventura de acción y sigilo en la Cartagena colonial, entre piratas y contrabandistas.',         34.99, '2026-08-28', 'publicado'), -- 9
(4, 'Mechs of Titan',          'Combate de robots gigantes en las lunas de Saturno. En revisión antes de su publicación.',       44.99, '2026-12-01', 'pendiente'), -- 10
(2, 'Battle Arena Zero',       'Arena de combate gratuita por equipos. Retirada del catálogo por cierre de sus servidores.',     0.00, '2025-03-01', 'retirado');  -- 11

-- ---------------------------------------------------------------------
-- 5. VIDEOJUEGO_GENERO (18): todo videojuego tiene al menos un género
-- ---------------------------------------------------------------------
INSERT INTO videojuego_genero (videojuego_id, genero_id) VALUES
(1, 2), (1, 6),      -- Chronos Odyssey: RPG, Aventura
(2, 1), (2, 7),      -- Neon Cyberpunk Runner: Acción, Carreras
(3, 5), (3, 6),      -- The Last Alchemist: Indie, Aventura
(4, 3),              -- Galactic Wars Online: Estrategia
(5, 4), (5, 6),      -- Echoes of the Deep: Terror, Aventura
(6, 3), (6, 5),      -- Pixel Dungeon Tactics: Estrategia, Indie
(7, 8), (7, 5),      -- Granja del Valle Andino: Simulación, Indie
(8, 7),              -- Turbo Drift Legends: Carreras
(9, 6), (9, 1),      -- Sombras de Cartagena: Aventura, Acción
(10, 1),             -- Mechs of Titan: Acción
(11, 1);             -- Battle Arena Zero: Acción

-- ---------------------------------------------------------------------
-- 6. IMAGEN_VIDEOJUEGO (14)
-- ---------------------------------------------------------------------
INSERT INTO imagen_videojuego (videojuego_id, url, orden) VALUES
(1,  'https://cdn.stanke.co/juegos/chronos-odyssey/portada.jpg',         1),
(1,  'https://cdn.stanke.co/juegos/chronos-odyssey/combate.jpg',         2),
(2,  'https://cdn.stanke.co/juegos/neon-cyberpunk-runner/portada.jpg',   1),
(2,  'https://cdn.stanke.co/juegos/neon-cyberpunk-runner/ciudad.jpg',    2),
(3,  'https://cdn.stanke.co/juegos/the-last-alchemist/portada.jpg',      1),
(4,  'https://cdn.stanke.co/juegos/galactic-wars-online/portada.jpg',    1),
(4,  'https://cdn.stanke.co/juegos/galactic-wars-online/flota.jpg',      2),
(5,  'https://cdn.stanke.co/juegos/echoes-of-the-deep/portada.jpg',      1),
(6,  'https://cdn.stanke.co/juegos/pixel-dungeon-tactics/portada.jpg',   1),
(7,  'https://cdn.stanke.co/juegos/granja-del-valle-andino/portada.jpg', 1),
(8,  'https://cdn.stanke.co/juegos/turbo-drift-legends/portada.jpg',     1),
(9,  'https://cdn.stanke.co/juegos/sombras-de-cartagena/portada.jpg',    1),
(10, 'https://cdn.stanke.co/juegos/mechs-of-titan/portada.jpg',          1),
(11, 'https://cdn.stanke.co/juegos/battle-arena-zero/portada.jpg',       1);

-- ---------------------------------------------------------------------
-- 7. PROMOCION (6) y PROMOCION_VIDEOJUEGO (15)
-- ---------------------------------------------------------------------
INSERT INTO promocion (nombre, descuento, fecha_inicio, fecha_fin) VALUES
('Navidad Stanke 2025',      30.00, '2025-12-20 00:00:00-05', '2026-01-05 23:59:59-05'), -- 1
('Fin de Semana Indie',      35.00, '2026-03-13 00:00:00-05', '2026-03-16 23:59:59-05'), -- 2
('Rebajas de Verano 2026',   20.00, '2026-06-20 00:00:00-05', '2026-07-05 23:59:59-05'), -- 3
('Halloween de Terror',      40.00, '2026-10-24 00:00:00-05', '2026-11-02 23:59:59-05'), -- 4
('Festival de Otoño Stanke', 25.00, '2026-11-01 00:00:00-05', '2026-11-30 23:59:59-05'), -- 5
('Black Friday Gaming',      50.00, '2026-11-27 00:00:00-05', '2026-11-30 23:59:59-05'); -- 6

INSERT INTO promocion_videojuego (promocion_id, videojuego_id) VALUES
(1, 1), (1, 2), (1, 5),
(2, 3), (2, 6), (2, 7),
(3, 1), (3, 2), (3, 4),
(4, 5),
(5, 3), (5, 8), (5, 9),
(6, 1), (6, 4);

-- ---------------------------------------------------------------------
-- 8. HISTORIAL_PRECIO (6): cambios de precio anteriores a las compras
-- ---------------------------------------------------------------------
INSERT INTO historial_precio (videojuego_id, precio_anterior, precio_nuevo, fecha_cambio) VALUES
(3, 19.99, 14.99, '2025-09-10 09:00:00-05'),
(1, 49.99, 39.99, '2025-11-01 08:00:00-05'),
(2, 24.99, 19.99, '2025-11-15 08:00:00-05'),
(4, 59.99, 49.99, '2025-11-20 08:00:00-05'),
(5, 29.99, 24.99, '2025-11-25 08:00:00-05'),
(7, 14.99, 12.99, '2026-02-01 08:00:00-05');

-- ---------------------------------------------------------------------
-- 9. COMPRA (30): tabla de mayor movimiento
--    Montos con descuento: Navidad 30 %, Indie 35 %, Verano 20 %,
--    Halloween 40 %, Otoño 25 % (ver promociones).
-- ---------------------------------------------------------------------
INSERT INTO compra (usuario_id, videojuego_id, fecha, monto, estado) VALUES
( 7,  1, '2025-12-02 19:15:00-05', 39.99, 'completada'),  --  1
( 7, 11, '2025-12-05 20:00:00-05',  0.00, 'completada'),  --  2 juego gratuito, hoy retirado
( 8,  3, '2025-12-10 10:30:00-05', 14.99, 'completada'),  --  3
( 9,  4, '2025-12-14 21:40:00-05', 49.99, 'completada'),  --  4
(10,  2, '2025-12-22 16:05:00-05', 13.99, 'completada'),  --  5 Navidad
(11,  5, '2025-12-28 23:10:00-05', 17.49, 'completada'),  --  6 Navidad
( 7,  2, '2026-01-03 18:45:00-05', 13.99, 'completada'),  --  7 Navidad
(12,  1, '2026-01-12 09:20:00-05', 39.99, 'completada'),  --  8
( 8,  5, '2026-01-25 22:00:00-05', 24.99, 'reembolsada'), --  9
(13,  4, '2026-02-02 17:35:00-05', 49.99, 'completada'),  -- 10
( 9,  6, '2026-02-20 20:10:00-05',  9.99, 'completada'),  -- 11
(10,  6, '2026-03-14 15:00:00-05',  6.49, 'completada'),  -- 12 Indie
(11,  3, '2026-03-15 11:25:00-05',  9.74, 'completada'),  -- 13 Indie
(12,  7, '2026-03-15 19:50:00-05',  8.44, 'completada'),  -- 14 Indie
(14,  1, '2026-03-20 21:30:00-05', 39.99, 'completada'),  -- 15
( 7,  4, '2026-04-08 18:00:00-05', 49.99, 'completada'),  -- 16
(13,  8, '2026-04-25 20:45:00-05', 29.99, 'completada'),  -- 17
( 8,  1, '2026-05-10 14:15:00-05', 39.99, 'completada'),  -- 18
(11,  1, '2026-06-21 10:00:00-05', 31.99, 'completada'),  -- 19 Verano
( 9,  2, '2026-06-25 19:30:00-05', 15.99, 'completada'),  -- 20 Verano
(12,  4, '2026-07-02 22:05:00-05', 39.99, 'reembolsada'), -- 21 Verano
(15,  6, '2026-07-15 16:40:00-05',  9.99, 'completada'),  -- 22
(10,  7, '2026-08-03 13:10:00-05', 12.99, 'completada'),  -- 23
(15,  1, '2026-08-19 21:00:00-05', 39.99, 'completada'),  -- 24
( 7,  5, '2026-09-05 20:20:00-05', 24.99, 'completada'),  -- 25
( 8,  8, '2026-09-18 17:55:00-05', 29.99, 'completada'),  -- 26
(11,  7, '2026-10-12 12:00:00-05', 12.99, 'completada'),  -- 27
(13,  5, '2026-10-25 22:30:00-05', 14.99, 'completada'),  -- 28 Halloween
(10,  5, '2026-10-30 23:45:00-05', 14.99, 'completada'),  -- 29 Halloween
( 9,  3, '2026-11-01 18:00:00-05', 11.24, 'completada');  -- 30 Otoño

-- ---------------------------------------------------------------------
-- 10. BIBLIOTECA (28): una fila por cada compra completada (RN-14)
-- ---------------------------------------------------------------------
INSERT INTO biblioteca (usuario_id, videojuego_id, fecha_adquisicion)
SELECT usuario_id, videojuego_id, fecha
  FROM compra
 WHERE estado = 'completada';

-- ---------------------------------------------------------------------
-- 11. LISTA_DESEOS (11): solo juegos que el jugador aún no posee
-- ---------------------------------------------------------------------
INSERT INTO lista_deseos (usuario_id, videojuego_id, fecha_agregado) VALUES
( 7, 8, '2026-05-02 20:10:00-05'),
( 7, 9, '2026-09-01 19:00:00-05'),
( 8, 5, '2026-02-10 21:30:00-05'),
( 8, 9, '2026-09-02 18:45:00-05'),
( 9, 8, '2026-05-15 12:20:00-05'),
(10, 1, '2026-06-01 17:05:00-05'),
(11, 9, '2026-08-30 22:40:00-05'),
(12, 4, '2026-07-20 10:15:00-05'),
(13, 3, '2026-10-28 23:00:00-05'),
(14, 4, '2026-03-25 16:30:00-05'),
(15, 3, '2026-10-02 14:55:00-05');

-- ---------------------------------------------------------------------
-- 12. RESENA (20): solo sobre juegos de la biblioteca (RN-15),
--     una por jugador y juego (RN-09)
-- ---------------------------------------------------------------------
INSERT INTO resena (usuario_id, videojuego_id, calificacion, comentario, fecha) VALUES
( 7,  1, 5, 'Una obra maestra: la narrativa con saltos temporales está muy bien llevada.',            '2025-12-09 22:00:00-05'),
( 7, 11, 2, 'Era divertido con amigos, pero los servidores siempre estaban llenos de tramposos.',   '2025-12-07 21:15:00-05'),
( 8,  3, 4, 'Los puzles de alquimia te obligan a pensar. Muy buen juego independiente.',            '2025-12-18 10:20:00-05'),
(10,  2, 4, 'Rápido y vistoso; las curvas cerradas del último distrito son muy exigentes.',         '2026-01-02 19:40:00-05'),
( 9,  4, 3, 'Gran escala, pero el inicio es lento y la diplomacia tiene poca profundidad.',         '2026-01-05 23:10:00-05'),
(11,  5, 5, 'El diseño de sonido da miedo de verdad. Jugarlo con audífonos es otra experiencia.',  '2026-01-08 00:30:00-05'),
( 7,  2, 4, 'Muy entretenido para partidas cortas, aunque la banda sonora se repite.',              '2026-01-10 18:00:00-05'),
(12,  1, 5, 'De lo mejor que he jugado este año; el sistema de combate es muy fluido.',             '2026-01-25 20:30:00-05'),
(13,  4, 5, 'Las batallas de flotas con amigos son espectaculares.',                                '2026-02-15 21:00:00-05'),
( 9,  6, 5, 'Ideal para partidas rápidas de estrategia. Muy recomendado.',                          '2026-03-01 14:00:00-05'),
(10,  6, 4, 'Buen nivel de reto, aunque algunos mapas se sienten repetidos.',                       '2026-03-20 16:45:00-05'),
(11,  3, 3, 'Entretenido pero corto; esperaba más profundidad en la historia.',                    '2026-03-22 23:00:00-05'),
(12,  7, 4, 'Relajante y con mucho cariño por la cultura andina.',                                  '2026-03-28 11:10:00-05'),
(14,  1, 2, 'El juego es bueno pero en mi equipo se cierra cada media hora.',                      '2026-03-28 22:35:00-05'),
( 7,  4, 4, 'Mucho contenido; las partidas largas pueden durar toda una tarde.',                    '2026-04-20 17:25:00-05'),
(13,  8, 3, 'Los circuitos son bonitos pero el control al derrapar es impreciso.',                  '2026-05-03 20:00:00-05'),
( 8,  1, 5, 'Valió cada peso. La banda sonora es increíble.',                                       '2026-05-20 13:50:00-05'),
(15,  6, 5, 'Pocas veces un juego tan pequeño engancha tanto.',                                      '2026-07-25 18:05:00-05'),
(10,  7, 5, 'Mi juego favorito para desconectarme después de clase.',                               '2026-08-15 21:20:00-05'),
( 7,  5, 4, 'Atmósfera impecable; le faltan algunos sustos más en la recta final.',                 '2026-09-12 23:55:00-05');

-- ---------------------------------------------------------------------
-- 13. AMISTAD (7)
-- ---------------------------------------------------------------------
INSERT INTO amistad (usuario_solicita_id, usuario_recibe_id, estado, fecha) VALUES
( 7,  8, 'aceptada',  '2025-05-01 18:00:00-05'),
( 8,  9, 'aceptada',  '2025-06-10 20:30:00-05'),
( 9, 10, 'pendiente', '2025-07-03 12:15:00-05'),
(10,  7, 'aceptada',  '2025-07-20 19:45:00-05'),
(11, 12, 'rechazada', '2025-11-02 21:10:00-05'),
(13,  7, 'pendiente', '2026-02-01 16:00:00-05'),
(12, 15, 'aceptada',  '2026-06-20 22:30:00-05');
