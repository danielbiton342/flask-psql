import os
from flask import Flask, request, jsonify
from datetime import datetime
import psycopg2

app = Flask(__name__)

# Database connection settings
DB_NAME = "mydatabase"
DB_USER = "postgres"
DB_PASSWORD = "danielbit"
DB_HOST = "10.0.2.4"
DB_PORT = "5432"

# Function to establish a database connection
def get_db_connection():
    return psycopg2.connect(
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
        host=DB_HOST,
        port=DB_PORT
    )

@app.route('/', methods=['GET'])
def home():
    return 'Welcome to the Flask App!', 200

@app.route('/data', methods=['GET'])
def get_data():
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM public.mytable;")
        records = cursor.fetchall()

        result = []
        for record in records:
            # Adjust these indices based on your table columns
            result.append({
                'id': record[0],  # ID column index
                'name': record[1],  # Name column index
                'value': record[2],  # Value column index
                'time': record[3].isoformat() if isinstance(record[3], datetime) else str(record[3])  # Time column index
            })

        cursor.close()
        conn.close()
        return jsonify(result), 200
    except Exception as e:
        return jsonify({'error': str(e), 'message': 'Error fetching data'}), 500

@app.route('/data', methods=['POST'])
def receive_data():
    try:
        data = request.get_json()

        # Validate the input data
        if not data or 'name' not in data or 'value' not in data or 'time' not in data:
            return jsonify({'error': 'Invalid input data'}), 400

        name = data['name']
        value = data['value']
        time_str = data['time']

        # Parse the time string into a datetime object
        try:
            time = datetime.strptime(time_str, "%a %b %d %H:%M:%S %Y")
        except ValueError:
            return jsonify({'error': 'Invalid date format'}), 400

        # Insert data into the table
        conn = get_db_connection()
        cursor = conn.cursor()
        insert_query = "INSERT INTO public.mytable (name, value, time) VALUES (%s, %s, %s)"
        cursor.execute(insert_query, (name, value, time))
        conn.commit()

        cursor.close()
        conn.close()

        response_data = {
            'name': name,
            'value': value,
            'time': time.isoformat()
        }

        return jsonify(response_data), 201
    except Exception as e:
        return jsonify({'error': str(e), 'message': 'Error inserting data'}), 500

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=8080, debug=True)
