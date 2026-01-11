"""
FastAPI Application with intentional security vulnerabilities for DevSecOps demo
WARNING: This code contains intentional security flaws for educational purposes only
"""

from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse
import sqlite3
import hashlib
import os
import requests

app = FastAPI()

# VULNERABILITY 1: Hardcoded secrets (GitLeaks will detect these)
AWS_ACCESS_KEY_ID = "AKIAIOSFODNN7EXAMPLE"
AWS_SECRET_ACCESS_KEY = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
GITHUB_TOKEN = "ghp_1234567890abcdefghijklmnopqrstuvwxyzAB"
DATABASE_PASSWORD = "SuperSecret123!@#"
SLACK_WEBHOOK = "https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX"

# Initialize SQLite database
def init_db():
    conn = sqlite3.connect('users.db')
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY,
            username TEXT NOT NULL,
            password TEXT NOT NULL,
            email TEXT
        )
    ''')
    conn.commit()
    conn.close()

init_db()


@app.get("/")
async def root():
    return {"message": "DevSecOps Demo API", "status": "running"}


# VULNERABILITY 2: SQL Injection (Semgrep will detect this)
@app.get("/users/{username}")
async def get_user(username: str):
    """
    Vulnerable endpoint - uses string concatenation for SQL query
    """
    conn = sqlite3.connect('users.db')
    cursor = conn.cursor()

    # SQL Injection vulnerability - direct string concatenation
    query = "SELECT * FROM users WHERE username = '" + username + "'"
    cursor.execute(query)

    result = cursor.fetchone()
    conn.close()

    if result:
        return {"user": {"id": result[0], "username": result[1], "email": result[3]}}
    raise HTTPException(status_code=404, detail="User not found")


# VULNERABILITY 3: Weak cryptography - MD5 usage (Semgrep will detect this)
@app.post("/register")
async def register_user(username: str, password: str, email: str):
    """
    Vulnerable endpoint - uses MD5 for password hashing
    """
    # MD5 is cryptographically broken and should not be used
    password_hash = hashlib.md5(password.encode()).hexdigest()

    conn = sqlite3.connect('users.db')
    cursor = conn.cursor()

    try:
        cursor.execute(
            "INSERT INTO users (username, password, email) VALUES (?, ?, ?)",
            (username, password_hash, email)
        )
        conn.commit()
        conn.close()
        return {"message": "User registered successfully", "username": username}
    except sqlite3.IntegrityError:
        conn.close()
        raise HTTPException(status_code=400, detail="Username already exists")


# VULNERABILITY 4: Missing input validation (Semgrep will detect this)
@app.get("/fetch")
async def fetch_url(url: str):
    """
    Vulnerable endpoint - no validation of URL parameter (SSRF vulnerability)
    """
    # No validation - allows SSRF attacks
    response = requests.get(url)
    return {"content": response.text[:200], "status_code": response.status_code}


@app.post("/login")
async def login(username: str, password: str):
    """
    Login endpoint with weak password hashing
    """
    password_hash = hashlib.md5(password.encode()).hexdigest()

    conn = sqlite3.connect('users.db')
    cursor = conn.cursor()

    # Using parameterized query here (correct)
    cursor.execute(
        "SELECT * FROM users WHERE username = ? AND password = ?",
        (username, password_hash)
    )

    result = cursor.fetchone()
    conn.close()

    if result:
        return {
            "message": "Login successful",
            "token": GITHUB_TOKEN,  # Using hardcoded secret
            "user": {"id": result[0], "username": result[1]}
        }
    raise HTTPException(status_code=401, detail="Invalid credentials")


@app.get("/health")
async def health_check():
    return {"status": "healthy", "api_version": "1.0.0"}


if __name__ == "__main__":
    import uvicorn
    # Running on all interfaces - potential security risk in production
    uvicorn.run(app, host="0.0.0.0", port=8000)
