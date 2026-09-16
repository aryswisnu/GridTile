#!/bin/bash
# Creates a self-signed code-signing certificate "GridTile Dev" in the login keychain, once.
# Signing with it keeps the same designated requirement across builds, so the Accessibility
# grant survives rebuilds. Usage: ./scripts/make-signing-cert.sh && CODESIGN_IDENTITY="GridTile Dev" ./build.sh
set -euo pipefail
NAME="GridTile Dev"
if security find-identity -v -p codesigning | grep -q "$NAME"; then
  echo "identity '$NAME' already exists"; exit 0
fi
T=$(mktemp -d)
cat > "$T/ext.cnf" <<EOF
[req]
distinguished_name = dn
x509_extensions = ext
prompt = no
[dn]
CN = $NAME
[ext]
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, codeSigning
basicConstraints = critical, CA:false
EOF
openssl req -x509 -newkey rsa:2048 -nodes -days 3650 -config "$T/ext.cnf" \
  -keyout "$T/key.pem" -out "$T/cert.pem" 2>/dev/null
openssl pkcs12 -export -inkey "$T/key.pem" -in "$T/cert.pem" -out "$T/id.p12" -passout pass:gridtile \
  -keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -macalg sha1
KC="$HOME/Library/Keychains/login.keychain-db"
security import "$T/id.p12" -k "$KC" -P gridtile -T /usr/bin/codesign -T /usr/bin/security >/dev/null
# Trust it for code signing at user level (may show one password dialog).
security add-trusted-cert -r trustRoot -p codeSign -k "$KC" "$T/cert.pem"
rm -rf "$T"
security find-identity -v -p codesigning | grep "$NAME" && echo "created '$NAME'"
