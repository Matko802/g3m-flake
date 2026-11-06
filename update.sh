#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
VERSION="${1:?Usage: ./update.sh <version>, e.g. ./update.sh 3.4.6}"
echo "Fetching G3M ${VERSION} for x86_64-linux ..."
JSON=$(nix store prefetch-file --json "https://github.com/y114git/G3M/releases/download/${VERSION}/G3M-Linux-x86_64-${VERSION}.zip")
HASH=$(echo "$JSON" | python3 -c "import json, sys; print(json.load(sys.stdin)['hash'])")
ICON_HASH=$(nix hash convert --hash-algo sha256 --to sri \
  "$(nix-prefetch-url --type sha256 "https://raw.githubusercontent.com/y114git/G3M/${VERSION}/src/assets/icons/g3m_icon.svg" 2>/dev/null)")
sed -i -E "s|version = \"[^\"]+\";|version = \"${VERSION}\";|" package.nix
python3 - "$HASH" "$ICON_HASH" <<'EOF'
import re, sys
src = open("package.nix").read()
zhash, ihash = sys.argv[1], sys.argv[2]
src = re.sub(r'(G3M-Linux-x86_64-\$\{version\}\.zip";\n\s*hash = "sha256-)[A-Za-z0-9+/=]+(")', r'\g<1>' + zhash + r'\g<2>', src)
src = re.sub(r'(g3m_icon\.svg";\n\s*hash = "sha256-)[A-Za-z0-9+/=]+(")', r'\g<1>' + ihash + r'\g<2>', src)
open("package.nix", "w").write(src)
EOF
echo "Updated package.nix to ${VERSION} (zip ${HASH}, icon ${ICON_HASH})"
echo "Rebuild to apply: nix build . || nixos-rebuild with the overlay"
