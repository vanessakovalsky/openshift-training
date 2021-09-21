# Transférer des fichiers dans et depuis un container avec OpenShift

Exercice original ici : https://www.katacoda.com/courses/openshift/introduction/transferring-files 

## Objectif
Apprendre à copier des fichiers dans et depuis un conteneur en fonctionnement sans reconstruire l'image du conteneur. Améliorer ça avec une fonction de surveillance qui applique automatiquement les modifications locales à un conteneur en cours de fonctionnement afin de voir immédiatement l'effet des changements sur l'application.


## Concepts
* Boucle rapid de développement pour modifier un conteneur en cours d'execution
* OpenShift Projets et Applications
* OpenShift outils oc et sa sous commande new-app

## Cas d'usage
Vous pouvez modifier une application dans un conteneur pour développer et tester avant de construire une nouvelle version de l'image de conteneur. Syncronisation automatique du conteneur avec les changements locaux rend plus rapide la boucle de développement et de tests, particulièrement dans les langages de programmations interprétés.

# Etape 1 - Crér un projet 

Avant de démarrer, vous devez vous connecter et créer un projet pour travailler dedans.

Pour se connecter au cluster OpenShift utilisé dans ce cours, lancer dans le terminal 
```
oc login -u developer -p developer
```
Vous serez alors identifiés avec les credentials :
```
Username: developer
Password: developer
```
Vous devriez avoir la sortie suivante :
```
Login successful.
```
Vous n'avez pas de projet. Vous pouvez en créer un avec la commande :
```
    oc new-project <projectname>
```
Pour créer un nouveau projet appelé myproject, lancer la commande :
```
oc new-project myproject
```
Le retour devrait ressembler à :
```
Now using project "myproject" on server "https://openshift:6443".
```
Vous pouvez ajouter des applications à ce projets avec la commande new-app. Par exemple, essayer :
```
    oc new-app django-psql-example
```
Nous n'utilisons pas la console web dans ce cours, mais vous pouvez vérifiez ce qu'il se passe dans la console web en cliquand sur l'onglet COnsole et en utilisant les mêmes identifiants que pour la ligne de commande.

# Etape 2- Télécharger les fichiers depuis un conteneur
Pour montrer le transfert de fichiers depuis et dans un conteneur en cours d'execution, nous devons d'abord déployer une application. Pour ce faire utiliser cette commande :
```
oc new-app openshiftkatacoda/blog-django-py --name blog
```
Pour accéder à l'application dans un navigateur web, nous abons besoin d'exposer l'application en créant une Route.
```
oc expose svc/blog
```
Pour suivre le déploiement de l'application lancer :
```
oc status 
``` 

Le résultat du déploiement sera l'execution du conteneur. Vous pouvez voir le nom des pods correspondant qui executent les conteneurs pour cette application en lançant : 
```
oc get pods --selector deployment=blog
```
Vous n'avez qu'une instance de l'application, donc un seul pod qui est listé, similaire à :
```
NAME           READY     STATUS    RESTARTS   AGE
blog-1-9j3p3   1/1       Running   0          1m
```
Pour les commandes suivantes qui intéragissent avec le pod vous aurez besoin du nom du pod comme argument.

