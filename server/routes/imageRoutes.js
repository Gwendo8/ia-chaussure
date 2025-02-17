const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const tf = require('@tensorflow/tfjs-node-gpu');
const mobilenet = require('@tensorflow-models/mobilenet');
const sharp = require('sharp');
const unzipper = require('unzipper');
const { Pool } = require("pg");

const router = express.Router();
router.use('/uploads', express.static(path.join(__dirname, 'uploads')));


// Configuration de la base de données
const pool = new Pool({
    connectionString: 'postgresql://sae_6x5u_user:grEwajEU74RxZppLNuGZAZXQLEk8z3u1@dpg-ctperna3esus73dh8odg-a.frankfurt-postgres.render.com/sae_6x5u',
    ssl: {
        rejectUnauthorized: false, // Render utilise des connexions SSL
    },
});

let baseModel;

// Charger le modèle MobileNet avec optimisation
const loadBaseModel = async () => {
    console.log('Chargement du modèle MobileNet...');
    baseModel = await mobilenet.load({ version: 2, alpha: 0.5 }); // Réduction de la taille du modèle
    console.log('Modèle MobileNet chargé.');
};
loadBaseModel(); // Charger le modèle dès le démarrage

// Configuration de Multer
const uploadMemory = multer({ storage: multer.memoryStorage() });
const uploadDisk = multer({
    storage: multer.diskStorage({
        destination: './uploads/',
        filename: (req, file, cb) => {
            cb(null, file.fieldname + '-' + Date.now() + path.extname(file.originalname));
        },
    }),
});

// Route : Upload image
// Route : Upload image
router.post('/upload', uploadDisk.single('image'), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).send('Aucune image uploadée.');
        }
  
        const fileName = req.file.filename;  // ✅ Stocke uniquement le nom de fichier
        const utilisateur_id = req.body.utilisateur_id;
  
        if (!utilisateur_id) {
            return res.status(400).json({ message: 'Utilisateur non spécifié.' });
        }
  
        // Vérifier si l'utilisateur existe
        const userCheck = await pool.query('SELECT * FROM "User" WHERE "IDUser" = $1', [utilisateur_id]);
        if (userCheck.rows.length === 0) {
            return res.status(404).json({ message: 'Utilisateur non trouvé.' });
        }
  
        // Insérer l'image en base de données
        const result = await pool.query(
            'INSERT INTO uploads (path, utilisateur_id, date_upload) VALUES ($1, $2, NOW()) RETURNING *',
            [fileName, utilisateur_id]  // ✅ Stocke uniquement le nom de fichier en base
        );
  
        res.status(201).json({ message: 'Image uploadée avec succès', image: result.rows[0] });
    } catch (error) {
        console.error('❌ Erreur lors de l\'upload :', error);
        res.status(500).json({ error: 'Erreur interne.' });
    }
  });

class ReduceLROnPlateau extends tf.Callback {
    constructor() {
        super();
        this.previousLoss = Infinity;
    }

    onEpochEnd(epoch, logs) {
        if (epoch > 5 && logs.loss > this.previousLoss * 0.99) {
            const newLR = this.model.optimizer.learningRate * 0.5;
            this.model.optimizer.learningRate = newLR;
            console.log(`📉 Réduction du learning rate à : ${newLR}`);
        }
        this.previousLoss = logs.loss;
    }

    setParams(params) {} // Évite l'erreur callback.setParams
}
const validateImage = async (imagePath) => {
    try {
        await sharp(imagePath).metadata(); // Vérifie si l'image est valide
        return true;
    } catch (error) {
        console.warn(`⚠️ Fichier corrompu ignoré : ${imagePath}`);
        return false;
    }
};


module.exports = router;