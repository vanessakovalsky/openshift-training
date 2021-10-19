# Exercice - différents moyens de déployer les applications

## Pré-requis
Pour réaliser cet exercice il est nécessaire d'avoir : 
* git
* un accès à un cluster OpenShift
* l'outil oc (OpenShift Cli)
* de se connecter sur le cluster avec oc login

## Présentation 

Le dépôt https://github.com/openshift-instruqt/blog-django-py contient un exemple d'implémentation d'une application de blog, conçu pour tester les différentes fonctionnalités d'OpenShift. L'application blog est implanté en utilsiant Python et Django.

Dans la configuration du déploiement par défaut, le blog utilise une base de donnée SQLite, dans le conteneur. En utilisant la base de données SQLite, elle sera pré-remplie chaque fois que l'application démarrer avec un ensemble de billets de blog. Un compte initial sera également créé pour se connecter à l'application pour ajouter plus de billets. Le nom d'utilisateur est ``developer`` et le mot de passe est ``developer``.

Puisque la base de données SQLite est stockée dans le conteneur, les nouveaux billets les images seront perdus lorsque le conteneur redémarre. Une base de données PostGreSQL peut être attaché à l'application pour ajouter de de la persistance aux billets et montrer l'utilisation d'une base de données. Un volume persistant séparé peut aussi être attaché à l'applciation blog pour fournir du stockage persistant pour les images téléchargées. Dans le cas de l'utilisation d'une base de données PostGreSQL, une étape manuelle est nécessaire pour configurer la base de données la première fois.

L'apparence de l'application blog peut être ajuster en utiliser un ensemble de variable d'environnement pour rendre plus facile les démonstrations de déploiement bleu/vert ou a/b, la séparation du trafic etc.

## Deployer depuis une image

Une image est automatiquement construite depuis ce dépôt lors des modification sud code en utilisant le mécanisme automatisé de build du DOcker Hub.

Pour déployer l'exemple d'application depuis la ligne de commande, vous pouvez utiliser les commande suivantes :

```
oc new-app openshiftkatacoda/blog-django-py --name blog-from-image
oc expose svc/blog-from-image
```

En cas d'erreur sur l'image docker, vous pouvez utiliser celle-ci : public.ecr.aws/s6z9z6k1/vanessa-ecr 

Vérifier ce qui s'affiche une fois le déploiement l'application terminée

## Construire depuis le code source

Une construction du code source et un déploiement peuvent être fait directement depuis ce dépôt.

Pour construire et déployer l'exemple d'application depuis la ligne de commande, vous pouvez utiliser les commande suivantes :

```
oc new-app python:latest~https://github.com/openshift-katacoda/blog-django-py --name blog-from-source-py
oc expose svc/blog-from-source-py
```

Noter que vous avez besoin de fournir le nom du constructeur S2I ``python:latest`` si vous ne lui dite pas explicitement avec  ``oc new-app`` alors la stratégie de construction depuis le code source sera utilisée. Cela vient du fait que le dépôt contienne un ``Dockerfile`` et qu'une détection automatique est faite par  ``oc new-app`` qui donne la prioriété à la stratégie de construction docker.

Pour construire et déployer l'exemple d'application depuis la ligne de commande, vous pouvez utiliser les commande suivantes :

```
oc new-app --strategy=source https://github.com/openshift-katacoda/blog-django-py --name blog-from-source-auto
oc expose svc/blog-from-source-auto
```

Vérifier ce qui s'affiche une fois le déploiement l'application terminée

## Construire depuis un Dockerfile

Une construction docker et un déploiement peuvent être lancer directement depuis ce dépôt.

Pour construire et déployer l'exemple d'application depuis la ligne de commande, vous pouvez utiliser les commande suivantes :

```
oc new-app https://github.com/openshift-katacoda/blog-django-py --name blog-from-docker
oc expose svc/blog-from-docker
```

Cela est lié au fait que ``oc new-app`` détecte automatiquement et trouve un fichier ``Dockerfile`` existant. Si l'on veut être spécifique, on peut utiliser , vous pouvez utiliser l'option ``--strategy=docker`` pour être sur.

## Ajouter une base de données PostgreSQL

A PostgreSQL database can be used to add persistence for blog posts.

Pour déployer une base de données PostgreSQL depuis la ligne de commande , vous pouvez lancer les commandes suivantes :

``` 
oc new-app postgresql-persistent --name blog-database --param DATABASE_SERVICE_NAME=blog-database --param POSTGRESQL_USER=sampledb --param POSTGRESQL_PASSWORD=sampledb --param POSTGRESQL_DATABASE=sampledb
```

Pour re-configurer l'application blog pour utiliser la base de donnée, il faut définir la variable d'environnement ``DATABASE_URL`` de l'applicaiton blog.

```
oc set env deployment blog-from-source-py DATABASE_URL=postgresql://sampledb:sampledb@blog-database:5432/sampledb
```