Pour faciliter la référence au nom du pod dans ces instructions, nous définissons une fonction shell pour capture le nom et le stocker comme variable d'environnement. Cette variable d'environnement sera utilisé dans les commandes à lancer.
La commande que nous lançons avec la fonction shell pour obtenir le nom du pod sera : 
```
oc get pods --selector deployment=blog -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}'
```
Comme au-dessus, nous utilisons oc get pods avec un sélécteur de label, mais aussi une requête jsonpath pour extraire le nom du pod en cours d'execution.
Pour créer la fonction shell lancer : 
```
pod() { local selector=$1; local query='?(@.status.phase=="Running")'; oc get pods --selector $selector -o jsonpath="{.items[$query].metadata.name}"; }
```
Pour enregistrer le nom du pod et le définir comme variable d'environnement POD lancer : 
```
POD=`pod deployment=blog`; echo $POD
```
Pour créer un shell interactif avec le même conteneur executant l'application, vous pouvez utiliser la command oc rsh, suivi du nom de la variable d'environnement qui contient le pod :
```
oc rsh $POD
```
Depuis le shell interactif, voir les fichiers qui existe dans le répertoire de l'application :
```
ls -las
```
Cela vous donnera une liste similaire à : 
```
total 80
 0 drwxrwxr-x. 1 default    root    52 Oct 24 02:51 .
 0 drwxrwxr-x. 1 default    root    28 Jun 18 02:10 ..
 4 -rwxrwxr-x. 1 default    root  1454 Jun 18 02:07 app.sh
 0 drwxrwxr-x. 1 default    root    43 Jun 18 02:11 blog
 0 drwxrwxr-x. 2 default    root    25 Jun 18 02:07 configs
 4 -rw-rw-r--. 1 default    root   230 Jun 18 02:07 cronjobs.py
44 -rw-r--r--. 1 1000520000 root 44032 Oct 24 02:51 db.sqlite3
 4 -rw-rw-r--. 1 default    root   430 Jun 18 02:07 Dockerfile
 0 drwxrwxr-x. 2 default    root    25 Jun 18 02:07 htdocs
 0 drwxrwxr-x. 1 default    root    25 Jun 18 02:11 katacoda
 4 -rwxrwxr-x. 1 default    root   806 Jun 18 02:07 manage.py
 0 drwxrwxr-x. 3 default    root    20 Jun 18 02:11 media
 0 drwxrwxr-x. 1 default    root    19 Apr  3  2019 .pki
 4 -rw-rw-r--. 1 default    root   832 Jun 18 02:07 posts.json
 8 -rw-rw-r--. 1 default    root  7861 Jun 18 02:07 README.md
 4 -rw-rw-r--. 1 default    root   203 Jun 18 02:07 requirements.txt
 4 -rw-rw----. 1 default    root  1024 Apr  3  2019 .rnd
 0 drwxrwxr-x. 4 default    root    57 Jun 18 02:09 .s2i
 0 drwxrwxr-x. 4 default    root    30 Jun 18 02:11 static
 0 drwxrwxr-x. 2 default    root   148 Jun 18 02:07 templates
 ```
 Pour l'application utilisé, cela a créer un fichier de base de données :
```
44 -rw-r--r--. 1 1000520000 root 44032 Oct 24 02:51 db.sqlite3
```
Voyons comment copier ce fichier de base de données sur la machine locale .
Pour confirmer le répertoire dans lequel le fichier se trouve, dans le conteneur lancer :
```
pwd
```
Cela devrait afficher : 
```
/opt/app-root/src
```
Pour sortir du terminal interactif et retourner à la machine local lancer :
```
exit
```
Pour copier des fichiers depuis le conteneur vers la machine local la command oc rsync peut être utilisé.
La form de la commande pour copier un fichier unique depuis le conteneur vers la machine local est :
```
oc rsync <pod-name>:/remote/dir/filename ./local/dir
```
Pour copier le fichier de base de données, lancer :
```
oc rsync $POD:/opt/app-root/src/db.sqlite3 .
```
Le resultat devrait être similaire à :
```
receiving incremental file list
db.sqlite3

sent 43 bytes  received 44,129 bytes  88,344.00 bytes/sec
total size is 44,032  speedup is 1.00
```
Vérifier le contenu du répertoire courant en lançant :
```
ls -las
```
Vous devriez voir que la machine local a maintenant une copie du fichier :
```
44 -rw-r--r--  1 root root 44032 Oct 24 04:15 db.sqlite3
```
NB : le répertoire local dans lequel le fichier est copié doit existé. Si vous ne voulez pas copier dans le répertoire courant, assurez-vous que le répertoire cible a été créé auparavant.

En plus de copier un fichier unique, un dossier peut aussi être copier. La forme de la commande pour copier un dossier vers la machine locale est :
```
oc rsync <pod-name>:/remote/dir ./local/dir
```
Pour copier le dossier media depuis le conteneur, lancer :
```
oc rsync $POD:/opt/app-root/src/media .
```
Si vous voulez renommer le répertoire qui est copier, vous devez créer le répertoire cible avec le nom que vous souhaiter avant :
```
mkdir uploads
```
puis copier les fichiers avec la commande :
```
oc rsync $POD:/opt/app-root/src/media/. uploads
```
Pour s'assurer que seul le contenu du dossier sur le conteneur est copié, et pas le répertoire lui-même, le dossier distant est suffixé avec /..

