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

# Creating a Simple Messaging Application
The sample project in the upper right part side of the screen, shows the components of your sample Node.js project. This project uses Red Hat 
OpenShift Application Runtimes, a set of open source cloud native application runtimes for modern applications.

The app implements a simple messaging greeting service that simply sends a Hello World! to a queue and the same application listens in the same 
queue for greeting messages. We use the Red Hat AMQ JavaScript Client to create a connection to the messaging broker to send and receive messages.

The AMQ Clients is a suite of AMQP 1.0 messaging APIs that allow you to make any application a messaging application. It includes both 
industry-standard APIs such as JMS and new event-driven APIs that make it easy to integrate messaging anywhere. The AMQ Javascript Client is 
based on the AMQP Rhea Project.

## Inspect the application code
Click the links below to open each file and inspect its contents:

* package.json - Metadata about the project: name, version, dependencies, and other information needed to build and maintain the project.
* app.js - Main logic of the sample application.
## Install Dependencies
Switch to the application directory in the command line by issuing the following command:
```
cd /root/projects/amq-examples/amq-js-demo
```
Dependencies are listed in the package.json file and declare which external projects this sample app requires. To download and install them, 
run the following command:
```
npm install
```
It will take a few seconds to download, and you should see a final report such as
```
added 140 packages in 2.937s
```

## Deploy
Build and deploy the project using the following command:
```
npm run openshift
```
This uses NPM and the Nodeshift project to build and deploy the sample application to OpenShift using the containerized Node.js runtime.

The build and deploy may take a minute or two. Wait for it to complete.

You should see INFO complete at the end of the build output, and you should not see any obvious errors or failures. In the next step you will 
explore OpenShift's web console to check your application is running.

# Access the application running on OpenShift
After the previous step build finishes, it will take less than a minute for the application to become available.

OpenShift ships with a web-based console that will allow users to perform various tasks via a browser.

## Open the OpenShift Web Console
To get a feel for how the web console works, click on the "OpenShift Console" tab.

OpenShift Console Tab

The first screen you will see is the authentication screen. Enter your username and password and then log in.

Your credentials are:
```
Username: developer
Password: developer
```
Web Console Login

After you have authenticated to the web console, you will be presented with a list of projects that your user has permission to work with.

Click on your the messaging project name to be taken to the project overview page.

Messaging Project

You will see the messaging broker and your brand new application running. Click in the amq-js-demo row to expand the panel.

AMQ Javascript Demo

Click in the 1 pod inside the blue circle to access the actual pod running your application.

Application Pod

Click in the logs tab to access the application container logs.

Log

You will see a message every 10 seconds with the following text:
```
Message received: Hello World!
```
This message is been sent and received to the example queue by the application you just deployed.