Comme un service séparé est utilisé pour la base de donnée, il est nécessaire de configurer manuellement la base de donnée la première fois. Cela nécessite de se connecter dans le pod et de lancer le script ``setup``.

Pour lancer le script ``setup`` depuis la ligne de commande, utiliser les commandes suivantes :

```
POD=`oc get pods --selector deployment=blog-from-source-py -o name`
oc rsh $POD /opt/app-root/src/.s2i/action_hooks//setup
```

Le script ``setup`` initialisera les tables de base de données et vous demanderez les détail du compte initial à paramétrer. (a vous de définir les informations de ce compte et de les noter).

```
$ oc rsh $POD scripts/setup
 -----> Running Django database table migrations.
Operations to perform:
  Apply all migrations: admin, auth, blog, contenttypes, sessions
Running migrations:
  No migrations to apply.
  Your models have changes that are not yet reflected in a migration, and so won't be applied.
  Run 'manage.py makemigrations' to make new migrations, and then re-run 'manage.py migrate' to apply them.
 -----> Running Django super user creation
Username: developer
Email address: mail@example.com
Password:
Password (again):
Superuser created successfully.
 -----> Pre-loading Django database with blog posts.
Installed 2 object(s) from 1 fixture(s)
```
Vous pouvez vous connecter à l'applciation de blog en cliquant sur l'icone de personne en haut à droite de la page web de l'application  blog. Puis cliquer sur l'icône Plus en haut à droit pour ajouter un nouveau billet.

Le titre du billet de blog et le contenu text devrait maintenant survivre à un rédemarrage du conteneur. Tous les images seront perdus quand même pour l'instant sur un redémarrage.

## Ajouter un volume persistant

Un volume persistant peut être utilisé pour stocker de manière persistante les images téléchargées.

Avant qu'un volume persistant soit ajouté, il est nécessaire de modifier la stratégie de déploiement pour l'application Blog en  ``Recreate`` au lieu de  ``Rolling``. Si cela n'est pas fait et qu'un volume persistant de type ``RWO`` est utilisé, les déploiements pourraient échouer en raison du fait que le volume ne peut être monté que sur un seule noeud de cluster en même temps.

Pour modifier la stratégie de déploiement depuis la ligne de commande, vous pouvez exécuter les commandes suivantes :
Une fois le fichier ouvert supprimer les lignes de la clé rolingUpdate puis dans la cle type, remplacer RollingUpdate par Recreate 

```
oc edit deployment blog-from-source-py 
```
Lors du montage du volume persistant pour stocker les images, il devrait être monté sur l'application de blog dans ``/opt/app-root/src/media``.

Pour ajouter un volume persistant depuis la ligne de commande, vous pouvez exécuter les commandes suivantes : 

```
oc set volume deployment blog-from-source-py --add --name=blog-images -t pvc --claim-size=1G -m /opt/app-root/src/media
```

Lorsque les images sont attachées à un billet, elle n'apparaisse pas sur la page racine qui contient tous les billets, vous devez aller dans le billet pour les voir.

Une fois le volume persistant ajouté, s'il est de type ``RWO`` et que vous n'êtes pas sur un cluster d'un seul noeud, vous devez aussi mettre à l'échelle le nombre de réplicas du volume pour éviter que le volume ne puisse pas se monté sur plusieurs noeuds en même temps.

## Personnaliser l'apparence

Pour rendre plus facile la démonstration du déploiements bleu/vert ou a/b, il est possible de modifier l'apparence de l'application blog en définissant des variables d'environnement.  Ce sont : 

* ``BLOG_SITE_NAME`` - Définir le titre pour les pages.
* ``BLOG_BANNER_COLOR`` - Définir la couleur de la bannière de la page.

Pour définir les variables d'environnement depuis la ligne de commande, vous pouvez exécuter les commandes suivantes : 

```
oc set env deployment blog-from-source-py BLOG_BANNER_COLOR=blue
```

Sous le titre de chaque page, le nom d'hôte pour le pod qui gère la requête est aussi affiché. Cela permet de voir que les différentes requêtes son tautomatiquement réparties entre les instances.

## Utiliser Config Maps

En plus d'être capable de faire des personnalisation en utilisant les variables d'environnement, on peut aussi le faire en utilisant une config map.

La config map doit être défini comme fichier de données JSON. Par exemple, enregistrer ce qui suit dans un fichier ``blog.json``.

```
{
   "BLOG_SITE_NAME": "OpenShift Blog",
   "BLOG_BANNER_COLOR": "black"
}
```

La config map peut être créé avec la commande suivante :

```
oc create configmap blog-settings --from-file=blog.json
```

Puis montée dans le conteneur en utilisant : 

```
oc set volume deployment blog-from-source-py --add --name settings --mount-path /opt/app-root/src/settings --configmap-name blog-settings -t configmap
```

Même si un config map est utilisé, les variables d'environnements définies pour les mêmes paramètres prendront le dessus et seront appliquées.
