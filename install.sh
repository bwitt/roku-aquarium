#!/usr/bin/env bash
# Usage: ROKU_DEV_PASSWORD=... ./install.sh <roku-ip>   (prompts for the password if unset)
set -e
ROKU_IP="$1"; PASS="${2:-$ROKU_DEV_PASSWORD}"
[ -z "$ROKU_IP" ] && { echo "Usage: $0 <roku-ip>  (password from \$ROKU_DEV_PASSWORD or prompt)"; exit 1; }
[ -z "$PASS" ] && { read -rsp "Roku dev password: " PASS; echo; }
cd "$(dirname "$0")"
rm -f /tmp/aquarium.zip
zip -qr /tmp/aquarium.zip manifest source components images
if ! RESULT=$(curl -sS --fail --user "rokudev:$PASS" --digest \
     -F "mysubmit=Install" -F "archive=@/tmp/aquarium.zip" \
     "http://$ROKU_IP/plugin_install"); then
    echo "Upload failed (wrong password, or developer mode off?)"; exit 1
fi
echo "$RESULT" | grep -oE "Install (Success|Failure)[^<]*|Identical to previous version" || echo "Uploaded, but no install status in the response"
echo "Done. Debug console: nc $ROKU_IP 8085"
