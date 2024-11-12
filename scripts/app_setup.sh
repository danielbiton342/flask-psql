#!/bin/bash
set -euo pipefail #script will fail quickly if there is an error and gets better outputs

sudo apt-get update
sudo apt-get install -yq python3-pip
sudo pip install psycopg2-binary flask

echo "installed all successfully"

sudo chmod +x ~/flask-psql/app.py

# the crontab does not work yet...
#sudo (crontab -l 2>/dev/null; echo "@reboot /usr/bin/python3 ~/flask-psql/app.py") | crontab -

#echo "inserted data to crontab successfully"
echo "python is running successfully"

APP_PATH="/home/terademo/flask-psql"
APP_PYTHON="/usr/bin/python3"
APP_USER="terademo"
SERVICE_NAME="flask-app-service"
cat << EOF | sudo tee /etc/systemd/system/$SERVICE_NAME.service
[Unit]
Description=My Flask Application
After=network.target

[Service]
User=$APP_USER
WorkingDirectory=$APP_PATH
ExecStart=$APP_PYTHON $APP_PATH/app.py

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable $SERVICE_NAME.service
sudo systemctl start $SERVICE_NAME.service

echo "A service for the application was created. the app will run if the VM restarts"
