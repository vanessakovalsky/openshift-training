# Exercice OpenShift : Gestion Multi-Cluster avec Advanced Cluster Management (ACM)

## Objectifs pédagogiques

À la fin de cet exercice, vous serez capable de :
- Comprendre l'architecture et les concepts d'ACM
- Déployer des applications sur plusieurs clusters
- Utiliser les politiques de gouvernance multi-cluster

## Prérequis

- Un cluster OpenShift 4.10+ (Hub cluster)
- Un second cluster OpenShift ou Kubernetes (Managed cluster) 
- Privilèges cluster-admin sur le hub
- CLI `oc` et `kubectl` configurés

## Partie 1 : Concepts théoriques ACM 

### Architecture ACM

```
┌─────────────────────────────────────────────────────────────┐
│                    HUB CLUSTER                              │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │   ACM Console   │  │   Governance    │  │  Application │ │
│  │                 │  │   & Policies    │  │  Lifecycle   │ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │              Cluster Management                         │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
           │                    │                    │
           │                    │                    │
┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐
│ MANAGED CLUSTER │   │ MANAGED CLUSTER │   │ MANAGED CLUSTER │
│      (OCP)      │   │   (Kubernetes)  │   │     (EKS)       │
└─────────────────┘   └─────────────────┘   └─────────────────┘
```

### Composants principaux ACM

- **Hub Cluster** : Cluster central qui gère tous les autres
- **Managed Clusters** : Clusters gérés par le hub
- **Klusterlet** : Agent installé sur chaque cluster managé
- **Application Lifecycle** : Gestion GitOps des applications
- **Governance** : Politiques de sécurité et conformité


## Partie 2 : Exploration de la console ACM 

### Accéder à la console ACM

```bash
# Obtenir l'URL de la console ACM
echo "URL Console ACM: https://$(oc get route acm-cli-downloads -n open-cluster-management -o jsonpath='{.spec.host}')"

# Obtenir les credentials (utiliser les mêmes que OpenShift)
oc whoami
```

### Navigation dans l'interface

1. **Accédez à la console ACM** via l'URL obtenue
2. **Explorez les sections :**
   - Overview : Vue d'ensemble des clusters
   - Clusters : Gestion des clusters
   - Applications : Déploiement d'applications
   - Governance : Politiques de sécurité

### Premiers éléments observables

```bash
# Vérifier le cluster hub lui-même
oc get managedcluster

# Voir les namespaces créés pour le management
oc get ns | grep -E "(cluster|multicloud)"
```



## Partie 3 : Gestion des applications multi-cluster 

### Étape 1 : Créer un Channel GitOps

```bash
# Créer le namespace pour les applications
oc new-project acm-applications

# Créer un Channel pointant vers un repo Git
cat << EOF | oc apply -f -
apiVersion: apps.open-cluster-management.io/v1
kind: Channel
metadata:
  name: demo-git-channel
  namespace: acm-applications
spec:
  type: Git
  pathname: https://github.com/stolostron/application-samples.git
EOF
```

### Étape 2 : Créer une Application ACM

```bash
cat << EOF | oc apply -f -
apiVersion: app.k8s.io/v1beta1
kind: Application
metadata:
  name: nginx-demo-app
  namespace: acm-applications
spec:
  componentKinds:
  - group: apps.open-cluster-management.io
    kind: Subscription
  descriptor: {}
  selector:
    matchExpressions:
    - key: app
      operator: In
      values:
      - nginx-demo-app
---
apiVersion: apps.open-cluster-management.io/v1
kind: Subscription
metadata:
  name: nginx-demo-sub
  namespace: acm-applications
  labels:
    app: nginx-demo-app
  annotations:
    apps.open-cluster-management.io/git-branch: main
    apps.open-cluster-management.io/git-path: nginx
spec:
  channel: acm-applications/demo-git-channel
  placement:
    placementRef:
      kind: PlacementRule
      name: nginx-demo-placement
---
apiVersion: apps.open-cluster-management.io/v1
kind: PlacementRule
metadata:
  name: nginx-demo-placement
  namespace: acm-applications
  labels:
    app: nginx-demo-app
spec:
  clusterSelector:
    matchLabels:
      environment: development
EOF
```

### Étape 3 : Vérifier le déploiement

```bash
# Vérifier l'application
oc get application -n acm-applications

# Vérifier la subscription
oc get subscription -n acm-applications

# Voir les détails du placement
oc describe placementrule nginx-demo-placement -n acm-applications

# Vérifier les ressources créées sur le cluster local
oc get all -n nginx --ignore-not-found
```

## Partie 4 : Politiques de gouvernance 

### Étape 1 : Créer une politique de sécurité

