#!/bin/bash
# security-audit.sh - Script d'audit sécurité automatisé

set -e

# Couleurs pour l'output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
APPROVED_REGISTRIES=("docker.io/library" "gcr.io" "quay.io")
LOG_FILE="security-audit-$(date +%Y%m%d-%H%M%S).log"

echo "🔍 Démarrage de l'audit sécurité Kubernetes..." | tee "$LOG_FILE"
echo "===============================================" | tee -a "$LOG_FILE"

# 1. Vérification des images non-approuvées
check_unapproved_images() {
    echo -e "\n${YELLOW}1. AUDIT DES IMAGES NON-APPROUVÉES${NC}" | tee -a "$LOG_FILE"
    echo "-----------------------------------" | tee -a "$LOG_FILE"
    
    kubectl get pods --all-namespaces -o json | jq -r '
    .items[] | 
    .spec.containers[] | 
    select(.image | test("^(docker.io/library|gcr.io|quay.io)") | not) |
    "⚠️  Image non-approuvée: " + .image + 
    " | Pod: " + .name + 
    " | Namespace: " + .namespace
    ' | tee -a "$LOG_FILE"
    
    # Compter les images non-conformes
    UNAPPROVED_COUNT=$(kubectl get pods --all-namespaces -o json | jq -r '.items[] | .spec.containers[] | select(.image | test("^(docker.io/library|gcr.io|quay.io)") | not) | .image' | wc -l)
    echo -e "Total d'images non-approuvées: ${RED}$UNAPPROVED_COUNT${NC}" | tee -a "$LOG_FILE"
}

# 2. Contrôle des ressources sans limits
check_resource_limits() {
    echo -e "\n${YELLOW}2. AUDIT DES RESSOURCES SANS LIMITS${NC}" | tee -a "$LOG_FILE"
    echo "------------------------------------" | tee -a "$LOG_FILE"
    
    # Pods sans resource limits
    kubectl get pods --all-namespaces -o json | jq -r '
    .items[] | 
    select(.spec.containers[] | .resources.limits == null) |
    "⚠️  Pod sans limits: " + .metadata.namespace + "/" + .metadata.name
    ' | tee -a "$LOG_FILE"
    
    # Pods sans resource requests
    kubectl get pods --all-namespaces -o json | jq -r '
    .items[] | 
    select(.spec.containers[] | .resources.requests == null) |
    "⚠️  Pod sans requests: " + .metadata.namespace + "/" + .metadata.name
    ' | tee -a "$LOG_FILE"
}

# 3. Détection des configurations non-sécurisées
check_insecure_configs() {
    echo -e "\n${YELLOW}3. AUDIT DES CONFIGURATIONS NON-SÉCURISÉES${NC}" | tee -a "$LOG_FILE"
    echo "-------------------------------------------" | tee -a "$LOG_FILE"
    
    # Pods avec privileged=true
    echo "Pods avec privilèges élevés:" | tee -a "$LOG_FILE"
    kubectl get pods --all-namespaces -o json | jq -r '
    .items[] | 
    select(.spec.containers[]?.securityContext?.privileged == true) |
    "🚨 Pod privilégié: " + .metadata.namespace + "/" + .metadata.name
    ' | tee -a "$LOG_FILE"
    
    # Pods avec runAsRoot
    echo -e "\nPods s'exécutant en tant que root:" | tee -a "$LOG_FILE"
    kubectl get pods --all-namespaces -o json | jq -r '
    .items[] | 
    select(
        (.spec.securityContext?.runAsUser == 0) or
        (.spec.containers[]?.securityContext?.runAsUser == 0) or
        (.spec.securityContext?.runAsUser == null and .spec.containers[]?.securityContext?.runAsUser == null)
    ) |
    "⚠️  Pod potentiellement root: " + .metadata.namespace + "/" + .metadata.name
    ' | tee -a "$LOG_FILE"
    
    # Pods avec hostNetwork=true
    echo -e "\nPods avec accès réseau host:" | tee -a "$LOG_FILE"
    kubectl get pods --all-namespaces -o json | jq -r '
    .items[] | 
    select(.spec.hostNetwork == true) |
    "🚨 Pod avec hostNetwork: " + .metadata.namespace + "/" + .metadata.name
    ' | tee -a "$LOG_FILE"
    
    # Services avec type LoadBalancer ou NodePort
    echo -e "\nServices exposés publiquement:" | tee -a "$LOG_FILE"
    kubectl get services --all-namespaces -o json | jq -r '
    .items[] | 
    select(.spec.type == "LoadBalancer" or .spec.type == "NodePort") |
    "⚠️  Service exposé (" + .spec.type + "): " + .metadata.namespace + "/" + .metadata.name
    ' | tee -a "$LOG_FILE"
}

# 4. Vérification des secrets et ConfigMaps
check_secrets_configmaps() {
    echo -e "\n${YELLOW}4. AUDIT DES SECRETS ET CONFIGMAPS${NC}" | tee -a "$LOG_FILE"
    echo "-----------------------------------" | tee -a "$LOG_FILE"
    
    # Secrets potentiellement sensibles
    kubectl get secrets --all-namespaces -o json | jq -r '
    .items[] | 
    select(.metadata.name | test("password|token|key|cert") | not) |
    select(.type != "kubernetes.io/service-account-token") |
    "ℹ️  Secret à vérifier: " + .metadata.namespace + "/" + .metadata.name + " (type: " + .type + ")"
    ' | tee -a "$LOG_FILE"
}

# 5. Vérification RBAC
check_rbac_permissions() {
    echo -e "\n${YELLOW}5. AUDIT DES PERMISSIONS RBAC${NC}" | tee -a "$LOG_FILE"
    echo "-------------------------------" | tee -a "$LOG_FILE"
    
    # ClusterRoles avec permissions dangereuses
    kubectl get clusterroles -o json | jq -r '
    .items[] | 
    select(.rules[]? | .verbs[]? == "*" and .resources[]? == "*") |
    "🚨 ClusterRole avec permissions complètes: " + .metadata.name
    ' | tee -a "$LOG_FILE"
    
    # ServiceAccounts avec automount activé
    kubectl get serviceaccounts --all-namespaces -o json | jq -r '
    .items[] | 
    select(.automountServiceAccountToken != false) |
    "⚠️  SA avec automount: " + .metadata.namespace + "/" + .metadata.name
    ' | tee -a "$LOG_FILE"
}

# Fonction de génération de rapport
generate_report() {
    echo -e "\n${GREEN}📊 RÉSUMÉ DE L'AUDIT${NC}" | tee -a "$LOG_FILE"
    echo "====================" | tee -a "$LOG_FILE"
    
    TOTAL_PODS=$(kubectl get pods --all-namespaces --no-headers | wc -l)
    TOTAL_SERVICES=$(kubectl get services --all-namespaces --no-headers | wc -l)
    TOTAL_SECRETS=$(kubectl get secrets --all-namespaces --no-headers | wc -l)
    
    echo "📈 Statistiques générales:" | tee -a "$LOG_FILE"
    echo "  - Total pods: $TOTAL_PODS" | tee -a "$LOG_FILE"
    echo "  - Total services: $TOTAL_SERVICES" | tee -a "$LOG_FILE"
    echo "  - Total secrets: $TOTAL_SECRETS" | tee -a "$LOG_FILE"
    
    echo -e "\n💾 Rapport sauvegardé dans: $LOG_FILE"
}

# Fonction principale
main() {
    check_unapproved_images
    check_resource_limits
    check_insecure_configs
    check_secrets_configmaps
    check_rbac_permissions
    generate_report
}

# Exécution du script
main