import os
import joblib
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, classification_report

from preprocessor import run_preprocessing

# ─────────────────────────────────────────
#  Configuration
# ─────────────────────────────────────────
MODELS_DIR = "models"
MODEL_FILES = {
    "type_programme"  : "model_type_programme.pkl",
    "intensite"       : "model_intensite.pkl",
    "split_musculaire": "model_split_musculaire.pkl",
}


def train_and_evaluate(X_train, X_test, splits):
    os.makedirs(MODELS_DIR, exist_ok=True)
    trained = {}

    for target, filename in MODEL_FILES.items():
        y_train, y_test = splits[target]

        print(f"\n{'=' * 50}")
        print(f"  Modèle : {target}")
        print(f"{'=' * 50}")

        clf = RandomForestClassifier(n_estimators=100, random_state=42)
        clf.fit(X_train, y_train)

        y_pred = clf.predict(X_test)
        acc = accuracy_score(y_test, y_pred)

        print(f"Accuracy : {acc:.4f} ({acc * 100:.2f} %)")
        print(classification_report(y_test, y_pred))

        path = os.path.join(MODELS_DIR, filename)
        joblib.dump(clf, path)
        print(f"Sauvegardé → {path}")

        trained[target] = clf

    return trained


if __name__ == "__main__":
    print("=" * 50)
    print("   TRAINING — SmartBell ML Pipeline")
    print("=" * 50)

    X_train, X_test, splits, encoders, scaler = run_preprocessing()

    trained_models = train_and_evaluate(X_train, X_test, splits)

    print(f"\n✅ Entraînement terminé ! {len(trained_models)} modèles sauvegardés dans '{MODELS_DIR}/'")
