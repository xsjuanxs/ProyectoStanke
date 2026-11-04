"""Genera el diagrama relacional de Stanke (2.1) a partir de la definición de 01_create.sql.

Uso:  python diagrama_er.py salida.png
Notación pata de gallo: || = uno (obligatorio), o| = cero o uno, o< = cero o muchos, |< = uno o muchos.
"""
import sys
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle, Circle

W, HDR, ROW = 4.5, 0.46, 0.32
COLX = [0, 7.0, 14.0, 21.0, 28.0]
KEYW = 0.78

T = {  # nombre: (columna, y_superior, [(columna, tipo, llave)])
    "desarrollador": (1, 0.0, [("id", "BIGINT", "PK"), ("usuario_id", "BIGINT", "FK, UK"),
                               ("nombre", "VARCHAR(150)", ""), ("pais", "VARCHAR(100)", ""),
                               ("sitio_web", "TEXT", "")]),
    "usuario": (0, 4.2, [("id", "BIGINT", "PK"), ("nombre", "VARCHAR(120)", ""),
                         ("correo", "VARCHAR(254)", "UK"), ("contrasena_hash", "VARCHAR(255)", ""),
                         ("rol", "VARCHAR(20)", ""), ("estado", "VARCHAR(20)", ""),
                         ("fecha_registro", "TIMESTAMPTZ", ""), ("saldo", "NUMERIC(12,2)", "")]),
    "amistad": (0, 10.4, [("id", "BIGINT", "PK"), ("usuario_solicita_id", "BIGINT", "FK"),
                          ("usuario_recibe_id", "BIGINT", "FK"), ("estado", "VARCHAR(20)", ""),
                          ("fecha", "TIMESTAMPTZ", "")]),
    "compra": (1, 3.2, [("id", "BIGINT", "PK"), ("usuario_id", "BIGINT", "FK"),
                        ("videojuego_id", "BIGINT", "FK"), ("fecha", "TIMESTAMPTZ", ""),
                        ("monto", "NUMERIC(12,2)", ""), ("estado", "VARCHAR(20)", "")]),
    "biblioteca": (1, 6.4, [("usuario_id", "BIGINT", "PK, FK"), ("videojuego_id", "BIGINT", "PK, FK"),
                            ("fecha_adquisicion", "TIMESTAMPTZ", "")]),
    "lista_deseos": (1, 8.4, [("usuario_id", "BIGINT", "PK, FK"), ("videojuego_id", "BIGINT", "PK, FK"),
                              ("fecha_agregado", "TIMESTAMPTZ", "")]),
    "resena": (1, 10.4, [("id", "BIGINT", "PK"), ("usuario_id", "BIGINT", "FK"),
                         ("videojuego_id", "BIGINT", "FK"), ("calificacion", "INTEGER", ""),
                         ("comentario", "TEXT", ""), ("fecha", "TIMESTAMPTZ", "")]),
    "videojuego": (2, 4.6, [("id", "BIGINT", "PK"), ("desarrollador_id", "BIGINT", "FK"),
                            ("titulo", "VARCHAR(200)", ""), ("descripcion", "TEXT", ""),
                            ("precio", "NUMERIC(12,2)", ""), ("fecha_lanzamiento", "DATE", ""),
                            ("estado", "VARCHAR(20)", "")]),
    "videojuego_genero": (3, 0.4, [("videojuego_id", "BIGINT", "PK, FK"), ("genero_id", "BIGINT", "PK, FK")]),
    "imagen_videojuego": (3, 2.6, [("id", "BIGINT", "PK"), ("videojuego_id", "BIGINT", "FK"),
                                   ("url", "TEXT", ""), ("orden", "INTEGER", "")]),
    "historial_precio": (3, 5.4, [("id", "BIGINT", "PK"), ("videojuego_id", "BIGINT", "FK"),
                                  ("precio_anterior", "NUMERIC(12,2)", ""), ("precio_nuevo", "NUMERIC(12,2)", ""),
                                  ("fecha_cambio", "TIMESTAMPTZ", "")]),
    "promocion_videojuego": (3, 8.6, [("promocion_id", "BIGINT", "PK, FK"), ("videojuego_id", "BIGINT", "PK, FK")]),
    "genero": (4, 0.2, [("id", "BIGINT", "PK"), ("nombre", "VARCHAR(80)", "UK"), ("descripcion", "TEXT", "")]),
    "promocion": (4, 8.2, [("id", "BIGINT", "PK"), ("nombre", "VARCHAR(150)", ""),
                           ("descuento", "NUMERIC(5,2)", ""), ("fecha_inicio", "TIMESTAMPTZ", ""),
                           ("fecha_fin", "TIMESTAMPTZ", "")]),
}

