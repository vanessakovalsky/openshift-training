### TP 1 : Configuration d'un Dashboard Multi-Cluster (20 min)

```bash
# 1. Créer un namespace pour l'observabilité
kubectl create namespace observability

# 2. Déployer Prometheus avec fédération
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus-federation
  namespace: observability
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus-federation
  template:
    metadata:
      labels:
        app: prometheus-federation
    spec:
      containers:
      - name: prometheus
        image: prom/prometheus:latest
        ports:
        - containerPort: 9090
        volumeMounts:
        - name: config
          mountPath: /etc/prometheus/prometheus.yml
          subPath: prometheus.yml
      volumes:
      - name: config
        configMap:
          name: prometheus-federation-config
EOF

# 3. Configurer Grafana avec les dashboards de sécurité
# (Appliquer les configurations précédentes)
```

### TP 2 : Mise en Place de la Corrélation de Logs (15 min)

```bash
# 1. Déployer la stack ELK
helm repo add elastic https://helm.elastic.co
helm install elasticsearch elastic/elasticsearch --namespace logging --create-namespace
helm install kibana elastic/kibana --namespace logging
helm install filebeat elastic/filebeat --namespace logging

# 2. Configurer les index patterns dans Kibana
# 3. Créer des dashboards de corrélation
```
