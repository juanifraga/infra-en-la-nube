const express = require("express");
const cors = require("cors");
const path = require("path");

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// Check if we're using PostgreSQL or SQLite
const usePostgres = process.env.DB_HOST && process.env.DB_NAME;

let db;
let pool;

if (usePostgres) {
  // PostgreSQL setup
  const { Pool } = require("pg");
  pool = new Pool({
    host: process.env.DB_HOST,
    port: 5432,
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
  });

  // Initialize PostgreSQL table
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
} else {
  // SQLite setup
  const Database = require("better-sqlite3");
  db = new Database(path.join(__dirname, "comments.db"));

  db.exec(`
    CREATE TABLE IF NOT EXISTS comments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT NOT NULL,
      comment TEXT NOT NULL,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  `);
  console.log("SQLite database initialized successfully");
}

app.get("/comments", async (req, res) => {
  try {
    if (usePostgres) {
      const result = await pool.query(
        "SELECT * FROM comments ORDER BY created_at DESC"
      );
      res.json({
        success: true,
        data: result.rows,
        count: result.rows.length,
      });
    } else {
      const comments = db
        .prepare("SELECT * FROM comments ORDER BY created_at DESC")
        .all();
      res.json({
        success: true,
        data: comments,
        count: comments.length,
      });
    }
  } catch (error) {
    console.error("Error fetching comments:", error);
    res.status(500).json({
      success: false,
      error: "Failed to fetch comments",
    });
  }
});

app.post("/comments", async (req, res) => {
  try {
    const { name, email, comment } = req.body;

    if (!name || !email || !comment) {
      return res.status(400).json({
        success: false,
        error: "Name, email, and comment are required",
      });
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
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

    res.status(201).json({
      success: true,
      data: newComment,
      message: "Comment created successfully",
    });
  } catch (error) {
    console.error("Error creating comment:", error);
    res.status(500).json({
      success: false,
      error: "Failed to create comment",
    });
  }
});

app.get("/health", async (req, res) => {
  try {
    if (usePostgres) {
      await pool.query("SELECT 1");
      res.json({
        status: "ok",
        database: "postgresql",
        connected: true,
        timestamp: new Date().toISOString(),
      });
    } else {
      db.prepare("SELECT 1").get();
      res.json({
        status: "ok",
        database: "sqlite",
        connected: true,
        timestamp: new Date().toISOString(),
      });
    }
  } catch (error) {
    res.status(500).json({
      status: "error",
      database: usePostgres ? "postgresql" : "sqlite",
      connected: false,
      timestamp: new Date().toISOString(),
    });
  }
});

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
  console.log(`Database: ${usePostgres ? "PostgreSQL" : "SQLite"}`);
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
