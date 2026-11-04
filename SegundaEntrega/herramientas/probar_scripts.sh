#!/usr/bin/env bash
# Crea la base "stanke" desde cero, ejecuta 01, 02 y 03 (deteniéndose ante cualquier error)
# y luego 04 sentencia por sentencia, guardando las salidas reales en ../evidencias/.
#
# Uso:  PSQL="/c/Program Files/PostgreSQL/18/bin/psql" PGHOST=localhost PGPORT=5432 PGUSER=postgres \
#       bash herramientas/probar_scripts.sh
# (la contraseña se toma de PGPASSWORD o de pgpass.conf si el servidor la pide)
set -u
cd "$(dirname "$0")/.."
PSQL="${PSQL:-psql}"
DB="${DB:-stanke}"
export PGCLIENTENCODING=UTF8 LC_ALL=C
mkdir -p evidencias

"$PSQL" -d postgres -q -c "DROP DATABASE IF EXISTS $DB;" -c "CREATE DATABASE $DB;" || exit 1

{
  "$PSQL" -d postgres -At -c "SELECT version();"
  for f in 01_create.sql 02_datos.sql 03_procedimientos_triggers.sql; do
    echo "=== $f"
    "$PSQL" -d "$DB" -v ON_ERROR_STOP=1 -f "sql/$f" 2>&1 | grep -v 'does not exist, skipping'
    echo "=== $f -> código de salida ${PIPESTATUS[0]}"
  done
} > evidencias/ejecucion_01_02_03.txt

"$PSQL" -d "$DB" -c "
SELECT 'usuario' AS tabla, count(*) AS filas FROM usuario
UNION ALL SELECT 'desarrollador', count(*) FROM desarrollador
UNION ALL SELECT 'videojuego', count(*) FROM videojuego
UNION ALL SELECT 'genero', count(*) FROM genero
UNION ALL SELECT 'videojuego_genero', count(*) FROM videojuego_genero
UNION ALL SELECT 'imagen_videojuego', count(*) FROM imagen_videojuego
UNION ALL SELECT 'compra', count(*) FROM compra
UNION ALL SELECT 'biblioteca', count(*) FROM biblioteca
UNION ALL SELECT 'lista_deseos', count(*) FROM lista_deseos
UNION ALL SELECT 'resena', count(*) FROM resena
UNION ALL SELECT 'amistad', count(*) FROM amistad
UNION ALL SELECT 'promocion', count(*) FROM promocion
UNION ALL SELECT 'promocion_videojuego', count(*) FROM promocion_videojuego
UNION ALL SELECT 'historial_precio', count(*) FROM historial_precio;" > evidencias/conteo_filas.txt

"$PSQL" -d "$DB" -e -f sql/04_pruebas.sql > evidencias/salida_04_pruebas.txt 2>&1

# Prueba de concurrencia: dos sesiones compran el mismo juego para el mismo jugador
C=(-d "$DB")
{
  echo "=== Antes"
  "$PSQL" "${C[@]}" -c "SELECT id, nombre, saldo FROM usuario WHERE id = 15;"
} > evidencias/concurrencia.txt
( "$PSQL" "${C[@]}" -e -c "SELECT 'A inicia: ' || clock_timestamp()::time(3) AS t" -c "BEGIN" \
     -c "CALL pr_comprar_videojuego(15, 9, NULL)" -c "SELECT pg_sleep(5)" \
     -c "SELECT 'A confirma: ' || clock_timestamp()::time(3) AS t" -c "COMMIT" > evidencias/.sesionA 2>&1 ) &
sleep 1
"$PSQL" "${C[@]}" -e -c "SELECT 'B inicia: ' || clock_timestamp()::time(3) AS t" -c '\timing on' \
     -c "CALL pr_comprar_videojuego(15, 9, NULL)" \
     -c "SELECT 'B termina: ' || clock_timestamp()::time(3) AS t" > evidencias/.sesionB 2>&1
wait
{
  echo; echo "=== Sesión A"; cat evidencias/.sesionA
  echo; echo "=== Sesión B"; cat evidencias/.sesionB
  echo; echo "=== Después"
  "$PSQL" "${C[@]}" -c "SELECT id, nombre, saldo FROM usuario WHERE id = 15;" \
       -c "SELECT id, usuario_id, videojuego_id, monto, estado FROM compra WHERE usuario_id = 15 AND videojuego_id = 9;"
} >> evidencias/concurrencia.txt
rm -f evidencias/.sesionA evidencias/.sesionB
echo "Listo: revise evidencias/"