NB : Si le dossier cible contient des fichiers ayant le même nom que les fichiers copiés depuis le conteneur, les fichiers locaux seront remplacés. S'il y a des fichiers dans le dossier cible qui n'existe pas sur le conteneur, ces fichiers ne seront pas modifiés. Si vous voulez une copie exacte, où le dossier cible soit toujours mis à jour avec exactement la même chose que ce qui existe dans le conteneur, utiliser l'option --delete avec le oc rsync.

Lorsque vous copier un dossier, vous pouvez être plus sélectif avec ce qui est copier en utilisant les options --excludes et --includes pour spécifier des modèles à trouver dans les dossiers et fichiers, qui seront exclus ou inclus comme indiqué.

Si vous avez plus d'un conteneur qui tourne dans un pod, vous devez spécifier avec quel conteneur vous voulez travailler avec l'option --container.

# Etape 3 - Envoyer  des fichiers dans un conteneur

Pour copier les fichiers depuis la machine locale vers le conteneur, on utilise encore la commande oc rsync
La forme de la commande pour copier des fichiers depuis la machine locale vers le conteneur est :
```
oc rsync ./local/dir <pod-name>:/remote/dir
```
A l'inverse de la copie depuis le conteneur vers la machine local, il n'y a pas de syntaxe pour copier un seul fichier. Pour copier les fichiers sélectionnés uniquement, vous aurez besoin d'utiliser les options --exclude et --includes pour filtre ce qui doit et ne doit pas être copier depuis un dossier spécifié.

Pour illustrer le process de copie d'un fichier, considérer le cas où vous avez déployé un site web et pas inclus le fichier robots.txt, mais que ce fichier est nécessaire pour les robot qui indexe votre site.

Une requête pour récupérer le fichier robots.txt courant sur le sit echoue avec une réponse 404 Not Found.
```
curl --head http://blog-myproject.2886795294-80-ollie05.environments.katacoda.com/robots.txt
```
Créer un fichier robtos.txt à envoyer.
```
cat > robots.txt << !
User-agent: *
Disallow: /
!
```
Pour que l'application l'utilise, les fichiers statiques sont dans un sous-dossier de htdocs au sein du code source. POur envoyer le fichier robots.txt, lancer : 
```
oc rsync . $POD:/opt/app-root/src/htdocs --exclude=* --include=robots.txt --no-perms
```
Comme déjà dit, il n'est pas possible de copier un fichier unique, donc nous indiquons le dossier courant doit tre copier, mais en utilisant l'option --exclude=* cela ignorent tous les fichiers. Ce modèle est surchargé juste pour le fichier robots.txt en utilisant l'option --include=robots.txt, assurant que le fichier robots.txt est copié.

Lorsque vous copier des fichiers dans le conteneur, il est nécessaire que le répertoire cible dans lequel les fichiers vont être copiés existe et qu'il soit accessible en ecriture pour l'utilisateur ou le groupe avec lequel le conteneur est executé. Les permissions sur les dossiers et fichiers doivent faire parties du process de construction de l'image.

Dans la commande ci-dessus, l'option --no-per est aussi utilisé car le répertoire cible dans le conteneur, bien qu'accessible en écriture par le groupe qui execute le conteneur, appartient à un utilisateur différent de celui qui execute le conteneur. Cela signifie que bien que des fichiers puissent être ajouté au dossier, les permissions sur les dossiers existant ne peuvent pas être modifiées. L'option --no-perms dit à oc rsync de ne pas essayer de mettre à jour les permissions pour éviter l'echec et le renvoit d'erreurs.

Avec la présence du fichier robotox.txt, récupérer le fichier robots.txt est maintenant un succès.
```
curl http://blog-myproject.2886795294-80-ollie05.environments.katacoda.com/robots.txt
```
Cela fonctionne sans actions supplémentaire car le serveur Apache HTTPD utilisé pour héberger les fichiers statiques, détecte automatique la présence de nouveau fichier dans le dossier.

