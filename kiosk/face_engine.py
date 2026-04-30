import logging
import os
import re
import time
from pathlib import Path

import cv2
import numpy as np
from deepface import DeepFace

from config import FACES_DB_PATH, DETECTION_THRESHOLD, DEEPFACE_MODEL, DEEPFACE_METRIC

log = logging.getLogger(__name__)


def enroll_member(member_id: int, image_path: str) -> str:
    """Copie l'image dans faces_db/{member_id}/{member_id}_{timestamp}.jpg"""
    dest_dir = Path(FACES_DB_PATH) / str(member_id)
    dest_dir.mkdir(parents=True, exist_ok=True)
    timestamp = int(time.time())
    dest = dest_dir / f"{member_id}_{timestamp}.jpg"

    img = cv2.imread(image_path)
    if img is None:
        raise ValueError(f"Image illisible : {image_path}")
    cv2.imwrite(str(dest), img)
    log.info("Visage enregistré : %s", dest)
    return str(dest)


def identify_face(frame: np.ndarray) -> int | None:
    """
    Cherche le visage du frame dans la base.
    Retourne le member_id (int) si trouvé sous le seuil, sinon None.
    """
    db_path = str(Path(FACES_DB_PATH).resolve())
    if not os.path.isdir(db_path) or not any(Path(db_path).iterdir()):
        return None

    try:
        results = DeepFace.find(
            img_path=frame,
            db_path=db_path,
            model_name=DEEPFACE_MODEL,
            distance_metric=DEEPFACE_METRIC,
            enforce_detection=False,
            silent=True,
        )

        if not results or results[0].empty:
            return None

        best = results[0].iloc[0]
        distance = best.get(f"{DEEPFACE_MODEL}_{DEEPFACE_METRIC}", 1.0)

        if distance > DETECTION_THRESHOLD:
            return None

        # Le chemin ressemble à faces_db/42/42_1234567890.jpg
        identity_path = best.get("identity", "")
        match = re.search(r"[\\/](\d+)[\\/]", identity_path)
        if match:
            return int(match.group(1))
        return None

    except Exception as e:
        log.debug("DeepFace.find error: %s", e)
        return None
