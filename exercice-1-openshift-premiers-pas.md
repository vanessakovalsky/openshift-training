# Premier pas avec OpenShift

Sandbox disponible chez RedHat (nécessite de se créer un compte) : [https://developers.redhat.com/developer-sandbox](https://developers.redhat.com/developer-sandbox)

## Objectif
Apprendre à utiliser OpenShift Container Platform pour construire et déployer une application avec un backend de données et un frontend web

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

# Etape 2 - Explorer la console web

Cette section se concentre sur la console web.

## Exercise: Se connecter avec la console Web
Ouvrir votre sandbox developpeur et vous connecter avec votre compte red hat.
Vous arrivez alors sur la console web.
Après vous être connecté à la console web, vous êtes sur la page des projets.


## Qu'est ce qu'un projet ? Pourquoi c'est important ?

OpenShift est souvent vu comme une plateforme d'applications dans des conteneurs dans le sens où la plateforme est conçue pour le développement et le déploiement d'applications dans des conteneurs.

Pour regrouper, nous utilons les projets. La raison pour avoir un projet qui contient les applications est de permettre de controller les accès et les quotas pour les développeurs ou équipes.

Plus techniquement, c'est une visualisation d'un namespace Kubernetes basé sur le contrôle d'accès pour les développeurs.


## Exercise: Explorer les perpectives Administrator et Developer

Regarder le menu de navigation situer à gauche. Lors de votre première connexion, vous êtes typiquement sur une perspective Administrator. Si vous n'êtes pas dans la perspective Administrator, cliquer sur le menu pour passer de Dévelopeur à Administrator ou l'inverse.

Vous êtes maintenant dans la perspective Administrateur, où vous trouverez Operators, Workloads, Networking, Storage, Builds et menu d'administrations dans la barre de menu.

Parcourez rapidement les options, en cliquant sur quelques menus vous verrez plus d'options.

Maintenant, passez à la perspective Développeur. Vous passerez la plupart du temps de cet exercice dans la perspective Développeur. La première chose que vous verrez à la vue par Topologie. Pour l'instant elle est vide, et liste différentes façons d'ajouter du contenu à votre projet. Une fois que votre application est déployée, elle apparaitra dans la vue Topologie

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

Comme expliqué plus tôt dans l'exercice, la méthode de deéploiement des Images de Conteneurs crée une Route par défaut. Comme nous avons décochez cette option, nous allons créer la Route manuellement.

## Exercise: Création d'une Route
Heureusement, créer une route est un process rapide standard. Commencer par aller à la perpective Administrator. Assurez vous que le project myproject est sélectionné dans la liste des projets. Puis, cliquer sur Networking, puis Routes dans le menu de gauche.

Cliquer sur le bouton bleu : Create Route


Entrer parksmap-katacoda pour le nom de la route, sélectionner parksmap-katacoda pour le service et 8080 pour le Target Port. Laisser les autres paramètres par défaut.

Lorsque vous cliquer sur Create, la route est crée et s'affiche dans la page Route Details.

Vous pouvez aussi voir votre Route dans la perspective Developpeur. Revenir à la perspective Developper et aller dans la vue Topologie. Dans la visualisation de parksmap-katacoda vous devriez voir une icone de cercle dans le coin en haut à droite. Cela représente la route, si vous cliquez dessus, cela ouvre l'URL dans votre navigateur.

Une fois que vous avez cliquer l'icon de la Route, vous devriez voir l'application.

## Etape 6 - Construire à partir du code source

Dans cette partie, vous allez déployer le service backend pour l'application Parksmap. Ce service fournit des données via une API REST, sur les principaux parcs nationaux partout dans le monde. Le frontend de l'application ParksMap récupère des données et les affiches sur une crate intractive dans un navigateur web.

## Background: Source-to-Image (S2I)
Dans la section précédente, vous avez appris à déployer une application (le front end de ParksMap) depuis une image de conteneur pré-existante. Ici vous allez apprendre à déployer une application directement depuis le code source hebergé dans un depôt distant Git. Cela est fait avec l'outil Source-To-Image (S2I). 

La documentation de S2I le décrit de la manière suivante :

Source-to-image (S2I) est un outil pour construire des images de conteneurs reproductibles. S2I produit des images prêtes à l'emploi en injectant le code source à l'intérieur d'une image de conteneur et en assemblant une nouvelle image de conteneur qui intègre l'image constuite et les sources. Le resultat est prêt à tre utiliser avec Docker. S2I supporte les constructions incrémentales qui réutilisent les dépendances déjà téléchargés, les artefacts déjà buildés, etc. 

OpenShift rend disponible S2I comme l'un de ces mécanismes de construction (en plus de la construction d'image de conteneurs depuis des DOckerFiles ou des builds "custom").

