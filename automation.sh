#!/bin/sh
myname="Varsha"
s3_bucket="upgrad-varshathomas"

echo "Updating the packages"
sudo apt update -y
echo "Installing apache"
sudo apt-get install apache2 -y

# Method to check if service is running
serviceCheck () {
        STATUS="$(systemctl is-active "$1")"
        if [ "${STATUS}" = "active" ]; then
                return 0
         else
                return 1
        fi  
}

#Checking to see if service is running, if service is inactive attempting to restart the service
if serviceCheck apache2 ; then
        echo "Service is running, Executing tasks.."
else
        echo " Service not running.... Attempting to restart service"
        sudo service apache2 restart
        if serviceCheck apache2 ; then
                echo "Service is running, Executing tasks"
        else
                echo "Service is not running, exiting"
                exit 1
        fi
fi

#Creating tar with timestamp
timestamp=$(date '+%d%m%Y-%H%M%S')
filename="/tmp/${myname}-httpd-logs-${timestamp}.tar"
sudo tar -cvf $filename  $( find /var/log/apache2/ -name "*.log")

# Upload file to S3
echo "Uploading file to S3"
aws s3 cp $filename s3://${s3_bucket}/$filename

# Bookeeping
FILE="/var/www/html/inventory.html"
fileSize=$(ls -lh $filename | awk '{print  $5}')
if [ ! -f "$FILE" ]; then
        echo "${FILE} does not exist, creating it.."
        sudo touch $FILE
        sudo chmod 777 $FILE
        echo "<table><b><tr>Log Type</tr> &emsp;&emsp;&emsp;&emsp;<tr>Time Created</tr>&emsp;&emsp;&emsp;&emsp;&emsp;<tr>Type</tr>&emsp;&emsp;&emsp;&emsp;<tr>Size</tr></b></table>" >> $FILE
fi

echo "Updating inventory"
echo "<table><tr>httpd-logs</tr> &emsp;&emsp;&emsp;<tr>${timestamp}</tr>&emsp;&emsp;&emsp;&emsp;<tr>tar</tr>&emsp;&emsp;&emsp;&emsp;&emsp;<tr>${fileSize}</tr></table>" >> $FILE
echo "Inventory updated"

# CRON
cronFile="/etc/cron.d/automation"
scriptLocation="/root/Automation_Project/automation.sh"

# Check if cron job is scheduled
isCronScheduled=$(sudo crontab -l | grep 'automation')
if [ "$isCronScheduled" ]; then
        echo "Automation cron is scheduled"
else
        echo "Automation cron is not scheduled, scheduling it"
        if [ ! -f "$cronFile" ]; then
                echo "Cron file not found, creating it"
                sudo touch $cronFile
                sudo chmod 777 $cronFile
                sudo echo "0 4 * * * $scriptLocation" >> $cronFile
        fi
        sudo crontab $cronFile
        echo "Cron has been scheduled"
fi       