Si vous voulez copier un dossier complet à la plase d'un seul fichier, retirer les options --incle et --exclude. Pour copier le contenu complet du dossier courant dans le dossier htdocs du conteneur lancer : 
```
oc rsync . $POD:/opt/app-root/src/htdocs --no-perms
```
Faite juste attention que cela inclus tout, y-compris les fichiers cachés ou les dossiers commençant par un ".". Vous devriez faire attention, et si nécessaire être plus spécifique en utilisant les options --include ou --exclude pour limiter la liste des fichiers ou dossiers copiés.

# Etape 4 - Syncroniser les fichiers avec un conteneur

En plus de permettre l'envoi ou le téléchargement manuel de fichiers, vous pouvez choisir de rendre vivante la syncronisation des fichiers entre votre local et le container avec la commande oc rsync.

Pour cela le système de fichier de votre local surveillera tous les changements fait sur les fichiers. En cas de changement, le fichier modifié sera automatiquement copié sur le conteneur.

Le même process peut aussi être lancer dans l'autre sens si nécessaire, lorsqu'un changement est fait dans le conteneur une copie est faite sur l'environnement local.

Un exemple de ce qui peut être utile peuvent utile d'avoir les changements copiés automatiquement du local vers le conteneur est la phase de développement d'une application.

Pour les langages de programmation interprétés comme PHP, Python ou Ruby, ou aucune phase de compilation est requise, cela permet au serveur web d'être manuellement démarré sans causé d'erreur dans le conteneur, ou si le serveur web recharge toujours les fichiers de code qui ont été modifié, vous pouvez faire du développement en live avec l'application qui tourne à l'intérieur d'OpenShift.

Pour tester cette possibilité, cloner ce dépôt git pour l'application que vous avez déjà déployée.
```
git clone https://github.com/openshift-katacoda/blog-django-py
```
Cela crée un sous dossier blog-django-py contenant le code source de l'application :
```
Cloning into 'blog-django-py'...
remote: Enumerating objects: 3, done.
remote: Counting objects: 100% (3/3), done.
remote: Compressing objects: 100% (3/3), done.
remote: Total 412 (delta 0), reused 0 (delta 0), pack-reused 409
Receiving objects: 100% (412/412), 68.49 KiB | 701.00 KiB/s, done.
Resolving deltas: 100% (200/200), done.
```
Lancer maintenant la commande oc rsync suivante pour avoir la syncronisation live du code, copiant les changement du dossier blog-django-py vers le conteneur.
```
oc rsync blog-django-py/. $POD:/opt/app-root/src --no-perms --watch &
```
Dans le cas où l'application tourne dans un process en arrière plan, et que nous n'avons qu'un terminal à disposition, vous pouvez lancer le process en arrière-plan dans un autre terminal.

Vous pouvez voir le détails de process tournant en arrière-plan en lançant : 
```
jobs
```
Lorsque vous lancer la commande oc rsync pour la première fois, vous voyez les fichiers se copier depuis le local vers le conteneur. Tous changements fait sur les fichiers en local seront maintenant automatiquement copier sur le dossier distant.

Avant de faire un changement, ouvrir l'URL de l'application web dans un autre onglet du navigateur.
```
http://blog-myproject.2886795294-80-ollie05.environments.katacoda.com/
```
Vous devriez voir la couleur du titre de la bannière en rouge.
Changeons la couleur de la bannière en lançant la commande : 
```
echo "BLOG_BANNER_COLOR = 'blue'" >> blog-django-py/blog/context_processors.py
```
Attendre que le fichier modifié soit envoyé, puis rafraichir la page du site web.

Malheureusement le titre de la bannière est toujours rouge. Cela vient du fait que Python met en cache le code lors du lancement du process et il est donc nécessaire de redémarrer le server web de l'application.

Pour ce déploiement, le serveur WSGI mod_wsgi_express est utilisé. Pour déclencher un redémarrage du serveur d'application, lancer : 
```
oc rsh $POD kill -HUP 1
```
Cette commande a pour effet d'envoyer un signal HUP au process avec l'ID 1 qui tourne dans le conteneur, qui est l'instance de mod_wsgi-express qui tourne. Cela déclenche un redemarrage et un rechargement de l'application, mais sans coupure du serveur web.

Rafraichir la page du site web une fois de plus et le titre de la bannière doit maintenant être bleu.

