import pandas as pd
import numpy as np
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.model_selection import train_test_split
import joblib
import os

# ─────────────────────────────────────────
#  Chargement du dataset
# ─────────────────────────────────────────
def charger_dataset(path="data/dataset_gym.csv"):
    df = pd.read_csv(path)
    print(f"Dataset chargé : {df.shape[0]} lignes, {df.shape[1]} colonnes")
    return df

# ─────────────────────────────────────────
#  Nettoyage
# ─────────────────────────────────────────
def nettoyer(df):
    avant = len(df)
    df = df.dropna()
    df = df.drop_duplicates()
    print(f"Nettoyage : {avant} → {len(df)} lignes")
    return df

# ─────────────────────────────────────────
#  Encodage des colonnes catégorielles
# ─────────────────────────────────────────
COLONNES_CAT = ["sexe", "imc_categorie", "objectif", "niveau"]
LABELS_CAT   = ["type_programme", "split_musculaire"]

def encoder(df):
    encoders = {}

    # Features catégorielles
    for col in COLONNES_CAT:
        le = LabelEncoder()
        df[col] = le.fit_transform(df[col])
        encoders[col] = le
        print(f"Encodé '{col}' : {list(le.classes_)}")

    # Labels cibles catégorielles
    for col in LABELS_CAT:
        le = LabelEncoder()
        df[col] = le.fit_transform(df[col])
        encoders[col] = le
        print(f"Encodé label '{col}' : {list(le.classes_)}")

    return df, encoders

# ─────────────────────────────────────────
#  Normalisation des features numériques
# ─────────────────────────────────────────
COLONNES_NUM = ["age", "poids_kg", "taille_cm", "imc", "seances_semaine"]

def normaliser(df):
    scaler = StandardScaler()
    df[COLONNES_NUM] = scaler.fit_transform(df[COLONNES_NUM])
    print(f"Normalisé : {COLONNES_NUM}")
    return df, scaler

# ─────────────────────────────────────────
#  Séparation Features / Labels
# ─────────────────────────────────────────
FEATURES = [
    "sexe", "age", "poids_kg", "taille_cm",
    "imc", "imc_categorie", "objectif",
    "niveau", "seances_semaine"
]

TARGETS = {
    "type_programme" : "type_programme",
    "intensite"      : "intensite",
    "split_musculaire": "split_musculaire",
}

def separer(df):
    X = df[FEATURES]
    y = {nom: df[col] for nom, col in TARGETS.items()}
    print(f"\nFeatures  : {list(X.columns)}")
    print(f"Labels    : {list(y.keys())}")
    return X, y

# ─────────────────────────────────────────
#  Train / Test split (80 / 20)
# ─────────────────────────────────────────
def splitter(X, y, test_size=0.2):
    splits = {}
    X_train, X_test = train_test_split(X, test_size=test_size, random_state=42)

    for nom, serie in y.items():
        y_train = serie.loc[X_train.index]
        y_test  = serie.loc[X_test.index]
        splits[nom] = (y_train, y_test)

    print(f"\nSplit 80/20 → Train: {len(X_train)} | Test: {len(X_test)}")
    return X_train, X_test, splits

# ─────────────────────────────────────────
#  Sauvegarde des objets de preprocessing
# ─────────────────────────────────────────
def sauvegarder(encoders, scaler, output_dir="models"):
    os.makedirs(output_dir, exist_ok=True)
    joblib.dump(encoders, f"{output_dir}/encoders.pkl")
    joblib.dump(scaler,   f"{output_dir}/scaler.pkl")
    print(f"\nSauvegardé → {output_dir}/encoders.pkl")
    print(f"Sauvegardé → {output_dir}/scaler.pkl")

# ─────────────────────────────────────────
#  Pipeline complet
# ─────────────────────────────────────────
def run_preprocessing(dataset_path="data/dataset_gym.csv"):
    print("=" * 45)
    print("   PREPROCESSING — SmartBell ML Pipeline")
    print("=" * 45)

    df               = charger_dataset(dataset_path)
    df               = nettoyer(df)
    df, encoders     = encoder(df)
    df, scaler       = normaliser(df)
    X, y             = separer(df)
    X_train, X_test, splits = splitter(X, y)

    sauvegarder(encoders, scaler)

    print("\n✅ Preprocessing terminé !")
    print(f"   X_train shape : {X_train.shape}")
    print(f"   X_test shape  : {X_test.shape}")

    return X_train, X_test, splits, encoders, scaler

if __name__ == "__main__":
    run_preprocessing()