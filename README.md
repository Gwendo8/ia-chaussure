## Description de l'application
Cette application mobile utilise un modèle d'apprentissage automatique pour reconnaître et classifier différents types de chaussures. Elle permet également à l'utilisateur d'effectuer un entraînement personnalisé pour améliorer les capacités du modèle. L'application est destinée à tout type de personne (que ce soient des développeurs ou des utilisateurs finaux) grâce à une interface conviviale.

## Fonctionnalités principales

### 1. **Acquisition d'images**
- Capture d'images en temps réel avec la caméra du téléphone.
- Importation d'images depuis la galerie du téléphone.

### 2. **Reconnaissance d'objets**
- Utilisation du modèle MobileNet pour détecter et classifier les chaussures.
- Affichage des résultats de classification avec une probabilité pour chaque catégorie. La catégorie ayant la plus forte probabilité est celle de la chaussure.

### 3. **Base de données et historique**
- Gestion des utilisateurs et des administrateurs
- Enregistrement des images analysées et de leurs résultats dans la base de données.
- Consultation d'un historique des analyses avec des détails tels que la catégorie, la probabilité, et la date d'analyse.

### 4. **Entraînement personnalisé**
- Entraînement du modèle avec des images personnalisées fournies par l'utilisateur (une seule image ou un dataset compressé en `.zip`).
- Mise à jour du modèle en fonction des nouvelles données.

### 5. **Gestion utilisateur (disponible que pour les administrateurs) **
- Ajout d'un utilisateur
- Modification d'un utilisateur
- Suppression d'un utilisateur

### 6. **Gestion profil**
- L'utilisateur peut modifier plusieurs des ses informations (nom, prénom, mot de passe, email)
     
### 7. **Gestion des chaussures**
- Historique des chaussures analysé par l'ia (nom, image, date)
- Filtrage de l'historique (ordre alphabétique et date)
- Suppression d'une ou plusieurs chaussures dans l'historique

### 8. **Système d'amis**
- Ajout d'amis au sein de l'application.
- Visualisation des historiques des amis.
  
### 9. **Mot de passe oublié**
- Envoie d'un nouveau mot de passe temporaire par mail lorsqu'un utilisateur à oublié le sien

### 10. **Interface utilisateur (UI)**
- Interface simple et intuitive.
- Fonctionnalités accessibles via un menu latéral (entraînement, analyse, historique, etc.).


## Installation et configuration

### Prérequis
1. **Systèmes et outils** :
   - Python 3.10.11
   - Visual Studio 2022 avec l'option *Development SDK for Desktop C++*.
   - Node.js (via `nvm`) :
     ```
     nvm install 16
     nvm use 16
     ```
     2. **Dépendances Node.js** :
   - La commande suivante installe toutes les dépendances nécessaires, y compris TensorFlow et MobileNet :
     ```
     npm install
     ```
     - **Note importante** : Si après cette commande certaines dépendances liées à TensorFlow sont absentes (affichage d'erreurs), exécutez les commandes suivantes pour les installer manuellement :
    ```
     npm install @tensorflow/tfjs-node-gpu
     npm install @tensorflow-models/mobilenet
     npm install @tensorflow/tfjs-core @tensorflow/tfjs-layers
     ```
         ```
     - **Note importante** : Si après l'installation du dossier node_modules (npm install), une erreur s'affiche concernant le module bcrypt:
    ```
     npm install bcrypt
     ```

3. **Installation de Sharp** :
   - Changez la version de Node.js à la version 18 ou plus récente avant d'installer `sharp` :
     ```
     nvm install 18
     nvm use 18
     ```

        - Installez ensuite la dépendance `sharp` :
     ```
     npm install sharp
     ```

4. **Dépendances Flutter** :
   - Flutter SDK installé sur votre machine.
   - Bibliothèques utilisées :
     ```bash
     flutter pub add http
     flutter pub add file_picker
     flutter pub add image
     flutter pub add image_picker
     flutter pub add permission_handler
     flutter pub add google_fonts
     ```

## Utilisation

### 1. **Démarrage du backend**
- Lancez le serveur backend pour gérer les requêtes d'entraînement, d'analyse et de gestion des données :
  ```
  node server.js
  ### 2. **Démarrage de l'application cliente Flutter**
- Lancez l'application sur votre téléphone ou un émulateur :
  ```
  flutter run
  ```


  ## Notes importantes pour l'utilisation
### Configuration de l'adresse IP pour un réseau local
Si vous exécutez l'application sur un téléphone connecté au même réseau que votre backend local, vous devez modifier l'adresse IP dans les fichiers frontend ( lib/pages) pour pointer vers l'adresse de votre PC .
```
const String apiBaseUrl = 'http://192.168.x.x:8000';
```
## Information supplémentaire

Pour l’envoi d’e-mails, ajoutez cette ligne dans le fichier index.js, situé dans le dossier server, à la ligne 181 :
sgMail.setApiKey("votre clé API SendGrid");
