"""Genera Entrega2_Stanke.docx con las salidas REALES guardadas en ../evidencias/.

Uso (desde SegundaEntrega/):  python herramientas/generar_documento.py
Antes hay que correr herramientas/probar_scripts.sh para regenerar las evidencias.
"""
import re
from pathlib import Path

from docx import Document
from docx.enum.section import WD_SECTION
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_BREAK
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Pt, RGBColor

BASE = Path(__file__).resolve().parent.parent
SQL = BASE / "sql"
EVI = BASE / "evidencias"
OUT = BASE / "Entrega2_Stanke.docx"

AZUL = RGBColor(0x1F, 0x3A, 0x5F)
FUENTE = "Calibri"
MONO = "Consolas"

# ---------------------------------------------------------------------------
# Salidas reales de 04_pruebas.sql, indexadas por etiqueta [R1], [P1], [T1] ...
# ---------------------------------------------------------------------------

def parse_pruebas():
    sql = (SQL / "04_pruebas.sql").read_text(encoding="utf-8")
    out = (EVI / "salida_04_pruebas.txt").read_text(encoding="utf-8")
    out = re.sub(r"psql:(?:sql/)?04_pruebas\.sql:\d+: ", "", out)
    label, buf, stmts = None, [], []
    for line in sql.splitlines():
        s = line.strip()
        if s.startswith("--"):
            m = re.match(r"--\s*\[(\w+)\]", s)
            if m:
                label = m.group(1)
            continue
        if not s and not buf:
            continue
        code = re.sub(r"\s+--\s.*$", "", line)
        buf.append(code)
        if code.rstrip().endswith(";"):
            stmts.append((label, "\n".join(buf)))
            buf = []
    pos, cursor = [], 0
    for lab, st in stmts:
        first = st.splitlines()[0].strip()
        i = out.find(first, cursor)
        if i < 0:
            raise SystemExit(f"No encontré en la salida la sentencia de [{lab}]: {first}")
        pos.append(i)
        cursor = i + len(first)
    pos.append(len(out))
    blocks = {}
    for k, (lab, _) in enumerate(stmts):
        blocks.setdefault(lab, []).append(out[pos[k]:pos[k + 1]].rstrip())
    return {k: "\n\n".join(v) for k, v in blocks.items()}


OUTS = parse_pruebas()


def salida(*labels):
    return "\n\n".join(OUTS[l] for l in labels)


# ---------------------------------------------------------------------------
# Ayudas de formato
# ---------------------------------------------------------------------------

def shade(cell, color):
    tcPr = cell._tc.get_or_add_tcPr()
    shd = OxmlElement("w:shd")
    shd.set(qn("w:val"), "clear")
    shd.set(qn("w:color"), "auto")
    shd.set(qn("w:fill"), color)
    tcPr.append(shd)


def cell_margins(table, top=60, bottom=60, left=100, right=100):
    tblPr = table._tbl.tblPr
    mar = OxmlElement("w:tblCellMar")
    for side, val in (("top", top), ("bottom", bottom), ("left", left), ("right", right)):
        el = OxmlElement(f"w:{side}")
        el.set(qn("w:w"), str(val))
        el.set(qn("w:type"), "dxa")
        mar.append(el)
    tblPr.append(mar)


def no_split(row):
    trPr = row._tr.get_or_add_trPr()
    el = OxmlElement("w:cantSplit")
    trPr.append(el)


def repeat_header(row):
    trPr = row._tr.get_or_add_trPr()
    el = OxmlElement("w:tblHeader")
    trPr.append(el)


def add_runs(p, text, size=None, color=None):
    """Texto con **negrita** y `código` en línea."""
    for part in re.split(r"(\*\*[^*]+\*\*|`[^`]+`)", text):
        if not part:
            continue
        if part.startswith("**"):
            r = p.add_run(part[2:-2]); r.bold = True
        elif part.startswith("`"):
            r = p.add_run(part[1:-1]); r.font.name = MONO
            r.font.size = Pt((size or 10.5) - 1)
            r._element.rPr.rFonts.set(qn("w:eastAsia"), MONO)
        else:
            r = p.add_run(part)
        if size and not part.startswith("`"):
            r.font.size = Pt(size)
        if color:
            r.font.color.rgb = color
    return p


def para(doc_or_cell, text, size=None, align=None, space_after=6, bold=False, italic=False, color=None):
    p = doc_or_cell.add_paragraph()
    add_runs(p, text, size=size, color=color)
    if bold or italic:
        for r in p.runs:
            r.bold = r.bold or bold
            r.italic = italic
    if align is not None:
        p.alignment = align
    p.paragraph_format.space_after = Pt(space_after)
    return p


def bullets(doc_or_cell, items, size=None):
    for it in items:
        p = doc_or_cell.add_paragraph(style="List Bullet")
        add_runs(p, it, size=size)
        p.paragraph_format.space_after = Pt(2)


def code(container, text, size=7.5, fill="F4F6F9"):
    """Bloque de código: tabla de una celda sombreada."""
    t = container.add_table(rows=1, cols=1)
    t.alignment = WD_TABLE_ALIGNMENT.CENTER
    t.style = "Table Grid"
    cell_margins(t, 80, 80, 120, 120)
    c = t.rows[0].cells[0]
    shade(c, fill)
    lines = text.rstrip("\n").split("\n")
    c.paragraphs[0].text = ""
    for i, line in enumerate(lines):
        p = c.paragraphs[0] if i == 0 else c.add_paragraph()
        p.paragraph_format.space_after = Pt(0)
        p.paragraph_format.line_spacing = 1.0
        r = p.add_run(line if line else " ")
        r.font.name = MONO
        r._element.rPr.rFonts.set(qn("w:eastAsia"), MONO)
        r.font.size = Pt(size)
        if line.startswith("ERROR:"):
            r.font.color.rgb = RGBColor(0xB0, 0x00, 0x20)
            r.bold = True
        elif line.startswith("NOTICE:"):
            r.font.color.rgb = RGBColor(0x1B, 0x5E, 0x20)
    sp = container.add_paragraph()
    sp.paragraph_format.space_after = Pt(4)
    return t


