import os
import joblib
import numpy as np
import pandas as pd

# ─────────────────────────────────────────
#  Constantes (doivent correspondre à preprocessor.py)
# ─────────────────────────────────────────
MODELS_DIR   = "models"
FEATURES     = ["sexe", "age", "poids_kg", "taille_cm",
                 "imc", "imc_categorie", "objectif",
                 "niveau", "seances_semaine"]
COLONNES_NUM = ["age", "poids_kg", "taille_cm", "imc", "seances_semaine"]

# Descriptions lisibles pour le prompt Gemini
DESC_TYPE = {
    "cardio_dominant": "programme cardio dominant (course, vélo, natation…)",
    "musculation"    : "programme de musculation (hypertrophie / force)",
    "mixte"          : "programme mixte (cardio + renforcement musculaire)",
    "HIIT"           : "programme HIIT (intervalles haute intensité)",
}
DESC_SPLIT = {
    "full_body" : "Full Body — tout le corps à chaque séance",
    "push_pull" : "Push / Pull — tirage vs. poussée en alternance",
    "ppl"       : "PPL — Poitrine-Épaules-Triceps / Dos-Biceps / Jambes",
    "haut_bas"  : "Haut du corps / Bas du corps en alternance",
}
DESC_OBJECTIF = {
    "perte_poids" : "perte de poids",
    "prise_masse" : "prise de masse musculaire",
    "endurance"   : "amélioration de l'endurance",
    "tonification": "tonification corporelle",
}
DESC_NIVEAU = {
    "debutant"      : "débutant",
    "intermediaire" : "intermédiaire",
    "avance"        : "avancé",
}
DESC_SEXE = {"homme": "Homme", "femme": "Femme"}

# ─────────────────────────────────────────
#  Chargement des artefacts
# ─────────────────────────────────────────
def _charger_artefacts():
    """Charge les modèles, encoders et scaler une seule fois."""
    modeles = {
        "type_programme"  : joblib.load(os.path.join(MODELS_DIR, "model_type_programme.pkl")),
        "intensite"       : joblib.load(os.path.join(MODELS_DIR, "model_intensite.pkl")),
        "split_musculaire": joblib.load(os.path.join(MODELS_DIR, "model_split_musculaire.pkl")),
    }
    encoders = joblib.load(os.path.join(MODELS_DIR, "encoders.pkl"))
    scaler   = joblib.load(os.path.join(MODELS_DIR, "scaler.pkl"))
    return modeles, encoders, scaler

# Chargement paresseux au premier appel
_cache = {}

def _get_artefacts():
    if not _cache:
        _cache["modeles"], _cache["encoders"], _cache["scaler"] = _charger_artefacts()
    return _cache["modeles"], _cache["encoders"], _cache["scaler"]


# ─────────────────────────────────────────
#  Calcul IMC
# ─────────────────────────────────────────
def _calculer_imc(poids_kg: float, taille_cm: float) -> tuple[float, str]:
    taille_m = taille_cm / 100
    imc = round(poids_kg / (taille_m ** 2), 1)
    if imc < 18.5:
        categorie = "maigreur"
    elif imc < 25:
        categorie = "normal"
    elif imc < 30:
        categorie = "surpoids"
    else:
        categorie = "obesite"
    return imc, categorie