```bash
# Créer le namespace pour les politiques
oc new-project acm-policies

# Créer une politique qui force la présence de NetworkPolicies
cat << EOF | oc apply -f -
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: policy-networkpolicy-required
  namespace: acm-policies
  annotations:
    policy.open-cluster-management.io/standards: NIST-CSF
    policy.open-cluster-management.io/categories: PR.AC Identity Management Authentication and Access Control
    policy.open-cluster-management.io/controls: PR.AC-3 Remote access
spec:
  remediationAction: inform
  disabled: false
  policy-templates:
    - objectDefinition:
        apiVersion: policy.open-cluster-management.io/v1
        kind: ConfigurationPolicy
        metadata:
          name: policy-networkpolicy-required
        spec:
          remediationAction: inform
          severity: medium
          object-templates:
            - complianceType: musthave
              objectDefinition:
                apiVersion: networking.k8s.io/v1
                kind: NetworkPolicy
                metadata:
                  name: default-deny-ingress
                  namespace: default
                spec:
                  podSelector: {}
                  policyTypes:
                  - Ingress
---
apiVersion: policy.open-cluster-management.io/v1
kind: PlacementBinding
metadata:
  name: binding-policy-networkpolicy-required
  namespace: acm-policies
placementRef:
  name: placement-policy-networkpolicy-required
  kind: PlacementRule
  apiGroup: apps.open-cluster-management.io
subjects:
- name: policy-networkpolicy-required
  kind: Policy
  apiGroup: policy.open-cluster-management.io
---
apiVersion: apps.open-cluster-management.io/v1
kind: PlacementRule
metadata:
  name: placement-policy-networkpolicy-required
  namespace: acm-policies
spec:
  clusterConditions:
  - status: "True"
    type: ManagedClusterConditionAvailable
  clusterSelector:
    matchExpressions:
    - key: environment
      operator: In
      values: ["development", "production"]
EOF
```

### Étape 2 : Créer une politique de conformité des pods

```bash
cat << EOF | oc apply -f -
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: policy-pod-security-standards
  namespace: acm-policies
spec:
  remediationAction: inform
  disabled: false
  policy-templates:
    - objectDefinition:
        apiVersion: policy.open-cluster-management.io/v1
        kind: ConfigurationPolicy
        metadata:
          name: policy-pod-security-standards
        spec:
          remediationAction: inform
          severity: high
          object-templates:
            - complianceType: mustnothave
              objectDefinition:
                apiVersion: v1
                kind: Pod
                metadata:
                  namespace: default
                spec:
                  containers:
                  - securityContext:
                      privileged: true
EOF
```

### Étape 3 : Vérifier les politiques

```bash
# Lister toutes les politiques
oc get policy -n acm-policies

# Voir le statut des politiques
oc get policy policy-networkpolicy-required -n acm-policies -o yaml

# Vérifier les violations
oc describe policy policy-pod-security-standards -n acm-policies
```



## Commandes de nettoyage

```bash
# Supprimer les ressources créées
oc delete application nginx-demo-app -n acm-applications
oc delete subscription nginx-demo-sub -n acm-applications
oc delete placementrule nginx-demo-placement -n acm-applications
oc delete channel demo-git-channel -n acm-applications

# Supprimer les politiques
oc delete policy --all -n acm-policies
oc delete placementbinding --all -n acm-policies
oc delete placementrule --all -n acm-policies

# Supprimer le cluster simulé
oc delete managedcluster demo-remote-cluster

# Supprimer les namespaces de demo
oc delete project acm-applications acm-policies simulated-cluster-demo

# Pour désinstaller complètement ACM (optionnel)
# oc delete multiclusterhub multiclusterhub -n open-cluster-management
# oc delete project open-cluster-management
```

## Ressources pour aller plus loin

### Documentation officielle
- [Red Hat ACM Documentation](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/)
- [Open Cluster Management Project](https://open-cluster-management.io/)

### Cas d'usage avancés
1. **GitOps avec ArgoCD et ACM**
2. **Gestion des clusters edge/IoT**
3. **Disaster Recovery multi-cluster**
4. **Compliance automatisée avec des politiques custom**
5. **Intégration avec des clouds hybrides (AWS, Azure, GCP)**

### Patterns architecturaux
- **Hub-and-Spoke** : Architecture centralisée
- **Federated** : Gestion décentralisée
- **Hierarchical** : Hubs multiples avec délégation

## Points clés à retenir

✅ **ACM simplifie** la gestion de clusters Kubernetes/OpenShift à grande échelle
✅ **L'approche déclarative** permet une gouvernance cohérente
✅ **GitOps natif** pour le déploiement d'applications multi-cluster
✅ **Politiques centralisées** pour la sécurité et la conformité
✅ **Observabilité unifiée** sur l'ensemble de la flotte