def table(container, headers, rows, widths, size=9, header_fill="1F3A5F"):
    t = container.add_table(rows=1, cols=len(headers))
    t.style = "Table Grid"
    t.alignment = WD_TABLE_ALIGNMENT.CENTER
    cell_margins(t)
    hdr = t.rows[0]
    repeat_header(hdr)
    for i, h in enumerate(headers):
        c = hdr.cells[i]
        shade(c, header_fill)
        c.paragraphs[0].text = ""
        r = c.paragraphs[0].add_run(h)
        r.bold = True; r.font.size = Pt(size); r.font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF)
    for k, row in enumerate(rows):
        cells = t.add_row().cells
        for i, val in enumerate(row):
            c = cells[i]
            if k % 2:
                shade(c, "F2F5F9")
            c.paragraphs[0].text = ""
            vals = val if isinstance(val, list) else [val]
            for j, v in enumerate(vals):
                p = c.paragraphs[0] if j == 0 else c.add_paragraph()
                p.paragraph_format.space_after = Pt(1)
                add_runs(p, v, size=size)
    for row in t.rows:
        for i, w in enumerate(widths):
            row.cells[i].width = Cm(w)
    container.add_paragraph().paragraph_format.space_after = Pt(2)
    return t


def ficha(doc, campos):
    """Ficha de caso de uso: tabla Campo | Contenido. El contenido es una lista de
    textos o tuplas ('code', texto) / ('bullets', [..])."""
    t = doc.add_table(rows=0, cols=2)
    t.style = "Table Grid"
    t.alignment = WD_TABLE_ALIGNMENT.CENTER
    cell_margins(t, 70, 70, 110, 110)
    for campo, contenido in campos:
        row = t.add_row()
        a, b = row.cells
        shade(a, "E3EAF3")
        a.paragraphs[0].text = ""
        r = a.paragraphs[0].add_run(campo); r.bold = True; r.font.size = Pt(9.5)
        r.font.color.rgb = AZUL
        b.paragraphs[0].text = ""
        first = True
        for item in contenido:
            if isinstance(item, tuple) and item[0] == "code":
                if first:
                    tiny(b.paragraphs[0])
                inner = b.add_table(rows=1, cols=1)
                inner.autofit = False
                inner.style = "Table Grid"
                cell_margins(inner, 60, 60, 90, 90)
                c = inner.rows[0].cells[0]
                shade(c, "F4F6F9")
                lines = item[1].rstrip("\n").split("\n")
                for i, line in enumerate(lines):
                    p = c.paragraphs[0] if i == 0 else c.add_paragraph()
                    p.paragraph_format.space_after = Pt(0)
                    rr = p.add_run(line if line else " ")
                    rr.font.name = MONO; rr._element.rPr.rFonts.set(qn("w:eastAsia"), MONO)
                    rr.font.size = Pt(7)
                    if line.startswith("ERROR:"):
                        rr.font.color.rgb = RGBColor(0xB0, 0x00, 0x20); rr.bold = True
                    elif line.startswith("NOTICE:"):
                        rr.font.color.rgb = RGBColor(0x1B, 0x5E, 0x20)
                inner.rows[0].cells[0].width = Cm(13.2)
                tiny(b.add_paragraph())
            elif isinstance(item, tuple) and item[0] == "bullets":
                for x in item[1]:
                    p = b.paragraphs[0] if first else b.add_paragraph(style="List Bullet")
                    if first:
                        p.style = doc.styles["List Bullet"]
                    add_runs(p, x, size=9)
                    p.paragraph_format.space_after = Pt(1)
                    first = False
            else:
                p = b.paragraphs[0] if first else b.add_paragraph()
                add_runs(p, item, size=9)
                p.paragraph_format.space_after = Pt(2)
            first = False
        a.width = Cm(3.3)
        b.width = Cm(13.7)
    doc.add_paragraph().paragraph_format.space_after = Pt(4)
    return t


def tiny(p):
    from docx.enum.text import WD_LINE_SPACING
    p.paragraph_format.space_after = Pt(0)
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.line_spacing_rule = WD_LINE_SPACING.EXACTLY
    p.paragraph_format.line_spacing = Pt(2)


def heading(doc, text, level):
    h = doc.add_heading(text, level=level)
    return h


def page_number_footer(section):
    p = section.footer.paragraphs[0]
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = p.add_run("Stanke · Entrega 2 · página ")
    r.font.size = Pt(8); r.font.color.rgb = RGBColor(0x66, 0x66, 0x66)
    run = p.add_run()
    for kind, txt in (("begin", None), (None, "PAGE"), ("end", None)):
        if kind:
            el = OxmlElement("w:fldChar"); el.set(qn("w:fldCharType"), kind)
        else:
            el = OxmlElement("w:instrText"); el.set(qn("xml:space"), "preserve"); el.text = txt
        run._r.append(el)
    run.font.size = Pt(8)


# ---------------------------------------------------------------------------
# Documento
# ---------------------------------------------------------------------------

