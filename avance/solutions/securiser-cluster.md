# Solutions Détaillées - Exercices Sécurité Kubernetes

## Exercice 1 : Configuration RBAC Granulaire ✅

### Solution Complète et Explications

#### 1. Création du namespace
```bash
# Création du namespace dédié à l'équipe de développement
kubectl create namespace dev-team-alpha

# Vérification de la création
kubectl get namespaces | grep dev-team-alpha
```

#### 2. Création du Role avec permissions granulaires
```yaml
# Fichier: dev-alpha-role.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: dev-team-alpha
  name: dev-alpha-role
rules:
# Permissions pour les Deployments
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]
# Permissions pour les Services
- apiGroups: [""]
  resources: ["services"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]
# Permissions pour les ReplicaSets (nécessaires pour les Deployments)
- apiGroups: ["apps"]
  resources: ["replicasets"]
  verbs: ["get", "list", "watch"]
# Permissions pour les Pods (lecture seule pour debug)
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
```

```bash
# Application du Role
kubectl apply -f dev-alpha-role.yaml
```

#### 3. Création du ServiceAccount
```bash
# Création du ServiceAccount
kubectl create serviceaccount dev-alpha-sa -n dev-team-alpha

# Vérification
kubectl get serviceaccounts -n dev-team-alpha
```

#### 4. Création du RoleBinding
```yaml
# Fichier: dev-alpha-rolebinding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: dev-alpha-binding
  namespace: dev-team-alpha
subjects:
- kind: ServiceAccount
  name: dev-alpha-sa
  namespace: dev-team-alpha
roleRef:
  kind: Role
  name: dev-alpha-role
  apiGroup: rbac.authorization.k8s.io
```

```bash
# Application du RoleBinding
kubectl apply -f dev-alpha-rolebinding.yaml

# Ou en une commande
kubectl create rolebinding dev-alpha-binding \
  --role=dev-alpha-role \
  --serviceaccount=dev-team-alpha:dev-alpha-sa \
  -n dev-team-alpha
```

#### 5. Tests de permissions approfondis
```bash
# Tests de permissions autorisées
echo "=== TESTS DES PERMISSIONS AUTORISÉES ==="
kubectl auth can-i create deployments --as=system:serviceaccount:dev-team-alpha:dev-alpha-sa -n dev-team-alpha
kubectl auth can-i create services --as=system:serviceaccount:dev-team-alpha:dev-alpha-sa -n dev-team-alpha
kubectl auth can-i get pods --as=system:serviceaccount:dev-team-alpha:dev-alpha-sa -n dev-team-alpha

# Tests de permissions interdites
echo "=== TESTS DES PERMISSIONS INTERDITES ==="
kubectl auth can-i delete secrets --as=system:serviceaccount:dev-team-alpha:dev-alpha-sa -n dev-team-alpha
kubectl auth can-i create secrets --as=system:serviceaccount:dev-team-alpha:dev-alpha-sa -n dev-team-alpha
kubectl auth can-i delete pods --as=system:serviceaccount:dev-team-alpha:dev-alpha-sa -n dev-team-alpha
kubectl auth can-i create pods --as=system:serviceaccount:dev-team-alpha:dev-alpha-sa -n dev-team-alpha

# Test dans un autre namespace
kubectl auth can-i create deployments --as=system:serviceaccount:dev-team-alpha:dev-alpha-sa -n default
```

#### 6. Test pratique avec un déploiement
```yaml
# Fichier: test-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-app
  namespace: dev-team-alpha
spec:
  replicas: 2
  selector:
    matchLabels:
      app: test-app
  template:
    metadata:
      labels:
        app: test-app
    spec:
      serviceAccountName: dev-alpha-sa
      containers:
      - name: nginx
        image: nginx:1.20
        ports:
        - containerPort: 80
```

```bash
# Test du déploiement
kubectl apply -f test-deployment.yaml
kubectl get deployments -n dev-team-alpha
```

---

## Exercice 2 : Audit et Recherche Sécurisée