# ─────────────────────────────────────────
#  Fonction principale
# ─────────────────────────────────────────
def predict_profil(
    poids: float,
    taille: float,
    age: int,
    sexe: str,
    objectif: str,
    niveau: str,
    seances: int = 4,
) -> dict:
    """
    Prédit le programme sportif optimal pour un profil donné et construit
    le prompt Gemini correspondant.

    Paramètres
    ----------
    poids    : poids en kg
    taille   : taille en cm
    age      : âge en années
    sexe     : 'homme' | 'femme'
    objectif : 'perte_poids' | 'prise_masse' | 'endurance' | 'tonification'
    niveau   : 'debutant' | 'intermediaire' | 'avance'
    seances  : nombre de séances par semaine (défaut : 4)

    Retourne
    --------
    dict avec clés : type_programme, intensite, split_musculaire, imc,
                     imc_categorie, prompt
    """
    modeles, encoders, scaler = _get_artefacts()

    # 1. IMC
    imc, imc_categorie = _calculer_imc(poids, taille)

    # 2. Encodage des colonnes catégorielles
    def encode(col, val):
        le = encoders[col]
        if val not in le.classes_:
            raise ValueError(f"Valeur '{val}' inconnue pour '{col}'. "
                             f"Valeurs acceptées : {list(le.classes_)}")
        return int(le.transform([val])[0])

    row = {
        "sexe"           : encode("sexe", sexe),
        "age"            : float(age),
        "poids_kg"       : float(poids),
        "taille_cm"      : float(taille),
        "imc"            : float(imc),
        "imc_categorie"  : encode("imc_categorie", imc_categorie),
        "objectif"       : encode("objectif", objectif),
        "niveau"         : encode("niveau", niveau),
        "seances_semaine": float(seances),
    }

    # 3. Normalisation des features numériques
    df_row = pd.DataFrame([row], columns=FEATURES)
    df_row[COLONNES_NUM] = scaler.transform(df_row[COLONNES_NUM])
    X = df_row[FEATURES].values

    # 4. Prédictions brutes
    pred_type_enc  = modeles["type_programme"].predict(X)[0]
    pred_intensite = int(modeles["intensite"].predict(X)[0])
    pred_split_enc = modeles["split_musculaire"].predict(X)[0]

    # 5. Décodage texte
    type_programme   = encoders["type_programme"].inverse_transform([pred_type_enc])[0]
    split_musculaire = encoders["split_musculaire"].inverse_transform([pred_split_enc])[0]
    intensite        = max(1, min(5, pred_intensite))   # borne sécurité

    # 6. Construction du prompt Gemini
    prompt = _construire_prompt(
        sexe=sexe, age=age, poids=poids, taille=taille,
        imc=imc, imc_categorie=imc_categorie,
        objectif=objectif, niveau=niveau, seances=seances,
        type_programme=type_programme,
        intensite=intensite,
        split_musculaire=split_musculaire,
    )

    # 7. Retour complet
    return {
        "type_programme"  : type_programme,
        "intensite"       : intensite,
        "split_musculaire": split_musculaire,
        "imc"             : imc,
        "imc_categorie"   : imc_categorie,
        "prompt"          : prompt,
    }


# ─────────────────────────────────────────
#  Constructeur de prompt
# ─────────────────────────────────────────
def _construire_prompt(
    sexe, age, poids, taille, imc, imc_categorie,
    objectif, niveau, seances,
    type_programme, intensite, split_musculaire,
) -> str:

    desc_type  = DESC_TYPE.get(type_programme,   type_programme)
    desc_split = DESC_SPLIT.get(split_musculaire, split_musculaire)
    desc_obj   = DESC_OBJECTIF.get(objectif,     objectif)
    desc_niv   = DESC_NIVEAU.get(niveau,         niveau)
    desc_sexe  = DESC_SEXE.get(sexe,             sexe)

    prompt = f"""Tu es un coach sportif expert. Génère un programme d'entraînement personnalisé.

PROFIL: {desc_sexe}, {age} ans, {poids} kg, {taille} cm, IMC {imc} ({imc_categorie})
OBJECTIF: {desc_obj} | NIVEAU: {desc_niv} | SÉANCES: {seances}/semaine
PROGRAMME: {desc_type} | SPLIT: {desc_split} | INTENSITÉ: {intensite}/5

IMPORTANT: Retourne UNIQUEMENT un objet JSON valide, sans texte avant ni après, sans balises markdown.

Format EXACT à respecter:
{{
  "seances": [
    {{
      "nom": "Séance 1 — [nom]",
      "exercices": [
        {{"id": 1, "name": "Nom exercice", "sets": 4, "reps": 10, "weight": 60.0, "restSeconds": 90, "muscles": "muscles ciblés"}}
      ]
    }}
  ],
  "note_coach": "Conseils de progression, nutrition et récupération adaptés au profil (4-5 phrases)."
}}

Règles:
- Génère exactement {seances} séances respectant le split {split_musculaire}
- 5 à 7 exercices par séance
- Poids réalistes adaptés au niveau {desc_niv} et à l'objectif {desc_obj}
- Repos: 60-90s cardio/tonification, 90-120s musculation
- note_coach: conseils nutrition (protéines/glucides/lipides en g/kg), progression sur 4 semaines, récupération
- Rédige en français
"""
    return prompt.strip()


# ─────────────────────────────────────────
#  Test rapide
# ─────────────────────────────────────────
if __name__ == "__main__":
    result = predict_profil(
        poids=82, taille=178, age=28,
        sexe="homme", objectif="prise_masse",
        niveau="intermediaire", seances=4,
    )

    print("=" * 55)
    print("  PRÉDICTIONS ML")
    print("=" * 55)
    print(f"  IMC               : {result['imc']} ({result['imc_categorie']})")
    print(f"  Type programme    : {result['type_programme']}")
    print(f"  Intensité         : {result['intensite']}/5")
    print(f"  Split musculaire  : {result['split_musculaire']}")

    print("\n" + "=" * 55)
    print("  PROMPT GEMINI GÉNÉRÉ")
    print("=" * 55)
    print(result["prompt"])
