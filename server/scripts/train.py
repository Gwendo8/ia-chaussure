import os
import sys
import json
import tensorflow as tf
from tensorflow import keras
import matplotlib.pyplot as plt
import numpy as np
from sklearn.metrics import confusion_matrix, ConfusionMatrixDisplay
from tensorflow.keras.utils import register_keras_serializable  # Utilisation de ce décorateur

# Lecture des paramètres (via Node.js ou en ligne de commande)
params = json.loads(sys.argv[1])
dataset_path = params.get("dataset_path", "./train-data")
epochs = params.get("epochs", 10)

# Définition des constantes
BATCH_SIZE = 32
image_width, image_height = 180, 180
IMG_SHAPE = (image_height, image_width, 3)

# Définition de la data augmentation
data_augmentation = keras.Sequential([
    keras.layers.RandomFlip("horizontal", name="random_flip"),
    keras.layers.RandomRotation(0.1, name="random_rotation"),
    keras.layers.RandomZoom(0.1, name="random_zoom"),
], name="data_augmentation")

# Chargement des datasets d'entraînement et de validation
train_dataset = keras.utils.image_dataset_from_directory(
    os.path.join(dataset_path, "Train"),
    shuffle=True,
    batch_size=BATCH_SIZE,
    image_size=(image_height, image_width)
)
class_names = train_dataset.class_names  # liste des classes détectées

validation_dataset = keras.utils.image_dataset_from_directory(
    os.path.join(dataset_path, "Valid"),
    shuffle=True,
    batch_size=BATCH_SIZE,
    image_size=(image_height, image_width)
)

# Optimisation du chargement
AUTOTUNE = tf.data.AUTOTUNE
train_dataset = train_dataset.cache().shuffle(1000).prefetch(buffer_size=AUTOTUNE)
validation_dataset = validation_dataset.cache().prefetch(buffer_size=AUTOTUNE)

# --- Définition d'une fonction pour extraire les bords (Sobel) ---
@register_keras_serializable()
def sobel_edges(x):
    # Convertir l'image en niveaux de gris
    gray = tf.image.rgb_to_grayscale(x)
    # Calculer les bords via l'opérateur Sobel (sortie: [batch, height, width, 1, 2])
    sobel = tf.image.sobel_edges(gray)
    # Calculer la magnitude des bords : sqrt(sum(sobel^2, axis=-1))
    sobel_magnitude = tf.sqrt(tf.reduce_sum(tf.square(sobel), axis=-1))
    return sobel_magnitude

# --- Construction du modèle avec l'API fonctionnelle ---
inputs = keras.Input(shape=(image_height, image_width, 3), name="input_layer")
# Appliquer la data augmentation
x_aug = data_augmentation(inputs)
# Normalisation
x_rescaled = keras.layers.Rescaling(1./255, name="rescaling")(x_aug)

# Branche principale : extraction de features via MobileNetV2
base_model = tf.keras.applications.MobileNetV2(
    input_shape=IMG_SHAPE,
    include_top=False,
    weights="imagenet"
)
# Pour la phase initiale, on gèle entièrement le base_model
base_model.trainable = False
# Attribuer un nom pour faciliter la récupération (ex. "mobilenetv2")
base_model._name = "mobilenetv2"
base_features = base_model(x_rescaled, training=False)
base_features = keras.layers.GlobalAveragePooling2D(name="global_avg_pool")(base_features)

# Branche supplémentaire : extraction d'edges via filtre Sobel
edges = keras.layers.Lambda(sobel_edges, name="sobel_edges")(x_rescaled)
# Traitement optionnel : une petite CNN pour traiter les bords
edge_features = keras.layers.Conv2D(16, (3,3), activation='relu', padding='same', name="edge_conv")(edges)
edge_features = keras.layers.GlobalAveragePooling2D(name="edge_gap")(edge_features)

# Concaténer les features des deux branches
concatenated = keras.layers.Concatenate(name="concat_features")([base_features, edge_features])

# Couches de classification
x = keras.layers.Dense(128,
                       activation="relu",
                       kernel_regularizer=keras.regularizers.l2(0.001),
                       name="dense_128")(concatenated)
x = keras.layers.Dropout(0.5, name="dropout")(x)
outputs = keras.layers.Dense(len(class_names),
                             activation="softmax",
                             name="predictions")(x)

