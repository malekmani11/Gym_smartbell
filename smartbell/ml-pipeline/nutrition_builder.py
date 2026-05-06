import os
import joblib
import numpy as np
import pandas as pd

# ─────────────────────────────────────────
#  Constantes
# ─────────────────────────────────────────
MODELS_DIR = "models"

DESC_OBJECTIF_NUTRITION = {
    "perte_poids" : "perte de poids",
    "prise_masse" : "prise de masse musculaire",
    "endurance"   : "amélioration de l'endurance",
    "tonification": "tonification corporelle",
}
DESC_NIVEAU = {
    "debutant"    : "débutant",
    "intermediaire": "intermédiaire",
    "avance"      : "avancé",
}
DESC_SEXE = {"homme": "Homme", "femme": "Femme"}

ALLERGIES_VALIDES = {"gluten", "lactose", "noix", "oeufs", "soja", "aucune"}


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
#  Calcul besoins caloriques (Mifflin-St Jeor)
# ─────────────────────────────────────────
def _calculer_calories(
    poids: float, taille: float, age: int,
    sexe: str, seances: int, objectif: str
) -> dict:
    # Métabolisme de base
    if sexe == "homme":
        bmr = 10 * poids + 6.25 * taille - 5 * age + 5
    else:
        bmr = 10 * poids + 6.25 * taille - 5 * age - 161

    # Facteur d'activité selon séances/semaine
    if seances <= 1:
        facteur = 1.2
    elif seances <= 3:
        facteur = 1.375
    elif seances <= 5:
        facteur = 1.55
    else:
        facteur = 1.725

    tdee = round(bmr * facteur)  # Total Daily Energy Expenditure

    # Ajustement selon objectif
    ajustements = {
        "perte_poids" : -400,
        "prise_masse" : +300,
        "endurance"   : +100,
        "tonification": -200,
    }
    calories_cible = tdee + ajustements.get(objectif, 0)

    # Macros selon objectif
    ratios = {
        "perte_poids" : {"proteines": 0.35, "glucides": 0.35, "lipides": 0.30},
        "prise_masse" : {"proteines": 0.30, "glucides": 0.50, "lipides": 0.20},
        "endurance"   : {"proteines": 0.20, "glucides": 0.55, "lipides": 0.25},
        "tonification": {"proteines": 0.35, "glucides": 0.40, "lipides": 0.25},
    }
    r = ratios.get(objectif, ratios["tonification"])

    proteines_g = round((calories_cible * r["proteines"]) / 4)
    glucides_g  = round((calories_cible * r["glucides"])  / 4)
    lipides_g   = round((calories_cible * r["lipides"])   / 9)

    # Ratio protéines par kg de poids
    proteines_par_kg = round(proteines_g / poids, 1)

    return {
        "bmr"              : round(bmr),
        "tdee"             : tdee,
        "calories_cible"   : calories_cible,
        "proteines_g"      : proteines_g,
        "glucides_g"       : glucides_g,
        "lipides_g"        : lipides_g,
        "proteines_par_kg" : proteines_par_kg,
    }


# ─────────────────────────────────────────
#  Fonction principale
# ─────────────────────────────────────────
def predict_nutrition(
    poids    : float,
    taille   : float,
    age      : int,
    sexe     : str,
    objectif : str,
    niveau   : str,
    seances  : int = 4,
    allergies: list[str] = None,
) -> dict:
    """
    Calcule les besoins nutritionnels et construit le prompt Qwen2.5
    pour générer un plan nutrition personnalisé.

    Paramètres
    ----------
    poids     : poids en kg
    taille    : taille en cm
    age       : âge en années
    sexe      : 'homme' | 'femme'
    objectif  : 'perte_poids' | 'prise_masse' | 'endurance' | 'tonification'
    niveau    : 'debutant' | 'intermediaire' | 'avance'
    seances   : nombre de séances par semaine (défaut : 4)
    allergies : liste d'allergies ex: ['gluten', 'lactose'] (défaut : ['aucune'])

    Retourne
    --------
    dict avec clés : calories, macros, imc, imc_categorie, prompt
    """
    if allergies is None:
        allergies = ["aucune"]

    # 1. IMC
    imc, imc_categorie = _calculer_imc(poids, taille)

    # 2. Calcul nutritionnel
    nutrition = _calculer_calories(poids, taille, age, sexe, seances, objectif)

    # 3. Construction du prompt
    prompt = _construire_prompt_nutrition(
        sexe=sexe, age=age, poids=poids, taille=taille,
        imc=imc, imc_categorie=imc_categorie,
        objectif=objectif, niveau=niveau, seances=seances,
        allergies=allergies,
        **nutrition,
    )

    return {
        "imc"            : imc,
        "imc_categorie"  : imc_categorie,
        "calories_cible" : nutrition["calories_cible"],
        "bmr"            : nutrition["bmr"],
        "tdee"           : nutrition["tdee"],
        "proteines_g"    : nutrition["proteines_g"],
        "glucides_g"     : nutrition["glucides_g"],
        "lipides_g"      : nutrition["lipides_g"],
        "proteines_par_kg": nutrition["proteines_par_kg"],
        "prompt"         : prompt,
    }


