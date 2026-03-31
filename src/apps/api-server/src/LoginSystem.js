const express = require('express');
const cors = require('cors');
const { z, toLowerCase } = require('zod');
const bcrypt = require('bcryptjs');
const { tr } = require('zod/locales');
const { error, log } = require('console');
const { Pool } = require('pg');


const path = require('path');
const fs = require('fs');

// 1. Defina o caminho (os 4 níveis que já validamos)
const envPath = path.resolve(__dirname, '../../../../.env');

// 2. Carregue o dotenv IMEDIATAMENTE
require('dotenv').config({ path: envPath });

// 3. SÓ AGORA você lê as variáveis do process.env
const hostAccess = process.env.DB_HOST;
const userAccess = process.env.DB_USER;
const passAccess = process.env.DB_PASS;
const portAccess = process.env.DB_PORT;
const databaseAcess = process.env.DB_NAME;

console.log('--- TESTE DE CONEXÃO ---');
console.log('Conectando em:', hostAccess); // Aqui NÃO pode ser undefined agora
console.log('Usuário:', userAccess);
console.log('------------------------');
const pool = new Pool({
  host: hostAccess,
  port: portAccess,
  database: databaseAcess,
  user: userAccess,
  password: passAccess,
  ssl: {
    rejectUnauthorized: false
  }
});

async function addToDB(name, username, email, hashedPassword) {
  try {
    const client = await pool.connect();
    console.log('conexão bem sucedida');
    const queryText = 'CALL user_insert( $1, $2, $3, $4)';
    const values = [name, username, email, hashedPassword];
    await client.query(queryText, values);
    console.log('usuario inserido');
    client.release();
  } catch (error) {
    console.error('--- DETALHES DO ERRO ---');
    console.error('Mensagem:', error.message);
    console.error('Código Postgre:', error.code); // Ex: 23505 (duplicado), 42P01 (tabela não existe)
    console.error('Detalhe:', error.detail);
    console.error('Onde:', error.where);
    console.error('------------------------');
  }
}

async function printDB() {
  try {
    const client = await pool.connect();
    console.log('conexão bem sucedida');
    const res = await client.query('SELECT * FROM public.listar_usuarios()');
    console.table(res.rows);
    client.release();
  } catch (error) {
    console.error('--- DETALHES DO ERRO ---');
    console.error('Mensagem:', error.message);
    console.error('Código Postgre:', error.code); // Ex: 23505 (duplicado), 42P01 (tabela não existe)
    console.error('Detalhe:', error.detail);
    console.error('Onde:', error.where);
    console.error('------------------------');

  }
}

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

    await addToDB(name, username, email, hashedPassword);
    await printDB();

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



