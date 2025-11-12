const express = require("express");
const cors = require("cors");

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
  console.log(JSON.stringify(logEntry));
}

const usePostgres = process.env.DB_HOST && process.env.DB_NAME;

let db;
let pool;

const { Pool } = require("pg");
pool = new Pool({
  host: process.env.DB_HOST,
  port: 5432,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  ssl: {
    rejectUnauthorized: false,
  },
});

async function initPostgresDB() {
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
    console.log("PostgreSQL database initialized successfully");
  } catch (error) {
    console.error("Error initializing PostgreSQL database:", error);
  } finally {
    client.release();
  }
}

initPostgresDB();

app.get("/comments", async (req, res) => {
  const startTime = Date.now();
  try {
    logAction("GET_COMMENTS_REQUEST", {
      method: "GET",
      endpoint: "/comments",
      ip: req.ip
    });

    if (usePostgres) {
      const result = await pool.query(
        "SELECT * FROM comments ORDER BY created_at DESC"
      );
      
      logAction("GET_COMMENTS_SUCCESS", {
        method: "GET",
        endpoint: "/comments",
        count: result.rows.length,
        duration_ms: Date.now() - startTime
      });

      res.json({
        success: true,
        data: result.rows,
        count: result.rows.length,
      });
    } else {
      const comments = db
        .prepare("SELECT * FROM comments ORDER BY created_at DESC")
        .all();
      
      logAction("GET_COMMENTS_SUCCESS", {
        method: "GET",
        endpoint: "/comments",
        count: comments.length,
        duration_ms: Date.now() - startTime
      });

      res.json({
        success: true,
        data: comments,
        count: comments.length,
      });
    }
  } catch (error) {
    logAction("GET_COMMENTS_ERROR", {
      method: "GET",
      endpoint: "/comments",
      error: error.message,
      duration_ms: Date.now() - startTime
    });
    console.error("Error fetching comments:", error);
    res.status(500).json({
      success: false,
      error: "Failed to fetch comments",
    });
  }
});

app.post("/comments", async (req, res) => {
  const startTime = Date.now();
  try {
    const { name, email, comment } = req.body;

    logAction("POST_COMMENT_REQUEST", {
      method: "POST",
      endpoint: "/comments",
      ip: req.ip,
      has_name: !!name,
      has_email: !!email,
      has_comment: !!comment
    });

    if (!name || !email || !comment) {
      logAction("POST_COMMENT_VALIDATION_ERROR", {
        method: "POST",
        endpoint: "/comments",
        error: "Missing required fields",
        duration_ms: Date.now() - startTime
      });
      return res.status(400).json({
        success: false,
        error: "Name, email, and comment are required",
      });
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      logAction("POST_COMMENT_VALIDATION_ERROR", {
        method: "POST",
        endpoint: "/comments",
        error: "Invalid email format",
        duration_ms: Date.now() - startTime
      });
      return res.status(400).json({
        success: false,
        error: "Invalid email format",
      });
    }

    let newComment;
    if (usePostgres) {
      const result = await pool.query(
        "INSERT INTO comments (name, email, comment) VALUES ($1, $2, $3) RETURNING *",
        [name, email, comment]
      );
      newComment = result.rows[0];
    } else {
      const stmt = db.prepare(
        "INSERT INTO comments (name, email, comment) VALUES (?, ?, ?)"
      );
      const result = stmt.run(name, email, comment);
      newComment = db
        .prepare("SELECT * FROM comments WHERE id = ?")
        .get(result.lastInsertRowid);
    }

    logAction("POST_COMMENT_SUCCESS", {
      method: "POST",
      endpoint: "/comments",
      comment_id: newComment.id,
      duration_ms: Date.now() - startTime
    });

    res.status(201).json({
      success: true,
      data: newComment,
      message: "Comment created successfully",
    });
  } catch (error) {
    logAction("POST_COMMENT_ERROR", {
      method: "POST",
      endpoint: "/comments",
      error: error.message,
      duration_ms: Date.now() - startTime
    });
    console.error("Error creating comment:", error);
    res.status(500).json({
      success: false,
      error: "Failed to create comment",
    });
  }
});

app.get("/health", async (req, res) => {
  try {
    await pool.query("SELECT 1");
    res.json({
      status: "ok",
      database: "postgresql",
      connected: true,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    res.status(500).json({
      status: "error",
      database: "postgresql",
      connected: false,
      timestamp: new Date().toISOString(),
    });
  }
});

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
  console.log(`Database: postgresql`);
  console.log(`Available endpoints:`);
  console.log(`  GET  /comments - Get all comments`);
  console.log(`  POST /comments - Create a new comment`);
  console.log(`  GET  /health   - Health check`);
});

process.on("SIGINT", () => {
  console.log("\nShutting down gracefully...");
  if (db) db.close();
  if (pool) pool.end();
  process.exit(0);
});
