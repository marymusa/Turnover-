"""Extrae el contorno exterior del escudo y lo guarda como lista de puntos.

Se ejecuta a mano cuando cambia `assets/images/league_logo.png`; su salida,
`assets/images/league_logo_outline.json`, sí se versiona. Trazar en el
arranque costaria mas que leer el resultado ya hecho.

    python scripts/trace_logo_outline.py
"""

import json
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "assets/images/league_logo.png"
TARGET = ROOT / "assets/images/league_logo_outline.json"

# Por debajo de esto el pixel se considera transparente. El PNG trae el borde
# suavizado, asi que el umbral cae a media altura para quedarse en el filo.
ALPHA_THRESHOLD = 128

# Distancia maxima, en unidades normalizadas, entre el contorno original y el
# simplificado. Mas alto simplifica mas y pierde las puntas de los pinchos.
SIMPLIFY_TOLERANCE = 0.0015

MOORE_NEIGHBOURS = [(-1, 0), (-1, 1), (0, 1), (1, 1), (1, 0), (1, -1), (0, -1), (-1, -1)]


def trace_outline(mask: np.ndarray) -> list[tuple[int, int]]:
    """Recorre el borde exterior de la silueta con Moore-neighbour tracing."""
    height, width = mask.shape
    ys, xs = np.nonzero(mask)
    start = (int(ys.min()), int(xs[ys.argmin()]))

    def is_opaque(y: int, x: int) -> bool:
        return 0 <= y < height and 0 <= x < width and bool(mask[y, x])

    contour = [start]
    current = start
    backtrack = 0
    # El limite corta un recorrido que no cierre, que solo puede venir de una
    # mascara rota: sin el, el bucle no terminaria.
    for _ in range(8 * mask.sum()):
        for step in range(8):
            direction = (backtrack + step) % 8
            dy, dx = MOORE_NEIGHBOURS[direction]
            candidate = (current[0] + dy, current[1] + dx)
            if is_opaque(*candidate):
                current = candidate
                contour.append(current)
                backtrack = (direction + 5) % 8
                break
        else:
            break
        if current == start and len(contour) > 2:
            break
    return contour


def simplify(points: list[tuple[float, float]], tolerance: float) -> list[tuple[float, float]]:
    """Ramer-Douglas-Peucker, para bajar de miles de puntos a unos cientos."""
    if len(points) < 3:
        return points
    start, end = np.array(points[0]), np.array(points[-1])
    segment = end - start
    length = np.hypot(*segment)
    if length == 0:
        distances = [np.hypot(*(np.array(p) - start)) for p in points]
    else:
        distances = [
            abs(segment[0] * (p[1] - start[1]) - segment[1] * (p[0] - start[0]))
            / length
            for p in points
        ]
    index = int(np.argmax(distances))
    if distances[index] <= tolerance:
        return [points[0], points[-1]]
    left = simplify(points[: index + 1], tolerance)
    right = simplify(points[index:], tolerance)
    return left[:-1] + right


def main() -> None:
    image = Image.open(SOURCE).convert("RGBA")
    mask = np.array(image.getchannel("A")) > ALPHA_THRESHOLD
    contour = trace_outline(mask)

    height, width = mask.shape
    size = max(width, height)
    # Normalizado a [0,1] sobre el lado mayor y centrado: asi el mismo contorno
    # vale para cualquier tamano en pantalla sin recalcularlo.
    normalised = [
        ((x - (width - size) / 2) / size, (y - (height - size) / 2) / size)
        for y, x in contour
    ]
    simplified = simplify(normalised, SIMPLIFY_TOLERANCE)

    TARGET.write_text(
        json.dumps(
            {
                "source": SOURCE.name,
                "points": [[round(x, 5), round(y, 5)] for x, y in simplified],
            }
        ),
        encoding="utf-8",
    )
    print(f"{len(contour)} puntos -> {len(simplified)} en {TARGET.name}")


if __name__ == "__main__":
    main()
