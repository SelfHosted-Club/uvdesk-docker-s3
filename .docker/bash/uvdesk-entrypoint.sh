#!/bin/bash


# Restart apache
service apache2 stop

if [[ ! -z "$S3_ACCESS_KEY_ID" && ! -z "$S3_SECRET_ACCESS_KEY" && ! -z "$S3_BUCKET" && ! -z "$S3_URL" ]]; then

	# Clear out assets directory
	rm -rf /var/www/uvdesk/public/assets/{.,}*

	# Change permissions on assets
	chmod 777 /var/www/uvdesk/public/assets


	# Create mini bucket configuration
	mc config host add S3 ${S3_URL} ${S3_ACCESS_KEY_ID} ${S3_SECRET_ACCESS_KEY}

	# First pull from S3 to sync files
	mc mirror S3/${S3_BUCKET} /var/www/uvdesk/public/assets

	# Make sure folders belong to uvdesek
	chown uvdesk:uvdesk -R /var/www/uvdesk/public/assets

	# Start sync service
	screen -dmS s3_sync
	screen -S s3_sync -X stuff '/usr/local/bin/s3_sync.sh\n'		
        
else
    echo -e "Notice: No S3 defined, proceeding without";
fi

# Check if require login is set to true
if [[ "$REQUIRE_LOGIN" == "TRUE" ]]; then
	file_path="/var/www/uvdesk/vendor/uvdesk/support-center-bundle/Resources/config/routes/public.yaml"
	line_number=3

	# Change the line as according to https://forums.uvdesk.com/topic/2027/require-login/2?_=1683106194155
	new_line='    controller: Webkul\\UVDesk\\SupportCenterBundle\\Controller\\Customer::login'
	# Use sed to replace the line in the file
	sed -i "${line_number}s/.*/${new_line}/" "$file_path"
	
	# Run console command to apply the setting
	php /var/www/uvdesk/bin/console c:c
fi

# Step down from sudo to uvdesk
apachectl -D FOREGROUND
su uvdesk

exec "$@"
