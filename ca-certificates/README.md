# Certificate Authorities Directory

This directory contains custom Certificate Authority (CA) certificates that will be added to the system trust store.

## Usage

Place your custom CA certificates in this directory with `.crt` extension:

```
ca-certificates/
├── company-root-ca.crt
├── internal-ca.crt
└── custom-ssl-ca.crt
```

## Supported Formats

- `.crt` files in PEM format
- `.pem` files in PEM format

## Example

If you have an internal company CA certificate, place it here:

```bash
# Copy your company's root CA certificate
cp /path/to/company-root-ca.crt ./ca-certificates/

# Rebuild container to apply changes
docker build -t ws-oracle-linux .
```

The certificates will be automatically installed during the container build process.

## Note

- Keep this directory even if empty to prevent Docker build errors
- Certificates are processed during build time, not runtime
- Invalid certificates will cause build failures
