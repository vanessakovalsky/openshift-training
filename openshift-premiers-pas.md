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

# Etape 4 - Mettre à l'échelle votre application

Mettons à l'échelle notre application pour obtenir 2 instance de pods. Vous pouvez le faire en cliquand à l'intérieur du cercle de l'applicatino parksmap-katacoda depuis la vue Topologie pour ouvrir la panneau sur le côté. Dans ce panneau, cliquer sur l'onglet Details, et cliquer sur la flèche "up" à côtéé 

Pour vérifier que nous avons changer le nombre de replicas, cliquer sur l'onglet Resources dans le panneau. Vous devriez voir une list de vos pods.

Vous voyez alors qu'il y a maintenant 2 replicas.

Soulignons comme il est simple de mettre à l'echelle une application (pods dans un service). La mise à l'échelle d'application peut être faite très vite car OpenShift lance juste de nouvelles instances d'image existante, surtout si l'image est déjà en cache sur le node.

## Application "Self Healing"

Les déploiements d'OpenShift sont monitorer en permanence pour vérifier que le nombre de Pods demandés est actuellement en fonctionnement. De plus, si l'état actuel est différent de l'état souhaité, OpenShift travaillera pour résoudre la situation.

Puisque nous avons 2 Pods qui tournent, voyons ce qu'il se passe si nous en tuons un "accidentellement".

Dans l'onglet Ressource, om l'on voit la liste des pods après la mise à l'échelle, ouvrir un pod en cliquant sur son nom dans la liste.

Dans le coin en haut à droite, il y a un menu déroulant Action. Cliquer dessus et choisir Delete Pod.

Après avoir cliquer sur Delete Pod, cliquer sur Delete dans la boite de confirmation. Vous revenez sur la page qui liste les pods, mais cette fois, il y a 3 pods. 

Le pod qui a été supprimé est terminé (il est en cours de nettoyage). Un nouveau pod a été créé puisqu'OpenShift s'assure tourjours lors de l'arrêt d'un pod, qu'un nouveau pod soit créé pour prendre sa place.


## Exercise: Scale Down
Avant de continuer, revenir à une seule instance de votre application. Cliquer sur Topologie pour revenir à la vue Topologie, puis cliquer sur parksmap-katacoda et dans l'onglet aperçu, cliquer sur la flèche vers le bas pour revenir à une seule instance.

## Etape 5 - Routing HTTP Requests
Les services fournissent une abstraction interne et du load balancinf entre les environnement OpenShift, mais certains clients (utilisateurs, systèmes, appareils, etc) en dehors d'OpenShift ont besoin d'avoir accès à l'application. Le moyen pour ces cliens d'avoir accès à l'application en cours d'execution dans Openshift se fait à travers la couche de routing d'OpenShift. L'objet ressource qui le contrôle est une Route.

Le routeur par défaut d'OpenShift (HAProxy) utilise le header HTTP de la requête entrante pour déterminer ou diriger la connexion. Vous pouvez définir des sécurités, comme TLS, pour la Route. Si vous souhaitez que les services, et par extension les Pods, soient accessible au reste du monde, vous devez créer une Route.

Comme expliqué plus tôt dans l'exercice, la méthode de deéploiement des Images de Conteneurs crée une Route par défaut. Comme nousa vons décochez cette option, nous allons créer la Route manuellement.

## Exercise: Création d'une Route
Heureusement, créer une route est un process rapide standard. Commencer par aller à la perpective Administrator. Assurez vous que le project myproject est sélectionné dans la liste des projets. Puis, cliquer sur Networking, puis Routes dans le menu de gauche.

Cliquer sur le bouton bleu : Create Route


Entrer parksmap-katacoda pour le nom de la route, sélectionner parksmap-katacoda pour le service et 8080 pour le Target Port. Laisser les autres paramètres par défaut.

Lorsque vous cliquer sur Create, la route est crée et s'affiche dans la page Route Details.

