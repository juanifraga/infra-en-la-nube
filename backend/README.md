# Comments Backend API

A simple Express.js backend for managing comments with support for both SQLite (local development) and PostgreSQL (production).

## Features

- RESTful API endpoints
- Dual database support (SQLite for local, PostgreSQL for production)
- CORS enabled
- Input validation
- Timestamps for comments
- Health check endpoint

## Installation

```bash
npm install
```

## Running the Server

### Local Development (SQLite)

```bash
# Production mode
npm start

# Development mode (with auto-reload on Node 18+)
npm run dev
```

### Production (PostgreSQL)

Set the following environment variables:

```bash
export DB_HOST=your-db-host
export DB_NAME=commentsdb
export DB_USER=admin
export DB_PASSWORD=your-password
export PORT=3000

npm start
```

Or create a `.env` file:

```
DB_HOST=your-rds-endpoint.rds.amazonaws.com
DB_NAME=commentsdb
DB_USER=admin
DB_PASSWORD=your-secure-password
PORT=3000
```

The server will automatically detect the database configuration and use PostgreSQL if `DB_HOST` and `DB_NAME` are set, otherwise it will use SQLite.

The server will start on port 3000 (or the PORT environment variable if set).

## API Endpoints

### GET /comments

Get all comments ordered by creation date (newest first).

**Response:**

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "comment": "Great article!",
      "created_at": "2025-11-11 00:00:00"
    }
  ],
  "count": 1
}
```

### POST /comments

Create a new comment.

**Request Body:**

```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "comment": "This is a great article!"
}
```

**Response:**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "comment": "This is a great article!",
    "created_at": "2025-11-11 00:00:00"
  },
  "message": "Comment created successfully"
}
```

**Validation Rules:**

- All fields (name, email, comment) are required
- Email must be in valid format

### GET /health

Health check endpoint.

**Response:**

```json
{
  "status": "ok",
  "timestamp": "2025-11-11T00:00:00.000Z"
}
```

## Testing with curl

```bash
# Create a comment
curl -X POST http://localhost:3000/comments \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "comment": "This is a test comment"
  }'

# Get all comments
curl http://localhost:3000/comments

# Health check
curl http://localhost:3000/health
```

## Database

The application uses SQLite with a file-based database (`comments.db`). The database is automatically created on first run.

### Schema

```sql
CREATE TABLE comments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  comment TEXT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```
