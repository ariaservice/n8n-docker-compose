#!/bin/bash

# n8n Docker Compose Installation Script with SSL
# Domain: n8n.ariaservice.online
# Author: Auto-generated setup script
# Date: $(date)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables
DOMAIN="n8n.ariaservice.online"
EMAIL="admin@ariaservice.online"  # Change this to your email
N8N_USER="admin"
N8N_PASSWORD=""
DB_PASSWORD=""
ENCRYPTION_KEY=""

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  n8n Docker Installation with SSL Setup${NC}"
echo -e "${BLUE}  Domain: ${DOMAIN}${NC}"
echo -e "${BLUE}================================================${NC}"

# Function to generate random password
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

# Function to generate encryption key
generate_encryption_key() {
    openssl rand -hex 16
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo -e "${RED}This script should not be run as root for security reasons${NC}"
   echo -e "${YELLOW}Please run as a regular user with sudo privileges${NC}"
   exit 1
fi

# Check if domain is pointing to this server
echo -e "${BLUE}Checking domain DNS resolution...${NC}"
DOMAIN_IP=$(dig +short $DOMAIN)
SERVER_IP=$(curl -s ifconfig.me)

if [ "$DOMAIN_IP" != "$SERVER_IP" ]; then
    echo -e "${RED}Warning: Domain $DOMAIN does not point to this server IP ($SERVER_IP)${NC}"
    echo -e "${YELLOW}Current domain IP: $DOMAIN_IP${NC}"
    echo -e "${YELLOW}Please update your DNS records before continuing${NC}"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Update system
echo -e "${BLUE}Updating system packages...${NC}"
sudo apt update && sudo apt upgrade -y

# Install required packages
echo -e "${BLUE}Installing required packages...${NC}"
sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    ufw \
    fail2ban \
    unzip \
    wget

# Install Docker
echo -e "${BLUE}Installing Docker...${NC}"
if ! command -v docker &> /dev/null; then
    # Add Docker's official GPG key
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    # Add Docker repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker Engine
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Add current user to docker group
    sudo usermod -aG docker $USER
    
    echo -e "${GREEN}Docker installed successfully${NC}"
else
    echo -e "${GREEN}Docker is already installed${NC}"
fi

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Create project directory
PROJECT_DIR="/opt/n8n"
echo -e "${BLUE}Creating project directory: $PROJECT_DIR${NC}"
sudo mkdir -p $PROJECT_DIR
sudo chown $USER:$USER $PROJECT_DIR
cd $PROJECT_DIR

# Generate passwords and keys
echo -e "${BLUE}Generating secure passwords and keys...${NC}"
N8N_PASSWORD=$(generate_password)
DB_PASSWORD=$(generate_password)
ENCRYPTION_KEY=$(generate_encryption_key)

echo -e "${GREEN}Generated credentials (save these securely):${NC}"
echo -e "${YELLOW}N8N Username: $N8N_USER${NC}"
echo -e "${YELLOW}N8N Password: $N8N_PASSWORD${NC}"
echo -e "${YELLOW}Database Password: $DB_PASSWORD${NC}"
echo -e "${YELLOW}Encryption Key: $ENCRYPTION_KEY${NC}"

# Create .env file
echo -e "${BLUE}Creating environment configuration...${NC}"
cat > .env << EOF
# Domain Configuration
DOMAIN_NAME=$DOMAIN
SUBDOMAIN=n8n
DOMAIN_EMAIL=$EMAIL

# n8n Configuration
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=$N8N_USER
N8N_BASIC_AUTH_PASSWORD=$N8N_PASSWORD
N8N_HOST=0.0.0.0
N8N_PORT=5678
N8N_PROTOCOL=http
WEBHOOK_URL=https://$DOMAIN
N8N_EDITOR_BASE_URL=https://$DOMAIN

# Security
N8N_ENCRYPTION_KEY=$ENCRYPTION_KEY

# Database Configuration
POSTGRES_USER=n8n
POSTGRES_PASSWORD=$DB_PASSWORD
POSTGRES_DB=n8n
POSTGRES_NON_ROOT_USER=n8n
POSTGRES_NON_ROOT_PASSWORD=$DB_PASSWORD

# Timezone
GENERIC_TIMEZONE=Asia/Tehran
TZ=Asia/Tehran

# Additional Settings
N8N_METRICS=true
N8N_LOG_LEVEL=info
N8N_LOG_OUTPUT=console
EOF

# Create docker-compose.yml
echo -e "${BLUE}Creating Docker Compose configuration...${NC}"
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  traefik:
    image: traefik:v2.10
    container_name: traefik
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080"  # Traefik dashboard (remove in production)
    environment:
      - TRAEFIK_API_DASHBOARD=true
      - TRAEFIK_API_INSECURE=true
      - TRAEFIK_PROVIDERS_DOCKER=true
      - TRAEFIK_PROVIDERS_DOCKER_EXPOSEDBYDEFAULT=false
      - TRAEFIK_ENTRYPOINTS_WEB_ADDRESS=:80
      - TRAEFIK_ENTRYPOINTS_WEBSECURE_ADDRESS=:443
      - TRAEFIK_CERTIFICATESRESOLVERS_MYRESOLVER_ACME_TLSCHALLENGE=true
      - TRAEFIK_CERTIFICATESRESOLVERS_MYRESOLVER_ACME_EMAIL=${DOMAIN_EMAIL}
      - TRAEFIK_CERTIFICATESRESOLVERS_MYRESOLVER_ACME_STORAGE=/letsencrypt/acme.json
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./traefik/letsencrypt:/letsencrypt
    networks:
      - n8n-network
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.traefik.rule=Host(`traefik.${DOMAIN_NAME}`)"
      - "traefik.http.routers.traefik.tls.certresolver=myresolver"
      - "traefik.http.middlewares.redirect-to-https.redirectscheme.scheme=https"
      - "traefik.http.routers.redirect-https.rule=hostregexp(`{host:.+}`)"
      - "traefik.http.routers.redirect-https.entrypoints=web"
      - "traefik.http.routers.redirect-https.middlewares=redirect-to-https"

  postgres:
    image: postgres:15-alpine
    container_name: n8n_postgres
    restart: unless-stopped
    environment:
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=${POSTGRES_DB}
      - POSTGRES_NON_ROOT_USER=${POSTGRES_NON_ROOT_USER}
      - POSTGRES_NON_ROOT_PASSWORD=${POSTGRES_NON_ROOT_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./postgres/init-data.sh:/docker-entrypoint-initdb.d/init-data.sh
    networks:
      - n8n-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 10s
      timeout: 5s
      retries: 5

  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
    restart: unless-stopped
    environment:
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=${POSTGRES_DB}
      - DB_POSTGRESDB_USER=${POSTGRES_NON_ROOT_USER}
      - DB_POSTGRESDB_PASSWORD=${POSTGRES_NON_ROOT_PASSWORD}
      - N8N_BASIC_AUTH_ACTIVE=${N8N_BASIC_AUTH_ACTIVE}
      - N8N_BASIC_AUTH_USER=${N8N_BASIC_AUTH_USER}
      - N8N_BASIC_AUTH_PASSWORD=${N8N_BASIC_AUTH_PASSWORD}
      - N8N_HOST=${N8N_HOST}
      - N8N_PORT=${N8N_PORT}
      - N8N_PROTOCOL=${N8N_PROTOCOL}
      - WEBHOOK_URL=${WEBHOOK_URL}
      - N8N_EDITOR_BASE_URL=${N8N_EDITOR_BASE_URL}
      - N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}
      - GENERIC_TIMEZONE=${GENERIC_TIMEZONE}
      - TZ=${TZ}
      - N8N_METRICS=${N8N_METRICS}
      - N8N_LOG_LEVEL=${N8N_LOG_LEVEL}
      - N8N_LOG_OUTPUT=${N8N_LOG_OUTPUT}
    ports:
      - "5678:5678"
    volumes:
      - n8n_data:/home/node/.n8n
    networks:
      - n8n-network
    depends_on:
      postgres:
        condition: service_healthy
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.n8n.rule=Host(`${DOMAIN_NAME}`)"
      - "traefik.http.routers.n8n.tls.certresolver=myresolver"
      - "traefik.http.routers.n8n.entrypoints=websecure"
      - "traefik.http.services.n8n.loadbalancer.server.port=5678"

volumes:
  n8n_data:
  postgres_data:

networks:
  n8n-network:
    driver: bridge
EOF

# Create Traefik directory
mkdir -p traefik/letsencrypt

# Create PostgreSQL init script
mkdir -p postgres
cat > postgres/init-data.sh << 'EOF'
#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE USER $POSTGRES_NON_ROOT_USER WITH PASSWORD '$POSTGRES_NON_ROOT_PASSWORD';
    GRANT ALL PRIVILEGES ON DATABASE $POSTGRES_DB TO $POSTGRES_NON_ROOT_USER;
    GRANT ALL PRIVILEGES ON SCHEMA public TO $POSTGRES_NON_ROOT_USER;
    ALTER USER $POSTGRES_NON_ROOT_USER CREATEDB;
EOSQL
EOF

chmod +x postgres/init-data.sh

# Configure firewall
echo -e "${BLUE}Configuring firewall...${NC}"
sudo ufw --force enable
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 8080/tcp  # Traefik dashboard (remove in production)

# Create management script
echo -e "${BLUE}Creating management script...${NC}"
cat > manage.sh << 'EOF'
#!/bin/bash

# n8n Management Script

case "$1" in
    start)
        echo "Starting n8n services..."
        docker compose up -d
        ;;
    stop)
        echo "Stopping n8n services..."
        docker compose down
        ;;
    restart)
        echo "Restarting n8n services..."
        docker compose down
        docker compose up -d
        ;;
    logs)
        docker compose logs -f "${2:-n8n}"
        ;;
    status)
        docker compose ps
        ;;
    update)
        echo "Updating n8n..."
        docker compose pull
        docker compose up -d
        ;;
    backup)
        echo "Creating backup..."
        mkdir -p backups
        docker compose exec postgres pg_dump -U n8n n8n > "backups/n8n_backup_$(date +%Y%m%d_%H%M%S).sql"
        docker run --rm -v n8n_n8n_data:/data -v $(pwd)/backups:/backup alpine tar czf "/backup/n8n_data_backup_$(date +%Y%m%d_%H%M%S).tar.gz" -C /data .
        echo "Backup completed in ./backups/"
        ;;
    restore)
        if [ -z "$2" ]; then
            echo "Usage: $0 restore <backup_file.sql>"
            exit 1
        fi
        echo "Restoring from $2..."
        docker compose exec -T postgres psql -U n8n n8n < "$2"
        ;;
    shell)
        docker compose exec "${2:-n8n}" /bin/bash
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|logs|status|update|backup|restore|shell} [service]"
        echo ""
        echo "Commands:"
        echo "  start    - Start all services"
        echo "  stop     - Stop all services"  
        echo "  restart  - Restart all services"
        echo "  logs     - Show logs (optionally specify service)"
        echo "  status   - Show service status"
        echo "  update   - Update n8n to latest version"
        echo "  backup   - Create database and data backup"
        echo "  restore  - Restore from SQL backup file"
        echo "  shell    - Open shell in container"
        exit 1
        ;;
