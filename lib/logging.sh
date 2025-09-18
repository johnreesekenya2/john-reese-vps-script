#!/bin/bash

# JOHN REESE VPS - Logging Functions
# Centralized logging functionality

# Log action to file
log_action() {
    local message="$1"
    local level="${2:-INFO}"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# Log with different levels
log_info() {
    log_action "$1" "INFO"
}

log_warn() {
    log_action "$1" "WARN"
    echo -e "${YELLOW}⚠️ WARNING: $1${NC}" >&2
}

log_error() {
    log_action "$1" "ERROR"
    echo -e "${RED}❌ ERROR: $1${NC}" >&2
}

log_success() {
    log_action "$1" "SUCCESS"
    echo -e "${GREEN}✅ $1${NC}"
}

# Initialize logging
init_logging() {
    touch "$LOG_FILE"
    log_info "JOHN REESE VPS Script started"
}