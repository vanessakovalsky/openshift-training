# Ajouter un stockage persistant pour Elasticsearch

Exercice original :  https://www.katacoda.com/courses/openshift/persistence/persistent-elasticsearch

## Qu'est ce qu'OpenShift COntainer Storage (OCS) ?
Red Hat® OpenShift® Container Storage est un stockage défini par logiciel pour les conteneurs. Conçu pour les données et les plateforme de service de stockage de Red Hat OpenShift, Red Hat OpenShift Container Storage aide les équipes à développer et déployer des applications rapidement et efficacement dans le cloud.

## Ce que vous allez apprendre
Dans cet exercice vous apprendrez à créer des Volumes Persistants et à l'utiliser pour déployer Elasticsearch. Vous déployer une application de démo qui est une bibliothère de moteur de recherche parmi 100 romans classiques. Une fois l'applications déployée avec succès, vous pourrez rechercher n'importe quel mot dans les 100 romans classiques, la recherche et motorisée par Elasticsearch qui utilise un stockage persistant depuis OCS. L'architecture logique de l'application que vous allez déployer ressemble à ça : 
![Schema d'architecture](https://github.com/mulbc/learn-katacoda/raw/master/persistence/persistent-elasticsearch/architecture.png)

# Créer le projet et le PVC
Vous êtes connecté en tant qu'utilisateur admin, verifiez le avec la commande whoami.

Le contenu des fichiers à récupéré est ici : https://github.com/mulbc/learn-katacoda/tree/master/persistence/persistent-elasticsearch/assets 

Créer un nouveau projet, qui sera utiliser tout le long de l'exercice et créer un PersistenVolumeClaim sur la classe de stockage OCS qui sera utiliser par le pod Elasticsearch pour persister les données.
```
oc create -f 1_create_ns_ocs_pvc.yaml

oc project e-library
```
Pour vérifier la Storage Class (SC) et le PersistentVolumClaim (PVC)
```
oc get pvc

oc get sc
```
Avec quelques lignes de YAML, vous avez créer un PVC nommé ocs-pv-claom sur une classe de stockage ocs-storagecluster-ceph-rbd qui est fournit par OpenShift Container Storage. Elasticsearch a besoin de persistance pour ces données et OCS est une des options les plus simples et fiable que vous pouvez choisir pour persister les données pour vos applications fonctionnant sur OpenShift Container Platform.
Continuons avec le déploiement du cluster Elasticsearch

# Deployer Elasticsearch sur OCS
Appliquer le fichier YAML pour déployer Elasticsearch :
```
oc create -f 2_deploy_elasticsearch.yaml
```
Pour rendre Elasticsearch persistant nous avons définis un PVC OCS dans la section volumes, monter celui ci dans volumeMounts à l'intérieur du fichier manifeste de déploiement comme montrer ci-dessous. De fait, Elasticsearch stockera toutes ses données sur le PVC qui est hébergé sur OCS.
```
...
    spec:
      volumes:
        - name: ocs-pv-storage
          persistentVolumeClaim:
            claimName: ocs-pv-claim
...
...
...
        volumeMounts:
          - mountPath: "/usr/share/elasticsearch/data"
            name: ocs-pv-storage
```
En tant que développeur, c'est l'étape la plus importante pour activer la persistance des données de l'application. Lorsque vous faite une requête PVC qui est provisionné par une classe de stockage OCS, le sous-système OCS s'assure que les données de votre application soit persistante et fiable.

# Deployer l'application backend & frontend
Appliquer le fichier YAML pour déployer le backend API de l'application :
```
oc create -f 3_deploy_backend_api.yaml
```
Pour permettre à l'application frontend d'attendre l'API Backend, définir la variable d'environnement BACKEND_URL en tant que config map, en executant la commande suivante :
```
echo "env = {BACKEND_URL: 'http://$(oc get route -n e-library -o=jsonpath="{.items[0]['spec.host']}")'}" > env.js

oc create configmap -n e-library env.js --from-file=env.js
```
Enfin, on déploie l'application frontend
```
oc create -f 4_deploy_frontend_app.yaml
```
A ce point les applications frontend et backend sont déployés et configurés pour utiliser Elasticsearch.

Pour vérifier, executez la commande suivante :
```
oc get po,svc,route
```
Avant de passer à l'étape suivante, assurez-cous que tous les pods sont à l'état Running. Si ce n'est pas le cas, attendre quelques minutes.

# Envoyer des jeux de données à  Elasticsearch
Charger le jeu de données avec les textes formatés des 100 romans classique de la collection Gutenberg dans le service Elasticsearch.
Note : Mains en l'air ! L'injection de donnée peut prendre plusieurs minutes.
```
oc exec -it e-library-backend-api  -n e-library -- curl -X POST http://localhost:3000/load_data
```
Les données injectés sont stockés dans des fragments Elasticsearch qui utilisent à leur tour le PVC OCS pour la persistance.

Dès que les données sont injectées, Elasticsearch indexera et les rendra recherchable.

Récupérer l'URL du frontend et ouvrez là dans un navigateur pour rechercher n'importe quel mot.
URL http://frontend-e-library.2886795278-80-simba07.environments.katacoda.com
```
oc get route frontend -n e-library
```
Les capacités de recherches en temps réél d'Elasticsearch, permette de cherche instatannément dans un large jeu de données.
Ce qui en fait un choix populaire pour les logs, les metriques, la recherche full-texte...

## Pour aller plus loin 
Elasticsearch offre de la réplication au niveau des indexes pour founir de la résilience sur les données.
La résilience de données supplémentaire peut être fournit en déployant Elasticsearch par dessus une couche de service de stockage fiable comme OCS qui offre d'importantes capacités de résilience. Cette resilience de données supplémentaires peut améliorer la disponibilité du service ElasticSearch pendant les scénarios d'erreurs important de l'infrastructure. A cause des ressources limitées de cet environnement de test, nous ne pouvons vous montrer les capacités de résiliences d'Elasticsearch lorsqu'il est déployé sur OCS, mais vous avez une bonne idée.


