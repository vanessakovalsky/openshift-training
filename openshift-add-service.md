# Ajouter un service de message 

Exercice original : https://www.katacoda.com/courses/openshift/middleware/amq-getting-started-broker

## Aperçu
AMQ fournit une messagerie rapide, légère et sécuriser pour les applications internet. Les composants AMQ utilise les protocoles de messagerie standard de l'industrie et supporte une large palette de langage de programmation et d'environnement d'opération. AMQ donne une fondation forte nécessaire pour construire des applications distribuées modernes.


## Qu'est que AMQ Broker ?
AMQ Broker est un broker de message multiprotocole en pur Java. Il est construit sur un coeur efficace et asynchrone avec un journal natif et rapide pour la persistance des message et l'option de réplication de l'état pour la haute disponibilité.

* Persistance - Un journal rapide et natif sur les IO ou un stockage basé sur JDBC
* Haute disponibilité - Store partagé ou réplication de l'état
* Système de queue avancée - Queues basées sur les dernières vlaures, une hiérarchie des sujet et le support de large message
* Multiprotocole - AMQP 1.0, MQTT, STOMP, OpenWire, et HornetQ Core

AMQ Broker est basé sur le projet Apache ActiveMQ Artemis.

## Objectif 
Dans cet exercice vous apprendrez à configurer une instance de Red Hat AMQ message broker sur OpenShift.

# Créer le projet intial 
Pour commencer, nous devons nous connecter à OpenShift.
Pour se connecter au cluster Openshift, utiliser la commande suivante : 
```
oc login -u developer -p developer 2886795276-8443-kitek02.environments.katacoda.com --insecure-skip-tls-verify=true
```
Cela vous connectera avec ces identifiants :
```
Username: developer
Password: developer
```
Vous devriez voir le résultat :
```
Login successful.
```
Vous n'avez pas de projet, vous pouvez en créer un en lançant : 
```
    oc new-project <projectname>
```
Pour ce scénario, créons un projet appelé messaging avec cette commande :
```
oc new-project messaging
```
Vous devriez avoir un retour similaire à : 
```
Now using project "messaging" on server "https://172.17.0.41:8443".
```
Vous pouvez ajouter des applications à ce projet avec la commande 'new-app'. Par exemple, essayez :
```
    oc new-app centos/ruby-22-centos7~https://github.com/openshift/ruby-ex.git
```
pour construire un nouvel exemple d'application en Ruby

# Déployer une instance de Broker
Avec l'espace de projet disponible, nous allons créer une instance de broker.

Pour autoriser le trafic ingress vers les destinations de message, configurer les secrets nécessaires avec la commande suivante :
```
oc create sa amq-service-account
```
Ajouter une capacité au cluster via un compte de service :
```
oc policy add-role-to-user view system:serviceaccount:messaging:amq-service-account
```
Créer une nouvelle application en utilisant la commande :
```
oc new-app amq-broker-71-basic -p AMQ_PROTOCOL=openwire,amqp,stomp,mqtt -p AMQ_USER=amquser -p AMQ_PASSWORD=amqpassword -p AMQ_QUEUES=example
```
Cette commande créer une instance de broker avec les protocoles OpenWire et AMQP activés. En mme temps, cela créer une queue appelée example
Vous aurez le retour suivant :
```
--> Deploying template "openshift/amq-broker-71-basic" to project messaging

     JBoss AMQ Broker 7.1 (Ephemeral, no SSL)
     ---------
     Application template for JBoss AMQ brokers. These can be deployed as standalone or in a mesh. This template doesn't feature SSL support.

     A new messaging service has been created in your project. It will handle the protocol(s) "openwire,amqp,stomp,mqtt". The username/password 
     for accessing the service is amquser/amqpassword.

     * With parameters:
        * Application Name=broker
        * AMQ Protocols=openwire,amqp,stomp,mqtt
        * Queues=example
        * Topics=
        * AMQ Username=amquser
        * AMQ Password=amqpassword
        * AMQ Role=admin
        * AMQ Name=broker
        * AMQ Global Max Size=100 gb
        * ImageStream Namespace=openshift

--> Creating resources ...
    route "console" created
    service "broker-amq-jolokia" created
    service "broker-amq-amqp" created
    service "broker-amq-mqtt" created
    service "broker-amq-stomp" created
    service "broker-amq-tcp" created
    deploymentconfig "broker-amq" created
--> Success
```
Accéder à votre application via la route 'console-messaging.2886795275-80-kitek02.environments.katacoda.com'
Lancer 'oc status' pour voir votre app.
Lorsque le provisionnement du broker est terminé, vous pourrez commencer à utiliser le service.

