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
mkdir -p ~/todoapp/templates
cd ~/todoapp

# Create the application file
cat << EOF > app.py
from flask import Flask, request, jsonify, render_template
from flask_sqlalchemy import SQLAlchemy
import os

app = Flask(__name__)

# Database configuration
db_name = os.environ.get('POSTGRES_DB', 'testdb')
db_user = os.environ.get('POSTGRES_USER', 'testuser')
db_password = os.environ.get('POSTGRES_PASSWORD')
db_host = os.environ.get('POSTGRES_HOST', '10.0.2.4')  # Use the actual IP of your DB VM
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

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/todos', methods=['POST'])
def create_todo():
    data = request.json
    if 'task' not in data:
        return jsonify({"error": "Task is required"}), 400
    
    new_todo = Todo(task=data['task'])
    db.session.add(new_todo)
    db.session.commit()
    return jsonify(new_todo.to_dict()), 201

@app.route('/todos', methods=['GET'])
def get_todos():
    todos = Todo.query.all()
    return jsonify([todo.to_dict() for todo in todos])

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    app.run(host='0.0.0.0', port=8080, debug=True)
EOF

# Create the HTML template
cat << EOF > templates/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Todo App</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
        h1 { color: #333; }
        form { margin-bottom: 20px; }
        input[type="text"] { width: 70%; padding: 10px; }
        input[type="submit"] { padding: 10px 20px; background-color: #4CAF50; color: white; border: none; cursor: pointer; }
        ul { list-style-type: none; padding: 0; }
        li { background-color: #f1f1f1; margin: 5px 0; padding: 10px; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>Todo List</h1>
    <form id="todo-form">
        <input type="text" id="task" name="task" placeholder="Enter a new task" required>
        <input type="submit" value="Add Task">
    </form>
    <ul id="todo-list"></ul>

    <script>
        document.getElementById('todo-form').addEventListener('submit', function(e) {
            e.preventDefault();
            var task = document.getElementById('task').value;
            fetch('/todos', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({task: task}),
            })
            .then(response => response.json())
            .then(data => {
                document.getElementById('task').value = '';
                loadTodos();
            });
        });

        function loadTodos() {
            fetch('/todos')
            .then(response => response.json())
            .then(data => {
                var list = document.getElementById('todo-list');
                list.innerHTML = '';
                data.forEach(todo => {
                    var li = document.createElement('li');
                    li.textContent = todo.task;
                    list.appendChild(li);
                });
            });
        }

        loadTodos();
    </script>
</body>
</html>
EOF

# Create .env file for environment variables
cat << EOF > .env
POSTGRES_DB=testdb
POSTGRES_USER=testuser
POSTGRES_PASSWORD=$DB_PASSWORD
POSTGRES_HOST=10.0.2.4
POSTGRES_PORT=5432
EOF

# Create a systemd service file for the application
sudo tee /etc/systemd/system/todoapp.service << EOF
[Unit]
Description=Todo App Flask Service
After=network.target

[Service]
User=terademo
WorkingDirectory=/home/terademo/todoapp
ExecStart=/usr/bin/python3 /home/terademo/todoapp/app.py
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
