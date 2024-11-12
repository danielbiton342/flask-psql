
#!/bin/bash

# Update system
sudo apt update && sudo apt upgrade -y

# Install PostgreSQL
sudo apt install -y postgresql postgresql-contrib

# Get PostgreSQL version and set config paths
PGVERSION=$(pg_config --version | awk '{print $2}' | cut -d. -f1)
PGCONF="/etc/postgresql/${PGVERSION}/main/postgresql.conf"
PGHBA="/etc/postgresql/${PGVERSION}/main/pg_hba.conf"



# Configure PostgreSQL
sudo -u postgres psql << EOF
CREATE DATABASE testdb;
CREATE USER testuser WITH PASSWORD '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE testdb TO testuser;
EOF

# Allow connections from the app subnet (adjust the IP range as needed)
echo "host all all 10.0.1.0/24 md5" | sudo tee -a $PGHBA

# Configure PostgreSQL to listen on all interfaces
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" $PGCONF

# Restart PostgreSQL
sudo systemctl restart postgresql

# Enable PostgreSQL to start on boot
sudo systemctl enable postgresql

echo "PostgreSQL setup complete!"
