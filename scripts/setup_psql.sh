
#!/bin/bash

# -------------------------------------------------------------------------
# -------------------- Mounting data disk to the VM -----------------------
# Prepare a new empty disk
sudo parted /dev/sdc --script mklabel gpt mkpart xfspart xfs 0% 100%
sudo mkfs.xfs /dev/sdc1
sudo partprobe /dev/sdc1

# Mount the disk
sudo mkdir /datadrive
sudo mount /dev/sdc1 /datadrive
sudo blkid
sudo sh -c 'echo "$(blkid | grep -o "UUID=\"[0-9a-f-]\+\"" | tail -1)   /datadrive   xfs   defaults,nofail   1   2" >> /etc/fstab'

# -------------------------------------------------------------------------------
# -------------------- Installing and configuring PostgreSQL --------------------

# Check if the environment variable POSTGRES_PASSWORD is set
if [ -z "$POSTGRES_PASSWORD" ]; then
    echo "Error: Environment variable POSTGRES_PASSWORD is not set."
    exit 1
fi

# Add PostgreSQL repository
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

# Import PostgreSQL repository key
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

# Update package lists
sudo apt-get update

# Install PostgreSQL
sudo apt-get -y install postgresql

# Create user, database, and table, and grant privileges to the user
sudo -i -u postgres psql -c "ALTER USER postgres PASSWORD '${POSTGRES_PASSWORD}';"
sudo -i -u postgres psql -c "CREATE DATABASE flask_db;"
sudo -i -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE flask_db TO postgres;"
sudo -i -u postgres psql -d flask_db -c "CREATE TABLE table_gifts_yovel (name VARCHAR, age_value NUMERIC, time VARCHAR);"

# Find the location of postgresql.conf and modify to allow remote connections
sudo find /etc/postgresql -name "postgresql.conf" -exec sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" {} \;

# Allow client connections to all databases
sudo find /etc/postgresql -name "pg_hba.conf" -exec sudo sed -i "$ a\host all all 0.0.0.0/0 md5" {} \; 

# Stop PostgreSQL service
sudo service postgresql stop

# Move the data directory to the new mount point
sudo mv /var/lib/postgresql/*/main /datadrive/postgres-data
sudo find /etc/postgresql -name "postgresql.conf" -exec sudo sed -i "s|data_directory = '.*'|data_directory = '/datadrive/postgres-data'|" {} \;

# Restart PostgreSQL service
sudo systemctl restart postgresql

echo "PostgreSQL setup complete. Password is stored in the environment variable POSTGRES_PASSWORD."
