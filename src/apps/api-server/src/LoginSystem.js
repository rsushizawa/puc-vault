const express = require('express');
const cors = require('cors');
const fs = require('fs');
const { z, toLowerCase } = require('zod');
const bcrypt = require('bcryptjs');
const { tr } = require('zod/locales');
const { error } = require('console');

const saltRounds = 10;

const app = express();
app.use(cors());
app.use(express.json());

const loginDB = './loginDB.json';// bd provisorio

if (!fs.existsSync(loginDB)) {
  fs.writeFileSync(loginDB, JSON.stringify([]));
}

function readDB() {
  try {
    const data = fs.readFileSync(loginDB, 'utf-8');

    if (!data || data.trim() === '') {
      return [];
    }
    return JSON.parse(data);
  } catch (error) {
    console.log("Warning: failed on reading JSON. Returning blank list.", error.message);
    return [];
  }
}

function saveDB(loginElmnt) {
  fs.writeFileSync(loginDB, JSON.stringify(loginElmnt, null, 2));
}

const loginSchema = z.object({
  email: z.string().trim().toLowerCase().email("Invalid email").max(50),
  name: z.string().min(3, "Nome(mínimo 3 caracteres)").max(75),
  username: z.string().min(3, "Username (mínimo 3 caracteres)").max(20),
  password: z.string().min(8, "Senha (mínimo 8 caracteres)")
});

app.get('/sign-in', (req, res) => {
  const login = readDB();
  res.json(login);
});

app.post('/sign-in', async (req, res) => {
  const validation = loginSchema.safeParse(req.body);

  if (!validation.success) {
    return res.status(400).json({ error: "Invalid data", detail: validation.error.format() });
  }

  const { email, name, username, password } = validation.data;
  const logins = readDB();
  if (logins.find(u => u.email === email) || logins.find(u => u.username === username)) {
    return res.status(400).json({ error: "This email/username already in use" });
  }
  try {
    const date = new Date();
    const hashedPassword = await bcrypt.hash(password, saltRounds);
    const newLogin = {
      id_user: logins.length > 0 ? logins[logins.length - 1].id_user + 1 : 0,
      email: email,
      name: name,
      username: username,
      password: hashedPassword,
      creation_date: date
    };

    logins.push(newLogin);
    saveDB(logins);

    res.status(201).json({ message: "Username created with success!", username });

  } catch (error) {
    res.status(500).json({ error: "Error processing password" });

  }

});

app.post('/login', async (req, res) => {
  const { userEmail, password } = req.body;
  const logins = readDB();
  const searchTerm = userEmail.toLowerCase().trim()

  const user = logins.find(u => (u.email.toLowerCase().trim() === searchTerm)
    || (u.username.toLowerCase().trim() === searchTerm));

  if (!user) {
    return res.status(401).json({ error: "Incorrect email or password" });
  }

  try {
    const isMatch = await bcrypt.compare(password, user.password);

    if (isMatch) {
      res.json({
        message: "Login successful",
      });
    } else {
      res.status(401).json({ error: "Incorrect email or password" });
    }
  } catch (error) {
    res.status(500).json({ error: "Error validating login" });
  }
});




app.listen(8000, () => console.log('Rodando!'));



