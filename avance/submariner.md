### TP : Déploiement d'une Application Multi-Cluster

```bash
#!/bin/bash
# TP : Application distribuée avec Submariner

# 1. Déploiement du frontend sur cluster-prod
kubectl --kubeconfig prod-kubeconfig apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: nginx:alpine
        ports:
        - containerPort: 80
        env:
        - name: BACKEND_URL
          value: "http://backend.demo.svc.clusterset.local"
---
apiVersion: v1
kind: Service
metadata:
  name: frontend
  namespace: demo
  annotations:
    submariner.io/export: "true"
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
EOF

# 2. Déploiement du backend sur cluster-staging
kubectl --kubeconfig staging-kubeconfig apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: httpd:alpine
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: backend
  namespace: demo
  annotations:
    submariner.io/export: "true"
spec:
  selector:
    app: backend
  ports:
  - port: 80
    targetPort: 80
---
apiVersion: multicluster.x-k8s.io/v1alpha1
kind: ServiceExport
metadata:
  name: backend
  namespace: demo
EOF

# 3. Test de connectivité cross-cluster
echo "🧪 Test de connectivité..."
kubectl --kubeconfig prod-kubeconfig run test-pod --rm -it --restart=Never \
    --image=busybox:1.35 -- nslookup backend.demo.svc.clusterset.local

# 4. Vérification des métriques Submariner
echo "📊 Vérification des connexions..."
subctl show connections --kubeconfig prod-kubeconfig
subctl show endpoints --kubeconfig prod-kubeconfig
subctl show gateways --kubeconfig prod-kubeconfig
```
