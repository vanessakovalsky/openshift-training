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

Before we get started, you need to login and create a project in OpenShift to work in.

To login to the OpenShift cluster used for this course from the Terminal, run:
```
oc login -u developer -p developer
```
This will log you in using the credentials:
```
Username: developer
Password: developer
```
You should see the output:
```
Login successful.
```
You don't have any projects. You can try to create a new project, by running
```
    oc new-project <projectname>
```
To create a new project called myproject run the command:
```
oc new-project myproject
```
You should see output similar to:

Now using project "myproject" on server "https://openshift:6443".

You can add applications to this project with the 'new-app' command. For example, try:
```
    oc new-app django-psql-example
```
to build a new example application in Python. Or use kubectl to deploy a simple Kubernetes application:
```
    kubectl create deployment hello-node --image=gcr.io/hello-minikube-zero-install/hello-node
```
We are not going to use the web console for this course, but if you want to check anything from the web console, switch to the Console and use the same credentials to login as you used above to login from the command line.
