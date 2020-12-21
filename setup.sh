#!/bin/bash

### Author: Abdullah Manzoor

function newDomain () {
	echo ""
	echo "Tell me a name for the Domain."
	echo "Use one DOT [.] only, no special characters."
	echo "Example: example.com || EXAMPLE.COM"

	until [[ "$DOMAIN" =~ ^[a-zA-Z0-9]+.[a-zA-Z0-9]+$ ]]; do
		read -rp "DOMAIN name: " -e DOMAIN
		echo "$DOMAIN" > /tmp/domain.text
	done
}

function newSubDomain () {
	echo ""
	echo "Tell me a name for the Sub-Domain."
	echo "Use 2 DOT [.] only, no special characters."
	echo "Example: example.example.com || EXAMPLE.EXAMPLE.COM"

	until [[ "$SUBDOMAIN" =~ ^[a-zA-Z0-9]+.[a-zA-Z0-9]+.[a-zA-Z0-9]+$ ]]; do
		read -rp "SUBDOMAIN name: " -e SUBDOMAIN
		echo "$SUBDOMAIN" > /tmp/subdomain.text
	done
}

function adminUser () {
	echo ""
	echo "Tell me the name of Admin User."
	echo "Use only one word, no special characters rather than []."

	until [[ "$ADMINUSER" =~ ^[a-zA-Z0-9_]+$ ]]; do
		read -rp "ADMINUSER name: " -e ADMINUSER
		echo "$ADMINUSER" > /tmp/adminuser.text
	done
}

function adminUserEmail () {
	echo ""
	echo "Tell me the Email of Admin User for Password."
	echo "Use on DOT [.] only & @, no special characters rather than [-,_]."
	echo "Example: admin@example.com || ADMIN@EXAMPLE.COM"

	until [[ "$ADMINUSEREMAIL" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$ ]]; do
		read -rp "ADMINUSEREMAIL name: " -e ADMINUSEREMAIL
		echo "$ADMINUSEREMAIL" > /tmp/adminuseremail.text
		strings /dev/urandom | grep -o '[.[:alnum:]]+$' | head -n 12 | tr -d '\n' > /tmp/adminpassword.text
	done
}

function sitePage(){
SITENAME=`cat /tmp/domain.text`
SERVERADMIN=`cat /tmp/adminuser.text`
ADMINPASSWORD=`cat /tmp/adminpassword.text`

sudo mkdir -p /var/www/$SITENAME/public_html
sudo chown -R apache:apache /var/www/$SITENAME/public_html
sudo chmod -R 755 /var/www

echo "<html>
  <head>
    <title>Welcome to "$SITENAME!"</title>
  </head>
  <body>
    <h1>Success! The "$SITENAME" virtual host is working!</h1>
  </body>
</html>" > /var/www/\"$SITENAME\"/public_html/index.html

htpasswd -b -c /var/www/$SITENAME/public_html/.htaccess $SERVERADMIN $ADMINPASSWORD

echo "<VirtualHost *:80>
    ServerAdmin "$SERVERADMIN"
    ServerName www."$SITENAME"
    ServerAlias "$SITENAME"
    DocumentRoot /var/www/"$SITENAME"/public_html
    ErrorLog /var/www/"$SITENAME"/error.log
    CustomLog /var/www/"$SITENAME"/requests.log combined
	<Directory "/var/www/$SITENAME">
      AuthType Basic
      AuthName "Restricted Content"
      AuthUserFile /var/www/"$SITENAME"/public_html/.htaccess
      Require valid-user
  </Directory>
</VirtualHost>" > /etc/httpd/conf.d/$SITENAME.conf
}
sitePage

function cloudflareDNS(){
SITENAME=`cat /tmp/domain.text`
read -rp "ZONEID name: " -e ZONEID
read -rp "EAMIL name: " -e EAMIL
read -rp "AUTH_KEY name: " -e AUTH_KEY

until [[ "$IP" =~ ^[1-255]+.[1-255].+[1-255].+[1-255]+$ ]]; do
		read -rp "IP Address of Server: " -e IP
done

curl -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONEID/dns_records/" \
     -H "X-Auth-Email: $EAMIL" \
     -H "X-Auth-Key: $AUTH_KEY" \
     -H "Content-Type: application/json" \
     --data '{"type":"A","name":"$SITENAME","content":"$IP","ttl":{},"proxied":false}'
}

function mailSendGrid() {
read -rp "SENDGRID_API_KEY name: " -e SENDGRID_API_KEY
read -rp "EMAIL_TO name: " -e EMAIL_TO
read -rp "FROM_EMAIL name: " -e FROM_EMAIL
read -rp "FROM_NAME name: " -e FROM_NAME
read -rp "SUBJECT name: " -e SUBJECT

bodyHTML="<p>Email body goes here</p>"

maildata='{"personalizations": [{"to": [{"email": "'${EMAIL_TO}'"}]}],"from": {"email": "'${FROM_EMAIL}'", 
	"name": "'${FROM_NAME}'"},"subject": "'${SUBJECT}'","content": [{"type": "text/html", "value": "'${bodyHTML}'"}]}'

curl --request POST \
  --url https://api.sendgrid.com/v3/mail/send \
  --header 'Authorization: Bearer '$SENDGRID_API_KEY \
  --header 'Content-Type: application/json' \
  --data "'$maildata'"
}

newDomain
newSubDomain
adminUser
adminUserEmail
sitePage
cloudflareDNS
mailSendGrid
