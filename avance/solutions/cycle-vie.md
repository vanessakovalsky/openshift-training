# Solutions Avancées - Kubernetes Sécurité

## Exercice 1 : Déploiement Multi-Environnements avec ArgoCD

### Architecture du Projet
```
project-structure/
├── environments/
│   ├── dev/
│   │   ├── kustomization.yaml
│   │   ├── namespace.yaml
│   │   ├── networkpolicy.yaml
│   │   └── security-context.yaml
│   └── prod/
│       ├── kustomization.yaml
│       ├── namespace.yaml
│       ├── networkpolicy.yaml
│       └── security-context.yaml
├── base/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── configmap.yaml
│   └── kustomization.yaml
└── argocd/
    ├── app-dev.yaml
    └── app-prod.yaml
```

### Fichiers

* L'intégralité des fichier de l'arborescence se trouve dans le sous dossier cycle-vie/exercice-1
* Récupérer ces fichiers en clonant ou en mettant à jour votre copie du dépôt

### Scripts de Validation

#### Script de Déploiement (`deploy.sh`)
* Le script de déploiement permet de déployer sur l'environnement de dev ou de prod ainsi que de tester en activant le dry-run

```bash
chmod +x deploy.sh
./deploy.sh dev false
```

#### Script de Validation Sécurité (`security-validation.sh`)

* Pour pouvoir valider les différentes règles de sécurité, pensez à vérifier qu'elles sont bien définies dans votre déploiement
* Ensuite vous pouvez exécutez le script suivant pour valider

```bash
chmod +x security-validation.sh.sh
./security-validation.sh.sh dev
```

## Exercice 2 : Configuration de Stockage Sécurisé

### Fichiers

* dans le dossier exercice2/storage, vous avez les fichiers qui correspondent à la création d'une classe de stockage pour les 3 principaux provider cloud ainsi que les deux application (base de donnée et app cliente)
* Appliquer le fichier de classe de stockage qui correspond à votre fournisseur cloud, exemple :
```
oc apply -f exercice2/storage/storageclass-gcp.yaml
```
* Puis créer le namespace et appliquer les déploiements
```
oc create ns secure-storage
oc create sa sa-secure-storage -n secure-storage
oc adm policy add-scc-to-user anyuid system:serviceaccount:secure-storage:sa-secure-storage

oc apply -f exercice2/storage/database-secrets.yaml
oc apply -f exercice2/storage/database-app.yaml
oc apply -f exercice2/storage/client-app.yaml

```
* Vérifiez dans la console ou avec oc cli que tout est bien déployer et les pods au statut running


### Scripts de Vérification du Chiffrement

* Choisir le script correspondant à votre fournisseur
* Pour l'exécuter
```
chmod +x exercice2/verify-encryption-gcp.sh
./exercice2/verify-encryption-gcp.sh
```
d
### Script de Test de Performance du Chiffrement (`performance-test.sh`)

* Pour executer un test de performance du chiffrement
```
chmod +x exercice2/performance-test.sh
./exercice2/performance-test.sh
```

## Résumé des Solutions

### ✅ **Exercice 1 - Déploiement Multi-Environnements**

**Points clés réalisés :**
- **Structure GitOps** avec Kustomize pour DEV/PROD
- **Politiques de sécurité différenciées** :
  - DEV : Permissions plus souples, debug activé
  - PROD : Sécurité renforcée, Pod Security Standards
- **Scripts de validation** automatisés
- **Tests de sécurité** intégrés

### 🔐 **Exercice 2 - Stockage Sécurisé**

**Points clés réalisés :**
- **StorageClasses chiffrées** pour AWS, Azure, GCP
- **Applications sécurisées** avec chiffrement at-rest
- **Vérification automatique** du chiffrement
- **Monitoring et alerting** complets
- **Tests de performance** et d'intégration
- **CronJob de vérification** périodique

### 🚀 **Fonctionnalités Avancées**

- **Automatisation complète** avec scripts Bash
- **Monitoring Prometheus/Grafana** intégré  
- **Gestion des erreurs** et debugging
- **Rapports de conformité** automatisés
- **Sécurité by-design** dans tous les composants

Ces solutions offrent une approche production-ready pour le déploiement sécurisé multi-environnements et la gestion du stockage chiffré dans Kubernetes.