#!/bin/sh
# Alpine Linux i3/Polybar/Rofi/Ly Setup Script
# This script installs i3 window manager with Polybar and Rofi, sets up the Ly login manager, 
# and configures X11 with optional settings (keyboard layout, resolution, multi-monitor).
# It is idempotent (safe to run multiple times). Run as root (e.g., with sudo).

set -eu

echo "== Alpine i3 Environment Setup =="

# 1. Enable community repository for needed packages:contentReference[oaicite:65]{index=65}
if grep -q "^#.*\/community" /etc/apk/repositories; then
    echo ":: Enabling Alpine community repository..."
    sed -i 's/^#\(.*\/community\)/\1/' /etc/apk/repositories
    apk update
fi

# 1. Install necessary packages (i3wm, polybar, rofi, ly, X11, terminal, etc.)
echo ":: Installing packages: i3wm, polybar, rofi, ly, X11, xfce4-terminal, etc..."
apk add --no-cache \
    i3wm xfce4-terminal \
    polybar rofi \
    ly ly-openrc \
    xorg-server xinit \
    xf86-video-vesa xf86-video-fbdev xf86-input-libinput \
    mesa-dri-gallium \
    setxkbmap xrandr autorandr \
    font-terminus dbus

# Start and enable D-Bus (for desktop features):contentReference[oaicite:66]{index=66}
rc-update add dbus default 2>/dev/null || true
rc-service dbus start 2>/dev/null || true

# Determine the non-root username for config file placement
USER_NAME="${SUDO_USER:-$USER}"
if [ "$USER_NAME" = "root" ]; then
    printf "Enter your regular (non-root) username: "
    read USER_NAME
fi
if ! id "$USER_NAME" >/dev/null 2>&1; then
    echo "ERROR: User '$USER_NAME' does not exist. Please create a user before running this script."
    exit 1
fi

# Add user to video and input groups (for X11 permissions):contentReference[oaicite:67]{index=67}
echo ":: Ensuring user '$USER_NAME' is in 'video' and 'input' groups..."
adduser "$USER_NAME" video 2>/dev/null || true
adduser "$USER_NAME" input 2>/dev/null || true

# Paths
USER_HOME="/home/$USER_NAME"
I3CFG_DIR="$USER_HOME/.config/i3"
POLYCFG_DIR="$USER_HOME/.config/polybar"
ROFICFG_DIR="$USER_HOME/.config/rofi"
I3CONFIG="$I3CFG_DIR/config"

# 2. Copy default configs for i3, polybar, rofi
echo ":: Setting up default configuration files..."
install -d -m 755 "$I3CFG_DIR" "$POLYCFG_DIR" "$ROFICFG_DIR"

if [ ! -f "$I3CFG_DIR/config" ]; then
    cp -f /etc/i3/config "$I3CFG_DIR/config"    # Default i3 config:contentReference[oaicite:68]{index=68}
    cp -f /etc/i3/config.keycodes "$I3CFG_DIR/" 2>/dev/null || true
    chown -R "$USER_NAME:" "$I3CFG_DIR"
    echo " + Default i3 config copied to $I3CFG_DIR/"
fi
if [ ! -f "$POLYCFG_DIR/config.ini" ] && [ -f /etc/polybar/config.ini ]; then
    cp -f /etc/polybar/config.ini "$POLYCFG_DIR/config.ini"   # Default polybar config:contentReference[oaicite:69]{index=69}
    chown -R "$USER_NAME:" "$POLYCFG_DIR"
    echo " + Default Polybar config copied to $POLYCFG_DIR/config.ini"
fi
if [ ! -f "$ROFICFG_DIR/config.rasi" ]; then
    # Generate default rofi config:contentReference[oaicite:70]{index=70}
    su - "$USER_NAME" -c "rofi -dump-config > $ROFICFG_DIR/config.rasi" 2>/dev/null || {
        # Fallback minimal config if rofi command fails
        echo "@theme \"default\"" > "$ROFICFG_DIR/config.rasi"
        echo "# (Generated minimal rofi config)" >> "$ROFICFG_DIR/config.rasi"
    }
    chown -R "$USER_NAME:" "$ROFICFG_DIR"
    echo " + Default Rofi config created at $ROFICFG_DIR/config.rasi"
fi

# 2b. Integrate Polybar and Rofi into i3 config
if grep -q "status_command i3status" "$I3CONFIG"; then
    echo ":: Removing default i3status bar from i3 config (using Polybar)..."
    sed -i 's/^\(bar {\)/#\1/; s/^\(}\)/#\1/; s/status_command i3status/#&/' "$I3CONFIG"
fi
if ! grep -q "polybar" "$I3CONFIG"; then
    echo ":: Adding Polybar autostart to i3 config..."
    printf "\n# Launch Polybar on i3 start\nexec_always --no-startup-id polybar example\n" >> "$I3CONFIG"
fi
if grep -q "dmenu_run" "$I3CONFIG"; then
    echo ":: Replacing dmenu with rofi in i3 config..."
    sed -i 's/exec .\?dmenu_run/exec --no-startup-id rofi -show drun/' "$I3CONFIG"
