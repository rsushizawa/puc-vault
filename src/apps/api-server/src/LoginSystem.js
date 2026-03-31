const express = require('express');
const cors = require('cors');
const { z } = require('zod');
const bcrypt = require('bcryptjs');
const { Pool } = require('pg');
const path = require('path');

const envPath = path.resolve(__dirname, '../../../../.env');

require('dotenv').config({ path: envPath });

const hostAccess = process.env.DB_HOST;
const userAccess = process.env.DB_USER;
const passAccess = process.env.DB_PASS;
const portAccess = process.env.DB_PORT;
const databaseAcess = process.env.DB_NAME;

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

async function validateCredentials(userEmail, password) {
  let client;
  try {
    client = await pool.connect();
    console.log('conexão sucedida');
    let returnvalue = await client.query('SELECT * FROM buscar_usuario_pelo_username( $1 )', [userEmail]);
    if (returnvalue.rowCount === 0) {
      returnvalue = await client.query('SELECT * FROM buscar_usuario_pelo_email( $1 )', [userEmail]);
    }
    if (returnvalue.rowCount === 0) {
      console.log('user not found');
      return {
        authenticated: false,
        message: 'user or email not found'
      };
    }
    const userRow = returnvalue.rows[0];
    const passwordValid = await bcrypt.compare(password, userRow.senha_hash);

    if (passwordValid) {
      delete userRow.senha_hash;
      console.log('login successful');
      return {
        authenticated: true,
        user: userRow
      };
    } else {
      console.log('login failed');
      return {
        authenticated: false,
        message: 'incorrect password'
      };
    }
  } catch (error) {
    console.error('--- DETALHES DO ERRO ---');
    console.error('Mensagem:', error.message);
    console.error('Código Postgre:', error.code); // Ex: 23505 (duplicado), 42P01 (tabela não existe)
    console.error('Detalhe:', error.detail);
    console.error('Onde:', error.where);
    console.error('------------------------');
    throw error;
  } finally {
    client.release();
  }
}

async function addToDB(name, username, email, hashedPassword) {
  let client;
  try {
    client = await pool.connect();
    console.log('conexão bem sucedida');
    const queryText = 'CALL user_insert( $1, $2, $3, $4)';
    const values = [name, username, email, hashedPassword];
    await client.query(queryText, values);
    console.log('usuario inserido');
  } catch (error) {
    console.error('--- DETALHES DO ERRO ---');
    console.error('Mensagem:', error.message);
    console.error('Código Postgre:', error.code); // Ex: 23505 (duplicado), 42P01 (tabela não existe)
    console.error('Detalhe:', error.detail);
    console.error('Onde:', error.where);
    console.error('------------------------');
  } finally {
    client.release();
  }
}



async function printDB() {
  let client;
  try {
    client = await pool.connect();
    console.log('conexão bem sucedida');
    const res = await client.query('SELECT * FROM public.listar_usuarios()');
    console.table(res.rows);
  } catch (error) {
    console.error('--- DETALHES DO ERRO ---');
    console.error('Mensagem:', error.message);
    console.error('Código Postgre:', error.code); // Ex: 23505 (duplicado), 42P01 (tabela não existe)
    console.error('Detalhe:', error.detail);
    console.error('Onde:', error.where);
    console.error('------------------------');

  } finally {
    client.release();
  }
}

const saltRounds = 10;

const app = express();
app.use(cors());
app.use(express.json());




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

//post sign-in basicamente pronto 
app.post('/sign-in', async (req, res) => {
  const validation = loginSchema.safeParse(req.body);

  if (!validation.success) {
    return res.status(400).json({ error: "Invalid data", detail: validation.error.format() });
  }

  const { email, name, username, password } = validation.data;
  try {
    const hashedPassword = await bcrypt.hash(password, saltRounds);


    await addToDB(name, username, email, hashedPassword);
    await printDB();


    res.status(201).json({ message: "Username created with success!", username });

  } catch (error) {
    // 1. Print the full error to your terminal
    console.error("CRITICAL ERROR IN /sign-in:", error);

    // 2. You can also send the error message to Postman/Frontend temporarily for debugging
    res.status(500).json({
      error: "Error processing password",
      details: error.message // Remove this line before putting your app in production!
    });

  }

});

app.post('/login', async (req, res) => {
  const { userEmail, password } = req.body;

  try {
    let isAuthenticated = await validateCredentials(userEmail, password);
    if (isAuthenticated.authenticated) {
      //entrou
      res.status(200).json(isAuthenticated.user);
    }
    else {
      //fica na tela de login pq nao entrou
      console.log('login failed', isAuthenticated.message);
      res.status(401).json({ error: isAuthenticated.message })
    }

  } catch (error) {
    console.log('internal server error', error.message);
  }
});




app.listen(8000, () => console.log('Rodando!'));



