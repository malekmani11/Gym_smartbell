import pandas as pd
import numpy as np
import random
import os

random.seed(42)
np.random.seed(42)

# ─────────────────────────────────────────
#  Valeurs possibles
# ─────────────────────────────────────────
OBJECTIFS  = ["perte_poids", "prise_masse", "endurance", "tonification"]
NIVEAUX    = ["debutant", "intermediaire", "avance"]
SEXES      = ["homme", "femme"]

TYPE_PROG  = ["cardio_dominant", "musculation", "mixte", "HIIT"]
SPLITS     = ["full_body", "push_pull", "ppl", "haut_bas"]

# ─────────────────────────────────────────
#  Règles métier → labels
# ─────────────────────────────────────────
def calculer_imc(poids, taille_cm):
    taille_m = taille_cm / 100
    return round(poids / (taille_m ** 2), 1)

def categoriser_imc(imc):
    if imc < 18.5:
        return "maigreur"
    elif imc < 25:
        return "normal"
    elif imc < 30:
        return "surpoids"
    else:
        return "obesite"

def determiner_programme(objectif, imc_cat, niveau, sexe):
    """Règles métier pour définir le type de programme."""
    # Perte de poids
    if objectif == "perte_poids":
        if imc_cat in ["surpoids", "obesite"]:
            return "cardio_dominant", 1 if niveau == "debutant" else 2
        else:
            return "HIIT", 2 if niveau == "debutant" else 3

    # Prise de masse
    elif objectif == "prise_masse":
        if imc_cat == "maigreur":
            return "musculation", 2
        return "musculation", 3 if niveau == "avance" else 2

    # Endurance
    elif objectif == "endurance":
        if niveau == "avance":
            return "cardio_dominant", 4
        return "cardio_dominant", 2 if niveau == "debutant" else 3

    # Tonification
    elif objectif == "tonification":
        if sexe == "femme":
            return "mixte", 2 if niveau == "debutant" else 3
        return "mixte", 2

def determiner_split(type_prog, niveau, seances):
    """Règles métier pour le split musculaire."""
    if type_prog == "cardio_dominant":
        return "full_body"
    elif type_prog == "HIIT":
        return "full_body"
    elif type_prog == "musculation":
        if seances <= 3:
            return "full_body" if niveau == "debutant" else "haut_bas"
        elif seances == 4:
            return "push_pull"
        else:
            return "ppl"
    else:  # mixte
        return "haut_bas" if niveau != "avance" else "push_pull"

def determiner_seances(objectif, niveau):
    base = {"perte_poids": (3, 5), "prise_masse": (4, 6),
            "endurance": (3, 5), "tonification": (3, 5)}
    lo, hi = base[objectif]
    if niveau == "debutant":
        hi = min(hi, lo + 1)
    elif niveau == "avance":
        lo = max(lo, hi - 1)
    return random.randint(lo, hi)

# ─────────────────────────────────────────
#  Génération des profils
# ─────────────────────────────────────────
def generer_profil():
    sexe      = random.choice(SEXES)
    objectif  = random.choice(OBJECTIFS)
    niveau    = random.choice(NIVEAUX)

    # Morphologie réaliste selon le sexe
    if sexe == "homme":
        taille = random.randint(160, 195)
        poids  = random.randint(55, 120)
        age    = random.randint(16, 65)
    else:
        taille = random.randint(150, 180)
        poids  = random.randint(45, 100)
        age    = random.randint(16, 65)

    imc     = calculer_imc(poids, taille)
    imc_cat = categoriser_imc(imc)
    seances = determiner_seances(objectif, niveau)

    type_prog, intensite = determiner_programme(objectif, imc_cat, niveau, sexe)
    split = determiner_split(type_prog, niveau, seances)

    # Bruit réaliste sur l'intensité (±1 parfois)
    bruit = random.choices([0, 1, -1], weights=[0.7, 0.15, 0.15])[0]
    intensite = max(1, min(5, intensite + bruit))

    return {
        # Features d'entrée
        "sexe"           : sexe,
        "age"            : age,
        "poids_kg"       : poids,
        "taille_cm"      : taille,
        "imc"            : imc,
        "imc_categorie"  : imc_cat,
        "objectif"       : objectif,
        "niveau"         : niveau,
        "seances_semaine": seances,
        # Labels (cibles)
        "type_programme" : type_prog,
        "intensite"      : intensite,
        "split_musculaire": split,
    }

# ─────────────────────────────────────────
#  Main
# ─────────────────────────────────────────
def generer_dataset(n=2000, output_path="data/dataset_gym.csv"):
    print(f"Génération de {n} profils...")
    profils = [generer_profil() for _ in range(n)]
    df = pd.DataFrame(profils)

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    df.to_csv(output_path, index=False)
    print(f"Dataset sauvegardé → {output_path}")
    return df

if __name__ == "__main__":
    df = generer_dataset(n=2000)

    print("\n=== Aperçu (5 premières lignes) ===")
    print(df.head())

    print("\n=== Distribution des labels ===")
    for col in ["type_programme", "intensite", "split_musculaire"]:
        print(f"\n{col}:")
        print(df[col].value_counts())

    print("\n=== Statistiques numériques ===")
    print(df[["age", "poids_kg", "taille_cm", "imc", "seances_semaine"]].describe())

    print("\n=== Distribution IMC ===")
    print(df["imc_categorie"].value_counts())

    print(f"\nTotal profils : {len(df)}")
    print(f"Colonnes      : {list(df.columns)}")