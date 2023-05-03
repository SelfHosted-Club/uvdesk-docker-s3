# uvdesk-docker-s3
Non-privileged dockerised version of uvdesk with S3 funtionality for assets

Prebuilt docker images can be found at https://hub.docker.com/r/tivini/uvdesk/tags - choose the ones with the s3 in the tag name.
s3-amd64 for pretty much all desktops and servers.
s3-arm64v8 works on mac, if someone tests it on RaspberryPi and it works let me know.

## Usage of S3 sync - non privileged container workaround
This is my own workaround, and so it may break or require troubleshooting on high volumes or other kind of changes.

The s3 image contains a function to sync the assets folder (/var/www/uvdesk/public/assets) to a S3 compatible bucket of your choice, I don't see the assets dir changing much and so it should be OK with low volumes of transactions.

This has been tested with Cloudflare R2 and works, so there's no reason it shouldn't work with others.

Everytime the container is initialised, a pull will start from the bucket, I recommend to watch your egress or use a provider that doesn't charge you for that (such as Cloudflare or Wasabi). The method it uses is to watch the directory using inotifywait function, and calling a script to either upload or delete files from the bucket, those correspond to the structure of the local folder - this is done through the minio client. You will need to configure the following environment variables to use the S3 functionality:

* S3_BUCKET=
* S3_ACCESS_KEY_ID=
* S3_SECRET_ACCESS_KEY=
* S3_URL=

The URL should NOT include the trailing slash with your bucket name!
