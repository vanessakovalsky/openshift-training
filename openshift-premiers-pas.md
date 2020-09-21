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

This section focuses on using the web console.

Exercise: Logging in with the Web Console
To begin, click on the Console tab on your screen. This will open the web console on your browser.

You should see a Red Hat OpenShift Container Platform window with Username and Password forms as shown below:

OpenShift Web Console

For this scenario, log in by entering the following:

Username: developer

Password: developer

After logging in to the web console, you'll be on a Projects page.

What is a project? Why does it matter?
OpenShift is often referred to as a container application platform in that it is a platform designed for the development and deployment of applications in containers.

To group your application, we use projects. The reason for having a project to contain your application is to allow for controlled access and quotas for developers or teams.

More technically, it's a visualization of the Kubernetes namespace based on the developer access controls.

Exercise: Creating a Project
Click the blue Create Project button.

You should now see a page for creating your first project in the web console. Fill in the Name field as myproject.

Create Project

The rest of the form is optional and up to you to fill in or ignore. Click Create to continue.

After your project is created, you will see some basic information about your project.

Exercise: Explore the Administrator and Developer Perspectives
Notice the navigation menu on the left. When you first log in, you'll typically be in the Administrator Perspective. If you are not in the Administrator Perspective, click the perspective toggle and switch from Developer to Administrator.

Perspective Toggle

You're now in the Administrator Perspective, where you'll find Operators, Workloads, Networking, Storage, Builds, and Administration menus in the navigation.

Take a quick look around these, clicking on a few of the menus to see more options.

Now, toggle to the Developer Perspective. We will spend most of our time in this tutorial in the Developer Perspective. The first thing you'll see is the Topology view. Right now it is empty, and lists several different ways to add content to your project. Once you have an application deployed, it will be visualized here in Topology view.

