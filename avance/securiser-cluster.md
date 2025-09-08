### Exercice 0 : Déploiement d'une application et mise en place des network policies

**Objectif :** Créer un déploiement d'une application web wordpress (site web + base de données) et sécuriser les flux réseaux 

**Tâches :**
1. Créer un namespace `dev-wordpress-prebil`
2. Créer le deploiement avec les deux pods et un service pour accèder aux deux pods
3. Créer les network policies correspondantes pour limiter les flux réseaux de cette applications
4. Déployer les ressources créé et vérifier à l'aide de commande ou de d'un script (à écrire) que les flux réseaux soient bien configurés


### Exercice 1 : Configuration RBAC Granulaire 

**Objectif :** Créer une structure RBAC pour une équipe de développement avec accès limité.

**Tâches :**
1. Créer un namespace `dev-team-alpha`
2. Créer un Role permettant seulement la gestion des Deployments et Services
3. Créer un ServiceAccount `dev-alpha-sa`
4. Lier le Role au ServiceAccount
5. Tester les permissions

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


