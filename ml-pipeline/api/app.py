import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import json
import re

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field, field_validator
from huggingface_hub import InferenceClient
from typing import List, Optional

from prompt_builder import predict_profil
from nutrition_builder import predict_nutrition

# ─────────────────────────────────────────
#  Configuration
# ─────────────────────────────────────────
load_dotenv(os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), ".env"))

HF_API_TOKEN = os.getenv("HF_API_TOKEN")
if not HF_API_TOKEN:
    raise RuntimeError("HF_API_TOKEN manquant dans .env")

# Modèle principal (programme sportif) — puissant
HF_MODEL         = "Qwen/Qwen2.5-72B-Instruct"
_hf_client       = InferenceClient(model=HF_MODEL, token=HF_API_TOKEN, timeout=150)

# Modèle nutrition — plus rapide, évite les timeouts
HF_MODEL_NUTRITION = "Qwen/Qwen2.5-7B-Instruct"
_hf_client_nutrition = InferenceClient(
    model=HF_MODEL_NUTRITION,
    token=HF_API_TOKEN,
    timeout=120,   # 120 secondes max
)

# ─────────────────────────────────────────
#  Application FastAPI
# ─────────────────────────────────────────
app = FastAPI(
    title="SmartBell ML API",
    description="Génération de programmes sportifs et plans nutritionnels via ML + Hugging Face",
    version="2.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:8080",   # Spring Boot
        "http://localhost:4200",   # Angular
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─────────────────────────────────────────
#  Constantes de validation
# ─────────────────────────────────────────
OBJECTIFS_VALIDES = {"perte_poids", "prise_masse", "endurance", "tonification"}
NIVEAUX_VALIDES   = {"debutant", "intermediaire", "avance"}
SEXES_VALIDES     = {"homme", "femme"}
ALLERGIES_VALIDES = {"gluten", "lactose", "noix", "oeufs", "soja", "aucune"}

# Mapping Spring Boot → valeurs internes du modèle ML
GOAL_MAPPING = {
    "perdre_du_poids": "perte_poids",
    "musculation"    : "prise_masse",
    "endurance"      : "endurance",
    "tonification"   : "tonification",
    # passer directement les valeurs internes aussi
    "perte_poids"    : "perte_poids",
    "prise_masse"    : "prise_masse",
}
LEVEL_MAPPING = {
    "debutant"      : "debutant",
    "intermediaire" : "intermediaire",
    "avance"        : "avance",
}

# ─────────────────────────────────────────
#  Schémas Pydantic — Programme
# ─────────────────────────────────────────
class ProfilRequest(BaseModel):
    poids   : float = Field(..., gt=20, lt=300,  description="Poids en kg")
    taille  : float = Field(..., gt=100, lt=250, description="Taille en cm")
    age     : int   = Field(..., ge=10, le=100,  description="Âge en années")
    sexe    : str   = Field(...,                 description="'homme' ou 'femme'")
    objectif: str   = Field(...,                 description="perte_poids | prise_masse | endurance | tonification")
    niveau  : str   = Field(...,                 description="debutant | intermediaire | avance")
    seances : int   = Field(4, ge=1, le=7,       description="Séances par semaine")

    @field_validator("sexe")
    @classmethod
    def valider_sexe(cls, v):
        v = v.lower().strip()
        if v not in SEXES_VALIDES:
            raise ValueError(f"sexe doit être parmi {SEXES_VALIDES}")
        return v

    @field_validator("objectif")
    @classmethod
    def valider_objectif(cls, v):
        v = v.lower().strip()
        if v not in OBJECTIFS_VALIDES:
            raise ValueError(f"objectif doit être parmi {OBJECTIFS_VALIDES}")
        return v

    @field_validator("niveau")
    @classmethod
    def valider_niveau(cls, v):
        v = v.lower().strip()
        if v not in NIVEAUX_VALIDES:
            raise ValueError(f"niveau doit être parmi {NIVEAUX_VALIDES}")
        return v


class ExerciceIA(BaseModel):
    id         : int
    name       : str
    sets       : int
    reps       : int
    weight     : float = 0.0
    restSeconds: int   = 90
    muscles    : str   = ""

class SeanceIA(BaseModel):
    nom      : str
    exercices: List[ExerciceIA]

class ProgrammeResponse(BaseModel):
    seances       : List[SeanceIA]
    note_coach    : str
    type_programme: str
    intensite     : int
    split         : str
    imc           : float
    imc_categorie : str


# ─────────────────────────────────────────
#  Schémas Pydantic — Nutrition
# ─────────────────────────────────────────
class NutritionRequest(BaseModel):
    poids    : float               = Field(..., gt=20, lt=300,  description="Poids en kg")
    taille   : float               = Field(..., gt=100, lt=250, description="Taille en cm")
    age      : int                 = Field(..., ge=10, le=100,  description="Âge en années")
    sexe     : str                 = Field(...,                 description="'homme' ou 'femme'")
    objectif : str                 = Field(...,                 description="perte_poids | prise_masse | endurance | tonification")
    niveau   : str                 = Field(...,                 description="debutant | intermediaire | avance")
    seances  : int                 = Field(4, ge=1, le=7,       description="Séances par semaine")
    allergies: Optional[List[str]] = Field(default=["aucune"],  description="Liste allergies : gluten | lactose | noix | oeufs | soja | aucune")

    @field_validator("sexe")
    @classmethod
    def valider_sexe(cls, v):
        v = v.lower().strip()
        if v not in SEXES_VALIDES:
            raise ValueError(f"sexe doit être parmi {SEXES_VALIDES}")
        return v

    @field_validator("objectif")
    @classmethod
    def valider_objectif(cls, v):
        v = v.lower().strip()
        if v not in OBJECTIFS_VALIDES:
            raise ValueError(f"objectif doit être parmi {OBJECTIFS_VALIDES}")
        return v

    @field_validator("niveau")
    @classmethod
    def valider_niveau(cls, v):
        v = v.lower().strip()
        if v not in NIVEAUX_VALIDES:
            raise ValueError(f"niveau doit être parmi {NIVEAUX_VALIDES}")
        return v

    @field_validator("allergies")
    @classmethod
    def valider_allergies(cls, v):
        if v is None:
            return ["aucune"]
        v = [a.lower().strip() for a in v]
        invalides = set(v) - ALLERGIES_VALIDES
        if invalides:
            raise ValueError(f"Allergies inconnues : {invalides}. Valides : {ALLERGIES_VALIDES}")
        return v


class NutritionResponse(BaseModel):
    plan_nutrition   : str
    calories_cible   : int
    proteines_g      : int
    glucides_g       : int
    lipides_g        : int
    proteines_par_kg : float
    imc              : float
    imc_categorie    : str
    bmr              : int
    tdee             : int


# ─────────────────────────────────────────
#  Endpoint 1 : Programme sportif
# ─────────────────────────────────────────
def _extraire_json(texte: str) -> dict:
    """Extrait un objet JSON depuis la réponse LLM (gère les balises markdown)."""
    texte = re.sub(r"```json\s*", "", texte)
    texte = re.sub(r"```\s*", "", texte)
    texte = texte.strip()
    match = re.search(r"\{.*\}", texte, re.DOTALL)
    if match:
        return json.loads(match.group())
    raise ValueError("Aucun JSON valide trouvé dans la réponse du LLM")


@app.post("/api/ai/generate-program", response_model=ProgrammeResponse)
async def generate_program(profil: ProfilRequest):
    # 1. Prédictions ML + construction du prompt
    try:
        ml_result = predict_profil(
            poids    =profil.poids,
            taille   =profil.taille,
            age      =profil.age,
            sexe     =profil.sexe,
            objectif =profil.objectif,
            niveau   =profil.niveau,
            seances  =profil.seances,
        )
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))
    except FileNotFoundError as e:
        raise HTTPException(status_code=503, detail=f"Modèle ML manquant : {e}")

    # 2. Appel Hugging Face — Qwen2.5-72B
    try:
        hf_response = _hf_client.chat_completion(
            messages=[{"role": "user", "content": ml_result["prompt"]}],
            max_tokens=3000,
            temperature=0.5,
        )
        raw_text = hf_response.choices[0].message.content.strip()
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Erreur Hugging Face API : {e}")

    # 3. Parse JSON
    try:
        data = _extraire_json(raw_text)
    except (ValueError, json.JSONDecodeError) as e:
        raise HTTPException(status_code=502, detail=f"Réponse LLM non parseable : {e}\nRaw: {raw_text[:300]}")

    # 4. Réponse structurée
    return ProgrammeResponse(
        seances       =data.get("seances", []),
        note_coach    =data.get("note_coach", ""),
        type_programme=ml_result["type_programme"],
        intensite     =ml_result["intensite"],
        split         =ml_result["split_musculaire"],
        imc           =ml_result["imc"],
        imc_categorie =ml_result["imc_categorie"],
    )


