#!/usr/bin/env bash
set -euo pipefail

# Aplicado pelo scripts/06-macos.sh ou rodado standalone.
# 21 defaults capturados da máquina atual em 2026-05-29.

# ================================ KEYBOARD ================================
defaults write -g ApplePressAndHoldEnabled -bool false
defaults write -g InitialKeyRepeat -int 15
defaults write -g KeyRepeat -int 2
defaults write -g NSAutomaticCapitalizationEnabled -bool false
defaults write -g NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write -g NSAutomaticDashSubstitutionEnabled -bool false
defaults write -g NSAutomaticQuoteSubstitutionEnabled -bool false

# ================================ FINDER =================================
defaults write -g AppleShowAllExtensions -bool true
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true

# ============================== TRACKPAD =================================
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

# ================================ DOCK ===================================
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock tilesize -int 46
defaults write com.apple.dock magnification -bool true
defaults write com.apple.dock show-recents -bool false

# =============================== APPEARANCE ==============================
defaults write -g AppleShowScrollBars -string "Always"
defaults write -g AppleHighlightColor -string "0.698039 0.843137 1.000000 Blue"

# =============================== HOT CORNERS =============================
# Action codes: 0=none, 2=mission-control, 4=desktop, 5=screen-saver,
# 10=display-sleep, 11=launchpad, 12=notif-center, 13=lock-screen, 14=quick-note
defaults write com.apple.dock wvous-br-corner -int 14         # bottom-right = Quick Note

# ============================ SCREENCAPTURE ==============================
defaults write com.apple.screencapture type -string "jpg"

# ================== Restart de apps afetados (idempotente) ===============
killall Dock 2>/dev/null || true
killall Finder 2>/dev/null || true

echo "✓ macos/defaults.sh aplicado. Logout/reboot pra mudanças globais (key repeat) tomarem efeito completo."