# Créer une application de message simple
Le projet exemple est la partie droite de l'ecran, qui montre les composants du projet exemple en Node.js. Ce projet utilises Red Hat OpenShift Application Runtimes, un ensemble d'environnement cloud natif open source pour les applications modernes.

L'application implémente un e messagerie simple avec un service qui envoie simplement un Hello World à une queue et la mme application écoute la même queue pour afficher les messages. Nous utilisons le Client Javascript de Red Hat AMQ pour créer une connection au broker de message pour envoyer et recevoir les messages. 

Le client AMQ est une suite d'aPI de message de AMQP 1.0 qui vous permet de transformer n'importe quel application en application de messagerie. Il inclut à la fois les API standard de l'industrie mais aussi JMS et des nouvelles API pilotées par les évènements qui rendre facile l'intégration des message à n'importe quoi. Le client JavaScript AMQ est basé sur le projet AMQP Rhea. 

## Découvrir le code de l'application :
Les fichiers de l'application sont : 
* package.json - Métadonnées à propos du projet : nom, version, dépendances et autres informations nécessaire pour construire et maintenir le projet
* app.js - Logique principale de l'application exemple

## Installer les dépendances
Se déplacer dans le dossier de l'application avec la commande :
```
cd /root/projects/amq-examples/amq-js-demo
```
Les dépendances sont listées dans le fichier package.json et déclare quel projets externes l'application exemple nécessite. Pour les télécharger et les installer, lancez la commande suivante :
```
npm install
```
Cela prend quelques secondes à télécharger et vous devriez avoir un rapport final ressemblant à :
```
added 140 packages in 2.937s
```

## Déployer
Construire et lancer le projet en utilisant la commande suivante :
```
npm run openshift
```
Cela utilise NPM et le projet NodeShit pour construire et déployer l'application exemple dans OpenShift en utilisant un environnement conteneurisée Node.js

La construction et le déploiement peuvent prendre une à deux minutes. Attendre que cela soit terminé.

Vous devriez voir INFO complete à la fin de la sortie du build, et vous ne devriez pas voir d'erreurs ou d'echecs.


# Accéder à l'application qui tourne sur OpenShift
After the previous step build finishes, it will take less than a minute for the application to become available.

OpenShift ships with a web-based console that will allow users to perform various tasks via a browser.

## Open the OpenShift Web Console
Pour voir comment la console fonctionne, cliquer sur l'onglet "OpenShift Console"
Le premier écran vous affiche un écran de connexion. Entre le nom d'utilisateur et le mot de passe puis cliquer sur Log in
Les informations de connexions sont :
```
Username: developer
Password: developer
```

Après vous être connecté à la console web, vous aurez une liste de projets sur lesquels votre utilisateur à le droit de travailler.

Cliquer sur le nom de projet messaging pour arriver sur la page de présentation du projet.

Vous verrez alors le broker de message et votre nouvelle application en cours de fonctionnement. Cliquer sur la ligne amq-js-demo pour ouvrir le panneau.

Cliquer sur un pod à l'intérieur du cercle blue pour accéder au pod qui exécute votre application.

Cliquer sur l'onglet logs pour accéders aux logs du conteneur de l'application.

Vous verrez un message toutes les 10 secondes avec le texte suivant :
```
Message received: Hello World!
```
Ce message est envoyé et reçu depuis la queue d'exemple de l'application que vous venez de déployer.