### 1. Lister tous les pods avec des volumes hostPath
```bash
# Script d'audit pour volumes hostPath
#!/bin/bash
echo "=== AUDIT DES VOLUMES HOSTPATH ==="
kubectl get pods --all-namespaces -o json | jq -r '
.items[] | 
select(.spec.volumes[]?.hostPath) | 
"Namespace: " + .metadata.namespace + 
" | Pod: " + .metadata.name + 
" | HostPath: " + (.spec.volumes[] | select(.hostPath) | .hostPath.path)
'

# Version alternative avec kubectl et grep
kubectl get pods --all-namespaces -o yaml | grep -B 10 -A 5 "hostPath"
```

### 2. Identifier les ServiceAccounts avec automountServiceAccountToken activé
```bash
#!/bin/bash
echo "=== AUDIT DES SERVICEACCOUNTS AVEC AUTOmount ==="

# ServiceAccounts avec automount explicitement activé
kubectl get serviceaccounts --all-namespaces -o json | jq -r '
.items[] | 
select(.automountServiceAccountToken == true) | 
"Namespace: " + .metadata.namespace + " | SA: " + .metadata.name
'

# Pods avec automount activé (par défaut)
kubectl get pods --all-namespaces -o json | jq -r '
.items[] | 
select(.spec.automountServiceAccountToken != false) | 
"Namespace: " + .metadata.namespace + 
" | Pod: " + .metadata.name + 
" | SA: " + (.spec.serviceAccountName // "default")
'
```

### 3. Trouver les NetworkPolicies manquantes par namespace
```bash
#!/bin/bash
echo "=== AUDIT DES NETWORKPOLICIES ==="

# Lister tous les namespaces
NAMESPACES=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}')

for NS in $NAMESPACES; do
    # Ignorer les namespaces système
    if [[ "$NS" =~ ^(kube-|default$) ]]; then
        continue
    fi
    
    # Vérifier la présence de NetworkPolicies
    NP_COUNT=$(kubectl get networkpolicies -n "$NS" --no-headers 2>/dev/null | wc -l)
    POD_COUNT=$(kubectl get pods -n "$NS" --no-headers 2>/dev/null | wc -l)
    
    if [ "$POD_COUNT" -gt 0 ] && [ "$NP_COUNT" -eq 0 ]; then
        echo "⚠️  Namespace '$NS' contient $POD_COUNT pods mais AUCUNE NetworkPolicy"
    elif [ "$POD_COUNT" -gt 0 ] && [ "$NP_COUNT" -gt 0 ]; then
        echo "✅ Namespace '$NS' contient $POD_COUNT pods et $NP_COUNT NetworkPolicy(ies)"
    fi
done
```

---

## Exercice 3 : Automatisation Sécurité

### Script de Validation Sécurité Complet
```bash
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
```

### Script de remédiation automatique
```bash
#!/bin/bash
# remediation.sh - Actions correctives automatiques

# Création d'une NetworkPolicy par défaut restrictive
create_default_networkpolicy() {
    local NAMESPACE=$1
    
    cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: $NAMESPACE
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF
}

# Application de PodSecurityPolicy restrictive
create_pod_security_policy() {
    cat <<EOF | kubectl apply -f -
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: restricted
spec:
  privileged: false
  allowPrivilegeEscalation: false
  requiredDropCapabilities:
    - ALL
  volumes:
    - 'configMap'
    - 'emptyDir'
    - 'projected'
    - 'secret'
    - 'downwardAPI'
    - 'persistentVolumeClaim'
  runAsUser:
    rule: 'MustRunAsNonRoot'
  seLinux:
    rule: 'RunAsAny'
  fsGroup:
    rule: 'RunAsAny'
EOF
}

echo "🔧 Script de remédiation exécuté"
```

---

## Points Clés de Sécurité

### ✅ Bonnes Pratiques RBAC
- **Principe du moindre privilège** : Accordez seulement les permissions nécessaires
- **Utilisez des Roles au lieu de ClusterRoles** quand possible
- **Évitez les permissions globales** (`*` dans verbs, resources)
- **Auditez régulièrement** les permissions accordées

### ⚠️ Configurations à éviter
- `privileged: true` dans les pods
- `hostNetwork: true` sans justification
- Images de registres non-approuvés
- Pods sans resource limits
- Services exposés sans NetworkPolicies

### 🔍 Monitoring continu
- Utilisez des outils comme **Falco** pour la détection d'intrusion
- Activez les **audit logs** de Kubernetes
- Implémentez des **admission controllers** personnalisés
- Automatisez les scans de sécurité avec **CI/CD**