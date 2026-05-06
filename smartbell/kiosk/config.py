import os

BACKEND_URL      = os.getenv("BACKEND_URL", "http://localhost:8080")
CAMERA_INDEX     = int(os.getenv("CAMERA_INDEX", "0"))
DETECTION_THRESHOLD = float(os.getenv("DETECTION_THRESHOLD", "0.6"))
COOLDOWN_SECONDS = int(os.getenv("COOLDOWN_SECONDS", "5"))
FACES_DB_PATH    = os.getenv("FACES_DB_PATH", "./faces_db")
DISPLAY_WIDTH    = int(os.getenv("DISPLAY_WIDTH", "1280"))
DISPLAY_HEIGHT   = int(os.getenv("DISPLAY_HEIGHT", "720"))

BORNE_EMAIL      = os.getenv("BORNE_EMAIL", "borne@smartbell.com")
BORNE_PASSWORD   = os.getenv("BORNE_PASSWORD", "Borne@2024!")

DEEPFACE_MODEL   = "VGG-Face"
DEEPFACE_METRIC  = "cosine"
