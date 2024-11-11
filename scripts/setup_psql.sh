#!/bin/bash

# Check if the environment variable for password is set
if [ -z "$PG_PASSWORD" ]; then
  echo "ERROR: The environment variable PG_PASSWORD is not set!"
  exit 1
fi

# Update the package list
echo "Updating package list..."
sudo apt-get update -y

# Install necessary dependencies
echo "Installing dependencies..."
sudo apt-get install -y wget ca-certificates curl gnupg lsb-release

# Add PostgreSQL APT repository
echo "Adding PostgreSQL repository..."
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo tee /etc/apt/trusted.gpg.d/pgdg.asc
echo "deb http://apt.postgresql.org/pub/repos/apt/ jammy-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list

# Update the package list again after adding the repository
echo "Updating package list after adding PostgreSQL repository..."
sudo apt-get update -y

# Install PostgreSQL
echo "Installing PostgreSQL..."
sudo apt-get install -y postgresql postgresql-contrib

# Install additional dependencies (if needed for PostgreSQL extensions, etc.)
echo "Installing additional dependencies for PostgreSQL..."
sudo apt-get install -y build-essential libreadline-dev zlib1g-dev

# Enable and start PostgreSQL service
echo "Enabling and starting PostgreSQL service..."
sudo systemctl enable postgresql
sudo systemctl start postgresql

# Check the PostgreSQL service status
echo "Checking PostgreSQL service status..."
sudo systemctl status postgresql

# Print PostgreSQL version to confirm installation
echo "PostgreSQL version:"
psql --version

# Create the database and user, and set the password from environment variable
echo "Creating PostgreSQL database and user..."
sudo -i -u postgres psql <<EOF
CREATE DATABASE mydatabase;
CREATE USER myuser WITH ENCRYPTED PASSWORD '${PG_PASSWORD}';
GRANT ALL PRIVILEGES ON DATABASE mydatabase TO myuser;
EOF

# Done
echo "PostgreSQL installation and database creation completed successfully."
