#!/bin/sh

# Define functions.
function fixperms {
	chown -R $UID:$GID /data /opt/mautrix-telegram
}

cd /opt/mautrix-telegram

# Replace database path in config.
sed -i "s#sqlite:///mautrix-telegram.db#sqlite:////data/mautrix-telegram.db#" /data/config.yaml

if [ -f /data/mx-state.json ]; then
	ln -s /data/mx-state.json
fi
# Check that database is in the right state
alembic -x config=/data/config.yaml upgrade head

if [ ! -f /data/config.yaml ]; then
	cp mautrix_telegram/example-config.yaml /data/config.yaml
	echo "Didn't find a config file."
	echo "Copied default config file to /data/config.yaml"
	echo "Modify that config file to your liking."
	echo "Start the container again after that to generate the registration file."
	fixperms
	exit
fi

if [ ! -f /data/registration.yaml ]; then
	python3 -m mautrix_telegram -g -c /data/config.yaml -r /data/registration.yaml
	echo "Didn't find a registration file."
	echo "Generated one for you."
	echo "Copy that over to synapses app service directory."
	fixperms
	exit
fi

fixperms
exec su-exec $UID:$GID python3 -m mautrix_telegram -c /data/config.yaml
