const express = require("express");
const { Pool } = require("pg");
const cors = require("cors");
const bodyParser = require("body-parser");
const bcrypt = require("bcrypt");
const path = require("path");

const multer = require("multer");
const fs = require("fs");
const tf = require("@tensorflow/tfjs-node-gpu");
const mobilenet = require("@tensorflow-models/mobilenet");
const sharp = require("sharp");
const { spawn } = require('child_process');

const app = express();

app.use(cors());
app.use(express.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));


const pool = new Pool({
  host: "localhost",
  user: "postgres",
  password: "azerty",
  database: "SAE_Detection",
  port: 5432,
});

// const pool = new Pool({
//   connectionString: 'postgresql://sae_6x5u_user:grEwajEU74RxZppLNuGZAZXQLEk8z3u1@dpg-ctperna3esus73dh8odg-a.frankfurt-postgres.render.com/sae_6x5u',
//   ssl: {
//     rejectUnauthorized: false, // Render utilise des connexions SSL
//   },
// });

pool
  .connect()
  .then(() => console.log("Connecté à la base de données PostgreSQL"))
  .catch((err) => console.error("Erreur de connexion", err.stack));

const imageRoutes = require("./routes/imageRoutes"); 
const predictRoutes = require('./routes/predictRoutes');
app.use("/", imageRoutes);
app.use("/", predictRoutes); 




//ROUTE POUR L'INSCRIPTION UTILISATEURS
app.post("/register", async (req, res) => {
  const { LastName, FirstName, Email, Password, ConfirmPassword } = req.body;

  if (!LastName || !FirstName || !Email || !Password || !ConfirmPassword) {
    return res.status(400).json({ message: "Tous les champs sont requis." });
  }

  if (Password !== ConfirmPassword) {
    return res
      .status(400)
      .json({ message: "Les mots de passe ne correspondent pas." });
  }

  try {
    const emailCheckQuery = 'SELECT * FROM "User" WHERE "Email" = $1';
    const emailCheckResult = await pool.query(emailCheckQuery, [Email]);
    if (emailCheckResult.rows.length > 0) {
      return res.status(400).json({ message: "Email déjà utilisé." });
    }

    const hashedPassword = await bcrypt.hash(Password, 10);

    const insertUserQuery = `
            INSERT INTO "User" ("LastName", "FirstName", "Email", "Password", "IDRole")
            VALUES ($1, $2, $3, $4, $5) RETURNING "IDUser";
        `;
    const newUser = await pool.query(insertUserQuery, [
      LastName,
      FirstName,
      Email,
      hashedPassword,
      1,
    ]);

    res.status(201).json({
      message: "Utilisateur créé avec succès.",
      userId: newUser.rows[0].IDUser,
    });
  } catch (error) {
    console.error("Erreur lors de l'inscription :", error);
    res.status(500).json({ message: "Erreur lors de l'inscription." });
  }
});

// ROUTE POUR LA CONNEXION UTILISATEURS
app.post("/login", async (req, res) => {
  const { email, password } = req.body;

  try {
    const result = await pool.query(
      `
      SELECT u.*, r."Name" AS rolename
      FROM "User" u
      JOIN "Role" r ON u."IDRole" = r."IDRole"
      WHERE u."Email" = $1
    `,
      [email]
    );

    const user = result.rows[0];

    if (!user) {
      return res.status(404).json({ message: "Utilisateur non trouvé" });
    }

    const isMatch = await bcrypt.compare(password, user.Password);
    if (!isMatch) {
      return res.status(401).json({ message: "Mot de passe incorrect" });
    }

    if (user.IDUser) {
      const response = {
        message: "Connexion réussie",
        IDUser: user.IDUser,
        firstName: user.FirstName,
        lastName: user.LastName,
        email: user.Email,
        roleName: user.rolename,
      };

      console.log("Réponse serveur : ", response);
      res.json(response);
    } else {
      res.status(500).json({ message: "Erreur : IDUser non disponible" });
    }
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Erreur serveur" });
  }
});

// Fonction pour générer un mot de passe aléatoire (6 lettres + 1 chiffre)
function generateRandomPassword() {
  const letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
  const digits = "0123456789";

  let password = "";
  for (let i = 0; i < 6; i++) {
    password += letters.charAt(Math.floor(Math.random() * letters.length));
  }
  password += digits.charAt(Math.floor(Math.random() * digits.length));

  return password;
}

