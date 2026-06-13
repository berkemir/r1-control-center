#!/usr/bin/env bash
# Creates and installs a stable self-signed code-signing certificate named
# "OpenShark Dev". Run once per machine. Subsequent rebuilds re-use the same
# identity so the Input Monitoring TCC permission persists.
set -euo pipefail

CERT_NAME="OpenShark Dev"
KEYCHAIN=~/Library/Keychains/login.keychain-db

# Already installed?
if security find-identity -v -p codesigning 2>/dev/null | grep -q "\"$CERT_NAME\""; then
    echo "✓ '$CERT_NAME' already in keychain — nothing to do."
    exit 0
fi

echo "Creating self-signed certificate '$CERT_NAME'..."

# Generate RSA key
openssl genrsa -out /tmp/openshark-key.pem 2048 2>/dev/null

# Build SAN + EKU config so codesign accepts it
cat > /tmp/openshark-cert.cfg << 'EOF'
[req]
distinguished_name = dn
x509_extensions = v3_ca
prompt = no

[dn]
CN = OpenShark Dev

[v3_ca]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical,CA:FALSE
keyUsage = critical,digitalSignature
extendedKeyUsage = critical,codeSigning
EOF

# Self-signed certificate valid for 10 years
openssl req -new -x509 -key /tmp/openshark-key.pem \
    -out /tmp/openshark-cert.pem \
    -days 3650 \
    -config /tmp/openshark-cert.cfg 2>/dev/null

# Trust the certificate for code signing
security add-trusted-cert -d -r trustAsRoot \
    -k "$KEYCHAIN" /tmp/openshark-cert.pem 2>/dev/null || \
security add-trusted-cert -d -r trustAsRoot \
    -k "$KEYCHAIN" /tmp/openshark-cert.pem

# Import private key
security import /tmp/openshark-key.pem \
    -k "$KEYCHAIN" \
    -T /usr/bin/codesign 2>/dev/null || true

# Import certificate (may already exist)
security import /tmp/openshark-cert.pem \
    -k "$KEYCHAIN" \
    -T /usr/bin/codesign 2>/dev/null || true

# Allow codesign to use the key without UI prompt
security set-key-partition-list -S apple-tool:,apple: -k "" \
    "$KEYCHAIN" 2>/dev/null || true

# Cleanup
rm -f /tmp/openshark-key.pem /tmp/openshark-cert.pem /tmp/openshark-cert.cfg

echo ""
if security find-identity -v -p codesigning 2>/dev/null | grep -q "\"$CERT_NAME\""; then
    echo "✓ '$CERT_NAME' installed successfully."
    echo "  From now on, 'make-app.sh' will sign with this identity."
    echo "  Grant Input Monitoring once in System Settings → it persists across rebuilds."
else
    echo "✗ Import failed. Try: Keychain Access → File → Import → select /tmp/openshark-cert.pem"
fi
