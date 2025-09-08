### Exercice : Déploiement d'une application et mise en place des network policies

**Objectif :** Créer un déploiement d'une application web wordpress (site web + base de données) et sécuriser les flux réseaux 

**Tâches :**
1. Créer un namespace `dev-wordpress-prenom`
2. Créer le deploiement avec les deux pods et un service pour accèder aux deux pods
3. Créer les network policies correspondantes pour limiter les flux réseaux de cette applications
4. Déployer les ressources créé et vérifier à l'aide de commande ou de d'un script (à écrire) que les flux réseaux soient bien configurés
