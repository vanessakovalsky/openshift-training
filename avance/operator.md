### Exercice 1 : Création d'un Operator Simple (25 min)
1. **Initialiser un projet Operator** avec l'Operator SDK
2. **Créer une CRD** pour une application web sécurisée
3. **Implémenter le controller** basique avec gestion de Deployment
4. **Tester le déploiement** et la réconciliation

```bash
# Commandes de base
operator-sdk init --domain=training.com --repo=github.com/training/web-operator
operator-sdk create api --group=web --version=v1 --kind=SecureWebApp --resource --controller
make install
make run
```

### Exercice 2 : Webhook de Validation (15 min)
1. **Créer un webhook** de validation pour votre CRD
2. **Implémenter des règles** de validation métier
3. **Tester les validations** avec des ressources correctes et incorrectes

### Exercice 3 : Intégration Monitoring (10 min)
1. **Ajouter des métriques** Prometheus à votre Operator
2. **Créer un ServiceMonitor** pour exposer les métriques
3. **Vérifier les métriques** dans Prometheus

### Exercice 4 : Tests E2E (10 min)
1. **Écrire des tests** d'intégration avec Ginkgo
2. **Tester les scenarios** de création, mise à jour, suppression
3. **Valider le comportement** du controller
