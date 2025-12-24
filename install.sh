#!/bin/bash
set -e

echo "=== Building TurboWM ==="
TMPDIR="$HOME" make -j$(nproc)

echo ""
echo "=== Installing TurboWM ==="
sudo cp tbwm /usr/local/bin/
sudo chmod 755 /usr/local/bin/tbwm

# Create wayland-sessions directory if it doesn't exist
sudo mkdir -p /usr/share/wayland-sessions

# Install session file
sudo tee /usr/share/wayland-sessions/tbwm.desktop > /dev/null << 'EOF'
[Desktop Entry]
Name=TurboWM
Comment=A Wayland compositor based on dwl with s7 Scheme configuration
Exec=/usr/local/bin/tbwm
Type=Application
EOF

echo ""
echo "=== Done! ==="
echo "TurboWM installed to /usr/local/bin/tbwm"
echo "Session file installed to /usr/share/wayland-sessions/tbwm.desktop"
echo "Log out and select 'TurboWM' from your display manager."
