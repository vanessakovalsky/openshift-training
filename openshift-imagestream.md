# OpenShift - Utiliser les flux d'image (ImageStream)


## Présentation

Certaines ressources OpenShift, commes les pods, deployments, DeploymentConfigs, ReplicationControllers, et ReplicaSets font référence à des images Docker pour déployer les conteneurs. Au lieu de référencer les images directement, l'approche commune est de les référencer au traver d'un flux d'image, qui serve de couche de référence entre le registre interne/externe et les ressources du client, en créant une vue virtuelle des images disponibles.

## Avantages

Utiliser les flux d'image présente les avantages suivants :

* Votre application ne cassera pas de manière inatendu si la mise à jour d'une image introduit des erreurs, car les pods pointes sur les tags du flux d'images, qui vous protèges au travers des déclencheurs de changement d'image (Image-change), et le réimport périodique de l'image peut être confuré au niveau du flux d'image.
* Vous n'aurez probablement pas à créer des flux d'images (ImageStream) depuis zéro, mais il est important de comprendre leur structure afin de comprendre leur fonctions. 

OpenShift inclut des dlus d'aimges par défaut pour les images les plus populaires comme PostgreSQL, HTTPD, et Python. Ils sont dans le projet openshift :
`oc get is -n openshift`

Afin de mieux comprendre la couche de reference dont on parlait avant, voyons de plus près le flux d'image de mongodb:
`oc describe is/mongodb -n openshift`{{execute}}


Les flux d'images utilise une notation spécifique poru référencer les images dans les registres. Si nous repartons de l'exemple précédons et le détaillons : 

Les flux d'aimges ne sont pas utile par eux-même et existent seulement pour supporter le cycle de vie de l'application. Ils sont créés généralement en arrière plan dans les scénarios suivants : 

- Création d'applications depuis les builds S2I
- Importation d'images
- Creation d'applications directement depuis des images Docker
- Envoi manuel d'image dans un registre interne


## Import

Les flux d'images peuvent être créés en important des images depuis des registres externes vers le registre interne : 
`oc import-image nginx --confirm`

Vous pouvez voir dans la sortie précédentente que l'image Ngninx a été envoyé dans le registre interne à l'adresse HOST_IP:5000/advanced/nginx. 
Comme vous pouvez le remarquer, son nom correspond à la structure de l'image référencé que nous avons fournit plus tôt

Supprimons le flux d'image pour préparer le prochain exercice:
`oc delete is/nginx`

```
imagestream "nginx" deleted
```

## Créer à partir d'une image Docker

Une autre façon de créer un flux d'image est d'utiliser la commande new-app qui permet de créer une application depuis une image Docker prête à être utilisée :

`oc new-app gists/lighttpd`

**Note:** Lighttpd est un autre serveur web, comme Nginx ou Apache. Nous utilisons dans cet exempla car les flux d'images de Nginx et Apache sont fournis nativement par OpenShift.

Cela crée plusieurs ressources, l'une d'elle est un flux d'image.

Si vous regarder la configuration du déploiement de l'application nouvellement crée, pas l'image en elle-même :
`oc describe deployment lighttpd`

Dans l'exemple précédente, les références de Deployment à une image de serveur dans le flux d'image selon le schéma suivant :

```
gists/lighttpd: Image stream name
sha256: Indicates that the image identifier is generated using the SHA256 hash algorithm
23c7c16d3c294e6595832dccc95c49ed56a5b34e03c8905b6db6fb8d66b8d950: The image hash/ID itself
```

Voici comment les configuration de déploiement et les controleurs de réplications utilisent généralement les images de référence de OpenShift.

Penser à nettoyer l'environnement:
`oc delete all --all`

## Pousser une image sur un registre interne OpenShift

La dernière méthode de création des flux d'images est de poussser des images directement sur un registre interne OpenShift.

Se connecter sur OpenShift (si ce n'est pas fait):
`oc login -u monuser`

Puis, lancer la commande suivante pour se connecter au registre interne : 
`docker login -u $(oc whoami) -p $(oc whoami -t) [[HOST_IP]]:5000`

Dans la commande précédente, nous utilisons une fonctionnalité de bash, appelé extension de commande, qui nous permet de fournir à la commande login, le nom d'utilisateur, password/token, et l'IP:port du registre, de la gauche à la droite.
Vous pouvez lancer ces commandes individuellement pour voir le retour de chaque commande (oc whoami et oc whoami -t).

Maintenant que nous sommes connecté au registre interne, vous pouvez pousser les images directement, comme vous le faites pour le registre Docker public. Vérifions es images présentes dans le registre interne d'OpenShift :
`docker images`

Supprimons l'image de Lighttpd restant du précédent exercice :
`docker rmi cd7b7073c0fc`

Nous pouvons maintenant utiliser l'image Lighttpd, comme dans la section précédente : 
`docker pull gists/lighttpd`

Tagguer le avec l'adresse du registre et le port dans le tag : 
`docker tag docker.io/gists/lighttpd [[HOST_IP]]:5000/advanced/lighttpd`

**Note:** Nous utilisons le nom du projet pour créer des flux d'images comme une partie du chemin de l'image dans le registre  car le token utilisé pour accordé l'accès à l'utilisateur pour créer un flux d'image est seulement autorisé dans notre projet. OpenShift cherche les images dans une localisation particulière à un endroit ou il peut créer des flux d'images depuis les images.

Voyons si l'image avec les deux tags est bien référencée :
`docker images`

Enfin, nous devons pousser l'image sur le dépôt : 
`docker push [[HOST_IP]]:5000/advanced/lighttpd`

L'envoi se fait sur le dépôt [[[HOST_IP]]:5000/advanced/lighttpd]

Vérifier maintenant que le flux d'image de lighttpd est crée sur OpenShift :
`oc get is`

```
NAME     DOCKER REPO                                        TAGS   UPDATED
lighttpd [[HOST_IP]]:5000/advanced/lighttpd latest 15 minutes ago
```

Comme prévu, le flux d'image est bien crée.

Pensez à supprimer ce qui a été créé avant de continuer :
`oc delete is/lighttpd`