# ─────────────────────────────────────────
#  Constructeur de prompt nutrition
# ─────────────────────────────────────────
def _construire_prompt_nutrition(
    sexe, age, poids, taille, imc, imc_categorie,
    objectif, niveau, seances, allergies,
    bmr, tdee, calories_cible,
    proteines_g, glucides_g, lipides_g, proteines_par_kg,
) -> str:

    desc_obj   = DESC_OBJECTIF_NUTRITION.get(objectif, objectif)
    desc_niv   = DESC_NIVEAU.get(niveau, niveau)
    desc_sexe  = DESC_SEXE.get(sexe, sexe)
    allergies_str = ", ".join(allergies) if allergies != ["aucune"] else "aucune allergie connue"

    prompt = f"""Tu es un nutritionniste sportif expert et un diététicien certifié.
Génère un plan nutritionnel hebdomadaire complet, personnalisé et pratique pour le profil suivant.

═══════════════════════════════════════════
  PROFIL DU MEMBRE
═══════════════════════════════════════════
• Sexe              : {desc_sexe}
• Âge               : {age} ans
• Poids             : {poids} kg
• Taille            : {taille} cm
• IMC               : {imc} ({imc_categorie})
• Objectif          : {desc_obj}
• Niveau sportif    : {desc_niv}
• Séances/semaine   : {seances}
• Allergies         : {allergies_str}

═══════════════════════════════════════════
  CALCULS NUTRITIONNELS (SmartBell)
═══════════════════════════════════════════
• Métabolisme de base (BMR) : {bmr} kcal/jour
• Dépense totale (TDEE)     : {tdee} kcal/jour
• Objectif calorique        : {calories_cible} kcal/jour
• Protéines cibles          : {proteines_g} g/jour  ({proteines_par_kg} g/kg)
• Glucides cibles           : {glucides_g} g/jour
• Lipides cibles            : {lipides_g} g/jour

═══════════════════════════════════════════
  CE QUE TU DOIS GÉNÉRER
═══════════════════════════════════════════
1. Plan alimentaire journalier type (5 repas)
   - Petit-déjeuner, Collation matin, Déjeuner, Collation après-midi, Dîner
   - Pour chaque repas : aliments, quantités en grammes, calories approximatives
   - Respecte les macros calculées ({proteines_g}g protéines / {glucides_g}g glucides / {lipides_g}g lipides)
   - Évite absolument : {allergies_str}

2. Exemple de menu sur 3 jours différents
   - Variété et praticité (aliments accessibles en Tunisie)
   - Indique les alternatives possibles pour chaque repas

3. Conseils nutritionnels ciblés pour "{desc_obj}"
   - Timing des repas par rapport aux séances
   - Aliments à privilégier et à éviter
   - Suppléments recommandés si nécessaire (whey, créatine, etc.)

4. Hydratation
   - Quantité d'eau journalière recommandée
   - Conseils avant/pendant/après entraînement

5. Liste de courses hebdomadaire
   - Aliments de base à toujours avoir
   - Budget estimatif (en DT tunisien si possible)

Rédige en français, avec un ton encourageant, pratique et professionnel.
Structure ta réponse avec des titres clairs et des tableaux si nécessaire.
"""
    return prompt.strip()


# ─────────────────────────────────────────
#  Test rapide
# ─────────────────────────────────────────
if __name__ == "__main__":
    result = predict_nutrition(
        poids=82, taille=178, age=28,
        sexe="homme", objectif="prise_masse",
        niveau="intermediaire", seances=4,
        allergies=["lactose"],
    )

    print("=" * 55)
    print("  CALCULS NUTRITIONNELS")
    print("=" * 55)
    print(f"  IMC               : {result['imc']} ({result['imc_categorie']})")
    print(f"  Calories cible    : {result['calories_cible']} kcal")
    print(f"  Protéines         : {result['proteines_g']} g ({result['proteines_par_kg']} g/kg)")
    print(f"  Glucides          : {result['glucides_g']} g")
    print(f"  Lipides           : {result['lipides_g']} g")

    print("\n" + "=" * 55)
    print("  PROMPT GÉNÉRÉ")
    print("=" * 55)
    print(result["prompt"])