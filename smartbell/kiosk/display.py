import time
import cv2
import numpy as np

from config import DISPLAY_WIDTH, DISPLAY_HEIGHT

_WINDOW = "SmartBell — Borne d'accès"

# Couleurs BGR
_GREEN  = (34, 197, 94)
_BLUE   = (234, 179, 8)
_RED    = (60,  60, 220)
_WHITE  = (255, 255, 255)
_GRAY   = (150, 150, 150)
_BLACK  = (0,   0,   0)

_FONT       = cv2.FONT_HERSHEY_DUPLEX
_FONT_BOLD  = cv2.FONT_HERSHEY_TRIPLEX


def _resize(frame: np.ndarray) -> np.ndarray:
    return cv2.resize(frame, (DISPLAY_WIDTH, DISPLAY_HEIGHT))


def _overlay_text(img: np.ndarray, text: str, y: int,
                  color=_WHITE, scale: float = 0.9, thickness: int = 2):
    (w, _), _ = cv2.getTextSize(text, _FONT, scale, thickness)
    x = (img.shape[1] - w) // 2
    cv2.putText(img, text, (x, y), _FONT, scale, _BLACK, thickness + 2, cv2.LINE_AA)
    cv2.putText(img, text, (x, y), _FONT, scale, color,  thickness,     cv2.LINE_AA)


def show_frame(frame: np.ndarray, message: str = "En attente…"):
    """Affiche le flux caméra avec un message en bas."""
    img = _resize(frame)
    h, w = img.shape[:2]

    # Bande de statut en bas
    cv2.rectangle(img, (0, h - 60), (w, h), _BLACK, -1)
    _overlay_text(img, message, h - 20, _GRAY, scale=0.75)

    cv2.imshow(_WINDOW, img)
    cv2.waitKey(1)


def show_result(frame: np.ndarray, result: dict):
    """
    Affiche un feedback 2 s après un check-in/out facial.
    result = {action, firstName, durationMinutes?}
    """
    action    = result.get("action", "IN")
    first     = result.get("firstName", "")
    duration  = result.get("durationMinutes")

    img = _resize(frame)
    h, w = img.shape[:2]

    if action == "IN":
        overlay_color = _GREEN
        title   = f"Bienvenue, {first} !"
        subtitle = time.strftime("Entrée à %H:%M")
    else:
        overlay_color = _BLUE
        hours, mins = divmod(int(duration or 0), 60)
        title    = f"A bientot, {first} !"
        subtitle = f"Duree : {hours}h{mins:02d}min" if hours else f"Duree : {mins} min"

    # Overlay coloré semi-transparent
    overlay = img.copy()
    cv2.rectangle(overlay, (0, 0), (w, h), overlay_color, -1)
    cv2.addWeighted(overlay, 0.35, img, 0.65, 0, img)

    # Textes centrés
    _overlay_text(img, title,    h // 2 - 30, _WHITE, scale=1.4, thickness=3)
    _overlay_text(img, subtitle, h // 2 + 30, _WHITE, scale=0.9, thickness=2)

    # Icône check en haut
    icon = "CHECK-IN" if action == "IN" else "CHECK-OUT"
    _overlay_text(img, icon, 60, overlay_color, scale=1.0, thickness=2)

    cv2.imshow(_WINDOW, img)
    cv2.waitKey(2000)   # 2 secondes d'affichage


def init_window():
    cv2.namedWindow(_WINDOW, cv2.WINDOW_NORMAL)
    cv2.resizeWindow(_WINDOW, DISPLAY_WIDTH, DISPLAY_HEIGHT)


def destroy():
    cv2.destroyAllWindows()
