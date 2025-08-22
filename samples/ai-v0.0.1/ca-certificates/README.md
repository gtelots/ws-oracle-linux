# Custom Certificate Authority Management

This directory contains custom Certificate Authority (CA) certificates for the Oracle Linux 9 development container, enabling secure connections to internal and corporate services.

## 🔐 Overview

Custom CA certificates are essential for:
- **Corporate Networks**: Internal services with self-signed certificates
- **Development Environments**: Local HTTPS services and APIs
- **Enterprise Integration**: Corporate PKI infrastructure
- **Security Compliance**: Meeting organizational security requirements

## 📁 Directory Structure

```
ca-certificates/
├── README.md              # This documentation
├── corporate/             # Corporate CA certificates
│   ├── company-root-ca.crt
│   ├── company-intermediate-ca.crt
│   └── department-ca.crt
├── development/           # Development environment certificates
│   ├── dev-root-ca.crt
│   ├── localhost-ca.crt
│   └── test-services-ca.crt
├── cloud-providers/       # Cloud provider certificates
│   ├── aws-private-ca.crt
│   ├── azure-private-ca.crt
│   └── oci-private-ca.crt
└── scripts/              # Certificate management scripts
    ├── install-ca.sh
    ├── verify-ca.sh
    └── update-ca-bundle.sh
```

## 🚀 Quick Setup

### 1. Add Certificate Files

Place your CA certificate files in the appropriate subdirectories:

```bash
# Corporate certificates
cp company-root-ca.crt ca-certificates/corporate/

# Development certificates
cp dev-ca.crt ca-certificates/development/

# Cloud provider certificates
cp aws-ca.crt ca-certificates/cloud-providers/
```

### 2. Install Certificates

The certificates are automatically installed during container build, but you can manually update them:

```bash
# Update CA trust store
sudo update-ca-trust

# Verify installation
sudo update-ca-trust extract
```

### 3. Verify Certificate Installation

```bash
# Check if certificate is trusted
openssl verify -CAfile /etc/ssl/certs/ca-bundle.crt your-certificate.crt

# Test HTTPS connection
curl -v https://your-internal-service.company.com
```

## 📋 Certificate Formats

### Supported Formats
- **PEM (.pem, .crt, .cer)**: Base64 encoded, most common
- **DER (.der)**: Binary format
- **PKCS#7 (.p7b, .p7c)**: Certificate chain format
- **PKCS#12 (.p12, .pfx)**: Certificate with private key (not for CA)

### Format Conversion
```bash
# DER to PEM
openssl x509 -inform der -in certificate.der -out certificate.pem

# PKCS#7 to PEM
openssl pkcs7 -print_certs -in certificate.p7b -out certificate.pem

# View certificate details
openssl x509 -in certificate.pem -text -noout
```

## 🔧 Certificate Management Scripts

### install-ca.sh
Installs custom CA certificates to the system trust store:

```bash
#!/bin/bash
# Install custom CA certificates
sudo cp ca-certificates/*/*.crt /usr/local/share/ca-certificates/
sudo update-ca-trust
echo "CA certificates installed successfully"
```

### verify-ca.sh
Verifies certificate installation and trust:

```bash
#!/bin/bash
# Verify CA certificate installation
for cert in ca-certificates/*/*.crt; do
    echo "Verifying: $cert"
    openssl x509 -in "$cert" -noout -subject -issuer -dates
done
```

### update-ca-bundle.sh
Updates the CA certificate bundle:

```bash
#!/bin/bash
# Update CA bundle
sudo update-ca-trust extract
echo "CA bundle updated: $(date)"
```

## 🏢 Corporate Environment Setup

### 1. Obtain Corporate Certificates

Contact your IT security team to obtain:
- Root CA certificate
- Intermediate CA certificates
- Department-specific certificates

### 2. Install Corporate Certificates

```bash
# Create corporate directory
mkdir -p ca-certificates/corporate

# Copy certificates
cp /path/to/corporate-root-ca.crt ca-certificates/corporate/
cp /path/to/corporate-intermediate-ca.crt ca-certificates/corporate/

# Set proper permissions
chmod 644 ca-certificates/corporate/*.crt
```

### 3. Configure Applications

Some applications may need additional configuration:

```bash
# Git (for corporate Git servers)
git config --global http.sslCAInfo /etc/ssl/certs/ca-bundle.crt

# Node.js (set CA bundle)
export NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-bundle.crt

# Python requests
export REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-bundle.crt
export SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt
```

