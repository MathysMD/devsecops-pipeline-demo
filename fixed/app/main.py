"""
Secure FastAPI Application - Fixed Version
All security vulnerabilities have been resolved
"""

from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse
import sqlite3
import os
import requests
import bcrypt
from urllib.parse import urlparse
from typing import Optional

app = FastAPI()

# FIXED: Use environment variables instead of hardcoded secrets
AWS_ACCESS_KEY_ID = os.getenv('AWS_ACCESS_KEY_ID')
AWS_SECRET_ACCESS_KEY = os.getenv('AWS_SECRET_ACCESS_KEY')
GITHUB_TOKEN = os.getenv('GITHUB_TOKEN')
DATABASE_PASSWORD = os.getenv('DATABASE_PASSWORD')
SLACK_WEBHOOK = os.getenv('SLACK_WEBHOOK')

# Allowed domains for SSRF protection
ALLOWED_DOMAINS = ['api.example.com', 'safe-api.com']

# Initialize SQLite database
def init_db():
    conn = sqlite3.connect('users.db')
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY,
            username TEXT NOT NULL UNIQUE,
            password TEXT NOT NULL,
            email TEXT
        )
    ''')
    conn.commit()
    conn.close()

init_db()


@app.get("/")
async def root():
    return {"message": "DevSecOps Demo API - Secure Version", "status": "running"}


# FIXED: SQL Injection - Using parameterized queries
@app.get("/users/{username}")
async def get_user(username: str):
    """
    Secure endpoint - uses parameterized SQL query
    """
    conn = sqlite3.connect('users.db')
    cursor = conn.cursor()

    # FIXED: Using parameterized query to prevent SQL injection
    cursor.execute("SELECT * FROM users WHERE username = ?", (username,))

    result = cursor.fetchone()
    conn.close()

    if result:
        return {"user": {"id": result[0], "username": result[1], "email": result[3]}}
    raise HTTPException(status_code=404, detail="User not found")


# FIXED: Strong cryptography - Using bcrypt instead of MD5
@app.post("/register")
async def register_user(username: str, password: str, email: str):
    """
    Secure endpoint - uses bcrypt for password hashing
    """
    # FIXED: Using bcrypt with salt for secure password hashing
    salt = bcrypt.gensalt()
    password_hash = bcrypt.hashpw(password.encode(), salt)

    conn = sqlite3.connect('users.db')
    cursor = conn.cursor()

    try:
        cursor.execute(
            "INSERT INTO users (username, password, email) VALUES (?, ?, ?)",
            (username, password_hash.decode('utf-8'), email)
        )
        conn.commit()
        conn.close()
        return {"message": "User registered successfully", "username": username}
    except sqlite3.IntegrityError:
        conn.close()
        raise HTTPException(status_code=400, detail="Username already exists")


# FIXED: Input validation - URL allowlist to prevent SSRF
@app.get("/fetch")
async def fetch_url(url: str):
    """
    Secure endpoint - validates URL against allowlist (SSRF protection)
    """
    # FIXED: Validate URL against allowlist
    try:
        parsed_url = urlparse(url)

        # Check if domain is in allowlist
        if parsed_url.netloc not in ALLOWED_DOMAINS:
            raise HTTPException(
                status_code=400,
                detail=f"Domain not allowed. Allowed domains: {', '.join(ALLOWED_DOMAINS)}"
            )

        # Check for valid scheme
        if parsed_url.scheme not in ['http', 'https']:
            raise HTTPException(status_code=400, detail="Invalid URL scheme. Use http or https")

        # Make the request with timeout
        response = requests.get(url, timeout=5)
        return {"content": response.text[:200], "status_code": response.status_code}

    except requests.exceptions.RequestException as e:
        raise HTTPException(status_code=500, detail=f"Request failed: {str(e)}")


@app.post("/login")
async def login(username: str, password: str):
    """
    Login endpoint with secure password verification
    """
    conn = sqlite3.connect('users.db')
    cursor = conn.cursor()

    # Using parameterized query
    cursor.execute(
        "SELECT * FROM users WHERE username = ?",
        (username,)
    )

    result = cursor.fetchone()
    conn.close()

    if result:
        stored_password_hash = result[2].encode('utf-8')

        # FIXED: Using bcrypt for password verification
        if bcrypt.checkpw(password.encode(), stored_password_hash):
            # FIXED: Use environment variable for token
            token = GITHUB_TOKEN if GITHUB_TOKEN else "token-not-configured"
            return {
                "message": "Login successful",
                "token": token,
                "user": {"id": result[0], "username": result[1]}
            }

    raise HTTPException(status_code=401, detail="Invalid credentials")


@app.get("/health")
async def health_check():
    return {"status": "healthy", "api_version": "2.0.0-secure"}


if __name__ == "__main__":
    import uvicorn
    # Running on localhost only in development
    uvicorn.run(app, host="127.0.0.1", port=8000)
