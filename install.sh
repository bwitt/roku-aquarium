#!/usr/bin/env bash
# Usage: ./install.sh <roku-ip> <dev-password>
set -e
ROKU_IP="$1"; PASS="$2"
[ -z "$ROKU_IP" ] || [ -z "$PASS" ] && { echo "Usage: $0 <roku-ip> <dev-password>"; exit 1; }
cd "$(dirname "$0")"
rm -f /tmp/aquarium.zip
zip -qr /tmp/aquarium.zip manifest source components images
curl -s --user "rokudev:$PASS" --digest \
     -F "mysubmit=Install" -F "archive=@/tmp/aquarium.zip" \
     "http://$ROKU_IP/plugin_install" | grep -oE "Install (Success|Failure)[^<]*|Identical to previous version" || true
echo "Done. Debug console: nc $ROKU_IP 8085"
