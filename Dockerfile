# Use Java 25 as the runtime environment
FROM eclipse-temurin:25-jre

# Set the working directory
WORKDIR /app

# Copy working directory
COPY . .

RUN chmod +x /app/entrypoint.sh

# Minecraft default server port
EXPOSE 25565

# Start the Minecraft server
ENTRYPOINT ["/app/entrypoint.sh"]