def GAP(parent, off):
    col = T[parent][0]
    return COLX[col] + W + off if col < 4 else COLX[3] + W + off


# (padre, hijo, columna FK del hijo, cardinalidad del lado hijo, x del canal)
R = [
    ("usuario", "desarrollador", "usuario_id", "0..1", GAP("usuario", 0.7)),
    ("usuario", "compra", "usuario_id", "0..N", GAP("usuario", 1.0)),
    ("usuario", "biblioteca", "usuario_id", "0..N", GAP("usuario", 1.3)),
    ("usuario", "lista_deseos", "usuario_id", "0..N", GAP("usuario", 1.6)),
    ("usuario", "resena", "usuario_id", "0..N", GAP("usuario", 1.9)),
    ("desarrollador", "videojuego", "desarrollador_id", "0..N", GAP("desarrollador", 0.7)),
    ("videojuego", "compra", "videojuego_id", "0..N", GAP("compra", 1.0)),
    ("videojuego", "biblioteca", "videojuego_id", "0..N", GAP("compra", 1.3)),
    ("videojuego", "lista_deseos", "videojuego_id", "0..N", GAP("compra", 1.6)),
    ("videojuego", "resena", "videojuego_id", "0..N", GAP("compra", 1.9)),
    ("videojuego", "videojuego_genero", "videojuego_id", "1..N", GAP("videojuego", 0.8)),
    ("videojuego", "imagen_videojuego", "videojuego_id", "0..N", GAP("videojuego", 1.15)),
    ("videojuego", "historial_precio", "videojuego_id", "0..N", GAP("videojuego", 1.5)),
    ("videojuego", "promocion_videojuego", "videojuego_id", "0..N", GAP("videojuego", 1.85)),
    ("genero", "videojuego_genero", "genero_id", "0..N", GAP("genero", 1.2)),
    ("promocion", "promocion_videojuego", "promocion_id", "1..N", GAP("promocion", 1.2)),
]

C_HDR, C_LINE, C_PK, C_FK, C_TXT = "#1f3a5f", "#3b4a5a", "#b8860b", "#2e7d32", "#1a1a1a"


def box(name):
    col, y, cols = T[name]
    return COLX[col], y, W, HDR + ROW * len(cols)


def row_y(name, colname):
    _, y, cols = T[name]
    i = [c[0] for c in cols].index(colname)
    return y + HDR + ROW * (i + 0.5)


def draw_table(ax, name):
    x, y, w, h = box(name)
    cols = T[name][2]
    ax.add_patch(Rectangle((x, y), w, h, fc="white", ec=C_HDR, lw=1.4, zorder=3))
    ax.add_patch(Rectangle((x, y), w, HDR, fc=C_HDR, ec=C_HDR, lw=1.4, zorder=4))
    ax.text(x + w / 2, y + HDR / 2, name, color="white", ha="center", va="center",
            fontsize=9.5, fontweight="bold", zorder=5, family="DejaVu Sans")
    for i, (cn, ty, key) in enumerate(cols):
        cy = y + HDR + ROW * (i + 0.5)
        if i % 2:
            ax.add_patch(Rectangle((x, y + HDR + ROW * i), w, ROW, fc="#f2f5f9", ec="none", zorder=3.5))
        kc = C_PK if "PK" in key else C_FK
        ax.text(x + 0.08, cy, key, color=kc, fontsize=6.6, fontweight="bold", va="center", zorder=5)
        ax.text(x + KEYW, cy, cn, color=C_TXT, fontsize=7.6, va="center", zorder=5,
                fontweight="bold" if "PK" in key else "normal")
        ax.text(x + w - 0.08, cy, ty, color="#5a6b7c", fontsize=6.8, va="center", ha="right", zorder=5)


