#!/data/data/com.termux/files/usr/bin/bash
# ================================================================
# PERISTYLE OS v3.0 :: HOME SCREEN SHORTCUT INSTALLER
# Moto G 2025 XT2513-2 | Termux:Widget + Launcher Icon
# ================================================================

R="\033[0m"; G="\033[38;5;46m"; D="\033[38;5;35m"
C="\033[38;5;51m"; O="\033[38;5;214m"; RE="\033[38;5;196m"
B="\033[1m"

echo -e "${G}${B}"
echo "  ____  _____ ____  ___ ____ _____ _____ _     _____"
echo " |  _ \| ____|  _ \|_ _/ ___|_   _|_   _| |   | ____|"
echo " | |_) |  _| | |_) || |\___ \ | |   | | | |   |  _|"
echo " |  __/| |___|  _ < | | ___) || |   | | | |___| |___"
echo " |_|   |_____|_| \_|___|____/ |_|   |_| |_____|_____|"
echo -e "${R}${D}"
echo "  HOME SCREEN SHORTCUT INSTALLER"
echo "  Moto G 2025 XT2513-2 | Termux:Widget"
echo -e "${R}"
echo -e "${D}────────────────────────────────────────────────────────${R}\n"

# ── Check Peristyle binary exists ─────────────────────────────
BINARY="$HOME/peristyle/peristyle_v3"
if [ ! -f "$BINARY" ]; then
    echo -e "${RE}[ERR]${R} Peristyle OS binary not found at $BINARY"
    echo -e "${D}Run the main setup script first:${R}"
    echo -e "  ${G}bash ~/peristyle_setup.sh${R}\n"
    exit 1
fi
echo -e "${G}[ OK ]${R} Peristyle OS binary found: $BINARY"

# ── Step 1: Install Termux:Widget ─────────────────────────────
echo -e "\n${G}[1/4]${R} Installing termux-widget support..."
pkg install -y termux-widget 2>&1 | tail -3
echo -e "${G}[ OK ]${R} termux-widget installed."

# ── Step 2: Create .shortcuts directory ───────────────────────
echo -e "\n${G}[2/4]${R} Creating Termux shortcuts directory..."
SHORTCUT_DIR="$HOME/.shortcuts"
mkdir -p "$SHORTCUT_DIR"
chmod 700 "$SHORTCUT_DIR"
echo -e "${G}[ OK ]${R} $SHORTCUT_DIR ready."

# ── Step 3: Write the shortcut launch script ──────────────────
echo -e "\n${G}[3/4]${R} Writing shortcut script..."

cat > "$SHORTCUT_DIR/Peristyle OS" << 'LAUNCHEOF'
#!/data/data/com.termux/files/usr/bin/bash
# Peristyle OS v3.0 - Home Screen Launch Script
clear
echo -e "\033[38;5;46m\033[1m"
echo "  Launching PERISTYLE OS v3.0..."
echo "  KURFEW KULT FINAL CODEX"
echo -e "\033[0m"
sleep 0.5
exec $HOME/peristyle/peristyle_v3
LAUNCHEOF

chmod +x "$SHORTCUT_DIR/Peristyle OS"
echo -e "${G}[ OK ]${R} Shortcut script written: $SHORTCUT_DIR/Peristyle OS"

# ── Step 4: Write the bash alias + .bashrc entry ──────────────
echo -e "\n${G}[4/4]${R} Setting up shell alias..."

BASHRC="$HOME/.bashrc"
ALIAS_LINE="alias peristyle='$BINARY'"
MOTD_LINE="peristyle_motd"

# Remove old entries if they exist
grep -v "alias peristyle=" "$BASHRC" > /tmp/.bashrc_tmp 2>/dev/null && mv /tmp/.bashrc_tmp "$BASHRC"
grep -v "peristyle_motd"   "$BASHRC" > /tmp/.bashrc_tmp 2>/dev/null && mv /tmp/.bashrc_tmp "$BASHRC"
grep -v "peristyle_v3"     "$BASHRC" > /tmp/.bashrc_tmp 2>/dev/null && mv /tmp/.bashrc_tmp "$BASHRC"

# Write MOTD function + alias
cat >> "$BASHRC" << 'BASHEOF'

# ── PERISTYLE OS v3.0 ──────────────────────────────────────────
alias peristyle='$HOME/peristyle/peristyle_v3'
alias p3='$HOME/peristyle/peristyle_v3'

peristyle_motd() {
    echo -e "\033[38;5;35m"
    echo "  ┌─────────────────────────────────────────┐"
    echo "  │  PERISTYLE OS v3.0  ::  KURFEW KULT     │"
    echo "  │  Type: peristyle  or  p3  to launch     │"
    echo "  └─────────────────────────────────────────┘"
    echo -e "\033[0m"
}
peristyle_motd
BASHEOF

echo -e "${G}[ OK ]${R} Alias added: ${G}peristyle${R} and ${G}p3${R}"

# ── Step 5: Create notification shortcut via termux-notification
echo -e "\n${G}[BONUS]${R} Creating persistent notification launcher..."
if command -v termux-notification &>/dev/null; then
    termux-notification \
        --id 3141 \
        --title "PERISTYLE OS v3.0" \
        --content "Tap to launch Kurfew Kult Final Codex" \
        --button1 "LAUNCH" \
        --button1-action "termux-open-url termux://run-command?path=$HOME/.shortcuts/Peristyle%20OS" \
        --ongoing 2>/dev/null
    echo -e "${G}[ OK ]${R} Persistent notification launcher created."
else
    echo -e "${D}[SKIP]${R} termux-notification not available (install termux-api for this feature)."
fi

# ── Done ──────────────────────────────────────────────────────
echo -e "\n${G}${B}"
echo "  ════════════════════════════════════════════════════"
echo "  SHORTCUT INSTALL COMPLETE"
echo "  ════════════════════════════════════════════════════"
echo -e "${R}"
echo -e "${D}You now have 3 ways to launch Peristyle OS:${R}\n"
echo -e "  ${G}1. HOME SCREEN WIDGET${R}"
echo -e "     ${D}→ Long-press home screen${R}"
echo -e "     ${D}→ Tap Widgets${R}"
echo -e "     ${D}→ Find 'Termux:Widget'${R}"
echo -e "     ${D}→ Place it → tap 'Peristyle OS'${R}\n"
echo -e "  ${G}2. TERMINAL ALIAS${R}"
echo -e "     ${D}→ Open Termux, type:${R} ${G}peristyle${R}"
echo -e "     ${D}→ Or short form:${R}   ${G}p3${R}\n"
echo -e "  ${G}3. DIRECT PATH${R}"
echo -e "     ${D}→${R} ${G}~/peristyle/peristyle_v3${R}\n"
echo -e "${D}────────────────────────────────────────────────────────${R}"
echo -e "${O}Apply alias now? (reload .bashrc) [y/N]:${R} \c"
read -r RELOAD
if [[ "$RELOAD" =~ ^[Yy]$ ]]; then
    source "$HOME/.bashrc"
    echo -e "${G}[ OK ]${R} Shell reloaded. Type ${G}peristyle${R} to launch.\n"
fi
