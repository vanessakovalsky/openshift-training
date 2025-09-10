# Exercice OpenShift : Découverte des Opérateurs et CRD avec Prometheus et Grafana

## Objectifs pédagogiques

À la fin de cet exercice, vous serez capable de :
- Comprendre les concepts d'opérateur et de CRD (Custom Resource Definition)
- Installer et configurer l'opérateur Prometheus
- Installer et configurer l'opérateur Grafana
- Créer des ressources personnalisées via les CRD
- Observer le comportement automatique des opérateurs

## Prérequis

- Cluster OpenShift 4.x accessible
- Privilèges cluster-admin ou namespace-admin
- CLI `oc` configuré

## Partie 1 : Concepts théoriques (15 min)

### Qu'est-ce qu'un opérateur ?

Un opérateur est un logiciel qui étend l'API Kubernetes pour automatiser la gestion d'applications complexes. Il combine :
- **Connaissances métier** : Comment déployer, configurer, mettre à jour l'application
- **API Kubernetes** : Utilise les primitives k8s pour implémenter cette logique

### Qu'est-ce qu'une CRD ?

Une **Custom Resource Definition** définit un nouveau type de ressource Kubernetes. Elle permet de :
- Étendre l'API Kubernetes avec vos propres objets
- Utiliser `kubectl/oc` pour gérer ces objets comme des ressources natives

## Partie 2 : Installation de l'opérateur Prometheus (20 min)

### Étape 1 : Explorer l'Operator Hub

```bash
# Lister les opérateurs disponibles
oc get packagemanifests -n openshift-marketplace | grep prometheus

# Obtenir des détails sur l'opérateur Prometheus
oc describe packagemanifest prometheus-operator -n openshift-marketplace
```

### Étape 2 : Créer un projet dédié (à adapter avec votre nom)

```bash
# Créer le namespace de travail
oc new-project monitoring-demo

# Vérifier le projet actuel
oc project
```

### Étape 3 : Installer l'opérateur Prometheus
* Depuis la console web Openshift, allez dans Operators > OperatorHub
* Vérifier que vous êtes bien dans votre nouveau projet
* Recherche Prometheus Operator
* Installer le.

### Étape 4 : Vérifier l'installation

```bash
# Vérifier que l'opérateur est installé
oc get csv -n monitoring-demo

# Vérifier les pods de l'opérateur
oc get pods -n monitoring-demo

# Lister les nouvelles CRD créées par l'opérateur
oc get crd | grep prometheus
```

**Questions de réflexion :**
1. Quelles CRD ont été créées ?
2. Combien de pods l'opérateur a-t-il créé ?

## Partie 3 : Déploiement d'une instance Prometheus via CRD (25 min)

### Étape 1 : Examiner la CRD Prometheus

```bash
# Voir la définition de la CRD Prometheus
oc explain prometheus

# Voir les champs disponibles
oc explain prometheus.spec
```

### Étape 2 : Créer une instance Prometheus

```bash
cat << EOF | oc apply -f -
apiVersion: monitoring.coreos.com/v1
kind: Prometheus
metadata:
  name: prometheus-demo
  namespace: monitoring-demo
spec:
  serviceAccountName: prometheus-demo
  serviceMonitorSelector:
    matchLabels:
      prometheus: demo
  resources:
    requests:
      memory: 400Mi
  storage:
    volumeClaimTemplate:
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 1Gi
EOF
```

### Étape 3 : Créer le ServiceAccount nécessaire

```bash
cat << EOF | oc apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: prometheus-demo
  namespace: monitoring-demo
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: prometheus-demo
rules:
- apiGroups: [""]
  resources: ["nodes", "services", "endpoints", "pods"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: prometheus-demo
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: prometheus-demo
subjects:
- kind: ServiceAccount
  name: prometheus-demo
  namespace: monitoring-demo
EOF
```

### Étape 4 : Observer le comportement de l'opérateur

```bash
# Vérifier que l'opérateur a créé les ressources
oc get prometheus -n monitoring-demo

# Observer les ressources créées automatiquement
oc get all -n monitoring-demo

# Vérifier les StatefulSets créés
oc get statefulset -n monitoring-demo

# Examiner les détails du StatefulSet
oc describe statefulset prometheus-prometheus-demo -n monitoring-demo
```

