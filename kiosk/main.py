"""
SmartBell — Borne de reconnaissance faciale
Lancer : python main.py
"""
import logging
import signal
import sys
import time

import cv2
from deepface import DeepFace

import api_client
import display
import face_engine
from config import CAMERA_INDEX, COOLDOWN_SECONDS

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s — %(message)s",
)
log = logging.getLogger("kiosk")

# cooldown par membre : {member_id: timestamp_dernier_checkin}
_last_checkin: dict[int, float] = {}


def _handle_signal(sig, frame):
    log.info("Arrêt de la borne…")
    display.destroy()
    sys.exit(0)


def main():
    signal.signal(signal.SIGINT,  _handle_signal)
    signal.signal(signal.SIGTERM, _handle_signal)

    display.init_window()

    # Authentification initiale
    log.info("Connexion au backend SmartBell…")
    if not api_client.get_auth_token():
        log.error("Impossible de s'authentifier. Vérifiez BACKEND_URL et les credentials.")

    cap = cv2.VideoCapture(CAMERA_INDEX)
    if not cap.isOpened():
        log.error("Impossible d'ouvrir la caméra index=%d", CAMERA_INDEX)
        sys.exit(1)

    log.info("Borne démarrée. Appuyez sur Ctrl+C pour quitter.")

    while True:
        ret, frame = cap.read()
        if not ret:
            log.warning("Frame caméra manquant, retry…")
            time.sleep(0.1)
            continue

        # Détection rapide de visages
        try:
            faces = DeepFace.extract_faces(
                frame,
                detector_backend="opencv",
                enforce_detection=False,
            )
            has_face = any(f.get("confidence", 0) > 0.5 for f in faces)
        except Exception:
            has_face = False

        if not has_face:
            display.show_frame(frame, "En attente d'un membre…")
            continue

        # Identification
        member_id = face_engine.identify_face(frame)

        if member_id is None:
            display.show_frame(frame, "Visage non reconnu")
            continue

        # Cooldown anti-doublons
        now = time.time()
        if now - _last_checkin.get(member_id, 0) < COOLDOWN_SECONDS:
            display.show_frame(frame, "Deja enregistre")
            continue

        # Appel API
        result = api_client.facial_checkin(member_id)
        if result:
            _last_checkin[member_id] = now
            display.show_result(frame, result)
            action = result.get("action", "?")
            name   = result.get("firstName", "")
            log.info("CHECK-%s — %s (memberId=%d)", action, name, member_id)
        else:
            display.show_frame(frame, "Erreur serveur — réessayez")

    cap.release()
    display.destroy()


if __name__ == "__main__":
    main()
