
import json
import numpy as np




import os
import sys

# ✅ Rediriger stderr et stdout pour supprimer tous les logs TensorFlow
sys.stdout = open(os.devnull, 'w')  # Cache stdout
sys.stderr = open(os.devnull, 'w')  # Cache stderr

import tensorflow as tf
from tensorflow import keras
import logging

# ✅ Désactiver complètement les logs internes de TensorFlow
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
tf.get_logger().setLevel(logging.ERROR)
tf.autograph.set_verbosity(0)

# ✅ Réactiver stdout pour afficher uniquement le JSON
sys.stdout = sys.__stdout__


# ✅ Supprime les logs TensorFlow complètement
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
tf.get_logger().setLevel(logging.ERROR)
tf.autograph.set_verbosity(0)


# ✅ Ajouter ceci pour forcer l'UTF-8
sys.stdout.reconfigure(encoding='utf-8')


# --- Définition des dimensions ---
image_width, image_height = 180, 180

# --- Chargement de la liste des classes ---
classes_path = os.path.join(os.path.dirname(__file__), "../custom-model/classes.json")
if not os.path.exists(classes_path):
    sys.exit(json.dumps({"error": "Le fichier classes.json est introuvable."}))

with open(classes_path, "r") as f:
    class_names = json.load(f)
num_classes = len(class_names)

# --- Définition de la fonction sobel_edges pour la désérialisation ---
@keras.utils.register_keras_serializable(package="Custom", name="sobel_edges")
def sobel_edges(x):
    gray = tf.image.rgb_to_grayscale(x)
    sobel = tf.image.sobel_edges(gray)
    return tf.sqrt(tf.reduce_sum(tf.square(sobel), axis=-1))

custom_objects = {"sobel_edges": sobel_edges}

# --- Chargement du modèle entraîné ---
trained_model_path = os.path.join(os.path.dirname(__file__), "../custom-model/trainedshoes.keras")
if not os.path.exists(trained_model_path):
    sys.exit(json.dumps({"error": "Le modèle entraîné est introuvable."}))

model = keras.models.load_model(trained_model_path, custom_objects=custom_objects)

# --- Vérifier l'argument de l'image ---
if len(sys.argv) < 2:
    sys.exit(json.dumps({"error": "Spécifiez une image à analyser : python predict.py path_to_image"}))

image_path = sys.argv[1]
if not os.path.exists(image_path):
    sys.exit(json.dumps({"error": f"L'image spécifiée {image_path} n'existe pas."}))

# --- Chargement et prétraitement de l'image ---
try:
    img = keras.preprocessing.image.load_img(image_path, target_size=(image_height, image_width))
    img_array = keras.preprocessing.image.img_to_array(img)
    img_array = np.expand_dims(img_array, axis=0) / 255.0
except Exception as e:
    sys.exit(json.dumps({"error": f"Erreur lors du chargement de l'image : {e}"}))

# --- Prédiction ---
try:
    predictions = model.predict(img_array)[0]  # Récupérer le premier résultat
    predicted_index = np.argmax(predictions)
    predicted_label = class_names[predicted_index]
    confidence = float(predictions[predicted_index]) * 100  # Convertir en pourcentage

    # ✅ Sortie JSON propre
    result = {
        "message": "Analyse terminée",
        "predictions": [
            {"className": predicted_label, "probability": confidence}
        ]
    }
    print(json.dumps(result, ensure_ascii=False))
except Exception as e:
    sys.exit(json.dumps({"error": f"Erreur lors de la prédiction : {e}"}))
