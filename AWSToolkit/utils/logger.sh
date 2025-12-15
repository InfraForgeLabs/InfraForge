#!/bin/bash
# Simple logging utility
log_info()    { echo -e "${CYAN}[INFO]$(date '+ %T')${NC} $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]$(date '+ %T')${NC} $*"; }
log_error()   { echo -e "${RED}[ERROR]$(date '+ %T')${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]$(date '+ %T')${NC} $*"; }
