#!/bin/bash

# ===========================
# Author: Andrew J. McDonald
# Date: 2023-03-15
# ============================================================================
# Description: Check and update certbot SSL certificates and copy to RabbitMQ
# certs folder. Restart RabbitMQ to use new certificates if updated.
# ============================================================================

# Set script name for logging
SCRIPT_NAME="rabbitmq-cert-copy"

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
#if false; then
if ! [[ $(find "$ORIG_FULLCHAIN" -mmin -90) ]] && ! [[ $(find "$ORIG_CERT" -mmin -90) ]] && ! [[ $(find "$ORIG_PRIVKEY" -mmin -90) ]] && ! [[ $(find "$ORIG_CHAIN" -mmin -90) ]]; then
  echo $(date +"%y-%m-%d %T")" ["$SCRIPT_NAME"]: No updates found for SSL certificates within last 90 minutes."
  exit 0
else
  echo $(date +"%y-%m-%d %T")" ["$SCRIPT_NAME"]: SSL certificates have been updated within the last 90mins!"

  # Compare SSL certificate contents and copy to RabbitMQ certs folder if they have changed
  #if false; then
  if cmp -s "$ORIG_FULLCHAIN" "$NEW_FULLCHAIN" && cmp -s "$ORIG_CERT" "$NEW_CERT" && cmp -s "$ORIG_PRIVKEY" "$NEW_PRIVKEY" && cmp -s "$ORIG_CHAIN" "$NEW_CHAIN"; then
    echo $(date +"%y-%m-%d %T")" ["$SCRIPT_NAME"]: SSL certificate contents match."
    exit 0
  else
    echo $(date +"%y-%m-%d %T")" ["$SCRIPT_NAME"]: SSL certificate contents do not match!"

    # Copy new certificates to rabbitmq folder
    echo $(date +"%y-%m-%d %T")" ["$SCRIPT_NAME"]: Copying updated SSL certificates..."
    cp -fv "$ORIG_FULLCHAIN" "$NEW_FULLCHAIN"
    cp -fv "$ORIG_CERT" "$NEW_CERT"
    cp -fv "$ORIG_PRIVKEY" "$NEW_PRIVKEY"
    cp -fv "$ORIG_CHAIN" "$NEW_CHAIN"

    # Set permissions and ownership for the copied files
    echo $(date +"%y-%m-%d %T")" ["$SCRIPT_NAME"]: Updating ownership and permissions of SSL certificates..."
    chmod 644 "$NEW_FULLCHAIN" "$NEW_CERT" "$NEW_CHAIN"
    chmod 600 "$NEW_PRIVKEY"
    chown rabbitmq:rabbitmq "$NEW_FULLCHAIN" "$NEW_CERT" "$NEW_CHAIN" "$NEW_PRIVKEY"

    # Restart RabbitMQ to ensure the new certificates are used
    echo $(date +"%y-%m-%d %T")" ["$SCRIPT_NAME"]: Restarting Rabbitmq to ensure updated SSL certifcates are utilised..."
    for i in {1..5}; do
      if systemctl restart rabbitmq-server; then
        echo $(date +"%y-%m-%d %T")" ["$SCRIPT_NAME"]: RabbitMQ has been successfully restarted!"
        exit 0
      else
        echo $(date +"%y-%m-%d %T")" ["$SCRIPT_NAME"]: RabbitMQ failed to restart. Retrying in 5 seconds..."
        sleep 5
      fi
    done

    # Check if RabbitMQ has been restarted
    if ! systemctl is-active --quiet rabbitmq-server; then
      echo $(date +"%y-%m-%d %T")" ["$SCRIPT_NAME"]: Error: RabbitMQ failed to start after 5 attempts."
      exit 1
    fi
  fi
fi