model = keras.Model(inputs, outputs, name="training_model")
model.summary()

# --- Définition des poids de classes pour la fonction de perte ---
# Par exemple, on suppose que "Ballet Flat" (indice 0) est la classe la plus difficile
class_weight = {0: 2.0, 1: 1.0, 2: 1.0, 3: 1.0, 4: 1.0}

# --- Compilation du modèle (phase initiale) ---
optimizer = keras.optimizers.Adam(learning_rate=1e-4)
model.compile(
    optimizer=optimizer,
    loss=keras.losses.SparseCategoricalCrossentropy(from_logits=False),
    metrics=["accuracy"]
)

# Callbacks : EarlyStopping et ModelCheckpoint
callbacks = [
    keras.callbacks.EarlyStopping(monitor="val_loss", patience=5, restore_best_weights=True),
    keras.callbacks.ModelCheckpoint(filepath="./custom-model/best_model.keras",
                                 monitor="val_loss",
                                 save_best_only=True)
]

print("Début de l'entraînement du modèle (phase initiale)...")
history = model.fit(train_dataset,
                    validation_data=validation_dataset,
                    epochs=epochs,
                    callbacks=callbacks,
                    class_weight=class_weight)

# Sauvegarde du modèle entraîné complet
model_dir = "./custom-model"
if not os.path.exists(model_dir):
    os.makedirs(model_dir)
model_save_path = os.path.join(model_dir, "trainedshoes.keras")
model.save(model_save_path, save_format="tf")
print(f"Modèle entraîné sauvegardé dans {model_save_path}")

# Sauvegarde de la liste des classes dans un fichier JSON
classes_path = os.path.join(model_dir, "classes.json")
with open(classes_path, "w") as f:
    json.dump(class_names, f)
print(f"Liste des classes sauvegardée dans {classes_path}")

# Évaluation globale sur le set de validation
val_loss, val_accuracy = model.evaluate(validation_dataset)
print(f"Précision globale sur validation : {val_accuracy*100:.2f}%")

# Calcul et affichage de la matrice de confusion
all_true = []
all_pred = []
for images, labels in validation_dataset:
    preds = model.predict(images)
    all_true.extend(labels.numpy())
    all_pred.extend(np.argmax(preds, axis=1))
cm = confusion_matrix(all_true, all_pred)
print("Matrice de confusion :")
print(cm)
disp = ConfusionMatrixDisplay(confusion_matrix=cm, display_labels=class_names)
disp.plot(cmap=plt.cm.Blues)
plt.title("Matrice de confusion sur le set de validation")
plt.show()

# Affichage des courbes d'entraînement
acc_history = history.history['accuracy']
val_acc_history = history.history['val_accuracy']
loss_history = history.history['loss']
val_loss_history = history.history['val_loss']
epochs_range = range(len(acc_history))

plt.figure(figsize=(12,6))
plt.subplot(1,2,1)
plt.plot(epochs_range, acc_history, label="Accuracy")
plt.plot(epochs_range, val_acc_history, label="Val Accuracy")
plt.legend(loc="lower right")
plt.title("Training and Validation Accuracy")
plt.subplot(1,2,2)
plt.plot(epochs_range, loss_history, label="Loss")
plt.plot(epochs_range, val_loss_history, label="Val Loss")
plt.legend(loc="upper right")
plt.title("Training and Validation Loss")
plt.show()

# --- Phase de fine-tuning ---
print("Début du fine-tuning du modèle...")
# Débloquer les 20 dernières couches du base_model
base_model.trainable = True
for layer in base_model.layers[:-20]:
    layer.trainable = False
fine_tune_lr = 1e-5
optimizer_finetune = keras.optimizers.Adam(learning_rate=fine_tune_lr)
model.compile(optimizer=optimizer_finetune,
              loss=keras.losses.SparseCategoricalCrossentropy(from_logits=False),
              metrics=["accuracy"])
fine_tune_epochs = 5
history_fine = model.fit(train_dataset,
                         validation_data=validation_dataset,
                         epochs=fine_tune_epochs,
                         callbacks=callbacks,
                         class_weight=class_weight)
model_save_path_ft = os.path.join(model_dir, "trainedshoes_finetuned.keras")
model.save(model_save_path, save_format="tf")
print("Modèle fine-tuné sauvegardé dans {model_save_path_ft}")

sys.exit(0)