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