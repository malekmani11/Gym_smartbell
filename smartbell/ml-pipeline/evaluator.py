import os
import joblib
import numpy as np
from sklearn.metrics import accuracy_score, f1_score, confusion_matrix

from preprocessor import run_preprocessing

# ─────────────────────────────────────────
#  Chemins
# ─────────────────────────────────────────
MODELS_DIR = "models"

MODEL_FILES = {
    "type_programme"  : "model_type_programme.pkl",
    "intensite"       : "model_intensite.pkl",
    "split_musculaire": "model_split_musculaire.pkl",
}

# ─────────────────────────────────────────
#  Chargement des modèles et artefacts
# ─────────────────────────────────────────
def charger_modeles():
    modeles = {}
    for cible, fichier in MODEL_FILES.items():
        path = os.path.join(MODELS_DIR, fichier)
        if not os.path.exists(path):
            raise FileNotFoundError(
                f"Modèle introuvable : {path}\n"
                f"  → Lance d'abord : python trainer.py"
            )
        modeles[cible] = joblib.load(path)
        print(f"  Chargé : {path}")
    return modeles


def charger_artefacts():
    enc_path    = os.path.join(MODELS_DIR, "encoders.pkl")
    scaler_path = os.path.join(MODELS_DIR, "scaler.pkl")
    encoders = joblib.load(enc_path)
    scaler   = joblib.load(scaler_path)
    print(f"  Chargé : {enc_path}")
    print(f"  Chargé : {scaler_path}")
    return encoders, scaler


# ─────────────────────────────────────────
#  Affichage de la matrice de confusion
# ─────────────────────────────────────────
def afficher_matrice(cm, classes):
    col_width = max(len(str(c)) for c in classes) + 2
    header = " " * col_width + "".join(f"{str(c):>{col_width}}" for c in classes)
    print(header)
    print(" " * col_width + "-" * (col_width * len(classes)))
    for i, row in enumerate(cm):
        line = f"{str(classes[i]):<{col_width}}" + "".join(f"{v:>{col_width}}" for v in row)
        print(line)


# ─────────────────────────────────────────
#  Évaluation
# ─────────────────────────────────────────
def evaluer(modeles, encoders, X_test, splits):
    resultats = {}

    for cible, clf in modeles.items():
        y_train, y_test = splits[cible]

        y_pred = clf.predict(X_test)

        acc = accuracy_score(y_test, y_pred)
        f1_macro  = f1_score(y_test, y_pred, average="macro",  zero_division=0)
        f1_weighted = f1_score(y_test, y_pred, average="weighted", zero_division=0)
        cm = confusion_matrix(y_test, y_pred)

        # Noms lisibles des classes via l'encoder si disponible
        if cible in encoders:
            classes = encoders[cible].classes_
        else:
            classes = np.unique(y_test)

        resultats[cible] = {
            "accuracy"    : acc,
            "f1_macro"    : f1_macro,
            "f1_weighted" : f1_weighted,
            "confusion_matrix": cm,
            "classes"     : classes,
        }

    return resultats


# ─────────────────────────────────────────
#  Rapport terminal
# ─────────────────────────────────────────
def afficher_rapport(resultats):
    separateur = "=" * 55

    print(f"\n{separateur}")
    print("   RAPPORT D'ÉVALUATION — SmartBell ML Pipeline")
    print(separateur)

    for cible, m in resultats.items():
        print(f"\n┌─ Modèle : {cible}")
        print(f"│  Accuracy         : {m['accuracy']:.4f}  ({m['accuracy']*100:.2f} %)")
        print(f"│  F1-score macro   : {m['f1_macro']:.4f}")
        print(f"│  F1-score weighted: {m['f1_weighted']:.4f}")
        print(f"│")
        print(f"│  Matrice de confusion :")
        lines = []
        col_w = max(len(str(c)) for c in m["classes"]) + 2
        header = " " * col_w + "".join(f"{str(c):>{col_w}}" for c in m["classes"])
        lines.append(header)
        lines.append(" " * col_w + "-" * (col_w * len(m["classes"])))
        for i, row in enumerate(m["confusion_matrix"]):
            line = f"{str(m['classes'][i]):<{col_w}}" + "".join(f"{v:>{col_w}}" for v in row)
            lines.append(line)
        for line in lines:
            print(f"│    {line}")
        print(f"└{'─' * 53}")

    # Résumé comparatif
    print(f"\n{separateur}")
    print(f"  {'Modèle':<22} {'Accuracy':>10} {'F1 macro':>10} {'F1 weighted':>12}")
    print(f"  {'-'*22} {'-'*10} {'-'*10} {'-'*12}")
    for cible, m in resultats.items():
        print(
            f"  {cible:<22} "
            f"{m['accuracy']:>10.4f} "
            f"{m['f1_macro']:>10.4f} "
            f"{m['f1_weighted']:>12.4f}"
        )
    print(separateur)


# ─────────────────────────────────────────
#  Pipeline principal
# ─────────────────────────────────────────
if __name__ == "__main__":
    print("=" * 55)
    print("   CHARGEMENT — SmartBell ML Pipeline")
    print("=" * 55)

    modeles          = charger_modeles()
    encoders, scaler = charger_artefacts()

    print("\nPréprocessing pour récupérer X_test et splits...")
    _, X_test, splits, _, _ = run_preprocessing()

    resultats = evaluer(modeles, encoders, X_test, splits)
    afficher_rapport(resultats)