Vous pouvez aussi voir votre Route dans la perspective Developpeur. Revenir à la perspective Developper et aller dans la vue Topologie. Dans la visualisation de parksmap-katacoda vous devriez voir une icone de cercle dans le coin en haut à droite. Cela représente la route, si vous cliquez dessus, cela ouvre l'URL dans votre navigateur.

Une fois que vous avez cliquer l'icon de la Route, vous devriez voir l'application.

## Etape 6 - Construire à partir du code source

In this section, you are going to deploy a backend service for the ParksMap application. This backend service will provide data, via a REST service API, on major national parks from all over the world. The ParksMap front end web application wi

Background: Source-to-Image (S2I)
In a previous section, you learned how to deploy an application (the ParksMap front end) from a pre-existing container image. Here you will learn how to deploy an application direct from source code hosted in a remote Git repository. This will be done using the Source-to-Image (S2I) tool.

The documentation for S2I describes itself in the following way:

Source-to-image (S2I) is a tool for building reproducible container images. S2I produces ready-to-run images by injecting source code into a container image and assembling a new container image which incorporates the builder image and built source. The result is then ready to use with docker run. S2I supports incremental builds which re-use previously downloaded dependencies, previously built artifacts, etc.

OpenShift is S2I-enabled and can use S2I as one of its build mechanisms (in addition to building container images from Dockerfiles and "custom" builds).

A full discussion of S2I is beyond the scope of this tutorial. More information about S2I can be found in the OpenShift S2I documentation and the GitHub project respository for S2I.

The only key concept you need to remember about S2I is that it handles the process of building your application container image for you from your source code.

Exercise: Deploying the application code
The backend service that you will be deploying in this section is called nationalparks-katacoda. This is a Python application that will return map coordinates of major national parks from all over the world as JSON via a REST service API. The source code repository for the application can be found on GitHub at:

https://github.com/openshift-roadshow/nationalparks-katacoda
To deploy the application you are going to use the +Add option in the left navigation menu of the Developer Perspective, so ensure you have the OpenShift web console open and that you are in the project called myproject. Click +Add. This time, rather than using Container Image, choose From Catalog, which will take you to the following page:

Browse Catalog

If you don't see any items, then uncheck the Operator Backed checkbox. Under the Languages section, select Python in the list of supported languages. When presented with the options of Django + Postgres SQL, Django + Postgres SQL (Ephemeral), and Python, select the Python option and click on Create Application.

Python Builder

For the Git Repo URL use:

https://github.com/openshift-roadshow/nationalparks-katacoda

Create Python

Once you've entered that, click outside of the text entry field, and then you should see the Name of the application show up as nationalparks-katacoda. The Name needs to be nationalparks-katacoda as the front end for the ParksMap application is expecting the backend service to use that name.

Leave all other options as-is.

Click on Create at the bottom right corner of the screen and you will return to the Topology view. Click on the circle for the nationalparks-katacoda application and then the Resources tab in the side panel. In the Builds section, you should see your build running.

Build Running

This is the step where S2I is run on the application source code from the Git repository to create the image which will then be run. Click on the View Logs link for the build and you can follow along as the S2I builder for Python downloads all the Python packages required to run the application, prepares the application, and creates the image.

Build Logs

Head back to Topology view when the build completes to see the image being deployed and the application being started up. The build is complete when you see the following in the build logs: Push successful.

Build Complete

The green check mark in the bottom left of the nationalparks-katacoda component visualization indicates that the build has completed. Once the ring turns from light blue to blue, the backend nationalparks-katacoda service is deployed.

Now, return to the ParksMap front end application in your browser, and you should now be able to see the locations of the national parks displayed. If you don't still have the application open in your browser, go to Topology view and click the icon at the top right of the circle for the parksmap-katacoda application to open the URL in your browser.

ParksMap Front End

Congratulations! You just finished learning the basics of how to get started with the OpenShift Container Platform.

Now that you've completed this tutorial, click Continue for more resources and tools to help you learn more about OpenShift.
