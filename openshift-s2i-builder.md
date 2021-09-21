# OpenShift - Builder ses propres images avec S2i


## Pré-requis

* Se connecter à un cluster OpenShift en ligne de commande
* Créer un nouveau projet 
* Récupérer l'archive assets_s2_builder.tar dans le dépôt git et décompresser là à l'endroit ou vous travailler.

## Découverte de S2I

L'outil Source-To-Image (S2I) est pleinement intégré à OpenShift. S2I est particulièrement utile pour les développeurs car il peut les protéger des détails de la création des images Docker.

Les deux raisons principales pour utiliser S2I sont : 

1. Les développeurs peuvent lancer des conteneurs Linux sans beaucoup de connaissance à propos de Docker. C'est très bien pour les développeurs qui veulent seulement que leur code fonctionne dans un conteneur Linux. 
2. Les entreprises ont besoin de plus de contrôle sur la manière dont les équipes construisent les images et ne veulent pas accorder la liberté aux développeurs d'installer tout ce qu'ils souhaitent (en tant qu'admin) dans les images de conteneurs. Le processus de S2I force la manière dont l'utilisateur construit ses images et ne permet pas d'installer autre chose durant le process S2I en utilisant les droit d'administrateur.


### Le Runtime simplifié The Simplified Runtime

Pour cet exercice, nous éviterons les complications avec des runtimes spécifiques et/ou des langages avec un process de build spécifique et nous utiliserons un runtime très simple.

Le "runtime" de l'application que nous utiliserons est simplement représenté par la commande Linux "cat" qui affiche le contenu d'un fichier.

Notre runtime de construction d'image S2I contiendra la commande "cat". Pour créer une image d'application, le développeur a seulement besoin de passer les fichiers (code source) pendant le process de build.
Le conteneur de Build connaitra l'endroit ou placer le code pour qu'il puisse être exécutée par le runtime "cat".


### Le process de Build S2I

Le constructeur d'image S2I contient les scripts nécessaire pour la première construction de l'application et le lancement de l'application.


![S2I Build Process](https://github.com/sjbylo/katacoda/tree/master/assets/intermediate/simple-s2i-builder/s2i-process.png)

Comme montré ci-dessus, and le cas le plus simple, le processus de construction de l'image de l'application est le suivant : 

1. Initialiser l'image de construction S2I (cela peut être déclencher automatiquement par un changement de code ou par l'utilisateur)
2. Copier le code source dans le conteneur qui fonctionne
3. Executer le script _assemble_ pour construire le code source et créer l'application
4. Sauvegarder le conteneur pour créer une nouvelle image

### Lancer l'Image de l'application

Lorsque l'image de l'application en résultant est initialiser, le script _run_ exécute la commande _cat_ pour afficher le contenu de tout le "code source" stocker dans l'image.

## Structure d'une image de construiction S2I. 

+ _assemble_ script - ce script est exécuté pendant le process de build de S2I et sait comment construire l'applciation depuis le code source. 
+ _run_ script - ce script est exécuté au lancement de l'application. 
+ _usage_ - affiche des inforamations d'utilisation sur l'image construite.

Regardons les fichier S2I qui seront utilisé pour créer l'image S2I :

``tree builder/``

Ouvrir le script d'assemblage, qui est responsable de la construction de notre application en s'appuyant sur le runtime "cat" 

``clear; cat builder/s2i/assemble``

Noter que les lignes les plus importante créé un dossier pour stocker le code et copie le code à l'intérieur.

```
mkdir -p /tmp/myapp

cp -Rf /tmp/src/* /tmp/myapp
```

Voici basiquement comment notre application simple - basée sur "cat" - est construite!


## Créer une constructin d'image S2I

Une construction d'image S2I peut être créer depuis n'importe quel image Docker standard.
Le Dockerfile dans le dossier _builder_ créer une construction d'image S2I basée sur une image Centos. 

Le schéma montre une façon dont une construction d'image S2I peut être créé.

![S2I Builder Image Build Process](https://github.com/sjbylo/katacoda/tree/master/assets/intermediate/simple-s2i-builder/s2i-builder-image-build-process.png)

Essayer la manière suivante : 

Lisez le Dockerfile pour comprendre comment il créer une construction d'image S2I spécial, principalement en : 


1. ajoutant les scripts nécessaires à S2I (surtout _assemble_ et _run_) et 
2. taguant l'image de manière appropriée.

``clear; cat builder/Dockerfile``

## Créer une construction d'image S2I en utilisant Docker

Créer une construction d'image S2I en utilisant la commande de build standard de Docker (en utilisant le Dockerfile se trouvant dans le dossier _builder_/) : 

``docker build -t s2i-simple-builder builder``

Noter comment les fichiers de scripts S2I sont copiés dans l'image :

``Step 3 : COPY ./s2i/ /usr/libexec/s2i``

La localisation est définie par le label :

``io.openshift.s2i.scripts-url="image:///usr/libexec/s2i"``

Pour qu'OpenShift sache que c'est une construction d'image S2, il faut la taguuer de la manière suivante : 

``io.openshift.tags="builder"``

Que pensez-vous qu'il se passera si vous essayer de lancer l'image de construction S2I directement ?

Essayer comme-ça :

``docker run s2i-simple-builder``

Noter que quand "docker run" est exécuté avec une image de construction S2i (c'est-à-die sans fournir de "code source") un message est affuché décrivant comment utiliser l'image. Le contenu du fichier "usage" est montré et le conteneur s'arrête. 

La commande "docker build" ci-dessous créer l'image mais seulement pour la stocker dans le stockage local de docker et non dans un registre Docker. Cette fois-ci nous allons effectuer la même construction docker mais à l'intérieur d'OpenShift dans le registre interne dans notre cas.

## Créer une construction d'image S2I en utilisant OpenShift

Pour commencer, nous avons besoin de créer la Confiiguratino de construction (Build configuration) qui sait comment construie notre image S2I (en utilisant la stratégie Docker).
  ``--binary=true`` signifie simplement que nous enverrons le Dockerfile et les script S2I nécessaires pour le build depuis un dossier local. 

Lancer les commandes suivante : 

``oc new-build --name s2i-simple-builder --binary=true``

Démarrer le build en utilisant le contenu du dossier local _builder/_ , en suivant les progrès et en attendant que cela soit terminé.

``oc start-build s2i-simple-builder --from-dir=builder --follow --wait``

Si tout c'est bien passé, la nouvelle image S2I  (s2i-simple-builder) a été créé et envoyé correctement dans le registre. Noter que la sortie est exactement la même que la commande "docker build" que nous avons exécutée plus tôt et que l'image est poussé dans le registre interne. Vous devriez vois un message : "Push successful". 

## Examiner le flux d'image du constructeur (Builder Image Stream)

Maintenant, regardon le flux d'image nouvellement créé qui référence et suit la construction d'image S2I dans le registre.  

``oc get is``

``oc describe is s2i-simple-builder``

Lorsque l'image de construction est mise à jour, la nouvelle construction de l'image de l'application peut être déclenchée au travers du flux d'image.

L'image est maintenant prête à être utilisé pour être déployée.

## Utiliser l'image construite avec S2I

Dans l'étape précende, nous avons créé un constructeur d'image S2I. Nous allons maintenant l'utiliser pour créer une nouvelle image de notre application simplifée.

Le "code source" est fait des fichiers dans le répertoire _src/_ .

Le répertoire  _src/_ contient le 'code' que le constructeur d'image S2I peut utiliser pour créer un nouveau conteneur avec l'application à l'intérieur. 

Le "cat runtime" affichera le contenu de tous les fichiers présent dans le dossier _src/_. C'est tout!!!

## Essayez

Pour essayer en utilisant le dossier existant _src/_ qui contient les fichiers de "code source", hellofile et worldfile.

Lisez ces fichiers :

``tree src``

La sortie de la commande devrait être : 

```
src
src/hellofile
src/worldfile
```

En tant que développeur, vous voudrez "tester" votre application en local avant de lancer u nouveau conteneur. Pour ela, lancer le "cat runtime" comme suit : 

``cat src/*``

La sortie de la commande devrait être : 

```
Hello
World
```

## Construire notre conteneur d'applcation

Maintenant que nous sommes satisfait de la manière dont l'application fonctionne, nous pouvons constuire notre conteneur d'application simple en utilisant l'une des façons suivantes : 


### 1st méthode

Construire en utilisant une configuration de construction qui télécharge les fichier depuis le dossier de travail courant et lance l'image en résultant.

Créer une configuration de construction appelé "simple1" en utilisant l'image de construction (s2i-simple-builder) que nous avons créer à l'étape précédente

``oc new-build s2i-simple-builder --binary=true --name simple1``

Lancer le processus de build S2I en envoyer le code source depuis le dossier _src/_ . Une nouvelle image est créé contenant notre application.

``oc start-build simple1 --from-dir=src --follow --wait``

Regarder la sortie. Pouvez vous voir où le script assemble a démarré et a terminé et ce qu'il fait ? 
Il crée un dossier pour l'application et copie les fichiers sources à l'intérieur :

```
+ mkdir -p /tmp/myapp
+ cp -Rf /tmp/src/hellofile /tmp/src/worldfile /tmp/myapp
```

Cela montre comment le processus de construction de S2I fonctionne.
D'abord, le code source est cloné et le script d'assemblage s'exectue. Puis le conteneur en fonctionnement est sauvegarder pour créer une nouvelle image et la pousser dans le registre.

Créer une application depuis la nouvelle image que nous avons créé simple1.

``oc new-app simple1``

Attendez que le pod démarre.

``oc get pod``

Montre que "application simple" fonctionne en affichant la sortie (ajustée en fonction de l'ID du pod) :

``oc logs <simple1-pod-id>``

ou utilisez cette commande : 

``oc logs $(oc get pods | grep ^simple1.*Running|awk '{print $1}'|tail -1)``

Le contenu des fichiers hellofile et worldfile devrait s'afficher comme ceci : 

```
Launching the 'cat runtime'...
Starting application: cat /tmp/myapp/*
Hello
World
Well, that was exhausting! Sleeping...
```

### 2nd méthode

Construire et lancer l'application depuis une seule commande, en utilisant "oc new-app" et en récupérant le code depuis un dépôt git. 

La commande new-app permet de tout faire en une seule ligne. Elle créer le build nécessaire et la configuration de déploiement dans OpenShift, déclenche le bulid qui récupère le code source, puis, une fois que la nouvelle image a été poussé dans le registre, la deploie automatiquement via la configuration du déploiement.

``oc new-app s2i-simple-builder~https://github.com/sjbylo/katacoda.git --context-dir=intermediate/simple-s2i-builder/assets/src --name simple2``

Voir le journal de construction de S2I :

``oc logs bc/simple2 --follow``

Voir le pod en cours d'execution :

``oc get pods``

Avec l'ID du pod, voir la sortie du pod (adapter l'ID du pod):

``oc logs <simple2-pod-id>``

ou lancer la commande suivante :

``oc logs $(oc get pods | grep ^simple2.*Running|awk '{print $1}'|tail -1)``

Comme dans l'étape précédente, la sortie de l'application qui fonctionne est la suivante : 

```
Launching the 'cat runtime'...
Starting application: cat /tmp/myapp/*
Hello
World
Well, that was exhausting! Sleeping...
```

Félicitations, vous savez maintenant utiliser S2I pour définir des constructeurs d'image et les utiliser pour lancer des applications