#!/bin/bash

# === Warna ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# === Fungsi Helper ===
print_step() { echo -e "${BLUE}[STEP]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_info() { echo -e "${CYAN}[INFO]${NC} $1"; }

# === Cek GPU ===
print_step "Mengecek keberadaan GPU..."
if command -v nvidia-smi &> /dev/null; then
    print_info "GPU terdeteksi: $(nvidia-smi --query-gpu=name --format=csv,noheader)"
    USE_GPU=true
else
    print_warning "GPU tidak ditemukan, setup akan dijalankan menggunakan CPU"
    USE_GPU=false
fi

# === Update & Install ===
print_step "Updating system and installing dependencies..."
sudo apt update && sudo apt install -y sudo git curl
print_success "Dependencies installed"

# === Cloning ===
print_step "Cloning Boundless repository..."
git clone https://github.com/boundless-xyz/boundless
cd boundless
git checkout release-0.10
print_success "Repository cloned and checked out to release-0.10"

# === Setup Script ===
print_step "Replacing setup script..."
rm scripts/setup.sh
curl -o scripts/setup.sh https://raw.githubusercontent.com/zunxbt/boundless-prover/refs/heads/main/script.sh
chmod +x scripts/setup.sh

if $USE_GPU; then
    print_step "Running setup script (GPU)..."
    sudo ./scripts/setup.sh
else
    print_warning "Skipping GPU-specific setup script karena tidak ada GPU"
fi

# === Source Rust ===
print_step "Loading Rust environment..."
# panggil fungsi source_rust_env seperti biasa...

# === Risc Zero ===
if $USE_GPU; then
    print_step "Installing Risc Zero..."
    curl -L https://risczero.com/install | bash
    export PATH="/root/.risc0/bin:$PATH"
else
    print_warning "Skipping Risc Zero installation karena tidak ada GPU"
fi

# === rzup check tetap jalan meski pakai CPU ===
if [[ -f "$HOME/.rzup/env" ]]; then
    source "$HOME/.rzup/env"
fi
if [[ -f "/root/.risc0/env" ]]; then
    source "/root/.risc0/env"
fi

# === Rzup Install ===
if command -v rzup &> /dev/null; then
    rzup install rust
    rzup update r0vm
    print_success "Risc Zero installed"
else
    print_warning "rzup tidak ditemukan, lanjut tanpa instalasi Risc Zero"
fi

# === Cargo Install ===
if command -v cargo &> /dev/null; then
    print_info "Installing boundless-cli..."
    cargo install --locked boundless-cli
    print_success "boundless-cli installed"
else
    print_warning "Cargo tidak tersedia. Lewati instalasi CLI boundless"
fi

# === Just Broker ===
if command -v just &> /dev/null; then
    print_info "Menjalankan broker..."
    just broker up ./.env.broker.base
else
    print_warning "Command just tidak tersedia, broker tidak dijalankan"
fi

print_success "Setup selesai! Jalan dengan ${USE_GPU:+GPU}${USE_GPU:-CPU} mode."
