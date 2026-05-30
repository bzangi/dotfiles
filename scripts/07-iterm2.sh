#!/usr/bin/env bash
# Sincroniza o iTerm2 com a pasta do repo via mecanismo nativo "custom prefs folder":
# lê no launch + salva automaticamente no quit. NÃO usa symlink do plist (o cfprefsd
# reescreve/ignora symlinks em ~/Library/Preferences). Idempotente.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ITERM_DIR="$REPO_ROOT/iterm2"
DOMAIN="com.googlecode.iterm2"

if [[ ! -f "$ITERM_DIR/$DOMAIN.plist" ]]; then
  echo "✗ $ITERM_DIR/$DOMAIN.plist não encontrado — capture o plist primeiro" >&2
  exit 1
fi

# iTerm2 vem do Brewfile (02-brew). Se não está instalado, não há o que apontar.
if [[ ! -d "/Applications/iTerm.app" ]]; then
  echo "ℹ iTerm2 não instalado (vem do Brewfile via 02-brew). Skip."
  exit 0
fi

# Sync bidirecional:
#  - LoadPrefsFromCustomFolder: o iTerm LÊ as prefs da pasta no launch.
#  - Save automático no quit (sem prompt): grava as prefs de volta na pasta ao sair.
#    O iTerm filtra keys voláteis (prefixos NoSync/NS/SU/UK), então o arquivo só muda
#    quando você altera uma config real → diffs limpos. Grava em XML (legível).
#    Confirmado no source iTermRemotePreferences.m: shouldSaveAutomatically (l.313-317)
#    exige Selection==Always(2) + HaveSelection; o filtro syncable está em l.105-108.
defaults write "$DOMAIN" PrefsCustomFolder -string "$ITERM_DIR"
defaults write "$DOMAIN" LoadPrefsFromCustomFolder -bool true

# Save-on-quit "Always", sem perguntar: HaveSelection=true + Selection=2 (Always).
# Estas keys são NoSync* (locais por máquina), então o script as seta em cada máquina.
defaults write "$DOMAIN" NoSyncNeverRemindPrefsChangesLostForFile -bool true
defaults write "$DOMAIN" NoSyncNeverRemindPrefsChangesLostForFile_selection -int 2

echo "✓ iTerm2 sincronizado com $ITERM_DIR (lê no launch + salva no quit, automático)."
echo "ℹ Toma efeito no próximo launch. Se o iTerm estiver aberto, saia (Cmd-Q) e reabra."