fi

# 3. X11 configuration: Xwrapper and Ly adjustments
echo ":: Configuring X11 and Ly for i3..."
if [ ! -f /etc/X11/Xwrapper.config ]; then
    echo "needs_root_rights = yes" > /etc/X11/Xwrapper.config   # Allow X as root (for Ly):contentReference[oaicite:71]{index=71}
    echo " + /etc/X11/Xwrapper.config created (X needs_root_rights=yes):contentReference[oaicite:72]{index=72}"
fi
# Configure Ly login manager (TTY and commands):contentReference[oaicite:73]{index=73}
LY_CFG="/etc/ly/config.ini"
if [ -f "$LY_CFG" ]; then
    sed -i 's/^tty *=.*/tty = 7/' "$LY_CFG"
    sed -i 's/^shutdown_cmd *=.*/shutdown_cmd = \/sbin\/poweroff/' "$LY_CFG"
    sed -i 's/^restart_cmd *=.*/restart_cmd = \/sbin\/reboot/' "$LY_CFG"
    echo " + Ly config updated (tty=7, poweroff/reboot commands):contentReference[oaicite:74]{index=74}"
fi

# 4. Interactive prompts for optional settings
# 4a. Keyboard layout
read -p ">> Enter desired keyboard layout (e.g., us, de, fr) or press Enter to skip: " KB
if [ -n "$KB" ]; then
    if ! grep -q "setxkbmap $KB" "$I3CONFIG"; then
        echo ":: Setting keyboard layout to '$KB' in i3 config..."
        printf "\n# Keyboard layout\nexec_always --no-startup-id setxkbmap %s\n" "$KB" >> "$I3CONFIG"
    fi
fi

# 4b. Screen Resolution prompt (using DRM sysfs, no X required)
echo ">> Screen Resolution Configuration (via /sys/class/drm)"
if [ -d /sys/class/drm ]; then
    for status in /sys/class/drm/*/status; do
        if grep -q connected "$status"; then
            conn=$(basename "$(dirname "$status")")
            echo "  • $conn"
            modefile="/sys/class/drm/$conn/modes"
            if [ -f "$modefile" ]; then
                while IFS= read -r mode; do
                    echo "     └ mode: $mode"
                done < "$modefile"
            else
                echo "     (no modes listed)"
            fi
        fi
    done
else
    echo "   ⚠️  /sys/class/drm not found; cannot list connectors."
fi

printf ">> Enter the output name to configure (e.g. HDMI-A-1): "
read DISP
if [ -n "$DISP" ]; then
    printf ">> Enter desired resolution for %s (e.g. 1920x1080): " "$DISP"
    read RES
    if [ -n "$RES" ]; then
        if ! grep -q "xrandr --output $DISP" "$I3CONFIG"; then
            echo ">> Adding xrandr command for $DISP $RES in i3 config..."
            printf "\n# Set screen resolution for $DISP\nexec_always --no-startup-id xrandr --output %s --mode %s\n" \
                "$DISP" "$RES" >> "$I3CONFIG"
        fi
    fi
fi

# 4c. Multi-monitor auto-detection (autorandr)
read -p ">> Enable autorandr for multi-monitor auto-detect? [y/N]: " MULTI
if echo "$MULTI" | grep -iq "^y"; then
    if ! grep -q "autorandr --change" "$I3CONFIG"; then
        echo ":: Enabling autorandr in i3 config (auto multi-monitor)..."
        printf "\n# Multi-monitor auto-detect\nexec_always --no-startup-id autorandr --change --default default\n" >> "$I3CONFIG"
    fi
    echo "   Tip: After logging into i3, arrange monitors and run 'autorandr --save default' to save default layout:contentReference[oaicite:76]{index=76}"
fi

# 5. Enable Ly login manager on boot (optional)
read -p ">> Enable Ly (login manager) at boot? [Y/n]: " ENABLE_LY
if [ -z "$ENABLE_LY" ] || echo "$ENABLE_LY" | grep -iq "^y"; then
    rc-update add ly default 2>/dev/null || true
    echo ":: Ly service enabled (will start at boot).:contentReference[oaicite:77]{index=77}"
    echo "   - On reboot, Ly will start on tty7. If X fails, switch to tty1 (Ctrl+Alt+F1) to troubleshoot."
else
    echo ":: Ly not enabled. You can use startx to start i3 manually."
fi

# 6. .xinitrc setup for fallback startx usage:contentReference[oaicite:78]{index=78}
XINITRC="$USER_HOME/.xinitrc"
if [ ! -f "$XINITRC" ]; then
    echo ":: Creating $XINITRC for startx fallback..."
    cat > "$XINITRC" << 'EOF'
#!/bin/sh
# ~/.xinitrc - start i3 on X initiation
exec i3
EOF
    chown "$USER_NAME:" "$XINITRC"
    chmod +x "$XINITRC"
    echo " + $XINITRC created (executes i3):contentReference[oaicite:79]{index=79}"
fi

echo "== Setup Complete! =="
echo "You can now reboot to use Ly login (or run 'startx' for a test). Enjoy i3 with Polybar and Rofi!"