# ─────────────────────────────────────────
#  Endpoint 2 : Plan nutritionnel
# ─────────────────────────────────────────
@app.post("/api/ai/generate-nutrition", response_model=NutritionResponse)
async def generate_nutrition(profil: NutritionRequest):
    # 1. Calculs nutritionnels + construction du prompt
    try:
        nutrition_result = predict_nutrition(
            poids    =profil.poids,
            taille   =profil.taille,
            age      =profil.age,
            sexe     =profil.sexe,
            objectif =profil.objectif,
            niveau   =profil.niveau,
            seances  =profil.seances,
            allergies=profil.allergies,
        )
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))

    # 2. Appel Hugging Face — Mistral-7B (rapide, évite timeout)
    try:
        hf_response = _hf_client_nutrition.chat_completion(
            messages=[{"role": "user", "content": nutrition_result["prompt"]}],
            max_tokens=800,
            temperature=0.7,
        )
        plan_texte = hf_response.choices[0].message.content.strip()
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Erreur Hugging Face API : {e}")

    # 3. Réponse structurée
    return NutritionResponse(
        plan_nutrition   =plan_texte,
        calories_cible   =nutrition_result["calories_cible"],
        proteines_g      =nutrition_result["proteines_g"],
        glucides_g       =nutrition_result["glucides_g"],
        lipides_g        =nutrition_result["lipides_g"],
        proteines_par_kg =nutrition_result["proteines_par_kg"],
        imc              =nutrition_result["imc"],
        imc_categorie    =nutrition_result["imc_categorie"],
        bmr              =nutrition_result["bmr"],
        tdee             =nutrition_result["tdee"],
    )


