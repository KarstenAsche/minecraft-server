#!/bin/sh
set -eu

# Ensure persistent data directory exists
mkdir -p /app/data

# Set default values
JAVA_MIN_RAM="${JAVA_MIN_RAM:-1G}"
JAVA_MAX_RAM="${JAVA_MAX_RAM:-2G}"
MAX_PLAYERS="${MAX_PLAYERS:-20}"
DIFFICULTY="${DIFFICULTY:-normal}"
MOTD="${MOTD:-DevSecOps Minecraft Server}"
WHITE_LIST="${WHITE_LIST:-true}"

# Check Minecraft EULA acceptance
if [ "${EULA:-false}" != "true" ]; then
    echo "ERROR: Minecraft EULA must be accepted."
    exit 1
fi

# Create EULA file if necessary
if [ ! -f /app/data/eula.txt ]; then
    echo "eula=true" > /app/data/eula.txt
fi

# Switch to persistent data directory
cd /app/data

# Create properties file if necessary
touch server.properties

# Remove previously managed settings
sed -i '/^max-players=/d; /^difficulty=/d; /^motd=/d; /^white-list=/d' server.properties

# Apply environment configuration
printf 'max-players=%s\n' "${MAX_PLAYERS}" >> server.properties
printf 'difficulty=%s\n' "${DIFFICULTY}" >> server.properties
printf 'motd=%s\n' "${MOTD}" >> server.properties
printf 'white-list=%s\n' "${WHITE_LIST}" >> server.properties

# Start Minecraft server
exec java \
    -Xms"${JAVA_MIN_RAM}" \
    -Xmx"${JAVA_MAX_RAM}" \
    -jar /app/server.jar nogui