def build():
    doc = Document()
    sec = doc.sections[0]
    sec.page_width, sec.page_height = Cm(21.59), Cm(27.94)
    sec.left_margin = sec.right_margin = Cm(2.3)
    sec.top_margin = sec.bottom_margin = Cm(2.2)

    st = doc.styles["Normal"]
    st.font.name = FUENTE; st.font.size = Pt(10.5)
    st.element.rPr.rFonts.set(qn("w:eastAsia"), FUENTE)
    for lvl, size in ((1, 15), (2, 12.5), (3, 11)):
        hs = doc.styles[f"Heading {lvl}"]
        hs.font.name = FUENTE; hs.font.size = Pt(size); hs.font.bold = True
        hs.font.color.rgb = AZUL
        hs.element.rPr.rFonts.set(qn("w:eastAsia"), FUENTE)
        hs.element.rPr.rFonts.set(qn("w:ascii"), FUENTE)
        hs.element.rPr.rFonts.set(qn("w:hAnsi"), FUENTE)
        hs.paragraph_format.space_before = Pt(14 if lvl == 1 else 10)
        hs.paragraph_format.space_after = Pt(6)
        hs.paragraph_format.keep_with_next = True

    # ---------------- Portada ----------------
    for _ in range(2):
        doc.add_paragraph()
    para(doc, "UNIVERSIDAD DISTRITAL FRANCISCO JOSÉ DE CALDAS", 14, WD_ALIGN_PARAGRAPH.CENTER, 2, bold=True, color=AZUL)
    para(doc, "Ingeniería de Sistemas · Bases de Datos Avanzadas", 11.5, WD_ALIGN_PARAGRAPH.CENTER, 2)
    para(doc, "Docente: René Alejandro Lobo Quintero", 11, WD_ALIGN_PARAGRAPH.CENTER, 40)
    para(doc, "Stanke", 34, WD_ALIGN_PARAGRAPH.CENTER, 2, bold=True, color=AZUL)
    para(doc, "Plataforma de gestión y distribución digital de videojuegos", 13, WD_ALIGN_PARAGRAPH.CENTER, 24, italic=True)
    para(doc, "Proyecto Final — Entrega 2", 15, WD_ALIGN_PARAGRAPH.CENTER, 2, bold=True)
    para(doc, "Modelo de datos, implementación y lógica en la base de datos", 12, WD_ALIGN_PARAGRAPH.CENTER, 40)
    para(doc, "Integrantes", 12, WD_ALIGN_PARAGRAPH.CENTER, 6, bold=True)
    table(doc, ["Nombre completo", "Código", "Correo institucional"], [
        ["Juan David Escallon Guzman", "20231020002", "jdescallong@udistrital.edu.co"],
        ["Juan Pablo Sarmiento Ramírez", "20221020138", "jpsarmientor@udistrital.edu.co"],
    ], [6.4, 3.2, 6.6], size=10)
    doc.add_paragraph()
    para(doc, "**Asignatura:** Bases de Datos Avanzadas", 11, WD_ALIGN_PARAGRAPH.CENTER, 2)
    para(doc, "**Grupo:** __________", 11, WD_ALIGN_PARAGRAPH.CENTER, 2)
    para(doc, "**Fecha:** __________", 11, WD_ALIGN_PARAGRAPH.CENTER, 2)
    doc.add_paragraph().add_run().add_break(WD_BREAK.PAGE)

    # ---------------- Introducción ----------------
    heading(doc, "Contenido de la entrega", 1)
    para(doc, "Este documento acompaña la carpeta `sql/` del archivo comprimido. Los archivos "
              "`01_create.sql`, `02_datos.sql` y `03_procedimientos_triggers.sql` se ejecutan completos, "
              "en ese orden y sin errores sobre una base de datos vacía; `04_pruebas.sql` contiene las "
              "pruebas de los componentes 2.3 y 2.4 y se ejecuta sentencia por sentencia. Todas las salidas "
              "que se muestran son salidas reales de psql sobre PostgreSQL 18 (los mensajes del servidor "
              "están en inglés, como en el ejemplo del enunciado).")
    table(doc, ["Archivo", "Contenido"], [
        ["`sql/01_create.sql`", "14 tablas con llaves primarias y foráneas, CHECK, UNIQUE, DEFAULT e índices. Reglas RN-01 a RN-11."],
        ["`sql/02_datos.sql`", "194 filas de prueba coherentes con las reglas; 30 compras en la tabla de mayor movimiento."],
        ["`sql/03_procedimientos_triggers.sql`", "5 casos de uso (RF-03, RF-06, RF-14, RF-15, RF-17) y 5 triggers (RN-12 a RN-16)."],
        ["`sql/04_pruebas.sql`", "11 pruebas de restricciones, pruebas de éxito y error de cada caso de uso y de cada trigger, y prueba de atomicidad."],
    ], [5.4, 11.6])

    # ---------------- 2.1 ----------------
    heading(doc, "2.1 Modelo de datos", 1)
    para(doc, "La Figura 1 muestra las 14 tablas de `01_create.sql` con sus columnas, tipos de dato, llaves "
              "primarias (PK), foráneas (FK), columnas únicas (UK) y la cardinalidad de cada relación en "
              "notación pata de gallo. El diagrama se genera a partir del mismo modelo del script, de modo "
              "que los nombres y tipos coinciden exactamente. La figura está en la página horizontal al final de esta sección.")
    heading(doc, "Decisiones de diseño", 2)
    para(doc, "**Tablas intermedias.** `videojuego_genero` y `promocion_videojuego` resuelven las relaciones "
              "muchos a muchos entre videojuegos y géneros, y entre promociones y videojuegos. Su llave primaria "
              "es la pareja de llaves foráneas, de modo que un juego no puede repetir un género ni aparecer dos "
              "veces en la misma promoción. `biblioteca` y `lista_deseos` también relacionan usuarios con "
              "videojuegos, pero significan cosas distintas (propiedad frente a interés), por eso son tablas "
              "separadas; ambas usan la pareja (usuario_id, videojuego_id) como llave primaria, lo que impide "
              "tener dos veces el mismo juego.")
    para(doc, "**Compra frente a biblioteca.** `compra` usa un identificador propio porque un jugador puede "
              "comprar, reembolsar y volver a comprar el mismo juego: es un registro histórico de dinero. "
              "`biblioteca` refleja solo lo que el jugador posee hoy; la llena el trigger de RN-14 y la "
              "vacía el reembolso (RF-17).")
    para(doc, "**Historial y auditoría.** `historial_precio` guarda cada cambio de precio con el precio anterior, "
              "el nuevo y la fecha (RN-16, RNF-09). Ninguna aplicación escribe en ella: la llena el trigger "
              "`trg_rn16_historial_precio`. Su llave foránea es ON DELETE RESTRICT para no perder la auditoría.")
    para(doc, "**Borrado.** Las tablas que dependen por completo de su padre (géneros e imágenes de un juego, "
              "biblioteca, lista de deseos, amistades, juegos de una promoción) usan ON DELETE CASCADE. Las que "
              "son registros de negocio (compras, reseñas, juegos de un desarrollador, historial) usan "
              "ON DELETE RESTRICT: no se puede borrar un usuario o un juego que ya tiene ventas.")
    heading(doc, "Cambios respecto a la Entrega 1", 2)
    bullets(doc, [
        "**Nombres de columnas.** La llave primaria de cada tabla se llama `id` y las llaves foráneas "
        "`<tabla>_id` (por ejemplo `usuario_id` en lugar de `id_usuario`). En `promocion`, "
        "`porcentaje_descuento` pasó a llamarse `descuento`.",
        "**Amistad.** Se agregó un identificador propio `id` y un índice único sobre la pareja de usuarios "
        "sin importar el orden (`LEAST/GREATEST`), para que no existan a la vez la solicitud A→B y la B→A.",
        "**Restricciones adicionales** que no eran reglas numeradas: un desarrollador no repite el título de "
        "sus juegos (`uq_videojuego_titulo_desarrollador`), las imágenes de un juego no repiten su orden, "
        "y el país del desarrollador es obligatorio.",
        "**RF-06.** Además de lo descrito en la Entrega 1, la compra quita el juego de la lista de deseos del jugador.",
        "**RF-17.** El reembolso también borra la reseña del jugador sobre ese juego; de lo contrario quedaría "
        "una reseña de un juego que ya no está en su biblioteca, en contra de RN-15.",
        "**RF-15** se implementa como función `RETURNS TABLE` y no como procedimiento, porque es una consulta "
        "que devuelve filas (lo permite el enunciado).",
        "Los requerimientos y reglas (RF-01 a RF-17, RN-01 a RN-16) conservan los identificadores de la Entrega 1.",
    ])

    sec_l = doc.add_section(WD_SECTION.NEW_PAGE)
    sec_l.orientation = 1
    sec_l.page_width, sec_l.page_height = Cm(27.94), Cm(21.59)
    sec_l.left_margin = sec_l.right_margin = Cm(1.2)
    sec_l.top_margin = sec_l.bottom_margin = Cm(1.2)
    doc.add_picture(str(BASE / "2.1 DiagramaRelacional.png"), width=Cm(25.4))
    doc.paragraphs[-1].alignment = WD_ALIGN_PARAGRAPH.CENTER
    para(doc, "Figura 1. Modelo relacional de Stanke (coincide con 01_create.sql).", 9,
         WD_ALIGN_PARAGRAPH.CENTER, italic=True)
    sec_p = doc.add_section(WD_SECTION.NEW_PAGE)
    sec_p.orientation = 0
    sec_p.page_width, sec_p.page_height = Cm(21.59), Cm(27.94)
    sec_p.left_margin = sec_p.right_margin = Cm(2.3)
    sec_p.top_margin = sec_p.bottom_margin = Cm(2.2)

    # ---------------- 2.2 ----------------
    heading(doc, "2.2 Script de creación", 1)
    para(doc, "El archivo `01_create.sql` empieza con `DROP TABLE IF EXISTS … CASCADE` para cada tabla, por lo "
              "que puede ejecutarse varias veces. Todas las tablas tienen llave primaria; cada relación del "
              "diagrama es una llave foránea con ON DELETE RESTRICT o ON DELETE CASCADE explícito, y cada "
              "restricción tiene nombre propio para que los mensajes de error indiquen qué regla se violó. "
              "Las reglas declarativas de la Entrega 1 se marcan en el script con el comentario `-- RN-xx`.")
    heading(doc, "Reglas de negocio implementadas como restricciones", 2)
    table(doc, ["Regla", "Tabla", "Restricción que la implementa"], [
        ["RN-01", "usuario, desarrollador, videojuego, genero, compra, resena, promocion",
         "`id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY`"],
        ["RN-02", "usuario", "`uq_usuario_correo UNIQUE (correo)`"],
        ["RN-03", "usuario", "`ck_usuario_rol CHECK (rol IN ('jugador', 'desarrollador', 'administrador'))`"],
        ["RN-04", "usuario", "`ck_usuario_saldo CHECK (saldo >= 0)`"],
        ["RN-05", "videojuego", "`ck_videojuego_precio CHECK (precio >= 0)`"],
        ["RN-06", "videojuego", "`desarrollador_id BIGINT NOT NULL` + `fk_videojuego_desarrollador REFERENCES desarrollador(id) ON DELETE RESTRICT`"],
        ["RN-07", "videojuego", ["`ck_videojuego_estado CHECK (estado IN ('pendiente', 'publicado', 'retirado'))`",
                                 "`estado … DEFAULT 'pendiente'`"]],
        ["RN-08", "resena", "`calificacion INTEGER` + `ck_resena_calificacion CHECK (calificacion BETWEEN 1 AND 5)`"],
        ["RN-09", "resena", "`uq_resena_usuario_videojuego UNIQUE (usuario_id, videojuego_id)`"],
        ["RN-10", "promocion", ["`ck_promocion_descuento CHECK (descuento BETWEEN 1 AND 90)`",
                                "`ck_promocion_fechas CHECK (fecha_fin > fecha_inicio)`"]],
        ["RN-11", "amistad", "`ck_amistad_distintos CHECK (usuario_solicita_id <> usuario_recibe_id)`"],
    ], [1.6, 4.4, 11.0], size=8.5)
    para(doc, "Las reglas RN-12 a RN-16 dependen de otras tablas o producen efectos en otras tablas, por lo que "
              "se implementan con triggers en `03_procedimientos_triggers.sql` (sección 2.4).")
    heading(doc, "Script completo (01_create.sql)", 2)
    code(doc, (SQL / "01_create.sql").read_text(encoding="utf-8"), size=7)

    # ---------------- 2.3 ----------------
    heading(doc, "2.3 Datos de prueba", 1)
    para(doc, "`02_datos.sql` carga una tienda con 15 usuarios (1 administrador, 5 estudios y 9 jugadores, uno "
              "de ellos suspendido), 11 videojuegos de 5 desarrolladores (9 publicados, 1 pendiente y 1 "
              "retirado), 6 promociones y 30 compras entre diciembre de 2025 y noviembre de 2026. Los datos se "
              "construyeron para que sean coherentes con todas las reglas aunque los triggers todavía no "
              "existan cuando se cargan:")
    bullets(doc, [
        "cada compra completada tiene su fila en `biblioteca` y las dos compras reembolsadas no (RN-14, RF-17);",
        "el monto de cada compra es el precio vigente en su fecha, con el descuento de la promoción activa "
        "(por ejemplo, 39.99 × 0.80 = 31.99 en las Rebajas de Verano);",
        "las 20 reseñas son de juegos que el autor posee y tienen fecha posterior a la compra (RN-15);",
        "las listas de deseos solo tienen juegos que el jugador aún no posee;",
        "las contraseñas son hashes bcrypt reales (costo 12), nunca texto plano (RNF-01);",
        "hay casos útiles para las pruebas y las preguntas de negocio: un juego publicado sin ventas "
        "(Sombras de Cartagena, P7), juegos en la lista de deseos con promoción vigente (P6), un juego "
        "gratuito retirado y una cuenta suspendida.",
    ])
    para(doc, "Conteo de filas después de ejecutar `01` y `02` (salida real):", space_after=3)
    code(doc, (EVI / "conteo_filas.txt").read_text(encoding="utf-8"))
    heading(doc, "Pruebas de restricciones", 2)
    para(doc, "Cada sentencia se ejecutó sobre la base recién cargada y PostgreSQL la rechazó con el mensaje "
              "que se muestra. Se incluyen más de las tres exigidas: CHECK, llave foránea, ON DELETE RESTRICT, "
              "UNIQUE y NOT NULL.")
    pruebas = [
        ("R1", "CHECK · RN-08: calificación fuera del rango 1–5"),
        ("R2", "CHECK · RN-04: el saldo no puede quedar negativo"),
        ("R3", "CHECK · RN-05: precio negativo"),
        ("R4", "CHECK · RN-10: descuento mayor que 90 %"),
        ("R5", "CHECK · RN-11: solicitud de amistad a sí mismo"),
        ("R6", "CHECK · RN-03: rol no permitido"),
        ("R7", "Llave foránea · RN-06: desarrollador inexistente"),
        ("R8", "Llave foránea · ON DELETE RESTRICT: borrar un desarrollador con juegos"),
        ("R9", "UNIQUE · RN-02: correo repetido"),
        ("R10", "UNIQUE · RN-09: segunda reseña del mismo jugador al mismo juego"),
        ("R11", "NOT NULL: usuario sin contraseña"),
    ]
    for lab, titulo in pruebas:
        para(doc, f"**{lab} · {titulo}**", 10, space_after=2).paragraph_format.keep_with_next = True
        code(doc, salida(lab))

    # ---------------- 2.4 ----------------
    heading(doc, "2.4 Procedimientos almacenados y triggers", 1)
    para(doc, "En la Entrega 1 se marcaron cinco requerimientos con procedimiento almacenado o transacción "
              "explícita (RF-03, RF-06, RF-14, RF-15 y RF-17) y cinco reglas con trigger (RN-12 a RN-16). "
              "Se implementaron todos. El código completo está en el Anexo A y en "
              "`sql/03_procedimientos_triggers.sql`.")
    table(doc, ["Caso de uso", "Objeto", "Tipo"], [
        ["RF-03 · Publicar un videojuego", "`pr_publicar_videojuego`", "PROCEDURE (una transacción)"],
        ["RF-06 · Comprar un videojuego", "`pr_comprar_videojuego`", "PROCEDURE (una transacción)"],
        ["RF-14 · Crear una promoción", "`pr_crear_promocion`", "PROCEDURE (una transacción)"],
        ["RF-15 · Reporte de ventas del desarrollador", "`fn_reporte_ventas_desarrollador`", "FUNCTION … RETURNS TABLE"],
        ["RF-17 · Reembolsar una compra", "`pr_reembolsar_compra`", "PROCEDURE (una transacción)"],
    ], [6.2, 6.0, 4.8])
    heading(doc, "Triggers", 2)
    table(doc, ["Regla", "Trigger", "Momento", "Qué hace"], [
        ["RN-12", "`trg_rn12_compra_solo_publicados`", "BEFORE INSERT ON compra",
         "Rechaza la compra si el juego no está publicado."],
        ["RN-13", "`trg_rn13_compra_no_duplicada`", "BEFORE INSERT ON compra",
         "Rechaza la compra si el juego ya está en la biblioteca del jugador."],
        ["RN-14", "`trg_rn14_compra_a_biblioteca`", "AFTER INSERT ON compra",
         "Inserta el juego en `biblioteca` (efecto en otra tabla)."],
        ["RN-15", "`trg_rn15_resena_solo_propios`", "BEFORE INSERT OR UPDATE ON resena",
         "Rechaza la reseña si el juego no está en la biblioteca del autor."],
        ["RN-16", "`trg_rn16_historial_precio`", "AFTER UPDATE OF precio ON videojuego",
         "Inserta precio anterior, nuevo y fecha en `historial_precio` (auditoría)."],
    ], [1.5, 5.2, 4.3, 6.0], size=8.5)
    para(doc, "Ninguno de estos triggers puede reemplazarse por un CHECK: RN-12, RN-13 y RN-15 consultan otra "
              "tabla, y RN-14 y RN-16 escriben en otra tabla. Los procedimientos repiten algunas validaciones "
              "de los triggers para dar un mensaje más claro al usuario; los triggers garantizan la regla "
              "aunque alguien inserte directamente en la tabla sin usar el procedimiento.")

    heading(doc, "Prueba de los triggers BEFORE (inserción directa, sin procedimiento)", 3)
    for lab, t in (("T4", "RN-12 · comprar un juego retirado"),
                   ("T5", "RN-13 · comprar un juego que ya está en la biblioteca"),
                   ("T6", "RN-15 · reseñar un juego que no se posee")):
        para(doc, f"**{t}**", 10, space_after=2).paragraph_format.keep_with_next = True
        code(doc, salida(lab))
    heading(doc, "Prueba de los triggers AFTER", 3)
    para(doc, "**RN-16 · el cambio de precio queda en el historial** (y un UPDATE que no cambia el precio no "
              "genera fila, gracias a la condición `WHEN (OLD.precio IS DISTINCT FROM NEW.precio)`):", 10, space_after=2)
    code(doc, salida("T1", "T2", "T3"))
    para(doc, "**RN-14 · un INSERT directo en compra agrega el juego a la biblioteca:**", 10, space_after=2)
    code(doc, salida("T7"))

    # Fichas
    heading(doc, "Ficha RF-03 · Publicar un videojuego", 2)
    ficha(doc, [
        ("Caso de uso", ["RF-03 · El desarrollador registra un videojuego con título, descripción, precio, fecha "
                         "de lanzamiento, imágenes y uno o más géneros en una sola operación. El juego queda en "
                         "estado pendiente (RN-07) hasta que un administrador lo publique (RF-13)."]),
        ("Objetos", ["`pr_publicar_videojuego` · restricciones `ck_videojuego_precio` (RN-05), "
                     "`fk_videojuego_desarrollador` (RN-06) y `DEFAULT 'pendiente'` (RN-07) · "
                     "`trg_rn16_historial_precio` registra los cambios de precio posteriores (RF-04)."]),
        ("Parámetros", [("bullets", [
            "`p_desarrollador_id BIGINT`: desarrollador que publica.",
            "`p_titulo VARCHAR`: título del juego.",
            "`p_descripcion TEXT`: descripción.",
            "`p_precio NUMERIC`: precio en dólares, mayor o igual a cero.",
            "`p_fecha_lanzamiento DATE`: fecha de lanzamiento.",
            "`p_generos BIGINT[]`: géneros del juego (al menos uno).",
            "`p_imagenes TEXT[]`: URLs de las imágenes en el orden en que se muestran (opcional).",
            "`INOUT p_videojuego_id BIGINT`: devuelve el id del juego creado (se pasa NULL).",
        ])]),
        ("Validaciones", [("bullets", [
            "El desarrollador existe → \"El desarrollador % no existe\".",
            "Su cuenta está activa → \"La cuenta del desarrollador % está suspendida: no puede publicar videojuegos\".",
            "El título no está vacío → \"El título del videojuego es obligatorio\".",
            "El desarrollador no tiene otro juego con ese título → \"El desarrollador % ya tiene un videojuego llamado \"%\"\".",
            "Precio ≥ 0 → \"El precio debe ser mayor o igual a cero: se recibió %\".",
            "Al menos un género → \"El videojuego \"%\" debe tener al menos un género\".",
            "Cada género existe → \"El género % no existe\".",
            "Ninguna imagen con URL vacía → \"Las imágenes del videojuego \"%\" no pueden tener URL vacía\".",
        ])]),
        ("Tablas afectadas", ["Lee `desarrollador`, `usuario`, `genero` y `videojuego`. Inserta en `videojuego`, "
                              "`videojuego_genero` e `imagen_videojuego`."]),
        ("Prueba de éxito", [("code", salida("P1"))]),
        ("Prueba de error", [("code", salida("P2", "P3", "P4", "P5")),
                             "Ninguno de los intentos fallidos dejó filas: siguen existiendo 12 videojuegos."]),
    ])

    heading(doc, "Ficha RF-06 · Comprar un videojuego", 2)
    ficha(doc, [
        ("Caso de uso", ["RF-06 · El jugador compra un videojuego. Se descuenta de su saldo el precio vigente "
                         "(con la mejor promoción activa) y se registra la compra con fecha y monto; el juego "
                         "pasa a su biblioteca y sale de su lista de deseos."]),
        ("Objetos", ["`pr_comprar_videojuego` · triggers `trg_rn12_compra_solo_publicados` y "
                     "`trg_rn13_compra_no_duplicada` (BEFORE), `trg_rn14_compra_a_biblioteca` (AFTER) · "
                     "`ck_usuario_saldo` (RN-04)."]),
        ("Parámetros", [("bullets", [
            "`p_usuario_id BIGINT`: jugador que compra.",
            "`p_videojuego_id BIGINT`: juego que compra.",
            "`INOUT p_compra_id BIGINT`: devuelve el id de la compra (se pasa NULL).",
        ])]),
        ("Validaciones", [("bullets", [
            "El usuario existe → \"El usuario % no existe\".",
            "Tiene rol jugador → \"El usuario % tiene rol % y solo los jugadores pueden comprar videojuegos\".",
            "Su cuenta está activa → \"La cuenta del usuario % está suspendida: no puede comprar videojuegos\".",
            "El juego existe → \"El videojuego % no existe\".",
            "Está publicado (RN-12) → \"El videojuego \"%\" no está a la venta: su estado es %\".",
            "No está ya en su biblioteca (RN-13) → \"El usuario % ya tiene \"%\" en su biblioteca\".",
            "Saldo suficiente (RN-04) → \"Saldo insuficiente: el usuario % tiene % y \"%\" cuesta %\".",
        ])]),
        ("Tablas afectadas", ["Lee `usuario`, `videojuego`, `biblioteca`, `promocion` y `promocion_videojuego`. "
                              "Modifica `usuario` (saldo), inserta en `compra` y, por el trigger RN-14, en "
                              "`biblioteca`; borra de `lista_deseos`."]),
        ("Prueba de éxito", ["Daniel (usuario 11, saldo 60.00) compra Sombras de Cartagena (34.99) con la "
                             "promoción de 30 % creada en RF-14: paga 24.49, el juego queda en su biblioteca y "
                             "sale de su lista de deseos.", ("code", salida("P10", "P11"))]),
        ("Prueba de error", [("code", salida("P12", "P13", "P14", "P15", "P16")),
                             "El saldo de Mateo (13) sigue en 5.25: los intentos fallidos no cambiaron nada."]),
    ])

    heading(doc, "Ficha RF-14 · Crear una promoción", 2)
    ficha(doc, [
        ("Caso de uso", ["RF-14 · El administrador crea una promoción con porcentaje de descuento, fecha de "
                         "inicio, fecha de fin y los videojuegos a los que aplica, en una sola operación."]),
        ("Objetos", ["`pr_crear_promocion` · restricciones `ck_promocion_descuento` y `ck_promocion_fechas` (RN-10)."]),
        ("Parámetros", [("bullets", [
            "`p_nombre VARCHAR`: nombre comercial de la promoción.",
            "`p_descuento NUMERIC`: porcentaje de descuento (1 a 90).",
            "`p_fecha_inicio TIMESTAMPTZ`, `p_fecha_fin TIMESTAMPTZ`: periodo de vigencia.",
            "`p_videojuegos BIGINT[]`: juegos incluidos (al menos uno).",
            "`INOUT p_promocion_id BIGINT`: devuelve el id de la promoción (se pasa NULL).",
        ])]),
        ("Validaciones", [("bullets", [
            "Nombre no vacío → \"El nombre de la promoción es obligatorio\".",
            "Descuento entre 1 y 90 (RN-10) → \"El descuento debe estar entre 1 % y 90 %: se recibió %\".",
            "Fechas presentes → \"La promoción \"%\" necesita fecha de inicio y fecha de fin\".",
            "Fin posterior al inicio (RN-10) → \"La fecha de fin (%) debe ser posterior a la fecha de inicio (%)\".",
            "La promoción no terminó ya → \"No se puede crear la promoción \"%\": su fecha de fin (%) ya pasó\".",
            "Al menos un juego → \"La promoción \"%\" debe aplicar al menos a un videojuego\".",
            "Cada juego existe → \"El videojuego % no existe\".",
            "Ningún juego retirado → \"El videojuego % \"%\" está retirado y no puede entrar en una promoción\".",
        ])]),
        ("Tablas afectadas", ["Lee `videojuego`. Inserta en `promocion` y `promocion_videojuego`."]),
        ("Prueba de éxito", [("code", salida("P6"))]),
        ("Prueba de error", [("code", salida("P7", "P8", "P9"))]),
    ])

    heading(doc, "Ficha RF-15 · Reporte de ventas del desarrollador", 2)
    ficha(doc, [
        ("Caso de uso", ["RF-15 · Generar para el desarrollador el número de copias vendidas y los ingresos de "
                         "cada uno de sus videojuegos en un periodo. Como devuelve filas, se implementa como "
                         "función `RETURNS TABLE`. Incluye los juegos sin ventas y las copias reembolsadas, que "
                         "no suman ingresos."]),
        ("Objetos", ["`fn_reporte_ventas_desarrollador` (STABLE)."]),
        ("Parámetros", [("bullets", [
            "`p_desarrollador_id BIGINT`: desarrollador del reporte.",
            "`p_desde DATE`, `p_hasta DATE`: periodo, ambos días incluidos.",
            "Devuelve: `videojuego_id`, `titulo`, `copias_vendidas`, `copias_reembolsadas`, `ingresos`.",
        ])]),
        ("Validaciones", [("bullets", [
            "El desarrollador existe → \"El desarrollador % no existe\".",
            "Fechas presentes → \"Debe indicar la fecha inicial y la fecha final del periodo\".",
            "Periodo en orden → \"Periodo inválido: la fecha final (%) es anterior a la inicial (%)\".",
        ])]),
        ("Tablas afectadas", ["Lee `desarrollador`, `videojuego` y `compra`. No modifica ninguna tabla."]),
        ("Prueba de éxito", [("code", salida("P21", "P22")),
                             "En el segundo reporte se ve la compra de Sombras de Cartagena que se reembolsó en "
                             "RF-17: cuenta como reembolsada y no suma ingresos."]),
        ("Prueba de error", [("code", salida("P23", "P24"))]),
    ])

    heading(doc, "Ficha RF-17 · Reembolsar una compra", 2)
    ficha(doc, [
        ("Caso de uso", ["RF-17 · El jugador pide el reembolso de una compra de hace menos de 14 días: se "
                         "devuelve el monto a su saldo, el juego sale de su biblioteca (y se borra su reseña, "
                         "por RN-15) y la compra queda marcada como reembolsada."]),
        ("Objetos", ["`pr_reembolsar_compra` · `ck_compra_estado`."]),
        ("Parámetros", [("bullets", [
            "`p_usuario_id BIGINT`: jugador que pide el reembolso.",
            "`p_compra_id BIGINT`: compra a reembolsar.",
        ])]),
        ("Validaciones", [("bullets", [
            "El usuario existe → \"El usuario % no existe\".",
            "La compra existe → \"La compra % no existe\".",
            "La compra es suya → \"La compra % no pertenece al usuario %\".",
            "No fue reembolsada antes → \"La compra % ya fue reembolsada\".",
            "Tiene menos de 14 días → \"La compra % se hizo el % y ya pasaron más de 14 días: no se puede reembolsar\".",
        ])]),
        ("Tablas afectadas", ["Lee y modifica `usuario` (saldo) y `compra` (estado). Borra de `biblioteca` y `resena`."]),
        ("Prueba de éxito", ["Daniel pide el reembolso de la compra 31 hecha en la prueba de RF-06: recupera "
                             "los 24.49 (saldo de nuevo en 60.00) y el juego sale de su biblioteca.",
                             ("code", salida("P17"))]),
        ("Prueba de error", [("code", salida("P18", "P19", "P20"))]),
    ])

    # ---------------- 2.5 ----------------
    heading(doc, "2.5 Diseño transaccional: RF-06 · Comprar un videojuego", 1)
    t = table(doc, ["Pregunta", "Respuesta"], [
        ["Caso de uso elegido y por qué",
         ["RF-06, comprar un videojuego. Es la única operación en la que el jugador entrega dinero y la que "
          "alimenta los ingresos de los desarrolladores (RF-15) y las preguntas P1, P2, P7 y P9. Si sale mal, "
          "el jugador pierde saldo sin recibir el juego, recibe el juego sin pagarlo o paga dos veces el mismo "
          "juego; además los reportes de ventas quedan inflados o incompletos."]],
        ["Operaciones de la transacción",
         ["Con autocommit, el CALL completo es una transacción. En orden:",
          "1. `SELECT rol, estado, saldo FROM usuario WHERE id = p_usuario_id FOR UPDATE` (lee y bloquea al jugador).",
          "2. `SELECT titulo, precio, estado FROM videojuego WHERE id = p_videojuego_id FOR SHARE`.",
          "3. `SELECT 1 FROM biblioteca …` (RN-13) y `SELECT max(descuento) FROM promocion …` (precio vigente).",
          "4. `UPDATE usuario SET saldo = saldo - monto` (el CHECK RN-04 se evalúa aquí).",
          "5. `INSERT INTO compra …` → disparan `trg_rn12` y `trg_rn13` (BEFORE) y `trg_rn14` (AFTER), que hace "
          "`INSERT INTO biblioteca`.",
          "6. `DELETE FROM lista_deseos …`.",
          "7. COMMIT al terminar el CALL."]],
        ["Si una operación falla",
         ["Cualquier RAISE EXCEPTION (de una validación, de un trigger o de una restricción) aborta la "
          "transacción completa y PostgreSQL deshace todo: el saldo vuelve a su valor, no queda la compra, el "
          "juego no entra a la biblioteca y la lista de deseos queda igual. La base queda exactamente como "
          "antes del CALL. Se comprobó en P12–P16 (el saldo de Mateo sigue en 5.25) y con la prueba de "
          "atomicidad A1–A3, que descuenta el saldo y luego falla en el INSERT por RN-13 (ver abajo)."]],
        ["Bloqueos",
         ["1) La fila del jugador en `usuario`, con `SELECT … FOR UPDATE`, antes de cualquier validación. Una "
          "segunda compra o reembolso del mismo jugador espera hasta el COMMIT de la primera.",
          "2) La fila del juego en `videojuego`, con `FOR SHARE`: otros jugadores pueden comprar el mismo juego a la "
          "vez, pero nadie puede cambiar su precio o retirarlo mientras dura la compra.",
          "3) Las filas nuevas de `compra` y `biblioteca` quedan bloqueadas por sus propios INSERT.",
          "El orden siempre es usuario → videojuego, y el reembolso usa usuario → compra; como todos empiezan por "
          "el usuario, no se forman ciclos de espera (deadlocks)."]],
        ["Nivel de aislamiento",
         ["READ COMMITTED, el predeterminado. Basta porque las decisiones que importan (saldo suficiente, juego "
          "no comprado antes) se toman después de bloquear la fila del jugador: quien espera el bloqueo, al "
          "continuar, lee en cada sentencia los datos ya confirmados por la otra transacción. Además, la llave "
          "primaria de `biblioteca` impide un duplicado aunque algo fallara. SERIALIZABLE obligaría a reintentar "
          "compras por errores de serialización sin aportar más protección para este caso."]],
        ["Problema de concurrencia que evita",
         ["Compra duplicada (y doble cobro): el jugador hace clic dos veces o compra desde dos pestañas. Sin el "
          "FOR UPDATE, ambas sesiones verían que el juego no está en la biblioteca, ambas descontarían el saldo y "
          "ambas registrarían una compra. También evita la actualización perdida del saldo: dos compras "
          "simultáneas que leen el mismo saldo y lo validan con un valor viejo. Con el bloqueo, la segunda "
          "sesión espera, ve el juego ya comprado y falla con un mensaje claro (prueba con dos sesiones abajo)."]],
    ], [3.8, 13.2], size=9)

    heading(doc, "Prueba de atomicidad (RNF-04)", 3)
    para(doc, "Se descuenta el saldo de Carlos (7) dentro de una transacción y después se intenta registrar "
              "una compra que viola RN-13. Al fallar, el ROLLBACK deja el saldo igual:", space_after=3)
    code(doc, salida("A1", "A2", "A3"))
    heading(doc, "Prueba de concurrencia con dos sesiones", 3)
    para(doc, "La sesión A abre una transacción, compra Sombras de Cartagena para Sebastián (15) y espera 5 "
              "segundos antes de confirmar. Un segundo después, la sesión B intenta la misma compra: queda "
              "bloqueada en el FOR UPDATE durante casi 4 segundos y, cuando A confirma, falla porque el juego "
              "ya está en la biblioteca. Resultado: una sola compra y un solo descuento de saldo "
              "(75.00 − 24.49 = 50.51). Salida real de las dos sesiones:", space_after=3)
    code(doc, (EVI / "concurrencia.txt").read_text(encoding="utf-8"))

    # ---------------- Anexo ----------------
    doc.add_paragraph().add_run().add_break(WD_BREAK.PAGE)
    heading(doc, "Anexo A. Código de 03_procedimientos_triggers.sql", 1)
    code(doc, (SQL / "03_procedimientos_triggers.sql").read_text(encoding="utf-8"), size=7)
    heading(doc, "Anexo B. Ejecución de los scripts sobre una base vacía", 1)
    para(doc, "Salida de `01`, `02` y `03` ejecutados con `ON_ERROR_STOP=1` (cualquier error detiene el "
              "script y cambia el código de salida). Los tres terminan con código 0:", space_after=3)
    log = (EVI / "ejecucion_01_02_03.txt").read_text(encoding="utf-8")
    lines, comp = log.splitlines(), []
    for ln in lines:
        if comp and comp[-1][0] == ln:
            comp[-1][1] += 1
        else:
            comp.append([ln, 1])
    log = "\n".join(l if n == 1 else f"{l}   (x{n})" for l, n in comp)
    code(doc, log)

    page_number_footer(doc.sections[0])  # las demás secciones heredan el pie
    doc.save(OUT)
    print("Generado", OUT)


if __name__ == "__main__":
    build()