def bar(ax, x, y):
    ax.plot([x, x], [y - 0.13, y + 0.13], color=C_LINE, lw=1.2, zorder=2)


def ring(ax, x, y):
    ax.add_patch(Circle((x, y), 0.075, fc="white", ec=C_LINE, lw=1.2, zorder=2.5))


def end_one(ax, x, y, d):          # || exactamente uno
    bar(ax, x + d * 0.14, y); bar(ax, x + d * 0.24, y)


def end_child(ax, x, y, d, card):
    if card in ("0..N", "1..N"):    # pata de gallo
        tip = x + d * 0.26
        for dy in (-0.14, 0, 0.14):
            ax.plot([tip, x], [y, y + dy], color=C_LINE, lw=1.2, zorder=2)
        (ring if card == "0..N" else bar)(ax, x + d * 0.40, y)
    else:                           # 0..1
        bar(ax, x + d * 0.16, y); ring(ax, x + d * 0.34, y)


def main(out):
    fig, ax = plt.subplots(figsize=(23, 12.4), dpi=150)
    for n in T:
        draw_table(ax, n)

    # puntos de salida repartidos sobre el borde del padre, en el orden vertical de los hijos
    by_side = {}
    for p, c, fk, card, mx in R:
        px, _, _, _ = box(p)
        side = 1 if mx > px else -1
        by_side.setdefault((p, side), []).append((row_y(c, fk), c))
    pstart = {}
    for (p, side), lst in by_side.items():
        lst.sort()
        _, y, _, h = box(p)
        top = y + HDR + (ROW * 2.2 if (p, side) == ("videojuego", -1) else 0)
        for i, (_, c) in enumerate(lst):
            pstart[(p, c)] = top + (y + h - top) * (i + 1) / (len(lst) + 1)

    for p, c, fk, card, mx in R:
        px, _, pw, _ = box(p)
        cx, _, cw, _ = box(c)
        d = 1 if mx > px else -1
        x0 = px + pw if d == 1 else px
        x1 = cx if d == 1 else cx + cw
        y0, y1 = pstart[(p, c)], row_y(c, fk)
        ax.plot([x0, mx, mx, x1], [y0, y0, y1, y1], color=C_LINE, lw=1.1, zorder=1)
        end_one(ax, x0, y0, d)
        end_child(ax, x1, y1, -d, card)

    # amistad: dos relaciones con usuario por el costado izquierdo
    ux, uy, _, uh = box("usuario")
    ax_ = ux
    for i, (fk, lx) in enumerate((("usuario_solicita_id", -0.55), ("usuario_recibe_id", -0.95))):
        y0 = uy + HDR + (uh - HDR) * (i + 1) / 3
        y1 = row_y("amistad", fk)
        ax.plot([ax_, lx, lx, ax_], [y0, y0, y1, y1], color=C_LINE, lw=1.1, zorder=1)
        end_one(ax, ax_, y0, -1)
        end_child(ax, ax_, y1, -1, "0..N")

    # leyenda
    lx, ly = 0, 13.6
    ax.text(lx, ly, "Notación pata de gallo:", fontsize=8, fontweight="bold", va="center")
    items = [("uno y solo uno", "1"), ("cero o uno", "0..1"), ("cero o muchos", "0..N"), ("uno o muchos", "1..N")]
    xx = lx + 3.4
    for label, card in items:
        ax.plot([xx, xx + 1.0], [ly, ly], color=C_LINE, lw=1.1)
        if card == "1":
            end_one(ax, xx + 1.0, ly, -1)
        else:
            end_child(ax, xx + 1.0, ly, -1, card)
        ax.text(xx + 1.15, ly, label, fontsize=7.6, va="center")
        xx += 3.6
    ax.text(lx + 18.2, ly, "PK = llave primaria   FK = llave foránea   UK = única", fontsize=7.6,
            va="center", color="#444")

    ax.set_xlim(-1.3, COLX[-1] + W + 0.3)
    ax.set_ylim(14.1, -0.5)
    ax.set_aspect("equal")
    ax.axis("off")
    fig.savefig(out, bbox_inches="tight", facecolor="white", pad_inches=0.15)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "diagrama_relacional.png")
