import os
from flask import Flask, jsonify
import psycopg2

app = Flask(__name__)

# Retrieve the secret values (environment variables) set in GitHub Codespaces
DB_HOST = "10.0.2.0"
DB_NAME = flask_db
DB_USER = adminuser
DB_PASSWORD = os.getenv("DB_PASSWORD")  # Get database password from Codespace secret
DB_PORT = 5432

# Function to connect to the PostgreSQL database
def get_db_connection():
    try:
        conn = psycopg2.connect(
            host=DB_HOST,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD,
            port=DB_PORT
        )
        return conn
    except Exception as e:
        print(f"Error connecting to database: {e}")
        return None

# Route to fetch users from the database
@app.route('/users', methods=['GET'])
def get_users():
    conn = get_db_connection()
    if conn is None:
        return jsonify({"error": "Unable to connect to the database"}), 500

    cursor = conn.cursor()
    cursor.execute('SELECT * FROM users;')
    users = cursor.fetchall()
    cursor.close()
    conn.close()

    # Format the result
    users_list = [{"id": user[0], "name": user[1], "email": user[2]} for user in users]
    return jsonify(users_list)

# Home route
@app.route('/')
def home():
    return "Welcome to the Simple Python App with PostgreSQL!"

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')

