#!/bin/bash

# n8n Video Summarizer Workflow - Installation Script
# This script helps set up the complete n8n video summarization workflow

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/installation.log"

# Logging function
log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

log_info() {
    log "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    log "${GREEN}✅ $1${NC}"
}

log_warning() {
    log "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    log "${RED}❌ $1${NC}"
}

print_header() {
    log ""
    log "${BOLD}🚀 n8n Video Summarizer Workflow Installation${NC}"
    log "${BOLD}=============================================${NC}"
    log ""
}

check_requirements() {
    log_info "Checking system requirements..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is required but not installed. Please install Docker first."
        log_info "Visit: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose is required but not installed."
        log_info "Visit: https://docs.docker.com/compose/install/"
        exit 1
    fi
    
    # Check Node.js (for validation script)
    if ! command -v node &> /dev/null; then
        log_warning "Node.js not found. Skipping validation checks."
        SKIP_VALIDATION=true
    fi
    
    # Check available disk space (minimum 5GB)
    AVAILABLE_SPACE=$(df "$SCRIPT_DIR" | awk 'NR==2 {print $4}')
    REQUIRED_SPACE=5242880  # 5GB in KB
    
    if [ "$AVAILABLE_SPACE" -lt "$REQUIRED_SPACE" ]; then
        log_warning "Low disk space detected. Minimum 5GB recommended."
    fi
    
    log_success "System requirements check completed"
}

validate_configuration() {
    if [ "$SKIP_VALIDATION" = true ]; then
        log_info "Skipping configuration validation (Node.js not available)"
        return
    fi
    
    log_info "Validating workflow configuration..."
    
    if node "$SCRIPT_DIR/validate-config.js" >> "$LOG_FILE" 2>&1; then
        log_success "Configuration validation passed"
    else
        log_warning "Configuration validation found issues. Check log for details."
    fi
}

setup_directories() {
    log_info "Setting up directory structure..."
    
    # Create directories for volumes
    mkdir -p "$SCRIPT_DIR/data/n8n"
    mkdir -p "$SCRIPT_DIR/data/postgres"
    mkdir -p "$SCRIPT_DIR/data/redis"
    mkdir -p "$SCRIPT_DIR/backups"
    mkdir -p "$SCRIPT_DIR/logs"
    mkdir -p "$SCRIPT_DIR/ssl"
    mkdir -p "$SCRIPT_DIR/workflows"
    
    # Copy workflow file to workflows directory
    if [ -f "$SCRIPT_DIR/n8n-workflow.json" ]; then
        cp "$SCRIPT_DIR/n8n-workflow.json" "$SCRIPT_DIR/workflows/"
        log_success "Workflow file copied to workflows directory"
    fi
    
    # Set appropriate permissions
    chmod 755 "$SCRIPT_DIR/data"
    chmod 755 "$SCRIPT_DIR/backups"
    chmod 755 "$SCRIPT_DIR/logs"
    
    log_success "Directory structure created"
}

generate_ssl_certificates() {
    log_info "Generating self-signed SSL certificates..."
    
    if [ ! -f "$SCRIPT_DIR/ssl/cert.pem" ] || [ ! -f "$SCRIPT_DIR/ssl/key.pem" ]; then
        openssl req -x509 -newkey rsa:4096 -keyout "$SCRIPT_DIR/ssl/key.pem" \
            -out "$SCRIPT_DIR/ssl/cert.pem" -days 365 -nodes \
            -subj "/C=ID/ST=Indonesia/L=Jakarta/O=N8N Video Summarizer/CN=localhost" \
            >> "$LOG_FILE" 2>&1 || {
            log_warning "Could not generate SSL certificates. HTTPS will not be available."
            return
        }
        log_success "SSL certificates generated"
    else
        log_info "SSL certificates already exist"
    fi
}

setup_environment() {
    log_info "Setting up environment configuration..."
    
    # Create .env file if it doesn't exist
    if [ ! -f "$SCRIPT_DIR/.env" ]; then
        cat > "$SCRIPT_DIR/.env" << EOF
# n8n Video Summarizer Environment Configuration
# Generated on $(date)

# Basic Authentication
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=$(openssl rand -base64 32 | tr -d '\n')

# Database Configuration
POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d '\n')
POSTGRES_USER=n8n
POSTGRES_DB=n8n

# Redis Configuration
REDIS_PASSWORD=$(openssl rand -base64 32 | tr -d '\n')

# n8n Configuration
N8N_HOST=0.0.0.0
N8N_PORT=5678
N8N_PROTOCOL=http
WEBHOOK_URL=https://localhost/

# Timezone
GENERIC_TIMEZONE=Asia/Jakarta

# Performance Settings
N8N_PAYLOAD_DEFAULT_MAX_SIZE=16
N8N_DEFAULT_BINARY_DATA_MODE=filesystem
N8N_BINARY_DATA_TTL=24
EOF
        log_success "Environment file created with secure passwords"
    else
        log_info "Environment file already exists"
    fi
}