const updateUserPassword = async (email, newPassword) => {
  try {
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    const query =
      'UPDATE "User" SET "Password" = $1 WHERE "Email" = $2 RETURNING "IDUser"';
    const values = [hashedPassword, email];

    const res = await pool.query(query, values);

    if (res.rows.length > 0) {
      console.log(
        "Mot de passe mis à jour pour l'utilisateur avec ID:",
        res.rows[0].IDUser
      );
    } else {
      console.log("Aucun utilisateur trouvé avec cet e-mail");
    }
  } catch (err) {
    console.error("Erreur lors de la mise à jour du mot de passe:", err.stack);
  }
};

const sgMail = require("@sendgrid/mail");




const sendPasswordResetEmail = async (email, newPassword) => {
  const msg = {
    to: email,
    from: "gwendolinedardari7@gmail.com",
    subject: "Réinitialisation de votre mot de passe",
    text: `Bonjour, voici votre nouveau mot de passe : ${newPassword}`,
  };

  try {
    await sgMail.send(msg);
    console.log("E-mail envoyé à :", email);
  } catch (error) {
    console.error("Erreur d'envoi de l'e-mail:", error);
  }
};

// Fonction pour vérifier si l'email existe dans la base de données
const checkIfEmailExists = async (email) => {
  try {
    const query = 'SELECT * FROM "User" WHERE "Email" = $1';
    const result = await pool.query(query, [email]);
    return result.rows.length > 0;
  } catch (err) {
    console.error("Erreur lors de la vérification de l'email:", err.stack);
    return false;
  }
};

// Route mot de passe oublié
app.post("/forgot-password", async (req, res) => {
  const { email } = req.body;

  if (!email) {
    return res.status(400).json({ error: "L'email est requis" });
  }

  const emailExists = await checkIfEmailExists(email);

  if (!emailExists) {
    return res
      .status(404)
      .json({ error: "Aucun utilisateur trouvé avec cet e-mail." });
  }

  const newPassword = generateRandomPassword();

  await updateUserPassword(email, newPassword);
  await sendPasswordResetEmail(email, newPassword);

  res
    .status(200)
    .json({
      message: "Un e-mail avec votre nouveau mot de passe a été envoyé.",
    });
});

//ROUTE POUR RECUPERER LES DONNES POUR LES ADMINS
app.get("/api/users", async (req, res) => {
  try {
    const result = await pool.query(`
       SELECT "User"."IDUser", "User"."LastName", "User"."FirstName", "User"."Email", "User"."Password","Role"."Name" as "roleName"
      FROM "User"
      JOIN "Role" ON "User"."IDRole" = "Role"."IDRole";
    `);

    console.log(result.rows);
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).send("Server error");
  }
});

