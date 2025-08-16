# n8n Docker Compose Installation Script

This repository provides an automated Bash script to install [n8n](https://n8n.io/) with Docker Compose, SSL via Traefik, PostgreSQL, and essential security tools on an Ubuntu server.

## Prerequisites

- Ubuntu server (20.04/22.04)
- Domain name pointing to your server's public IP
- Non-root user with sudo privileges
- Port 80 and 443 available

## Quick Start

1. **Download the script:**
   ```bash
   curl -O https://raw.githubusercontent.com/ariaservice/n8n-docker-compose/refs/heads/main/install.sh
   chmod +x install.sh
   ```

2. **Run the installation:**
   ```bash
   ./install.sh your-domain.com your-email@domain.com
   ```

## Usage Examples

```bash
# Basic installation
./install.sh n8n.example.com admin@example.com

# View help
./install.sh
```

## Management Commands

After installation, use the `manage.sh` script to control your n8n instance:

```bash
# Start all services
./manage.sh start

# Stop all services
./manage.sh stop

# View logs
./manage.sh logs
./manage.sh logs n8n    # View n8n logs specifically
./manage.sh logs traefik # View traefik logs

# Check service status
./manage.sh status

# Update n8n to latest version
./manage.sh update

# Create backup
./manage.sh backup

# Restore from backup
./manage.sh restore backup_file.sql

# Access container shell
./manage.sh shell
./manage.sh shell n8n     # n8n container
./manage.sh shell postgres # database container
```

## File Locations

```
/opt/n8n/
├── .env                    # Environment configuration
├── docker-compose.yml      # Docker services configuration
├── manage.sh              # Management script
├── credentials.txt        # Generated credentials (secured)
├── traefik/              # Traefik configuration
└── postgres/             # PostgreSQL initialization
```

## Security Notes

1. **Credentials:**
   - Saved in `/opt/n8n/credentials.txt`
   - File permissions set to 600 (owner read/write only)
   - Save credentials in a secure location and delete the file

2. **Firewall:**
   - Ports 80 (HTTP) and 443 (HTTPS) are open
   - Port 8080 (Traefik dashboard) is open - consider restricting in production
   - SSH port (22) remains accessible

3. **SSL/TLS:**
   - Automatic SSL certificate generation via Let's Encrypt
   - Automatic renewal handled by Traefik

## Troubleshooting

1. **DNS Issues:**
   ```bash
   # Check if domain points to server
   dig +short your-domain.com
   # Should match your server IP
   curl ifconfig.me
   ```

2. **Service Issues:**
   ```bash
   # Check service status
   ./manage.sh status
   
   # View logs
   ./manage.sh logs
   ```

3. **Common Problems:**
   - Error 502: Services still starting (wait 1-2 minutes)
   - SSL not working: Check DNS settings and wait 5 minutes
   - Database connection failed: Check postgres logs with `./manage.sh logs postgres`

## Backup and Recovery

1. **Create Backup:**
   ```bash
   ./manage.sh backup
   # Backs up both database and n8n data to /opt/n8n/backups/
   ```

2. **Restore Backup:**
   ```bash
   ./manage.sh restore /opt/n8n/backups/backup_file.sql
   ```

## Updates

1. **Update n8n:**
   ```bash
   ./manage.sh update
   ```

2. **Update all services:**
   ```bash
   docker compose pull
   docker compose up -d
   ```

## License

This script is provided as-is under the MIT License. Use at your own risk.

## Support

- For n8n issues: [n8n Documentation](https://docs.n8n.io/)
- For script issues: Open an issue in this repository
- For general help: [n8n Community Forum](https://community.n8n.io/)