#!/bin/bash

# This script checks if the SSL certificates generated by certbot have been updated and copies them to the RabbitMQ certs folder
# if they have changed. If the certificates are updated, the script also restarts RabbitMQ to ensure the new certificates are used.

# Set source file/folder paths
ORIG_FOLDER="/etc/letsencrypt/live/DOMAIN_NAME"

ORIG_FULLCHAIN="$ORIG_FOLDER/fullchain.pem"
ORIG_CERT="$ORIG_FOLDER/cert.pem"
ORIG_PRIVKEY="$ORIG_FOLDER/privkey.pem"
ORIG_CHAIN="$ORIG_FOLDER/chain.pem"

# Set destination file/folder paths
DEST_FOLDER="/full/path/rabbitmq-certs"

NEW_FULLCHAIN="$DEST_FOLDER/fullchain.pem"
NEW_CERT="$DEST_FOLDER/cert.pem"
NEW_PRIVKEY="$DEST_FOLDER/privkey.pem"
NEW_CHAIN="$DEST_FOLDER/chain.pem"

# Check if the SSL certificates have not been updated by checking for no modification in the last 90 minutes
if ! [[ $(find "$ORIG_FULLCHAIN" -mmin -90) ]] && ! [[ $(find "$ORIG_CERT" -mmin -90) ]] && ! [[ $(find "$ORIG_PRIVKEY" -mmin -90) ]] && ! [[ $(find "$ORIG_CHAIN" -mmin -90) ]]; then
#if false; then
  echo "No updates seen for SSL certificates in last 90 minutes."
  exit 0
else
  echo "SSL certificates changes found within the last 90mins!"

  # Compare SSL certificate contents and copy to RabbitMQ certs folder if they have changed
  #if false; then
  if cmp -s "$ORIG_FULLCHAIN" "$NEW_FULLCHAIN" && cmp -s "$ORIG_CERT" "$NEW_CERT" && cmp -s "$ORIG_PRIVKEY" "$NEW_PRIVKEY" && cmp -s "$ORIG_CHAIN" "$NEW_CHAIN"; then
    echo "No mismatch of SSL contents found."
    exit 0
  else
    echo "SSL certificate contents do not match!"

    # Copy new certificates to rabbitmq folder
    echo "Copying new SSL certificates..."
    cp -fv "$ORIG_FULLCHAIN" "$NEW_FULLCHAIN"
    cp -fv "$ORIG_CERT" "$NEW_CERT"
    cp -fv "$ORIG_PRIVKEY" "$NEW_PRIVKEY"
    cp -fv "$ORIG_CHAIN" "$NEW_CHAIN"

    # Set permissions and ownership for the copied files
    echo "Updating ownership and permissions of SSL certificates..."
    chmod 644 "$NEW_FULLCHAIN" "$NEW_CERT" "$NEW_CHAIN"
    chmod 600 "$NEW_PRIVKEY"
    chown rabbitmq:rabbitmq "$NEW_FULLCHAIN" "$NEW_CERT" "$NEW_CHAIN" "$NEW_PRIVKEY"

    # Restart RabbitMQ to ensure the new certificates are used
    echo "Restarting Rabbitmq to ensure new SSL certificates are utilised..."
    for i in {1..5}; do
      if systemctl restart rabbitmq-server; then
        echo "RabbitMQ has been successfully restarted!"
        exit 0
      else
        echo "RabbitMQ failed to restart. Retrying in 5 seconds..."
        sleep 5
      fi
    done

    # Check if RabbitMQ has been restarted
    if ! systemctl is-active --quiet rabbitmq-server; then
      echo "Error: RabbitMQ failed to start after 5 attempts."
      exit 1
    fi
  fi
fi