esac
EOF

chmod +x manage.sh

# Set proper permissions
chmod 600 .env
chmod +x postgres/init-data.sh

# Start services
echo -e "${BLUE}Starting n8n services...${NC}"
docker compose up -d

# Wait for services to be ready
echo -e "${BLUE}Waiting for services to start...${NC}"
sleep 30

# Check service status
echo -e "${BLUE}Checking service status...${NC}"
docker compose ps

# Show final information
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  n8n Installation Completed Successfully!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo -e "${BLUE}Access Information:${NC}"
echo -e "${YELLOW}n8n URL: https://$DOMAIN${NC}"
echo -e "${YELLOW}Username: $N8N_USER${NC}"
echo -e "${YELLOW}Password: $N8N_PASSWORD${NC}"
echo ""
echo -e "${YELLOW}Traefik Dashboard: http://$(curl -s ifconfig.me):8080${NC}"
echo ""
echo -e "${BLUE}Management Commands:${NC}"
echo -e "${YELLOW}Start services: ./manage.sh start${NC}"
echo -e "${YELLOW}Stop services: ./manage.sh stop${NC}"
echo -e "${YELLOW}View logs: ./manage.sh logs${NC}"
echo -e "${YELLOW}Check status: ./manage.sh status${NC}"
echo -e "${YELLOW}Create backup: ./manage.sh backup${NC}"
echo -e "${YELLOW}Update n8n: ./manage.sh update${NC}"
echo ""
echo -e "${BLUE}Files Location:${NC}"
echo -e "${YELLOW}Project Directory: $PROJECT_DIR${NC}"
echo -e "${YELLOW}Configuration: $PROJECT_DIR/.env${NC}"
echo -e "${YELLOW}Docker Compose: $PROJECT_DIR/docker-compose.yml${NC}"
echo ""
echo -e "${RED}Important: Save your credentials securely!${NC}"
echo ""
echo -e "${GREEN}Installation completed! Please wait a few minutes for SSL certificates to be generated.${NC}"

# Save credentials to file
cat > credentials.txt << EOF
n8n Installation Credentials
============================

Domain: https://$DOMAIN
Username: $N8N_USER
Password: $N8N_PASSWORD

Database Password: $DB_PASSWORD
Encryption Key: $ENCRYPTION_KEY

Generated on: $(date)
EOF

chmod 600 credentials.txt

echo -e "${YELLOW}Credentials saved to: $PROJECT_DIR/credentials.txt${NC}"