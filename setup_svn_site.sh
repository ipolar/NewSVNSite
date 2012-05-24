#! /bin/bash
# Maybe I should use dynamic vhosts instead...
# Make sure SVN and apachectl are in your path
# To edit your vhosts file and restart apache you'll need your root password
# You'll also need to edit the Document root as well

# Constants
DOCUMENT_ROOT="/Users/andy/Sites/"
VHOST_LOCATION="/private/etc/apache2/extra/httpd-vhosts.conf"

# Ask the user for the beanstalk SVN URL...
echo "Please enter your SVN URL:"
read SVN_URL

echo "Please enter your SVN username:"
read SVN_USER

echo "Please enter your SVN password:"
read SVN_PASS

BS_FOLDER=`echo "$SVN_URL" | cut -d '/' -f4`
BS_FOLDER=$BS_FOLDER"_beanstalk"

if [ ! -d $DOCUMENT_ROOT$BS_FOLDER ]; then
	
	echo "* creating folder structure..."
	mkdir $DOCUMENT_ROOT$BS_FOLDER
	
	echo "* checking out source [please wait]..."
	svn co $SVN_URL $DOCUMENT_ROOT$BS_FOLDER --username $SVN_USER --password $SVN_PASS --non-interactive
	
	echo "* adding vhosts entry..."
	if [ -d $DOCUMENT_ROOT$BS_FOLDER/trunk/httpdocs ]; then
		WEB_ROOT="httpdocs";
	else
		WEB_ROOT="htdocs";
	fi
	
	NEXT_PORT=`cat $VHOST_LOCATION | grep -o "\[[0-9][0-9][0-9][0-9]\]" | sed -n '$p' | sed 's:^.\(.*\).$:\1:'`
    NEXT_PORT=$(($NEXT_PORT+1))
	
	# Backup vhosts before editing...
	sudo cp -p $VHOST_LOCATION $VHOST_LOCATION.orig	
	
	sudo bash -c "cat >> $VHOST_LOCATION" <<EOF	
	
# [$NEXT_PORT] $BS_FOLDER
Listen $NEXT_PORT
<VirtualHost *:$NEXT_PORT>
    DocumentRoot "$DOCUMENT_ROOT$BS_FOLDER/trunk/$WEB_ROOT"
    ServerName localhost:$NEXT_PORT
	
    <Directory "$DOCUMENT_ROOT$BS_FOLDER/trunk/$WEB_ROOT">
      AllowOverride All
      Options All
      Deny from None
    </Directory>
</VirtualHost>
EOF
	
	sudo apachectl restart
	echo "* your new site is ready: http://localhost:$NEXT_PORT"
else
	echo "* folder already exists! Exiting..."
	exit;
fi