//ROUTE POUR AJOUTER UN UTILISATEUR POUR LES ADMINS
app.post("/api/addusers", async (req, res) => {
  const { lastName, firstName, email, password, idRole } = req.body;

  if (!lastName || !firstName || !email || !password || !idRole) {
    return res.status(400).send("Tous les champs sont obligatoires.");
  }

  try {
    const hashedPassword = await bcrypt.hash(password, 10);

    const result = await pool.query(
      `INSERT INTO public."User"(
        "LastName", "FirstName", "Email", "Password", "IDRole"
      ) VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [lastName, firstName, email, hashedPassword, idRole]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).send("Erreur serveur");
  }
});

//ROUTE POUR MODIFIER LES DONNES DUN UTILISATEUR POUR LES ADMINS
app.get("/api/roles", async (req, res) => {
  try {
    const result = await pool.query('SELECT "IDRole", "Name" FROM "Role"');
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).send("Erreur serveur");
  }
});

// ROUTE POUR MODIFIER LES DONNEES D'UN UTILISATEUR AVEC HACHAGE DU MOT DE PASSE
app.put("/api/users/:id", async (req, res) => {
  const { id } = req.params;
  const { last_name, first_name, email, password, role } = req.body;

  console.log("Received update data:", req.body);

  try {
    const roleResult = await pool.query(
      `SELECT "IDRole" FROM "Role" WHERE "Name" = $1`,
      [role]
    );
    if (roleResult.rows.length === 0) {
      console.error(`Role "${role}" not found`);
      return res.status(400).send("Role not found");
    }
    const role_id = roleResult.rows[0].IDRole;
    console.log("Fetched role_id:", role_id);

    let hashedPassword = password;
    if (password && !password.startsWith("$2b$")) {
      hashedPassword = await bcrypt.hash(password, 10);
    }

    const result = await pool.query(
      `
        UPDATE "User"
        SET "LastName" = $1, "FirstName" = $2, "Email" = $3, "Password" = $4, "IDRole" = $5
        WHERE "User"."IDUser" = $6
        RETURNING "User"."IDUser", "User"."LastName", "User"."FirstName", "User"."Email", "User"."IDRole";
      `,
      [last_name, first_name, email, hashedPassword, role_id, id]
    );

    console.log("Update result:", result.rows[0]);
    res.json(result.rows[0]);
  } catch (err) {
    console.error("Error during user update:", err);
    res.status(500).send("Server error");
  }
});

//ROUTE POUR SUPPRIMER UN UTILISATEUR POUR LES ADMINS
app.delete("/api/users/:id", async (req, res) => {
  const { id } = req.params;
  try {
    // Supprimer les enregistrements liés dans la table Friends
    await pool.query(`DELETE FROM "Friends" WHERE "FriendID" = $1 OR "UserID" = $1`, [id]);

    // Supprimer les fichiers associés dans la table uploads
    await pool.query(`DELETE FROM "uploads" WHERE "utilisateur_id" = $1`, [id]);

    // Supprimer l'utilisateur
    const result = await pool.query(
      `DELETE FROM "User" WHERE "IDUser" = $1 RETURNING "IDUser"`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Utilisateur non trouvé" });
    }

    res.status(200).json({ message: "Utilisateur supprimé avec succès" });
  } catch (err) {
    console.error(err);
    res.status(500).send("Erreur serveur");
  }
});

// Servir les fichiers du dossier "uploads"
app.use("/uploads", express.static(path.join(__dirname, "uploads")));

app.get("/api/historique", async (req, res) => {
  const userId = req.query.userId;

  try {
    const query = userId
    ? 'SELECT uploads.id, uploads.path, uploads.date_upload, uploads.name, uploads.category, uploads.probability FROM uploads WHERE uploads."utilisateur_id" = $1'
    : "SELECT uploads.id, uploads.path, uploads.date_upload, uploads.name, uploads.category, uploads.probability FROM uploads";
  

    const params = userId ? [userId] : [];
    const result = await pool.query(query, params);

    const historiqueData = result.rows.map((row) => ({
      ...row,
      path: `http://192.0.0.2:8000/uploads/${row.path.replace(/^uploads[\\/]/, "")}`,
      category: row.category || 'Non catégorisé',
      date_upload_iso: row.date_upload.toISOString(),
      date_upload: new Date(row.date_upload)
        .toLocaleString("fr-FR", {
          day: "numeric",
          month: "long",
          year: "numeric",
          hour: "2-digit",
          minute: "2-digit",
        })
        .replace(",", " à"),
    }));

    res.json(historiqueData);
  } catch (err) {
    console.error(err);
    res.status(500).send("Erreur serveur");
  }
});

app.delete("/api/historique/:id", async (req, res) => {
  const { id } = req.params;

  if (!id || isNaN(id)) {
    return res.status(400).json({ message: "ID invalide ou manquant" });
  }

  try {
    const query = 'DELETE FROM uploads WHERE id = $1 RETURNING *';
    const result = await pool.query(query, [id]);

    if (result.rowCount === 0) {
      return res.status(404).json({ message: "Élément introuvable" });
    }

    res.json({ message: "Élément supprimé avec succès", data: result.rows[0] });
  } catch (error) {
    console.error("Erreur lors de la suppression :", error);
    res.status(500).json({ message: "Erreur serveur" });
  }
});

