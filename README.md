# Minecraft Java Server with Docker Compose

A small DevSecOps training project that runs a **Minecraft Java Edition server** in a custom Docker image. It uses an Eclipse Temurin Java runtime rather than a prebuilt Minecraft server image, externalizes selected settings through `.env`, and keeps game data in a Docker-managed volume.

## Table of contents

- [Project objectives](#project-objectives)
- [Requirements](#requirements)
- [Quick start](#quick-start)
- [Repository contents](#repository-contents)
- [Configuration](#configuration)
- [How it works](#how-it-works)
- [Usage and operations](#usage-and-operations)
- [Testing](#testing)
- [Security notes](#security-notes)
- [References](#references)

## Project objectives

- Build and run a Minecraft server using a **custom** Dockerfile, not a ready-made Minecraft server image.
- Configure the application from outside the container.
- Preserve the world, player data, and `server.properties` across container recreation.
- Make the server reachable over TCP port **8888** on the Docker host.
- Automatically restart the service when the main process unexpectedly exits.
- Practice inspecting logs, testing connectivity, and troubleshooting containers.

## Requirements

- Docker Engine / Docker Desktop with the Docker Compose plugin.
- A host with sufficient memory and disk space; the example uses a **2 GB maximum Java heap**, in addition to memory needed by the operating system and Java itself.
- The official **Minecraft Java Edition 26.3** `server.jar`, compatible with the Java runtime used in this project.
- TCP port **8888** available and, for remote access, permitted by applicable host and cloud-provider firewall rules.
- A Minecraft Java Edition client of a compatible version for the gameplay test (optional for a status-only test).
- Python and [`mcstatus`](https://pypi.org/project/mcstatus/) for the optional external status check.

Read and accept the [Minecraft EULA](https://www.minecraft.net/eula) before setting `EULA=true`.

## Quick start

1. Clone this repository and switch to its directory:

   ```bash
   cd /var/www/minecraft-server
   git clone <YOUR-REPOSITORY-SSH-URL> .
   ```

2. Ensure the official `server.jar` is in the project root. The Dockerfile uses `COPY` rather than downloading the server binary.
3. Create your local configuration:

   ```bash
   cp .env.example .env
   ```

4. Edit `.env` and set `EULA=true` **only if you accept the Minecraft EULA**. Adjust memory and gameplay settings as needed.
5. Validate, build, and start:

   ```bash
   docker compose config --quiet #to check the docker compose config without starting container
   docker compose build # to build the image
   docker compose up -d # to start teh container
   ```

6. Check the container:

   ```bash
    docker compose ps
   ```
   ```bash
        NAME                          IMAGE                    COMMAND                  SERVICE     CREATED         STATUS          PORTS
        minecraft-server-mc-server-1  minecraft-server:1.0.0   "/app/entrypoint.sh"     mc-server   30 seconds ago  Up 30 seconds   0.0.0.0:8888->25565/tcp
    ```

7. Connect a compatible Minecraft Java client to `HOST_IP:8888`, or run the status test described below.

## Repository contents

| File | Purpose |
| --- | --- |
| `Dockerfile` | Builds the custom image on top of `eclipse-temurin:25-jre`. |
| `server.jar` | Official Minecraft Java server binary, copied into the image at build time. Obtain it from the official download page if it is not included in your checkout. |
| `entrypoint.sh` | Checks EULA acceptance, applies supported environment settings, and starts Java. |
| `docker-compose.yml` | Defines the `mc-server` service, tagged image, port mapping, environment file, volume, and restart policy. |
| `.env.example` | Example configuration values; safe to commit without secrets. |
| `.env` | Local runtime configuration; **not committed** to Git. |
| `.gitignore` | Excludes local environment files, generated data, and other unwanted content. |
| `.dockerignore` | Excludes files unnecessary or unsafe for the Docker build context. |
| `README.md` | Project documentation and testing instructions. |

The project intentionally does not require a separate Python test script, Minecraft plugins, mods, a database, or an orchestration platform.

## Configuration

Docker Compose loads `.env` into the container via `env_file`. The entrypoint converts the supported variables into arguments or values in `/app/data/server.properties`.

Example `.env`:

```dotenv
EULA=true
JAVA_MIN_RAM=1G
JAVA_MAX_RAM=2G
MAX_PLAYERS=4
DIFFICULTY=normal
MOTD=DevSecOps Minecraft Server
WHITE_LIST=true
```

| Variable | Purpose | Example | Fallback in entrypoint |
| --- | --- | --- | --- |
| `EULA` | Explicit license acceptance; server refuses to start unless `true` | `true` | `false` |
| `JAVA_MIN_RAM` | Initial JVM heap (`-Xms`) | `1G` | Check current `entrypoint.sh` |
| `JAVA_MAX_RAM` | Maximum JVM heap (`-Xmx`) | `2G` | Check current `entrypoint.sh` |
| `MAX_PLAYERS` | Minecraft `max-players` property | `4` | `20` |
| `DIFFICULTY` | `peaceful`, `easy`, `normal`, or `hard` | `normal` | `normal` |
| `MOTD` | Message displayed in the multiplayer server list | `DevSecOps Minecraft Server` | `DevSecOps Minecraft Server` |
| `WHITE_LIST` | Minecraft `white-list` setting (`true`/`false`) | `true` | `true` |

[!NOTE]
The `WHITE_LIST` mapping is included for the latest project change. Confirm that the deployed `entrypoint.sh` contains the `WHITE_LIST` assignment and updates `white-list=` in `server.properties` before relying on it. Set `WHITE_LIST=false` only when intentionally allowing any authenticated player to join.

When changing only `.env`, recreate the container to apply new environment values **without rebuilding the image**:

```bash
docker compose up -d --force-recreate
```

When modifying `Dockerfile`, `entrypoint.sh`, or `server.jar`, rebuild the image:

```bash
docker compose up -d --build
```

The entrypoint updates only the configuration keys it manages; the world and unrelated properties are preserved. Avoid editing managed keys manually in `server.properties`, because `.env` takes precedence at startup.

## How it works

1. The Dockerfile starts from **`eclipse-temurin:25-jre`**.
2. `COPY . .` copies the project files (including `server.jar`) into `/app`.
3. `entrypoint.sh` checks `EULA`, creates `/app/data` if needed, and writes or updates selected properties.
4. Java starts Minecraft from `/app/server.jar` with `/app/data` as its working directory.
5. Docker Compose maps host TCP **8888** to container TCP **25565**.
6. The named volume `minecraft_data` stores `/app/data` beyond the lifespan of an individual container.
7. The `unless-stopped` restart policy restarts an unexpectedly terminated container unless it was manually stopped.

The Compose image is tagged **`minecraft-server:1.0.0`**. That is the **project image tag**, not the Minecraft release version.

## Usage and operations

Run these commands in the directory containing `docker-compose.yml`:

```bash
# Validate the Compose configuration
docker compose config --quiet

# Build the image
docker compose build

# Start in detached mode
docker compose up -d

# Show status and published ports
docker compose ps

# Stop cleanly
docker compose stop mc-server

# Start again
docker compose start mc-server

# Recreate while preserving the named volume
docker compose up -d --force-recreate

# View runtime memory use
docker stats --no-stream
```

[!CAUTION]
**Do not run `docker compose down -v` when you want to preserve world data.** The `-v` option removes Compose-managed named volumes.

Inspect the managed Minecraft settings:

```bash
docker compose exec mc-server grep -E '^(max-players|difficulty|motd|white-list)=' /app/data/server.properties
```

On **Windows Git Bash**, MSYS path conversion may affect arguments that contain Linux paths. Prefix commands that pass `/app/...` with `MSYS_NO_PATHCONV=1`, for example:

```bash
MSYS_NO_PATHCONV=1 docker compose exec mc-server ls -la /app/data
```

## Testing

### 1. Container startup

```bash
docker compose ps
docker compose logs --tail=30 mc-server
```

Confirm that the service is running and Minecraft reports startup completion.

### 2. Network access using mcstatus

From a **different machine** with Python installed:

```bash
python -m pip install mcstatus
python -m mcstatus HOST_IP:8888 status
```

Replace `HOST_IP` with the address of the Docker host. For a local test, use `localhost:8888`. The response should report the Minecraft version, online/max players, and latency. A successful local status check does not, by itself, prove Internet reachability.

### 3. Gameplay and persistent data

1. Connect with Minecraft Java Edition to `HOST_IP:8888`.
2. Place a few blocks in a recognizable location and leave the game.
3. Stop and recreate the container without deleting its volume:

   ```bash
   docker compose down
   docker compose build
   docker compose up -d
   ```

4. Reconnect and confirm that the blocks and player progress remain.
5. Confirm that the existing `server.properties` still contains the expected settings.

### 4. External configuration

1. Set e.g. `MAX_PLAYERS=4`, `DIFFICULTY=hard`, and a distinctive `MOTD` in `.env`.
2. Run `docker compose up -d --force-recreate`.
3. Inspect the generated `server.properties` and query the status with `mcstatus`.
4. Confirm that `mcstatus` reports a maximum of four players. Difficulty is checked in `server.properties` rather than through the standard status query.

### 5. Automatic restart

The service uses `restart: unless-stopped`. A manual `docker compose stop` or `docker compose kill` is **not** a reliable way to test unexpected-exit restart behavior, since an explicitly stopped container may remain stopped.

For a controlled test environment, terminate the Java main process from within the container with `SIGTERM`:

```bash

# Send TERM from inside the container
docker compose exec mc-server sh -c 'kill -TERM 1'

# Verify that the service is back up
docker compose ps
```

This is a process-termination/restart test, not a simulation of every possible crash. Perform disruptive tests only when players are disconnected and world data is not at risk.

## Security notes

- Never commit `.env`, passwords, SSH private keys, tokens, or actual private addresses.
- Do not publish an `EULA=true` setting as if it automatically represents another user's acceptance; `.env.example` should use `EULA=false`.
- Keep Minecraft `online-mode=true` for public network access.
- Prefer `WHITE_LIST=true` on a private server. Disabling it lets other authenticated users join if they know the address.
- Keep the Minecraft server binary and Docker base image updated; review licensing before redistributing `server.jar`, especially in a public repository.
- Back up the named volume before important updates or destructive tests.

## References

- [Minecraft Java server download](https://www.minecraft.net/en-us/download/server)
- [Minecraft EULA](https://www.minecraft.net/eula)
- [Minecraft Wiki — Server properties](https://minecraft.wiki/w/Server.properties)
- [Minecraft Wiki — Whitelist](https://minecraft.wiki/w/Whitelist)
- [Docker Docs — Compose services (`env_file`, `restart`)](https://docs.docker.com/reference/compose-file/services/)
- [Docker Docs — Set environment variables](https://docs.docker.com/compose/how-tos/environment-variables/set-environment-variables/)
- [Docker Docs — Volumes](https://docs.docker.com/engine/storage/volumes/)
- [Docker Docs — Restart policies](https://docs.docker.com/engine/containers/start-containers-automatically/)
- [mcstatus — Python package](https://pypi.org/project/mcstatus/)
