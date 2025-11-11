#!/bin/bash
set -e

# Update system
apt-get update -y
apt-get upgrade -y

# Install Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# Install git
apt-get install -y git

# Install PostgreSQL client
apt-get install -y postgresql-client

# Create app directory
mkdir -p /opt/backend
cd /opt/backend

# Create backend application files
cat > package.json <<'EOF'
{
  "name": "backend",
  "version": "1.0.0",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {
    "express": "^5.1.0",
    "cors": "^2.8.5",
    "pg": "^8.11.3"
  }
}
EOF

cat > index.js <<'EOF'
const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// PostgreSQL connection
const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  ssl: {
    rejectUnauthorized: false
  }
});

// Initialize database table
async function initDB() {
  const client = await pool.connect();
  try {
    await client.query(`
      CREATE TABLE IF NOT EXISTS comments (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        email VARCHAR(255) NOT NULL,
        comment TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('Database initialized successfully');
  } catch (error) {
    console.error('Error initializing database:', error);
  } finally {
    client.release();
  }
}

initDB();

// GET /comments - Get all comments
app.get('/comments', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM comments ORDER BY created_at DESC');
    res.json({
      success: true,
      data: result.rows,
      count: result.rows.length
    });
  } catch (error) {
    console.error('Error fetching comments:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch comments'
    });
  }
});

// POST /comments - Create a comment
app.post('/comments', async (req, res) => {
  try {
    const { name, email, comment } = req.body;

    if (!name || !email || !comment) {
      return res.status(400).json({
        success: false,
        error: 'Name, email, and comment are required'
      });
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid email format'
      });
    }

    const result = await pool.query(
      'INSERT INTO comments (name, email, comment) VALUES ($1, $2, $3) RETURNING *',
      [name, email, comment]
    );

    res.status(201).json({
      success: true,
      data: result.rows[0],
      message: 'Comment created successfully'
    });
  } catch (error) {
    console.error('Error creating comment:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to create comment'
    });
  }
});

// GET /health - Health check
app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ 
      status: 'ok', 
      database: 'connected',
      timestamp: new Date().toISOString() 
    });
  } catch (error) {
    res.status(500).json({ 
      status: 'error', 
      database: 'disconnected',
      timestamp: new Date().toISOString() 
    });
  }
});

app.listen(PORT, () => {
  console.log(`Server is running on port $${PORT}`);
  console.log(`Available endpoints:`);
  console.log(`  GET  /comments - Get all comments`);
  console.log(`  POST /comments - Create a new comment`);
  console.log(`  GET  /health   - Health check`);
});
EOF

# Create environment file
cat > .env <<EOF
DB_HOST=${db_host}
DB_PORT=${db_port}
DB_NAME=${db_name}
DB_USER=${db_user}
DB_PASSWORD=${db_password}
PORT=3000
EOF

# Install dependencies
npm install

# Create systemd service
cat > /etc/systemd/system/backend.service <<'EOF'
[Unit]
Description=Backend API Service
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/opt/backend
EnvironmentFile=/opt/backend/.env
ExecStart=/usr/bin/node index.js
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
systemctl daemon-reload
systemctl enable backend.service
systemctl start backend.service

echo "Backend setup complete!"
