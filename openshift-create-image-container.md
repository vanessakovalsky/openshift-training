# Construire une image personnalisé et la stocker sur le registre OpenShift

## Pré-requis :
- Récupérer le code dans ce depot (app.py et requirements.txt):
https://github.com/praqma-training/docker-katas/tree/master/labs/building-an-image

## Créer le docker file
- Nous allons créer un docker file pour pouvoir construire l'image nécessaire à l'execution de l'application :
- Créer un fichier Dockerfile (sans extension) au même niveau que les deux fichiers récupérer sur le dépôt
- Ouvrir le fichier (toutes les instructions seront à rajouter dans le fichier) et ajouter l'image de base :
```
FROM ubuntu:latest
```
- Ajouter maintenant l'installation des outils nécessaires :
```
RUN apt-get update -y
RUN apt-get install -y python3-pip python3-dev build-essential
```
- Ensuite installer les bibliothèques nécessaires à l'aide pip et du fichier requirements.txt :
```
COPY requirements.txt /usr/src/app/
RUN pip3 install --no-cache-dir -r /usr/src/app/requirements.txt
```
- Puis copier le fichier de l'application
```
COPY app.py /usr/src/app/
```
- Et exposer le port 5000 sur lequel l'application tourne 
```
EXPOSE 5000
```
- Enfin nous utilisons CMD pour lancer l'application
```
CMD ["python3", "/usr/src/app/app.py"]
```
- Notre dockerfile est prêt pour la suite

## Construction de notre image
- Dans le dossier avec le dockerfile, lancer la commande de build pour construire l'image, l'option -t permet de nommer l'image construite :
```
docker build -t myfirstapp .
```
- Que s'est t'il passé pendant le build ?
- Vérifier que l'image est bien disponible :
```
docker images
```

## Lancement du conteneur avec l'image construite
- Il ne reste plus qu'à lancer le conteneur :
```
docker container run -p 8888:5000 --name myfirstapp myfirstapp
```
- Pour accéder à l'application, ouvrir le port 8888 sur l'hôte puisque c'est ce port qui est mappé sur le port 5000 de notre application (ou tout autre port au choix lors du lancement du conteneur)

## Layer des images :
- Chaque image construire est basée sur plusieurs layers, c'est-à-dire plusieurs images superposées les unes aux autres
- Pour voir l'ensemble des images utilisées par une image :
```
docker image history <image ID>
```
- Il est possible d'utiliser chacune de ces couches puisqu'elles sont mises en cache dans le gestionnaires d'images de docker, ce qui permet de réutiliser différents layers pour des images finales différentes

## Tagguer notre image et la pousser sur le registre OpenShift

* Afin de pouvoir envoyer notre image, nous allons devoir nous connecter au registre OpenShift, pour cela utiliser les commandes suivantes :
```sh
docker login -u `oc whoami` -p `oc whoami --show-token` docker tag newimage [URL-DE-VOTRE-REGISTRE]:[PORT]/newimage
```

* Puis nous allons commiter l'image, puis lui associé un tag et enfin l'envoyer sur le registre 
```sh
docker commit <containerID> newimage
docker tag newimage [URL-DE-VOTRE-REGISTRE]:[PORT]/newimage
docker push [URL-DE-VOTRE-REGISTRE]:[PORT]/newimage:latest
```

* Vérifier dans le registre d'OC dans la console web si l'image est bien présente