## 🌐 Development Environment Certificates

### Self-Signed Certificate Creation

```bash
# Create development CA
openssl genrsa -out dev-ca-key.pem 4096
openssl req -new -x509 -days 365 -key dev-ca-key.pem -out dev-ca.crt \
    -subj "/C=US/ST=State/L=City/O=Development/CN=Dev CA"

# Create server certificate signed by dev CA
openssl genrsa -out server-key.pem 2048
openssl req -new -key server-key.pem -out server.csr \
    -subj "/C=US/ST=State/L=City/O=Development/CN=localhost"
openssl x509 -req -in server.csr -CA dev-ca.crt -CAkey dev-ca-key.pem \
    -CAcreateserial -out server.crt -days 365
```

### Local Development Setup

```bash
# Add development CA to trust store
cp dev-ca.crt ca-certificates/development/
sudo update-ca-trust

# Test local HTTPS service
curl -v https://localhost:8443
```

## ☁️ Cloud Provider Integration

### AWS Private CA

```bash
# Download AWS Private CA certificate
aws acm-pca get-certificate-authority-certificate \
    --certificate-authority-arn arn:aws:acm-pca:region:account:certificate-authority/ca-id \
    --output text > aws-private-ca.crt

# Install certificate
cp aws-private-ca.crt ca-certificates/cloud-providers/
```

### Azure Private CA

```bash
# Download Azure certificate
az keyvault certificate download \
    --vault-name your-keyvault \
    --name ca-certificate \
    --file azure-private-ca.crt

# Install certificate
cp azure-private-ca.crt ca-certificates/cloud-providers/
```

### Oracle Cloud Infrastructure

```bash
# Download OCI certificate
oci certificates certificate get \
    --certificate-id ocid1.certificate.oc1..example \
    --file oci-private-ca.crt

# Install certificate
cp oci-private-ca.crt ca-certificates/cloud-providers/
```

## 🔍 Troubleshooting

### Common Issues

1. **Certificate Not Trusted**
   ```bash
   # Check if certificate is in trust store
   trust list | grep "Your CA Name"
   
   # Manually add certificate
   sudo trust anchor your-ca.crt
   ```

2. **Application Still Failing**
   ```bash
   # Check application-specific CA settings
   curl -v --cacert /etc/ssl/certs/ca-bundle.crt https://example.com
   
   # Test with specific certificate
   curl -v --cacert your-ca.crt https://example.com
   ```

3. **Permission Issues**
   ```bash
   # Fix certificate permissions
   sudo chmod 644 /usr/local/share/ca-certificates/*.crt
   sudo update-ca-trust
   ```

### Verification Commands

```bash
# List all trusted CAs
trust list --filter=ca-anchors

# Check certificate details
openssl x509 -in certificate.crt -text -noout

# Test SSL connection
openssl s_client -connect hostname:443 -CAfile /etc/ssl/certs/ca-bundle.crt

# Verify certificate chain
openssl verify -CAfile ca-bundle.crt server-certificate.crt
```

## 🛡️ Security Best Practices

### Certificate Validation
- ✅ Verify certificate authenticity before installation
- ✅ Check certificate expiration dates regularly
- ✅ Use proper certificate chain validation
- ✅ Monitor certificate usage and access

### Access Control
- ✅ Limit access to private keys
- ✅ Use proper file permissions (644 for certificates)
- ✅ Audit certificate installations
- ✅ Document certificate sources and purposes

### Maintenance
- ✅ Regular certificate rotation
- ✅ Monitor certificate expiration
- ✅ Update CA bundles regularly
- ✅ Test certificate functionality after updates

## 📚 Additional Resources

- [Oracle Linux Certificate Management](https://docs.oracle.com/en/operating-systems/oracle-linux/9/security/security-CertificateManagement.html)
- [OpenSSL Certificate Commands](https://www.openssl.org/docs/man1.1.1/man1/openssl-x509.html)
- [CA Certificate Best Practices](https://www.ssl.com/guide/ssl-best-practices/)
- [Enterprise PKI Management](https://csrc.nist.gov/publications/detail/sp/800-57-part-1/rev-5/final)

---

*Custom CA certificate management is part of the Oracle Linux 9 Development Container project, designed for enterprise security and compliance.*