# ─────────────────────────────────────────
#  Endpoint 3 : /predict — interface Spring Boot
#  Accepte {height, weight, goal, level}
#  Retourne {type_programme, intensite, split_musculaire}
# ─────────────────────────────────────────

class PredictRequest(BaseModel):
    height: float = Field(..., gt=100, lt=250, description="Taille en cm")
    weight: float = Field(..., gt=20,  lt=300, description="Poids en kg")
    goal  : str   = Field(..., description="perdre_du_poids | musculation | endurance")
    level : str   = Field(..., description="debutant | intermediaire | avance")

    @field_validator("goal")
    @classmethod
    def valider_goal(cls, v: str) -> str:
        v = v.lower().strip()
        if v not in GOAL_MAPPING:
            raise ValueError(
                f"goal '{v}' invalide. Valeurs acceptées : {list(GOAL_MAPPING.keys())}"
            )
        return v

    @field_validator("level")
    @classmethod
    def valider_level(cls, v: str) -> str:
        v = v.lower().strip()
        if v not in LEVEL_MAPPING:
            raise ValueError(
                f"level '{v}' invalide. Valeurs acceptées : {list(LEVEL_MAPPING.keys())}"
            )
        return v


class PredictResponse(BaseModel):
    type_programme  : str
    intensite       : str
    split_musculaire: str


@app.post("/predict", response_model=PredictResponse)
async def predict(req: PredictRequest):
    """
    Interface légère pour Spring Boot :
    - Accepte height/weight/goal/level
    - Calcule le BMI automatiquement
    - Encode goal et level pour le Random Forest
    - Retourne type_programme, intensite, split_musculaire (sans texte généré)
    """
    # 1. Mapper goal et level vers les valeurs internes du modèle
    objectif_interne = GOAL_MAPPING[req.goal]
    niveau_interne   = LEVEL_MAPPING[req.level]

    # 2. Appel predict_profil (IMC calculé à l'intérieur)
    try:
        ml_result = predict_profil(
            poids   =req.weight,
            taille  =req.height,
            age     =30,         # valeur par défaut (non fournie par Spring Boot)
            sexe    ="homme",    # valeur par défaut (non fournie par Spring Boot)
            objectif=objectif_interne,
            niveau  =niveau_interne,
            seances =4,          # valeur par défaut
        )
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))
    except FileNotFoundError as e:
        raise HTTPException(status_code=503, detail=f"Modèle ML manquant : {e}")

    # 3. Retourner uniquement les prédictions (pas le texte Hugging Face)
    return PredictResponse(
        type_programme  =ml_result["type_programme"],
        intensite       =str(ml_result["intensite"]),
        split_musculaire=ml_result["split_musculaire"],
    )


# ─────────────────────────────────────────
#  Health check
# ─────────────────────────────────────────
@app.get("/health")
def health():
    return {
        "status"   : "ok",
        "service"  : "SmartBell ML API v2",
        "modeles"  : {
            "programme" : HF_MODEL,
            "nutrition" : HF_MODEL_NUTRITION,
        },
        "endpoints": [
            "POST /predict",
            "POST /api/ai/generate-program",
            "POST /api/ai/generate-nutrition",
        ],
    }


# ─────────────────────────────────────────
#  Lancement local
# ─────────────────────────────────────────
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app:app", host="0.0.0.0", port=8000, reload=True)