Une explication complète de S2I est en dehors de l'objectif de cet exercice. Plus d'informations peuvent tre trouvé dans la documentation d'OpenSHift sur S2I et sur le déoôt Github de S2I.

Le seul concept clé que vous devez retenir à propos de S2I est qu'il gère le process de construction des images de conteneur de votre application à partir de votre code source.


## Exercise: Déployer le code de l'applciation
Le service backend que vous allez déployer dans cette partie est appelé nationalparks-katacoda. C'est une application en Python qui renvoir les coordonnées de cartes des principaux parcs nationaux du monde au format JSO via une API REST. Le code source de cette application est disponible sur Github 

https://github.com/openshift-roadshow/nationalparks-katacoda

Pour déployer l'application, utiliser l'option +ADD dans le menu de gauche de la perspective Deloppeur, donc assurez vous d'avoir la console web OpenShift ouverte et d'être dans le projet appelé myproject. Cliquer sur le +ADD. Cette fois au lieu de choisir Container Image, choisir From Catalogue.

SI vous ne voyee aucune option, décocher la case Operator Backed. Dans la section Languages, choisir Python dans la liste des langages supportés. Puis lorsque les options Django + Postgres SQL, Django + Postgres SQL (Ephemeral), et Python, choisir l'option Python et cliquer sur Create Application.

Pour l'adresse du dépôt Git utiliser : 

https://github.com/openshift-roadshow/nationalparks-katacoda

Une fois que vous avez entrer cela, cliquer en dehors du champ text, et sélectionner le nom de l'application qui apparait comme nationalparks-katacoda.Le nom doit être nationalparks-katacoda puisque c'est le nom attendu par l'application Front End ParksMap. 
Laissez les autres options par défaut.
Cliquer sur Create en bas à droite de l'écran et vous revenez à la vue Topologie. Cliquer sur le cercle de l'application nationalparks-katacoda puis que l'onglet Resources dans le panneau. Dans la section Builds, vous devriez voir votre build en cours.

C'est à cette étape où S2I construit l'application à partir du code source du depôt Git pour créer l'image qu'elle lancera. Cliquer sur View Logs pour le build et vous pourrez suivre le constructeur S2I depuis le téléchargement de Python et des paquets nécessaires pour l'applications, puis la préparation de l'application et la création de l'image.

Revenir à la vue TOpologie, lorsque le build est terminé pour voir l'image qui se déploit et l'application qui démarre. Le build est complété lorsque vous voyez dans les logs : Push successful.

La coche verte en bas à gauche dans la visualisation du composant nationalparks-katacoda indique que le build est complet. Une fois que l'anneau passe du bleu clair au bleu, le service backend nationalparks-katacoda est déployé.

Retourner sur l'application front end ParksMap dans le navigateur et vous devriez pouvoir voir les localisation des parcs nationaux apparaitre. Si vous n'avez pas l'application ouverte dans votre navigateur, revvenir à la vue Topologie, et cliquer sur l'icone en haut à droit du cercle de parksmpa-katacoda pour ouvrir l'URL dans votre navigateur.

Féliciations! Vous avez fini d'apprendre les bases du démarrage sur Openshift Container Platform.

