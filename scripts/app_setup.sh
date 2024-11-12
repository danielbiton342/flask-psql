#!/bin/bash

# Check if the password environment variable is set
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
mkdir -p /home/azureuser/todoapp
cd /home/azureuser/todoapp

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
db_host = os.environ.get('POSTGRES_HOST', 'PRIVATE_VM_IP')  # Replace with actual private IP
db_port = os.environ.get('POSTGRES_PORT', '5432')

app.config['SQLALCHEMY_DATABASE_URI'] = f"postgresql://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}"
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)

# ... (rest of your Todo app code)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=True)
EOF

# Create .env file for environment variables
cat << EOF > .env
POSTGRES_DB=testdb
POSTGRES_USER=testuser
POSTGRES_PASSWORD=$DB_PASSWORD
POSTGRES_HOST=PRIVATE_VM_IP
POSTGRES_PORT=5432
EOF

# Create a systemd service file for the application
sudo tee /etc/systemd/system/todoapp.service << EOF
[Unit]
Description=Todo App Flask Service
After=network.target

[Service]
User=azureuser
WorkingDirectory=/home/azureuser/todoapp
ExecStart=/usr/bin/python3 /home/azureuser/todoapp/app.py
Restart=always
EnvironmentFile=/home/azureuser/todoapp/.env

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable todoapp
sudo systemctl start todoapp

echo "Todo App setup complete!"
