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

```bash
# Test du déploiement
kubectl apply -f test-deployment.yaml
kubectl get deployments -n dev-team-alpha
```



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
* Le script security-audit.sh vérifie différents points de sécurité d'un cluster
* Vous pouvez l'exécuter depuis le dossier où se trouve ce script avec les commandes suivantes :

```bash
chmod +x security-audit.sh
./security-audit.sh
```

### Script de remédiation automatique

* Le deuxième script remediation.sh permet de corriger automatique les problèmes de sécurités trouvé
* Pour l'exécuter depuis le dossier où se trouve le script

```bash
chmod +x remediation.sh
./remediation.sh
```


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