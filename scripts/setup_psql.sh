#!/bin/bash

# Update system
sudo apt update && sudo apt upgrade -y

# Install PostgreSQL
sudo apt install -y postgresql postgresql-contrib

# Set up environment variable for database password


# Configure PostgreSQL
sudo -u postgres psql -c "CREATE DATABASE testdb;"
sudo -u postgres psql -c "CREATE USER testuser WITH PASSWORD '$DB_PASSWORD';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE testdb TO testuser;"

# Allow connections from the app subnet (adjust the IP range as needed)
echo "host all all 10.0.1.0/24 md5" | sudo tee -a /etc/postgresql/12/main/pg_hba.conf

# Configure PostgreSQL to listen on all interfaces
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/12/main/postgresql.conf

# Restart PostgreSQL
sudo systemctl restart postgresql

# Enable PostgreSQL to start on boot
sudo systemctl enable postgresql

echo "PostgreSQL setup complete!"
