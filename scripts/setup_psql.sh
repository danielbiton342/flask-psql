#!/bin/bash

# -------------------------------------------------------------------------
# -------------------- Mounting data disk to the VM -----------------------
# Check if the data disk is already mounted
if grep -qs '/datadrive' /proc/mounts; then
  echo "Data disk is already mounted."
else
  # Prepare a new empty disk
  sudo parted /dev/sdc --script mklabel gpt mkpart xfspart xfs 0% 100%
  sudo mkfs.xfs /dev/sdc1
  sudo partprobe /dev/sdc1

  # Mount the disk
  sudo mkdir /datadrive
  sudo mount /dev/sdc1 /datadrive
  sudo sh -c 'echo "$(blkid | grep -o "UUID=\"[0-9a-f-]\+\"" | tail -1)  /datadrive  xfs  defaults,nofail  1  2" >> /etc/fstab'
  echo "Data disk mounted successfully."
fi

# Check if the environment variable POSTGRES_PASSWORD is set
if [ -z "$POSTGRES_PASSWORD" ]; then
  echo "Error: Environment variable POSTGRES_PASSWORD is not set."
  exit 1
fi

# Install PostgreSQL
sudo apt-get update
sudo apt-get -y install postgresql

# Create a new PostgreSQL role and database
sudo -u postgres psql -c "CREATE ROLE myuser WITH LOGIN PASSWORD '${POSTGRES_PASSWORD}';"
sudo -u postgres psql -c "CREATE DATABASE mydatabase OWNER myuser;"

# Grant all privileges on the database to the user
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE mydatabase TO myuser;"

# Create a table in the database with columns for name, age_value, and time
sudo -u postgres psql -d mydatabase -c "CREATE TABLE mytable (name VARCHAR, age_value NUMERIC, time VARCHAR);"

# Insert sample values into the table
sudo -u postgres psql -d mydatabase -c "INSERT INTO mytable (name, age_value, time) VALUES ('Alice', 30, 'morning'), ('Bob', 25, 'afternoon');"

# Restart PostgreSQL service
sudo systemctl restart postgresql

echo "PostgreSQL setup complete. Initial user, database, table created, and sample values inserted. Password is stored in the environment variable POSTGRES_PA
SSWORD."