update_docker_compose() {
    log_info "Updating Docker Compose configuration..."
    
    # Update docker-compose.yml to use .env file
    if [ -f "$SCRIPT_DIR/docker-compose.yml" ]; then
        # Create backup
        cp "$SCRIPT_DIR/docker-compose.yml" "$SCRIPT_DIR/docker-compose.yml.backup"
        
        # Update paths to use absolute paths
        sed -i "s|./workflows|$SCRIPT_DIR/workflows|g" "$SCRIPT_DIR/docker-compose.yml"
        sed -i "s|./backups|$SCRIPT_DIR/backups|g" "$SCRIPT_DIR/docker-compose.yml"
        sed -i "s|./ssl|$SCRIPT_DIR/ssl|g" "$SCRIPT_DIR/docker-compose.yml"
        sed -i "s|./nginx.conf|$SCRIPT_DIR/nginx.conf|g" "$SCRIPT_DIR/docker-compose.yml"
        
        log_success "Docker Compose configuration updated"
    fi
}

start_services() {
    log_info "Starting n8n services..."
    
    cd "$SCRIPT_DIR"
    
    # Pull latest images
    docker-compose pull >> "$LOG_FILE" 2>&1
    
    # Start services
    docker-compose up -d >> "$LOG_FILE" 2>&1
    
    # Wait for services to be ready
    log_info "Waiting for services to initialize..."
    sleep 30
    
    # Check if services are running
    if docker-compose ps | grep -q "Up"; then
        log_success "Services started successfully"
    else
        log_error "Some services failed to start. Check logs with: docker-compose logs"
        exit 1
    fi
}

setup_n8n_credentials() {
    log_info "Setting up n8n credentials..."
    
    log_warning "Manual setup required for API credentials:"
    log "1. Access n8n at: http://localhost:5678"
    log "2. Create credentials for:"
    log "   - Google Service Account (Google Drive API)"
    log "   - OpenAI API"
    log "   - Telegram Bot API"
    log "3. Import the workflow from: $SCRIPT_DIR/workflows/n8n-workflow.json"
    log "4. Update credential IDs in the imported workflow"
}

run_tests() {
    log_info "Running post-installation tests..."
    
    # Test n8n accessibility
    if curl -f -s http://localhost:5678/healthz > /dev/null 2>&1; then
        log_success "n8n is accessible at http://localhost:5678"
    else
        log_warning "n8n may not be fully ready yet. Try accessing it in a few minutes."
    fi
    
    # Test database connection
    if docker-compose exec -T postgres pg_isready -U n8n > /dev/null 2>&1; then
        log_success "Database connection test passed"
    else
        log_warning "Database connection test failed"
    fi
}

print_summary() {
    log ""
    log "${BOLD}📋 Installation Summary${NC}"
    log "${BOLD}======================${NC}"
    log ""
    log "${GREEN}✅ n8n Video Summarizer Workflow installed successfully!${NC}"
    log ""
    log "${BOLD}🌐 Access Information:${NC}"
    log "• n8n Interface: http://localhost:5678"
    log "• Default credentials: admin / (check .env file for password)"
    log ""
    log "${BOLD}📁 Important Files:${NC}"
    log "• Workflows: $SCRIPT_DIR/workflows/"
    log "• Configuration: $SCRIPT_DIR/.env" 
    log "• Logs: $SCRIPT_DIR/logs/"
    log "• SSL Certificates: $SCRIPT_DIR/ssl/"
    log ""
    log "${BOLD}🔧 Next Steps:${NC}"
    log "1. Access n8n web interface"
    log "2. Configure API credentials (Google Drive, OpenAI, Telegram)"
    log "3. Import workflow: $SCRIPT_DIR/workflows/n8n-workflow.json"
    log "4. Update workflow credential IDs"
    log "5. Test with: $SCRIPT_DIR/test-webhook.sh"
    log ""
    log "${BOLD}📚 Documentation:${NC}"
    log "• Setup Guide: $SCRIPT_DIR/setup-guide.md"
    log "• Configuration: $SCRIPT_DIR/config-example.json"
    log "• Installation Log: $LOG_FILE"
    log ""
    log "${BOLD}🆘 Support:${NC}"
    log "• Check logs: docker-compose logs"
    log "• Restart services: docker-compose restart"
    log "• Stop services: docker-compose down"
}

cleanup_on_error() {
    log_error "Installation failed. Cleaning up..."
    docker-compose down > /dev/null 2>&1 || true
    log_info "Check installation log: $LOG_FILE"
    exit 1
}

# Main installation flow
main() {
    # Set up error handling
    trap cleanup_on_error ERR
    
    # Clear log file
    > "$LOG_FILE"
    
    print_header
    check_requirements
    validate_configuration
    setup_directories
    generate_ssl_certificates
    setup_environment
    update_docker_compose
    start_services
    setup_n8n_credentials
    run_tests
    print_summary
    
    log_success "Installation completed successfully!"
}

# Check if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi