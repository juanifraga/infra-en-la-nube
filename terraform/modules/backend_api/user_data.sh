#!/bin/bash
set -e

# Update system
apt-get update -y
apt-get upgrade -y

# Install Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# Install git and other tools
apt-get install -y git jq

# Install PostgreSQL client
apt-get install -y postgresql-client

# Install CloudWatch Agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i amazon-cloudwatch-agent.deb

# Create CloudWatch Agent configuration
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'CWEOF'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/backend-api.log",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "{instance_id}/backend-api",
            "timestamp_format": "%Y-%m-%dT%H:%M:%S.%fZ"
          }
        ]
      }
    }
  }
}
CWEOF

# Start CloudWatch Agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

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

cat > index.js <<'JSEOF'
const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const fs = require('fs');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// Helper function for logging
function logAction(action, details) {
  const logEntry = {
    timestamp: new Date().toISOString(),
    action: action,
    ...details
  };
  const logLine = JSON.stringify(logEntry) + '\n';
  console.log(logLine.trim());
  
  // Also write to file for CloudWatch
  fs.appendFileSync('/var/log/backend-api.log', logLine);
}

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
    logAction('DATABASE_INITIALIZED', { status: 'success' });
  } catch (error) {
    logAction('DATABASE_INIT_ERROR', { error: error.message });
  } finally {
    client.release();
  }
}

initDB();

// GET /comments - Get all comments
app.get('/comments', async (req, res) => {
  const startTime = Date.now();
  try {
    logAction('GET_COMMENTS_REQUEST', {
      method: 'GET',
      endpoint: '/comments',
      ip: req.ip
    });

    const result = await pool.query('SELECT * FROM comments ORDER BY created_at DESC');
    
    logAction('GET_COMMENTS_SUCCESS', {
      method: 'GET',
      endpoint: '/comments',
      count: result.rows.length,
      duration_ms: Date.now() - startTime
    });

    res.json({
      success: true,
      data: result.rows,
      count: result.rows.length
    });
  } catch (error) {
    logAction('GET_COMMENTS_ERROR', {
      method: 'GET',
      endpoint: '/comments',
      error: error.message,
      duration_ms: Date.now() - startTime
    });
    console.error('Error fetching comments:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch comments'
    });
  }
});

// POST /comments - Create a comment
app.post('/comments', async (req, res) => {
  const startTime = Date.now();
  try {
    const { name, email, comment } = req.body;

    logAction('POST_COMMENT_REQUEST', {
      method: 'POST',
      endpoint: '/comments',
      ip: req.ip,
      has_name: !!name,
      has_email: !!email,
      has_comment: !!comment
    });

    if (!name || !email || !comment) {
      logAction('POST_COMMENT_VALIDATION_ERROR', {
        method: 'POST',
        endpoint: '/comments',
        error: 'Missing required fields',
        duration_ms: Date.now() - startTime
      });
      return res.status(400).json({
        success: false,
        error: 'Name, email, and comment are required'
      });
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      logAction('POST_COMMENT_VALIDATION_ERROR', {
        method: 'POST',
        endpoint: '/comments',
        error: 'Invalid email format',
        duration_ms: Date.now() - startTime
      });
      return res.status(400).json({
        success: false,
        error: 'Invalid email format'
      });
    }

    const result = await pool.query(
      'INSERT INTO comments (name, email, comment) VALUES ($1, $2, $3) RETURNING *',
      [name, email, comment]
    );

    logAction('POST_COMMENT_SUCCESS', {
      method: 'POST',
      endpoint: '/comments',
      comment_id: result.rows[0].id,
      duration_ms: Date.now() - startTime
    });

    res.status(201).json({
      success: true,
      data: result.rows[0],
      message: 'Comment created successfully'
    });
  } catch (error) {
    logAction('POST_COMMENT_ERROR', {
      method: 'POST',
      endpoint: '/comments',
      error: error.message,
      duration_ms: Date.now() - startTime
    });
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
  logAction('SERVER_STARTED', {
    port: PORT,
    environment: 'production',
    nodejs_version: process.version
  });
  console.log(`Server is running on port $${PORT}`);
  console.log(`Available endpoints:`);
  console.log(`  GET  /comments - Get all comments`);
  console.log(`  POST /comments - Create a new comment`);
  console.log(`  GET  /health   - Health check`);
});
JSEOF

# Create environment file
cat > .env <<EOF
DB_HOST=${db_host}
DB_PORT=${db_port}
DB_NAME=${db_name}
DB_USER=${db_user}
DB_PASSWORD=${db_password}
PORT=3000
EOF

# Create log file with proper permissions
touch /var/log/backend-api.log
chown ubuntu:ubuntu /var/log/backend-api.log
chmod 644 /var/log/backend-api.log

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

echo "Backend setup complete with CloudWatch logging enabled!"
