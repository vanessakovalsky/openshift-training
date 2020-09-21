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

# Etape 3 - Déployer une image Docker
Dans cette section, vous allez déployer le composant front end d'une application appelée parksmap. Cette application web affiche une caerte interactive,
qui sera utilisée pour afficher les localisations de parcs nationaux principaux partout dans le monde.

## Exercise: Déployer votre première image 
La méthode la plus simple pour déployer une application sur OpenShift est de prendre une image de conteneur existante et de la lancer. Nous allons utiliser la console web d'OpenShift pour cela, assurez vous d'avoir la console web OpenShift ouverte avec la perspective Developper et d'être dans le projet appelé myproject.

La console web d'OpenShift fournit de nombreuses options pour déployer une application dans un projet. Pour cette section, nous allons utiliser la méthode d'Image de Conteneur.
Comme le projet est vide actuellement, la vue Topologie doit afficher les options suivantes : From Git, Container Image, From Catalog, From Dockerfile, YAML, et Database.

Choisir l'option Container Image

Plus tard, pour revenir à ce menu, vous pouvez cliquer sur +Add dans le menu de gauche.

Sur la page Deploy image entrer lee nom suivant pour l'image depuis un registre externe :

docker.io/openshiftroadshow/parksmap-katacoda:1.2.0

Appuyer sur entrer ou cliquer en dehors de la boite de texte pour valider l'image.

Le champ Application name est rempli avec parksmap-katacoda-app et le champ Nom avec parksmap-katacoda. Ces noms seront ceux utilisés pour votre applications et les composants créé qui se rattache à l'application. Laissez les valeurs générées puisque les étapes suivante utilisent ce nom.

Par défaut, la creation d'un déploiement en utilisant la méthode d'Image de Contneur crée aussi une Route pour notre application. Une Route rend votre application disponible à une URL publique.

Généralement, on laisse cette case coché, car il est très pratique d'avoir une Route crée automatiquement. Dans l'objectif d'apprentissage, décochez cette case. Nous verrons plus tards comment créer une Route nous-mme dans cet exercice. 

Vous êtes prêt à déployer l'image existante de conteneur. Cliquer sur le bouton bleu Create en bas de l'écran. Cela doit vous ramener à la vue Topologie, où vuous aurez une représentation visuelle de l'application que vosu venez juste de déployer. Avec la progression du déploiement de l'image, vous verrez l'anneau de progression de déploiement de parksmap-katacoda passer du bleu clair au bleu.

Ce sont les seuls étapes nécessaire pour déployer un conteneur "vanilla" sur OpenShift. Cela permet à n'importe quel image de conteneur qui suit les bonnes pratiques, comme définir le port des sevices et l'expoiser, dans avoir besion d'utiliser l'utilisateur root ou un autre utilisateur dédié, et qui embarque une commande par défaut pour lancer l'application.
