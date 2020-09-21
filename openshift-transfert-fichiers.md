# Transférer des fichiers dans et depuis un container avec OpenShift

Exercice original ici : https://www.katacoda.com/courses/openshift/introduction/transferring-files 

## Objectif
Apprendre à copier des fichiers dans et depuis un conteneur en fonctionnement sans reconstruire l'image du conteneur. Améliorer ça avec une fonction de surveillance qui applique automatiquement les modifications locales à un conteneur en cours de fonctionnement afin de voir immédiatement l'effet des changements sur l'application.


## Concepts
* Boucle rapid de développement pour modifier un conteneur en cours d'execution
* OpenShift Projets et Applications
* OpenShift outils oc et sa sous commande new-app

## Cas d'usage
Vous pouvez modifier une application dans un conteneur pour développer et tester avant de construire une nouvelle version de l'image de conteneur. Syncronisation automatique du conteneur avec les changements locaux rend plus rapide la boucle de développement et de tests, particulièrement dans les langages de programmations interprétés.

# Etape 1 - Crér un projet 

Avant de démarrer, vous devez vous connecter et créer un projet pour travailler dedans.

Pour se connecter au cluster OpenShift utilisé dans ce cours, lancer dans le terminal 
```
oc login -u developer -p developer
```
Vous serez alors identifiés avec les credentials :
```
Username: developer
Password: developer
```
Vous devriez avoir la sortie suivante :
```
Login successful.
```
Vous n'avez pas de projet. Vous pouvez en créer un avec la commande :
```
    oc new-project <projectname>
```
Pour créer un nouveau projet appelé myproject, lancer la commande :
```
oc new-project myproject
```
Le retour devrait ressembler à :
```
Now using project "myproject" on server "https://openshift:6443".
```
Vous pouvez ajouter des applications à ce projets avec la commande new-app. Par exemple, essayer :
```
    oc new-app django-psql-example
```
Pour constuire une nouvelle application en Python. Ou utiliser kubectl pour déployer une application simple Kubernetes.
```
    kubectl create deployment hello-node --image=gcr.io/hello-minikube-zero-install/hello-node
```
Nous n'utilisons pas la console web dans ce cours, mais vous pouvez vérifiez ce qu'il se passe dans la console web en cliquand sur l'onglet COnsole et en utilisant les mêmes identifiants que pour la ligne de commande.


