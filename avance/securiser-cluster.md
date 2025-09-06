### Exercice 1 : Configuration RBAC Granulaire (15 min)

**Objectif :** Créer une structure RBAC pour une équipe de développement avec accès limité.

**Tâches :**
1. Créer un namespace `dev-team-alpha`
2. Créer un Role permettant seulement la gestion des Deployments et Services
3. Créer un ServiceAccount `dev-alpha-sa`
4. Lier le Role au ServiceAccount
5. Tester les permissions

**Solution :**
```bash
# 1. Création du namespace
kubectl create namespace dev-team-alpha

# 2. Création du Role
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: dev-team-alpha
  name: dev-alpha-role
rules:
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]
- apiGroups: [""]
  resources: ["services"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]
EOF

# 3. Création du ServiceAccount
kubectl create serviceaccount dev-alpha-sa -n dev-team-alpha

# 4. RoleBinding
kubectl create rolebinding dev-alpha-binding \
  --role=dev-alpha-role \
  --serviceaccount=dev-team-alpha:dev-alpha-sa \
  -n dev-team-alpha

# 5. Test des permissions
kubectl auth can-i create deployments --as=system:serviceaccount:dev-team-alpha:dev-alpha-sa -n dev-team-alpha
kubectl auth can-i delete secrets --as=system:serviceaccount:dev-team-alpha:dev-alpha-sa -n dev-team-alpha
```

### Exercice 2 : Audit et Recherche Sécurisée (10 min)

**Objectif :** Identifier et analyser les ressources potentiellement à risque.

**Tâches :**
1. Lister tous les pods avec des volumes hostPath
2. Identifier les ServiceAccounts avec automountServiceAccountToken activé
3. Trouver les NetworkPolicies manquantes par namespace

### Exercice 3 : Automatisation Sécurité (10 min)

**Objectif :** Créer un script de validation sécurité automatisé.

**Tâches :**
1. Script vérifiant les images non-approuvées
2. Contrôle des ressources sans limits
3. Détection des configurations non-sécurisées

---