**Questions de réflexion :**
1. Quelles ressources l'opérateur a-t-il créées automatiquement ?
2. Comment l'opérateur a-t-il nommé ces ressources ?

## Partie 4 : Installation et configuration de l'opérateur Grafana (30 min)

### Étape 1 : Installer l'opérateur Grafana

* Depuis la console web Openshift, allez dans Operators > OperatorHub
* Vérifier que vous êtes bien dans votre nouveau projet
* Recherche Grafana Operator
* Installer le (avec les paramètres par défaut).

### Étape 2 : Vérifier l'installation et explorer les CRD

```bash
# Vérifier l'installation
oc get csv -n monitoring-demo

# Lister les CRD Grafana
oc get crd | grep grafana

# Explorer les nouvelles ressources disponibles
oc explain grafana
oc explain grafanadashboard
oc explain grafanadatasource
```

### Étape 3 : Créer une instance Grafana

```bash
cat << EOF | oc apply -f -
apiVersion: grafana.integreatly.org/v1beta1
kind: Grafana
metadata:
  name: grafana-demo
  namespace: monitoring-demo
  labels:
    app: grafana-demo
    dashboards: "grafana"
spec:
  config:
    auth:
      disable_signout_menu: "true"
    auth.anonymous:
      enabled: "true"
    log:
      level: warn
      mode: console
    security:
      admin_password: secret
      admin_user: root
  deployment:
    spec:
      selector:
        matchLabels:
          app: grafana-demo
      template:
        metadata:
          labels:
            app: grafana-demo
        spec:
          containers:
          - name: grafana
            image: grafana/grafana:latest
            ports:
            - containerPort: 3000
              name: grafana-http
              protocol: TCP
  service:
    metadata:
      labels:
        app: grafana-demo
    spec:
      ports:
      - name: grafana-http
        port: 3000
        protocol: TCP
        targetPort: grafana-http
      selector:
        app: grafana-demo
EOF
```

### Étape 4 : Créer une DataSource Prometheus

```bash
cat << EOF | oc apply -f -
apiVersion: grafana.integreatly.org/v1beta1
kind: GrafanaDatasource
metadata:
  name: prometheus-datasource
  namespace: monitoring-demo
spec:
  instanceSelector:
    matchLabels:
      dashboards: "grafana"
  datasource:
    access: proxy
    database: prometheus
    jsonData:
      timeInterval: 5s
      tlsSkipVerify: true
    name: Prometheus
    type: prometheus
    url: http://prometheus-operated:9090
    isDefault: true
EOF
```

### Étape 5 : Accéder à Grafana

```bash
# Ajouter une route
oc expose sv grafana-demo-service

# Obtenir l'URL de Grafana
oc get route -n monitoring-demo

# Obtenir le service Grafana
oc get svc -n monitoring-demo | grep grafana

# Port-forward pour accéder localement (alternative)
oc port-forward svc/grafana-demo-service 3000:3000 -n monitoring-demo
```

## Partie 5 : Création d'un Dashboard via CRD (20 min)

### Créer un dashboard Grafana via CRD

