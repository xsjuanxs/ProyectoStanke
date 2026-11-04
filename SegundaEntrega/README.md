# Stanke · Entrega 2 — Modelo de datos, implementación y lógica en la base de datos

## Contenido

| Ruta | Qué es |
|---|---|
| `Entrega2_Stanke.docx` / `.pdf` | Documento de la entrega (portada, 2.1 a 2.5, anexos). Falta llenar **Grupo** y **Fecha** en la portada. |
| `sql/01_create.sql` | 14 tablas, llaves, CHECK/UNIQUE/DEFAULT e índices. Reglas RN-01 a RN-11 marcadas con `-- RN-xx`. |
| `sql/02_datos.sql` | 194 filas de prueba coherentes con las reglas (30 compras). |
| `sql/03_procedimientos_triggers.sql` | RF-03, RF-06, RF-14, RF-15, RF-17 y triggers RN-12 a RN-16. |
| `sql/04_pruebas.sql` | Pruebas de 2.3 y 2.4 (incluye las que deben fallar). Se ejecuta sentencia por sentencia. |
| `2.1 DiagramaRelacional.png` | Diagrama relacional (coincide con `01_create.sql`). |
| `2.1 CodigoDiagramaRelacional.mmd` | El mismo modelo en Mermaid (se puede pegar en mermaid.live). |
| `evidencias/` | Salidas reales de psql usadas en el documento. |
| `herramientas/` | Scripts para regenerar evidencias, diagrama y documento. |

## Cómo ejecutar (pgAdmin o psql)

Sobre una base de datos vacía, en este orden:

```
01_create.sql  →  02_datos.sql  →  03_procedimientos_triggers.sql
```

Luego `04_pruebas.sql` sentencia por sentencia, **en orden** (algunas pruebas usan los IDs que generan las anteriores, por ejemplo la compra 31).

Con psql:

```bash
createdb stanke
psql -d stanke -v ON_ERROR_STOP=1 -f sql/01_create.sql
psql -d stanke -v ON_ERROR_STOP=1 -f sql/02_datos.sql
psql -d stanke -v ON_ERROR_STOP=1 -f sql/03_procedimientos_triggers.sql
psql -d stanke -e -f sql/04_pruebas.sql
```

Requiere PostgreSQL 14 o superior (`CREATE OR REPLACE TRIGGER`). Probado en PostgreSQL 18.1.

## Regenerar evidencias, diagrama y documento

```bash
# 1. Evidencias (crea/borra la base "stanke" en el servidor indicado)
PSQL="/c/Program Files/PostgreSQL/18/bin/psql" PGHOST=localhost PGPORT=5433 PGUSER=postgres \
  bash herramientas/probar_scripts.sh
# 2. Diagrama
python herramientas/diagrama_er.py "2.1 DiagramaRelacional.png"
# 3. Documento Word (necesita python-docx); luego exportar a PDF desde Word
python herramientas/generar_documento.py
```

## Antes de entregar

1. Llenar **Grupo** y **Fecha** en la portada y exportar a PDF.
2. Armar `Entrega2_Stanke_<Grupo>.zip` con el PDF y la carpeta `sql/` (los 4 archivos).
