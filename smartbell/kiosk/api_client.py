import logging
import requests
from config import BACKEND_URL, BORNE_EMAIL, BORNE_PASSWORD

log = logging.getLogger(__name__)

_token: str | None = None


def get_auth_token() -> str | None:
    global _token
    try:
        resp = requests.post(
            f"{BACKEND_URL}/api/auth/login",
            json={"email": BORNE_EMAIL, "password": BORNE_PASSWORD},
            timeout=5,
        )
        resp.raise_for_status()
        _token = resp.json().get("token")
        log.info("Borne authentifiée avec succès")
        return _token
    except Exception as e:
        log.error("Échec authentification borne: %s", e)
        return None


def _headers() -> dict:
    return {"Authorization": f"Bearer {_token}", "Content-Type": "application/json"}


def facial_checkin(member_id: int) -> dict | None:
    """POST /api/checkins/facial — retourne {action, firstName, durationMinutes, ...}"""
    global _token
    for attempt in range(2):
        try:
            resp = requests.post(
                f"{BACKEND_URL}/api/checkins/facial",
                json={"memberId": member_id},
                headers=_headers(),
                timeout=5,
            )
            if resp.status_code == 401 and attempt == 0:
                log.warning("Token expiré, re-authentification…")
                get_auth_token()
                continue
            resp.raise_for_status()
            return resp.json()
        except Exception as e:
            log.error("Erreur facial_checkin: %s", e)
            return None
    return None
