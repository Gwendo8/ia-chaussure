const express = require('express');
const multer = require('multer');
const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');
const { Pool } = require("pg");

const router = express.Router();

const pool = new Pool({
  connectionString: 'postgresql://sae_6x5u_user:grEwajEU74RxZppLNuGZAZXQLEk8z3u1@dpg-ctperna3esus73dh8odg-a.frankfurt-postgres.render.com/sae_6x5u',
  ssl: {
    rejectUnauthorized: false, // Render utilise des connexions SSL
  },
});

// Configuration de multer pour sauvegarder les images temporairement
const upload = multer({ dest: 'uploads/' });

router.post('/predict', upload.single('image'), (req, res) => {
    if (!req.file) {
        return res.status(400).json({ message: 'Aucune image envoyée.' });
    }

    const imagePath = req.file.path; // Chemin temporaire de l'image

    // Exécuter le script Python pour l'analyse
    const pythonProcess = spawn('/Users/gwendolinedardari/Documents/projet-ia-chaussure/app-nico/sae_py_test/server/myenv/bin/python', ['scripts/predict.py', imagePath]);

    let result = '';

    // Capturer la sortie standard (stdout) du script Python
    pythonProcess.stdout.on('data', (data) => {
        console.log("Réponse brute du script Python :", data.toString()); // Debug
        result += data.toString();
    });

    // Capturer les erreurs du script Python
    pythonProcess.stderr.on('data', (data) => {
        console.error(`Erreur Python: ${data.toString()}`);
    });


    pythonProcess.on('close', (code) => {
        if (code !== 0) {
            return res.status(500).json({ message: "Erreur lors de l'exécution du script Python." });
        }

        try {
            const jsonMatches = result.match(/{.*}/gs); 
            if (jsonMatches && jsonMatches.length > 0) {
                result = jsonMatches[jsonMatches.length - 1]; 
                console.log("✅ JSON extrait :", result); 
            } else {
                throw new Error("Aucune réponse JSON trouvée.");
            }
        
            const parsedResult = JSON.parse(result);
        
            res.setHeader('Content-Type', 'application/json; charset=utf-8');  
            res.json({
                message: "Analyse terminée",
                result: parsedResult
            });

                        // Mettre à jour la table `uploads` si un `upload_id` est fourni
                        if (req.body.upload_id) {
                            const category = parsedResult.predictions[0].className;
                            let probability = parsedResult.predictions[0].probability / 100; 
                        
                            console.log("DEBUG SQL - Catégorie :", category);
                            console.log("DEBUG SQL - Probabilité avant insertion :", probability);
                        
                            
                            probability = parseFloat(probability.toFixed(4));


                            // ✅ S'assurer que la probabilité est bien un nombre arrondi correctement
                            
                            probability = parseFloat(probability.toFixed(4));
                            


                            console.log("🔍 DEBUG API - Probabilité corrigée avant insertion :", probability);

                            pool.query(
                                'UPDATE uploads SET category = $1, probability = $2 WHERE id = $3',
                                [category, probability, req.body.upload_id]
                            ).catch(err => console.error("❌ Erreur SQL :", err));

                            
                        
                            pool.query(
                                'UPDATE uploads SET category = $1, probability = $2 WHERE id = $3',
                                [category, probability, req.body.upload_id]
                            ).catch(err => console.error("Erreur SQL :", err));
                        }
                        
                        
                        
                        
            
        
        } catch (e) {
            console.error("❌ Erreur parsing JSON :", e);
            res.status(500).json({ message: "Réponse Python invalide.", raw: result.trim() });
        }
        
    });

});

module.exports = router;