```bash
cat << EOF | oc apply -f -
apiVersion: grafana.integreatly.org/v1beta1
kind: GrafanaDashboard
metadata:
  name: prometheus-dashboard
  namespace: monitoring-demo
  labels:
    app: grafana
spec:
  instanceSelector:
    matchLabels:
      dashboards: "grafana"
  json: |
    {
      "id": null,
      "uid": "prometheus-stats",
      "title": "Prometheus Statistics",
      "tags": ["prometheus", "monitoring"],
      "timezone": "browser",
      "editable": true,
      "panels": [
        {
          "id": 1,
          "title": "Prometheus Up Status",
          "type": "stat",
          "targets": [
            {
              "expr": "up{job=\"prometheus\"}",
              "refId": "A",
              "legendFormat": "Prometheus"
            }
          ],
          "gridPos": {
            "h": 8,
            "w": 12,
            "x": 0,
            "y": 0
          },
          "fieldConfig": {
            "defaults": {
              "mappings": [
                {
                  "options": {
                    "0": {"text": "DOWN"},
                    "1": {"text": "UP"}
                  },
                  "type": "value"
                }
              ],
              "thresholds": {
                "mode": "absolute",
                "steps": [
                  {"color": "red", "value": 0},
                  {"color": "green", "value": 1}
                ]
              }
            }
          }
        },
        {
          "id": 2,
          "title": "Prometheus Targets Discovered",
          "type": "timeseries",
          "targets": [
            {
              "expr": "prometheus_sd_discovered_targets",
              "refId": "B",
              "legendFormat": "Discovered Targets"
            }
          ],
          "gridPos": {
            "h": 8,
            "w": 12,
            "x": 12,
            "y": 0
          },
          "fieldConfig": {
            "defaults": {
              "custom": {
                "drawStyle": "line",
                "lineInterpolation": "linear",
                "lineWidth": 1,
                "fillOpacity": 10
              }
            }
          }
        }
      ],
      "time": {
        "from": "now-1h",
        "to": "now"
      },
      "refresh": "5s",
      "schemaVersion": 30,
      "version": 1
    }
EOF
```

## Partie 6 : Expérimentation et observation (15 min)

### Exercices pratiques

1. **Modifier la configuration Prometheus :**
   ```bash
   # Éditer l'instance Prometheus pour changer les ressources
   oc edit prometheus prometheus-demo -n monitoring-demo
   # Modifier spec.resources.requests.memory à 600Mi
   ```

2. **Observer la réaction de l'opérateur :**
   ```bash
   # Regarder les pods en temps réel
   oc get pods -w -n monitoring-demo
   
   # Vérifier que le StatefulSet a été mis à jour
   oc describe statefulset prometheus-prometheus-demo -n monitoring-demo
   ```

3. **Supprimer une ressource et observer la réconciliation :**
   ```bash
   # Supprimer le service Prometheus
   oc delete svc prometheus-operated -n monitoring-demo
   
   # Observer que l'opérateur le recrée automatiquement
   oc get svc -n monitoring-demo
   ```

## Questions d'évaluation

### Questions conceptuelles

1. **Différence entre ressource native et CRD :**
   - Donnez trois exemples de ressources natives Kubernetes
   - Expliquez comment une CRD étend cette liste

2. **Rôle de l'opérateur :**
   - Que se passe-t-il quand vous modifiez une instance de CRD ?
   - Comment l'opérateur assure-t-il la cohérence de l'état désiré ?

3. **Avantages des opérateurs :**
   - Quels avantages voyez-vous par rapport à un déploiement manuel ?
   - Dans quels cas utiliseriez-vous un opérateur ?

### Questions techniques

1. **Listez toutes les CRD créées par les opérateurs installés**
2. **Trouvez le nom du controller manager de l'opérateur Prometheus**
3. **Identifiez les labels utilisés par l'opérateur pour gérer ses ressources**

## Nettoyage

```bash
# Supprimer les instances créées
oc delete prometheus prometheus-demo -n monitoring-demo
oc delete grafana grafana-demo -n monitoring-demo
oc delete grafanadashboard prometheus-dashboard -n monitoring-demo
oc delete grafanadatasource prometheus-datasource -n monitoring-demo

# Supprimer les subscriptions (opérateurs)
oc delete subscription prometheus-operator -n monitoring-demo
oc delete subscription grafana-operator -n monitoring-demo

# Supprimer le projet
oc delete project monitoring-demo
```

## Pour aller plus loin

1. **Explorer d'autres opérateurs :** Elasticsearch, MongoDB, Redis
2. **Créer ses propres CRD** avec l'Operator SDK
3. **Comprendre les webhooks** d'admission et de mutation
4. **Étudier les patterns** de réconciliation et de finalizers

## Ressources

- [Documentation OpenShift Operators](https://docs.openshift.com/container-platform/latest/operators/understanding/olm-understanding-operatorhub.html)
- [Prometheus Operator Documentation](https://prometheus-operator.dev/)
- [Grafana Operator GitHub](https://github.com/grafana-operator/grafana-operator)

