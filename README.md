# n8n Docker Compose Installation Script

This repository provides an automated Bash script to install [n8n](https://n8n.io/) with Docker Compose, SSL via Traefik, PostgreSQL, and essential security tools on an Ubuntu server.

## Features

- Automated installation of Docker, Docker Compose, Traefik (reverse proxy with SSL), PostgreSQL, and n8n.
- Secure password and encryption key generation.
- Firewall configuration (UFW) and Fail2Ban setup.
- Environment and Docker Compose configuration files are auto-generated.
- Management script (`manage.sh`) for starting, stopping, updating, backing up, and restoring n8n services.
- Credentials saved securely to `credentials.txt`.

## Prerequisites

- Ubuntu server (tested on 20.04/22.04).
- Domain name pointing to your server's public IP.
- Non-root user with sudo privileges.

## Usage

1. **Clone or copy the script to your server.**

2. **Run the installation script:**
   ```bash
   bash install.sh
   ```

3. **Follow the prompts:**
   - The script checks if your domain points to your server.
   - Installs required packages and Docker.
   - Sets up Traefik, PostgreSQL, and n8n using Docker Compose.
   - Configures firewall and security settings.
   - Generates credentials and saves them to `credentials.txt`.

4. **Access n8n:**
   - Visit `https://<your-domain>` in your browser.
   - Credentials are shown at the end of the installation and saved in `credentials.txt`.

5. **Manage your n8n stack:**
   - Use the management script:
     ```bash
     ./manage.sh start      # Start all services
     ./manage.sh stop       # Stop all services
     ./manage.sh restart    # Restart all services
     ./manage.sh logs       # View logs
     ./manage.sh status     # Check service status
     ./manage.sh update     # Update n8n to latest version
     ./manage.sh backup     # Create database and data backup
     ./manage.sh restore <backup_file.sql>  # Restore from SQL backup
     ./manage.sh shell      # Open shell in container
     ```

## Files Generated

- `.env` – Environment variables for Docker Compose.
- `docker-compose.yml` – Docker Compose configuration.
- `manage.sh` – Management script for n8n services.
- `credentials.txt` – Generated credentials (save securely).
- `traefik/letsencrypt` – SSL certificate storage.
- `postgres/init-data.sh` – PostgreSQL initialization script.

## Security Notes

- Do **not** run the script as root; use a regular user with sudo privileges.
- Save your credentials securely.
- Remove or restrict access to the Traefik dashboard (`:8080`) in production.

## Troubleshooting

- Ensure your domain DNS is correctly set up before running the script.
- If Docker is already installed, the script will skip its installation.
- For SSL certificate issues, check Traefik logs via `./manage.sh logs traefik`.

## License

This script is provided as-is, without warranty. Use at your own risk.

---

**Author:** Ariaservice Team