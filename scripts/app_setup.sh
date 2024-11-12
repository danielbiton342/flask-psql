#!/bin/bash

# Check if the DB_PASSWORD environment variable is set
if [ -z "$DB_PASSWORD" ]; then
    echo "Error: DB_PASSWORD environment variable is not set."
    echo "Please set it before running this script, for example:"
    echo "export DB_PASSWORD='your_secure_password'"
    exit 1
fi

# Update system
sudo apt update && sudo apt upgrade -y

# Install Python and pip
sudo apt install -y python3 python3-pip

# Install required Python packages
pip3 install Flask Flask-SQLAlchemy psycopg2-binary python-dotenv

# Create a directory for the application
mkdir -p ~/todoapp
cd ~/todoapp

# Create the application file
cat << EOF > app.py
from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
import os
from dotenv import load_dotenv

load_dotenv()  # Load environment variables from .env file

app = Flask(__name__)

# Database configuration
db_name = os.environ.get('POSTGRES_DB', 'testdb')
db_user = os.environ.get('POSTGRES_USER', 'testuser')
db_password = os.environ.get('POSTGRES_PASSWORD')
db_host = os.environ.get('POSTGRES_HOST', 'localhost')  # Assuming DB is on the same VM
db_port = os.environ.get('POSTGRES_PORT', '5432')

app.config['SQLALCHEMY_DATABASE_URI'] = f"postgresql://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}"
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)

class Todo(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    task = db.Column(db.String(200), nullable=False)
    completed = db.Column(db.Boolean, default=False)

    def to_dict(self):
        return {
            "id": self.id,
            "task": self.task,
            "completed": self.completed
        }

@app.route('/todos', methods=['GET'])
def get_todos():
    todos = Todo.query.all()
    return jsonify([todo.to_dict() for todo in todos])

@app.route('/todos', methods=['POST'])
def create_todo():
    data = request.json
    new_todo = Todo(task=data['task'])
    db.session.add(new_todo)
    db.session.commit()
    return jsonify(new_todo.to_dict()), 201

@app.route('/todos/<int:todo_id>', methods=['PUT'])
def update_todo(todo_id):
    todo = Todo.query.get_or_404(todo_id)
    data = request.json
    todo.task = data.get('task', todo.task)
    todo.completed = data.get('completed', todo.completed)
    db.session.commit()
    return jsonify(todo.to_dict())

@app.route('/todos/<int:todo_id>', methods=['DELETE'])
def delete_todo(todo_id):
    todo = Todo.query.get_or_404(todo_id)
    db.session.delete(todo)
    db.session.commit()
    return '', 204

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    app.run(host='0.0.0.0', port=8080, debug=True)
EOF

# Create .env file for environment variables
cat << EOF > .env
POSTGRES_DB=testdb
POSTGRES_USER=testuser
POSTGRES_PASSWORD=$DB_PASSWORD
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
EOF

# Create a systemd service file for the application
sudo tee /etc/systemd/system/todoapp.service << EOF
[Unit]
Description=Todo App Flask Service
After=network.target

[Service]
User=tera-db
WorkingDirectory=/home/tera-db/todoapp
ExecStart=/usr/bin/python3 /home/tera-db/todoapp/app.py
Restart=always
Environment="DB_PASSWORD=$DB_PASSWORD"

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable todoapp
sudo systemctl start todoapp

echo "Todo App setup complete!"
