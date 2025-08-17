#!/bin/bash
# =============================================================================
# Kubernetes Tools Installation
# =============================================================================

set -euo pipefail

install_k8s_tools() {
    if [ "${INSTALL_K8S:-0}" = "1" ]; then
        local kubectl_version="${KUBECTL_VERSION:-1.31.12}"
        local helm_version="${HELM_VERSION:-3.18.0}"
        local k9s_version="${K9S_VERSION:-0.50.9}"
        
        echo "==> Installing Kubernetes tools"
        
        # Install kubectl
        curl -fsSL -o /usr/local/bin/kubectl "https://dl.k8s.io/release/v${kubectl_version}/bin/linux/amd64/kubectl"
        chmod +x /usr/local/bin/kubectl
        
        # Install helm
        curl -fsSL -o /tmp/helm.tgz "https://get.helm.sh/helm-v${helm_version}-linux-amd64.tar.gz"
        tar -xzf /tmp/helm.tgz -C /tmp
        mv /tmp/linux-amd64/helm /usr/local/bin/helm
        chmod +x /usr/local/bin/helm
        rm -rf /tmp/helm.tgz /tmp/linux-*
        
        # Install k9s
        curl -fsSL -o /tmp/k9s.tgz "https://github.com/derailed/k9s/releases/download/v${k9s_version}/k9s_Linux_amd64.tar.gz"
        tar -xzf /tmp/k9s.tgz -C /usr/local/bin k9s
        rm -f /tmp/k9s.tgz
        
        echo "==> Kubernetes tools installed successfully"
    else
        echo "==> Skipping Kubernetes tools installation"
    fi
}

install_k8s_tools