app.put("/user/:id", async (req, res) => {
  const userId = req.params.id;
  const { firstName, lastName, email, password, confirmPassword } = req.body;

  try {
    const userResult = await pool.query(
      'SELECT * FROM public."User" WHERE "IDUser" = $1',
      [userId]
    );
    if (userResult.rows.length === 0) {
      return res.status(404).json({ message: "Utilisateur non trouvé" });
    }
    const existingUser = userResult.rows[0];

    const updatedFirstName = firstName || existingUser.FirstName;
    const updatedLastName = lastName || existingUser.LastName;
    const updatedEmail = email || existingUser.Email;

    let updatedPassword = existingUser.Password;
    if (password && confirmPassword) {
      if (password !== confirmPassword) {
        return res
          .status(400)
          .json({ message: "Les mots de passe ne correspondent pas." });
      }
      updatedPassword = await bcrypt.hash(password, 10);
    }
    await pool.query(
      'UPDATE public."User" SET "FirstName" = $1, "LastName" = $2, "Email" = $3, "Password" = $4 WHERE "IDUser" = $5',
      [updatedFirstName, updatedLastName, updatedEmail, updatedPassword, userId]
    );

    res.json({ message: "Informations mises à jour avec succès" });
  } catch (error) {
    console.error(
      "Erreur lors de la mise à jour des informations utilisateur:",
      error
    );
    res.status(500).json({ message: "Erreur serveur" });
  }
});


// Gestion des amis

app.post('/api/friends', async (req, res) => {
  const { userId, friendId } = req.body;

  try {
    await pool.query(
      'INSERT INTO "Friends" ("UserID", "FriendID") VALUES ($1, $2)',
      [userId, friendId]
    );
    res.status(201).json({ message: 'Ami ajouté avec succès' });
  } catch (error) {
    console.error('Erreur lors de l\'ajout d\'un ami :', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

app.get('/api/friends/:userId', async (req, res) => {
  const userId = req.params.userId;

  try {
    // Requête SQL corrigée pour joindre les informations des amis
    const query = `
      SELECT
        f."FriendID",
        u."FirstName",
        u."LastName",
        u."Email"
      FROM
        "Friends" f
      INNER JOIN
        "User" u ON u."IDUser" = f."FriendID" -- Correction : utilisation de "IDUser" pour joindre les tables
      WHERE
        f."UserID" = $1
    `;
    const result = await pool.query(query, [userId]);

    if (result.rows.length > 0) {
      res.status(200).json(result.rows); // Retourne les détails des amis
    } else {
      res.status(200).json([]); // Retourne un tableau vide si aucun ami n'est trouvé
    }
  } catch (error) {
    console.error('Erreur lors de la récupération des amis :', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

app.delete('/api/friends', async (req, res) => {
  const { userId, friendId } = req.body;

  if (!userId || !friendId) {
    return res.status(400).json({ error: 'Les champs userId et friendId sont requis.' });
  }

  try {
    const query = `
      DELETE FROM "Friends"
      WHERE "UserID" = $1 AND "FriendID" = $2
    `;
    const result = await pool.query(query, [userId, friendId]);

    if (result.rowCount > 0) {
      res.status(200).json({ message: 'Ami supprimé avec succès' });
    } else {
      res.status(404).json({ error: 'Aucun ami trouvé pour cette relation.' });
    }
  } catch (error) {
    console.error('Erreur lors de la suppression de l\'ami :', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

app.get('/api/uploads/:friendId', async (req, res) => {
  const { friendId } = req.params;

  try {
    // Récupérer les uploads pour un ami donné
    const result = await pool.query(
      'SELECT * FROM uploads WHERE utilisateur_id = $1',
      [friendId]
    );

    if (result.rows.length > 0) {
      res.status(200).json(result.rows);
    } else {
      res.status(404).json({ error: 'Aucun upload trouvé pour cet utilisateur.' });
    }
  } catch (error) {
    console.error('Erreur lors de la récupération des uploads :', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

app.post('/train-python', (req, res) => {
  const datasetPath = req.body.dataset_path || "./train-data";
  const epochs = req.body.epochs || 10;

  const scriptPath = path.join(__dirname, './scripts/train.py');
  const params = JSON.stringify({ dataset_path: datasetPath, epochs });

  console.log("🚀 Lancement de l'entraînement en Python...");

  const pythonProcess = spawn('python', [scriptPath, params]);

  pythonProcess.stdout.on('data', (data) => {
      console.log(`📌 Python: ${data}`);
  });

  pythonProcess.stderr.on('data', (data) => {
      console.error(`❌ Erreur Python: ${data}`);
  });

  pythonProcess.on('close', (code) => {
      if (code === 0) {
          console.log("✅ Entraînement terminé avec succès !");
          res.status(200).send("Modèles entraînés avec succès !");
      } else {
          res.status(500).send(`Erreur durant l'entraînement, code: ${code}`);
      }
  });
});


const PORT = 8000;

app.listen(PORT, "0.0.0.0", () => {
  console.log(`Serveur démarré sur http://192.0.0.2:${PORT}`); 
});