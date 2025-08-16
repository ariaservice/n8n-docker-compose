# AI Assistant Instructions for n8n Installation Script

## Project Overview
This repository contains an automated installation script for n8n workflow automation platform using Docker Compose. The project focuses on secure, production-ready deployment with SSL, reverse proxy, and database setup.

## Key Components

### Core Files
- `install.sh`: Main installation script accepting domain and email parameters
- `manage.sh`: Generated management script for day-to-day operations
- `docker-compose.yml`: Service definitions for n8n, PostgreSQL, and Traefik
- `.env`: Environment configuration generated during installation

### Architecture
- **Traefik**: Handles SSL termination and reverse proxy
- **PostgreSQL**: Persistent database for n8n workflows
- **n8n**: Main application container with mounted volumes
- **Security Layer**: UFW firewall and Fail2Ban integration

## Development Workflows

### Installation Script Modifications
1. Command-line arguments follow this pattern:
```bash
./install.sh <domain> <email>
```

2. Environment variables are set in this section:
```bash
# Configuration variables
DOMAIN="$1"
EMAIL="$2"
N8N_USER="admin"
```

### Testing Changes
1. Test script in a clean environment:
```bash
# Create test VM/container
# Run installation
./install.sh test.domain.com admin@test.com
```

2. Verify service health:
```bash
./manage.sh status
./manage.sh logs
```

## Project Conventions

### Script Structure
1. Command-line validation before any operations
2. Functions defined at the top
3. Main execution flow at bottom
4. Clear section comments for navigation

### Security Practices
- All passwords/keys randomly generated
- Credentials stored in restricted `credentials.txt`
- SSL certificates auto-renewed
- Firewall configured by default

### Error Handling
- `set -e` ensures script stops on errors
- Each major step has error checking
- Clear error messages with color coding

## Integration Points

### External Services
1. Let's Encrypt for SSL certificates
2. Docker Hub for container images
3. PostgreSQL for data persistence

### Cross-Component Communication
- Services communicate through Docker network
- Traefik routes traffic based on domain
- Database connections use internal Docker DNS

## Common Tasks

### Adding New Features
1. Update `install.sh` with new configuration
2. Add corresponding Docker services if needed
3. Update management script commands
4. Document in README.md

### Troubleshooting
- Check service logs with `./manage.sh logs <service>`
- Verify domain DNS with `dig +short <domain>`
- Monitor SSL status through Traefik dashboard

## Key Files to Study
- `install.sh`: Main entry point and configuration
- `README.md`: Usage examples and management commands
- Generated `docker-compose.yml`: Service architecture
- Generated `manage.sh`: Common operations
