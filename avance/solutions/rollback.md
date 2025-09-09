# Guide OpenShift - Rolling Update et Rollback Automatisé

## Exercice 1 : Configuration Rolling Update

### Étape 1 : Création du projet OpenShift
```bash
# Créer un nouveau projet
oc new-project rolling-update-demo
oc create sa sa-rolling -n rolling-update-demo
oc adm policy add-scc-to-user anyuid system:serviceaccount:rolling-update-demo:sa-rolling
# Vérifier le projet actuel
oc project
```



### Étape 2 : Déploiement et configuration des ImageStreams

```bash
# Créer l'ImageStream pour nginx
oc import-image nginx:1.20 --from=docker.io/nginx:1.20 --confirm
oc import-image nginx:1.21 --from=docker.io/nginx:1.21 --confirm

# Appliquer les configurations
oc apply -f webapp-config.yaml
oc apply -f rolling-update-app.yaml
oc apply -f service-route.yaml

# Vérifier le déploiement
oc get dc,pods,svc,route
oc rollout status dc/webapp-rolling
```

### Étape 3 : Tests et mise à jour


```bash
# Rendre le script exécutable
chmod +x rollback/monitor-rolling-update.sh

# Démarrer le monitoring
./rollback/monitor-rolling-update.sh &

# Dans un autre terminal, effectuer la mise à jour
oc patch configmap webapp-config -p '{"data":{"index.html":"<!DOCTYPE html>\n<html>\n<head>\n    <title>Rolling Update Demo</title>\n    <style>\n        body { \n            font-family: Arial, sans-serif; \n            text-align: center; \n            background-color: #e8f5e8;\n            padding: 50px;\n        }\n        .version { \n            color: #2e7d32; \n            font-size: 2em; \n            font-weight: bold;\n        }\n    </style>\n</head>\n<body>\n    <h1>Application Web - Rolling Update Demo</h1>\n    <div class=\"version\">Version: 2.0</div>\n    <p>Hostname: <span id=\"hostname\"></span></p>\n    <p>Timestamp: <span id=\"timestamp\"></span></p>\n    <p><strong>Nouvelle fonctionnalité ajoutée!</strong></p>\n    <script>\n        document.getElementById(\"hostname\").textContent = window.location.hostname;\n        document.getElementById(\"timestamp\").textContent = new Date().toISOString();\n        setInterval(() => {\n            document.getElementById(\"timestamp\").textContent = new Date().toISOString();\n        }, 1000);\n    </script>\n</body>\n</html>"}}'

# Déclencher un nouveau déploiement
oc rollout latest dc/webapp-rolling

# Observer le rollout
oc rollout status dc/webapp-rolling -w
```

---

## Exercice 2 : Script de Rollback Automatisé
`

```bash
# Rendre tous les scripts exécutables
cd rollback/exercice2/
chmod +x *.sh

# Installer les dépendances (si nécessaire)
if ! command -v bc &> /dev/null; then
    echo "Installation de bc (calculatrice)..."
    # Sur RHEL/CentOS: yum install bc
    # Sur Ubuntu/Debian: apt-get install bc
fi

if ! command -v jq &> /dev/null; then
    echo "Installation de jq..."
    # Sur RHEL/CentOS: yum install jq
    # Sur Ubuntu/Debian: apt-get install jq
fi

# Exécuter le test complet
./full-test.sh

# Surveillance manuelle des logs
tail -f /tmp/auto-rollback.log

# Vérification des métriques
cat /tmp/metrics.json | jq '.'

# Vérification de l'historique des déploiements
oc rollout history dc/webapp-rolling

# Nettoyage (si nécessaire)
oc delete project rolling-update-demo
```

## Points Clés OpenShift vs Kubernetes

1. **DeploymentConfig vs Deployment** : OpenShift utilise DeploymentConfig avec des hooks et triggers spécifiques
2. **ImageStreams** : Gestion native des images avec déclencheurs automatiques
3. **Routes** : Exposition automatique avec TLS/SSL intégré
4. **Hooks de déploiement** : Pre/post hooks pour les validations
5. **Rollback natif** : Commande `oc rollback` spécifique à OpenShift
6. **Monitoring intégré** : Utilisation des métriques OpenShift pour le monitoring

Cette solution complète démontre une approche professionnelle de gestion des déploiements avec surveillance proactive et récupération automatique en cas de problème.