NB : le nom du pod affiché dans la bannière n'a pas changer, ce qui indique le pod n'a pas redémarrer mais seulement le process du serveur web d'application qui a été redémarré.

Forcer manuellement un rédemarrage du serveur web d'application aurait fait le travail, mais une meilleur façon de faire est que le serveur puisse détécter automatique les modifications de code et déclencher un redémarrage.

Dans le cad u mod_wsgi-express et la manière dont l'application a été configuré, on peut l'activer en définissant une variable d'environnement pour le déploiement. Pour définir la variable d'environnement lancer :
```
oc set env deployment blog MOD_WSGI_RELOAD_ON_CHANGES=1
```
Cette commande met à jour la configuration du déploiement, eteint le pod existant et le remplace avec un nouvelle instance de notre application avec la variable d'environement qui est passé à l'application.

Suivre le re-déploiement de l'application en lançant :
```
oc status
```
Puisque le pod existant a été éteint, il est nécessaire de ré-enregistrer le nom du nouveau pod.
Because the existing pod has been shutdown, we will need to capture again the new name for the pod.
```
POD=`pod deployment=blog`; echo $POD
```
Vous avez peut être remarque que le process de syncronisation qui tournait en arrière plan c'est aussi arrêté. Cela vient du fait que le pod ait été arrêté.

Vous pouvez le vérifier avec : 
```
jobs
```
S'il apparait encore comme en cours, cela vient du fait que l'arret du pod n'a pas encore été détécté, lancer la commande suivante pour l'arrêter : 
```
kill -9 %1
```
S'assurer que la tache en arrière plan s'est arrêtée : 
```
jobs
```
Maintenant lancer de nouveau la commande oc rsync, avec le nouveau pod.
```
oc rsync blog-django-py/. $POD:/opt/app-root/src --no-perms --watch &
```
Rafraichir la page du site web, et le titre de la bannière devrait encore être bleu, mais le nom du pod a été modifié.

Modifier de nouveau le fichier de code pour passer la couleur à vert.
```
echo "BLOG_BANNER_COLOR = 'green'" >> blog-django-py/blog/context_processors.py
```
Rafraichir de nouveau la page du site web, plusieurs fois si nécessaires, jusqu'à ce que la bannière apparaissent en vert. Le changement peut ne pas être immédiat et prendre quelques instants, le temps que la détection du changement de code et le rédémarrage du process du serveur web d'application se fasse.

Arrêter la tache de syncronisation avec : 
```
kill -9 %1
```
Bien que l'on puisse synchroniser les fichiers depuis le local vers le conteneur de cette façon, le fait d'activer cela comme mécanisme de live codinf dépend du langage de programmation utilisé, et de la stack de l'application web. Cela est possible pour Python lors de ly'utilisation de mod_wsgi-express, mais cela n'est pas possible avec d'autres serveurs WSGI pour Python ou d'autres langage de programmation.

NB : Mme dans le cas de Python, cela fonctionne uniquement pour la modification de fichiers de code. Dans le cas où vous devez installer des paquets Python supplémentaire, vous aurez besoin de re-construire l'application depuis le code source original. Cela vient du fait que les paquets nécessaires sont écrit pour Python dans un fichier requirements.txt, qui ne déclenche pas l'installation des paquets en utilisant ce mécanisme.


# Etape 5 - Copier des fichiers vers un Volume Persistant
Si vous montez un volume persistant dans le conteneur de votre application et que vous avz besoin de copier des fichiers dans ce volume, oc rsync peut être utilisé de la mme façon que décrit précédemment pour l'envoi de fichier. Tout ce que vous avez à faire est de remplacer le dossier cible, par le chemin dans lequel le volume persistant est monté dans le conteneur.

Si vous n'avez pas encore déployé votre application, mais que vous souhaitez préparer à l'avance le volume perisistant avec toutes les données nécessaire, vous pouvez créer un volume perisistant et transférer les données dans celui-ci. Pour cela, vous devez avoir une application bateau sur laquel votre volume peristant peut être montée.

