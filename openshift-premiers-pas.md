# Premier pas avec OpenShift

L'exercice de base en anglais et l'environnement sont dispos ici : https://www.katacoda.com/courses/openshift/introduction/getting-started

## Objectif
Apprendre à utiliser OpenShift Container Platform pour construire et déplouer une application avec un backend de données et un frontend web

## Concepts
* OpenShift Web Console et Perspectives
* OpenShift oc outil ligne de commande
* Constuire des applications depuis les sources sur OpenShift
* OpenShift REST API
* Public URLs et OpenShift Routes

## Cas d'usage

Etre capable de fournir une bonne expérience aux développeurs et aux administrateurs systèmes pour développer, déployer et faire tourner des applications dans des conteneurs en utilisant OpenShift. 


# Etape 1 - Explorer la ligne de commande 
## Command Line Interface (CLI)
Le CLI Openshift est accédé via la commande oc. A partir de cette commande, vous pouvez administrer entièrement le cluster OpenShift et déployer de nouvelles applications.

Le CLI expose le système d'orchestration Kubernetes avec des améliorations faites par OpenShift. Les utilisateurs familiers de Kubernetes seront capables de s'adapter à OpenShift rapidement. OC fournit toutes les fonctionnalités de kubectl, et même des fonctionnalités supplémentaires qui rende plus facile de travailler avec OpenShift. 

Le CLI est idéal dans les situations suivantes :

1) Travaille directement avec le code source du projet

2) Opération de Scripting sur OpenShift

3) Accès restreint en bande passante et pas de possibilité d'utiliser la console web.

Cet exercice, n'est pas dédi au CLI OpenSHift, mais il est important de connaitre les cas où il est préférable d'utiliser la ligne de commande. Pour aller plus loin vous pouvez suivre d'autres exercices. Ici nous ne faisons que nous connecter afin de comprendre comme le CLI fonctionne.

## Exercise: Se connecter avec le CLI
Commençons par nous connecter. Entrer la commande suivante dans la console :
```shell
oc login
```
Lorsqu'on vous le demande entrer les informations suivantes pour le username et le password :
```
Username: developer

Password: developer
```
Ensuite, pour vérifier si cela à fonctionner entrer : 
```shell
oc whoami
```
Cette commande doit retourner la réponse : 
```
developer
```
Et c'est tout !
Dans l'étape suivante, on créera un premier projet en utilisant la console web.

# Etape 2 - Explorer la console web

Cette section se concentre sur la console web.

## Exercise: Se connecter avec la console Web
Pour commencer, appuyer sur l'onglet Console de l'écran. Cela ouvre la console web dans le navigateur.
Vous devriez voir une fenêtre de Red Hat OpenShift Container Plateform s'ouvrir qui vous demande Username et Password
Pour ce scénario, entre les informations suivantes :
```
Username: developer

Password: developer
```
Après vous être connecté à la console web, vous êtes sur la page des projets.

## Qu'est ce qu'un projet ? Pourquoi c'est important ?

OpenShift est souvent vu comme une plateforme d'applications dans des conteneurs dans le sens où la plateforme est conçue pour le développement et le déploiement d'applications dans des conteneurs.

Pour regrouper, nous utilons les projets. La raison pour avoir un projet qui contient les applications est de permettre de controller les accès et les quotas pour les développeurs ou équipes.

Plus techniquement, c'est une visualisation d'un namespace Kubernetes basé sur le contrôle d'accès pour les développeurs.

## Exercise: Créer un Projet
Cliquer sur le bouton blue Create project

Vous devriez voir une page pour créer votre premier projet dans la console web. Remplissez le champ nom avec myproject

Le reste du formulaire est optionnel et à vous de choisir si vous voulez le remplir ou l'ignorez. Cliquuez sur Create pour continuer.

Après que votre projet soit créé vous verrez quelques informations basiques sur votre projet.

## Exercise: Explorer les perpectives Administrator et Developer
Regarder le menu de navigation situer à gauche. Lors de votre première connexion, vous êtes typiquement sur une perspective Administrator. Si vous n'êtes pas dans la perspective Administrator, cliquer sur le menu pour passer de Dévelopeur à Administrator ou l'inverse.

Vous êtes maintenant dans la perspective Administrateur, où vous trouverez Operators, Workloads, Networking, Storage, Builds et menu d'administrations dans la barre de menu.

Parcourez rapidement les options, en cliquant sur quelques menus vous verrez plus d'options.

Maintenant, passez à la perspective Développeur. Vous passeerez la plupart du temps de cet exercice dans la perspective Développeur. La première chose que vous verrez à la vue par Topologie. Pour l'instant elle est vide, et liste différentes façons d'ajouter du contenu à votre projet. Une fois que votre application est déployée, elle apparaitra dans la vue Topologie