Pour créer un application bateau pour cet objectif, voici la commande :
```
oc new-app --name=dummy  centos/httpd-24-centos7
```
Nous utilisons la commande oc run pour créer une configuration de déploiement et un pod managé. Aucun service n'est crée car nosu n'avons pas besoin que l'application s'execute, une instance du serveru Apache HTTPD dans ce cas, qui pourrait être exposé. Ici, le serveur Apache HTTPd est utilisé seulement pour permettre l'eecution en continue du pod.

Pour suvire le démarrage du pod, et s'assurer qu'il est déployé, utilisez : 
```
oc status
```
Une fois que le pod s'execute, vous pouvez voir la list limitée des ressources créés, et la comparer à ce qui aurait été crée en utilisant oc new-app en lançant : 
```
oc get all --selector run=dummy -o name
```
Maintenant que nous avons une application qui fonctionne, nous avons besoin de créer un volume persistant et de le monter dans notre application bateau. En faisant cela, nous assignerons un nom à notre claim de données afin de pouvoir utiliser ce nom plus tard. Nous montons le volume perisistant dans /mnt à l'intérieur du conteneur, le dossier standard utilisé par les système Linux pour les montages de volumes temporaire.
```
oc set volume deployment/dummy --add --name=tmp-mount --claim-name=data --type pvc --claim-size=1G --mount-path /mnt
```
Cela déclenche un nouveau déploiement de notre application bateau, cette fois-ci avec le volume persistant montée. Vous pouvez suivre l'avancée du déploiement pour s'avoir s'il est complet, en lançant :
```
oc status
```
Pour confirmer que le volume persistantclaim a été créé, vous pouvez lancer :
```
oc get pvc
```
Avec l'application beateau qui tourne, et le volume persistant monté, enregistrer le nom du pod de l'application en cours d'execution.
```
POD=`pod run=dummy`; echo $POD
```
Vous pouvez maintenant copier n'importe quel fichier dans le volume persistant, en utilisant le dossier /mnt dans lequel le volume persistant est monté, en tant que dossier cible. Dans ce cas, puisque nous faisons une copie unique , nous pouvons utiliser la strategie du tar au lieu du rsync.
```
oc rsync ./ $POD:/mnt --strategy=tar
```
Lorsque cela est terminé, vous pouvez validez que les fichiers ont été transférés en listant le contenu du dossier cible à l'intérieur du conteneur.
```
oc rsh $POD ls -las /mnt
```
Si vous avez terminer avec le volume persistant et que vous avez besoin de répéter le process avec un autre volume persistant et des données différentes, vous pouvez démonter le volume persistant de votre application bateau.
```
oc set volume deployment/dummy --remove --name=tmp-mount
```
Pour suivre le process et confirmer de nouveau que le re-déploiement a été complété.
```
oc status
```
On enregistre de nouveau le nom du pod courant :
```
POD=`pod run=dummy`; echo $POD
```
et on vérifier encore ce qui est présent dans le dossier cible. Il devrait être vide à ce point. Cela vient du fait que le volume persistant n'est plus montée et vous vérifier dans le dossier du système de fichier du conteneur.
```
oc rsh $POD ls -las /mnt
```
Si vous avez déjà un claim volume persistant, comme nous actuellement, vous pouvez monter un claimed volume sur l'application à la place.
C'est différent de ce qu'il y a ci-dessus puisque dans les deux cas on a créé un nouveau claim volume persistent et on l'a montée en même temps.
```
oc set volume deployment/dummy --add --name=tmp-mount --claim-name=data --mount-path /mnt
```
Vérifiez l'état du re-déploiement :
```
oc status
```
Enregistrer le nom du pod :
```
POD=`pod run=dummy`; echo $POD
```
et vérifier le contenu du dossier cible. Les fichiers copiés sur le volume persistant sont de nouveau visible.
```
oc rsh $POD ls -las /mnt
```
Lorsque c'est fait, on veut supprimer l'application bateau, on utilise la commande oc delete pour le faire, avec un sélecteur de label sur run=dummy pour s'assurer que l'on ne supprime que les objets de ressources liés à l'application bateau.
```
oc delete all --selector run=dummy
```
Vérifier que toutes les objets de ressources ont été supprimés
```
oc get all --selector run=dummy -o name
```
Bien que nous ayons supprimer l'application bateau, le claim du volume persistant existe encore et peut être montée plus tard sur une autre appplication qui a besoin des données.
```
oc get pvc
```
