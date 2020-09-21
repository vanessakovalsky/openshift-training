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
Pour constuire une nouvelle application en Python. Ou utiliser kubectl pour déployer une application simple Kubernetes.
```
    kubectl create deployment hello-node --image=gcr.io/hello-minikube-zero-install/hello-node
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
oc rollout status dc/blog
```
La commande s'arreter une fois que le déploiement de l'application a été complété et que l'application web est prête. 

Le résultat du déploiement sera l'execution du conteneur. Vous pouvez voir le nom des pods correspondant qui executent les conteneurs pour cette application en lançant : 
```
oc get pods --selector deploymentconfig=blog
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
oc get pods --selector deploymentconfig=blog -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}'
```
Comme au-dessus, nous utilisons oc get pods avec un sélécteur de label, mais aussi une requête jsonpath pour extraire le nom du pod en cours d'execution.
Pour créer la fonction shell lancer : 
```
pod() { local selector=$1; local query='?(@.status.phase=="Running")'; oc get pods --selector $selector -o jsonpath="{.items[$query].metadata.name}"; }
```
Pour enregistrer le nom du pod et le définir comme variable d'environnement POD lancer : 
```
POD=`pod deploymentconfig=blog`; echo $POD
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

Lorsque vous copier un dossier, vous pouvez être plus sélectif avec ce qui est copier en utilisant les options --excludes 

When copying a directory, you can be more selective about what is copied by using the --exclude and --include options to specify patterns to be matched against directories and files, with them being excluded or included as appropriate.

If there is more than one container running within a pod, you will need to specify which container you want to work with by using the --container option.

Topic 3 - Uploading Files to a Container
To copy files from the local machine to the container, the oc rsync command is again used.

The form of the command when copying files from the local machine to the container is:

oc rsync ./local/dir <pod-name>:/remote/dir
Unlike when copying from the container to the local machine, there is no form for copying a single file. To copy selected files only, you will need to use the --exclude and --include options to filter what is and isn't copied from a specified directory.

To illustrate the process for copying a single file, consider the case where you had deployed a web site and had not included a robots.txt file, but needed to quickly stop a web robot which was crawling your site.

A request to fetch the current robots.txt file for the web site fails with a HTTP 404 Not Found response.

curl --head http://blog-myproject.2886795294-80-ollie05.environments.katacoda.com/robots.txt

Create a robots.txt file to upload.

cat > robots.txt << !
User-agent: *
Disallow: /
!

For the web application being used, it hosts static files out of the htdocs sub directory of the application source code. To upload the robots.txt file run:

oc rsync . $POD:/opt/app-root/src/htdocs --exclude=* --include=robots.txt --no-perms

As already noted it is not possible to copy a single file, so we indicate that the current directory should be copied, but use the --exclude=* option to first say that all files should be ignored when performing the copy. That pattern is then overridden for just the robots.txt file by using the --include=robots.txt file, ensuring the robots.txt file is copied.

When copying files to the container, it is required that the directory into which files are being copied exists, and that it is writable to the user or group that the container is being run as. Permissions on directories and files should be set as part of the process of building the image.

In the above command, the --no-perms option is also used because the target directory in the container, although writable by the group the container is run as, is owned by a different user to that which the container is run as. This means that although files can be added to the directory, permissions on existing directories cannot be changed. The --no-perms options tells oc rsync to not attempt to update permissions to avoid it failing and returning errors.

Having uploaded the robots.txt file, fetching the robots.txt file again now succeeds.

curl http://blog-myproject.2886795294-80-ollie05.environments.katacoda.com/robots.txt

This worked without needing to take any further actions as the Apache HTTPD server being used to host static files, would automatically detect the presence of a new file in the directory.

If instead of copying a single file you wanted to copy a complete directory, leave off the --include and --exclude options. To copy the complete contents of the current directory to the htdocs directory in the container, run:

oc rsync . $POD:/opt/app-root/src/htdocs --no-perms

Just be aware that this will be everything, including notionally hidden files or directories starting with ".". You should therefore be careful, and if necessary be more specific by using --include or --exclude options to limit the set of files or directories copied.

Topic 4 - Synchronizing Files with a Container
In addition to being able to manually upload or download files when you choose to, the oc rsync command can also be set up to perform live synchronization of files between your local computer and the container.

That is, the file system of your local computer will be monitored for any changes made to files. When there is a change to a file, the changed file will be automatically copied up to the container.

This same process can also be run in the opposite direction if required, with changes made in the container being automatically copied back to your local computer.

An example of where it can be useful to have changes automatically copied from your local computer into the container is during the development of an application.

For scripted programming languages such as PHP, Python or Ruby, where no separate compilation phase is required, provided that the web server can be manually restarted without causing the container to exit, or if the web server always reloads code files which have been modified, you can perform live code development with your application running inside of OpenShift.

To demonstrate this ability, clone the Git repository for the web application which you have already deployed.

git clone https://github.com/openshift-katacoda/blog-django-py

This will create a sub directory blog-django-py containing the source code for the application:

Cloning into 'blog-django-py'...
remote: Enumerating objects: 3, done.
remote: Counting objects: 100% (3/3), done.
remote: Compressing objects: 100% (3/3), done.
remote: Total 412 (delta 0), reused 0 (delta 0), pack-reused 409
Receiving objects: 100% (412/412), 68.49 KiB | 701.00 KiB/s, done.
Resolving deltas: 100% (200/200), done.
Now run the following command to have oc rsync perform live synchronisation of the code, copying any changes from the blog-django-py directory up to the container.

oc rsync blog-django-py/. $POD:/opt/app-root/src --no-perms --watch &

In this case we are running this as a background process as we only have the one terminal window available, you could run it as a foreground process in a separate terminal if doing this yourself.

You can see the details for the background process by running:

jobs

When you initially ran this oc rsync command, you will see that it copied up the files so the local and remote directory are synchronized. Any changes made to the local files will now be automatically copied up to the remote directory.

Before we make a change, bring up the web application we have deployed in a separate browser window by using the URL:

http://blog-myproject.2886795294-80-ollie05.environments.katacoda.com/

You should see that the color of the title banner for the web site is red.

Blog Web Site Red

Lets change that banner color by running the command:

echo "BLOG_BANNER_COLOR = 'blue'" >> blog-django-py/blog/context_processors.py

Wait to see that the changed file is uploaded, and then refresh the page for the web site.

Unfortunately you will see that the title banner is still red. This is because for Python any code changes are cached by the running process and it is necessary to restart the web server application processes.

For this deployment the WSGI server mod_wsgi-express is being used. To trigger a restart of the web server application processes, run:

oc rsh $POD kill -HUP 1

This command will have the affect of sending a HUP signal to process ID 1 running within the container, which is the instance of mod_wsgi-express which is running. This will trigger the required restart and reloading of the application, but without the web server actually exiting.

Refresh the page for the web site once more and the title banner should now be blue.

Blog Web Site Blue

Note that the name of the pod as displayed in the title banner is unchanged, indicating that the pod was not restarted and only the web server application processes were restarted.

Manually forcing a restart of the web server application processes will get the job done, but a better way is if the web server can automatically detect code changes and trigger a restart.

In the case of mod_wsgi-express and how this web application has been configured, this can be enabled by setting an environment variable for the deployment. To set this environment variable run:

oc set env dc/blog MOD_WSGI_RELOAD_ON_CHANGES=1

This command will update the deployment configuration, shutdown the existing pod and replace it with a new instance of our application with the environment variable now being passed through to the application.

Monitor the re-deployment of the application by running:

oc rollout status dc/blog

Because the existing pod has been shutdown, we will need to capture again the new name for the pod.

POD=`pod deploymentconfig=blog`; echo $POD

You may also notice that the synchronization process we had running in the background may have stopped. This is because the pod it was connected to had been shutdown.

You can check this is the case by running:

jobs

If it is still showing as running, due to shutdown of the pod not yet having been detected, run:

kill -9 %1

to kill it.

Ensure the background task has exited:

jobs

Now run the oc rsync command again, against the new pod.

oc rsync blog-django-py/. $POD:/opt/app-root/src --no-perms --watch &

Refresh the page for the web site again and the title banner should still be blue, but you will notice that the pod name displayed has changed.

Modify the code file once more, setting the color to green.

echo "BLOG_BANNER_COLOR = 'green'" >> blog-django-py/blog/context_processors.py

Refresh the web site page again, multiple times if need be, until the title banner shows as green. The change may not be immediate as the file synchronization may take a few moments, as may the detection of the code changes and restart of the web server application process.

Blog Web Site Green

Kill the synchronization task by running:

kill -9 %1

Although one can synchronize files from the local computer into a container in this way, whether you can use it as a mechanism for enabling live coding will depend on the programming language being used, and the web application stack being used. This was possible for Python when using mod_wsgi-express, but may not be possible with other WSGI servers for Python, or other programming languages.

Do note that even for the case of Python, this can only be used where modifying code files. If you need to install additional Python packages, you would need to re-build the application from the original source code. This is because changes to packages required, which for Python is given in the requirements.txt file, isn't going to trigger the installation of that package when using this mechanism.

Topic 5 - Copying Files to a Persistent Volume
If you are mounting a persistent volume into the container for your application and you need to copy files into it, then oc rsync can be used in the same way as described previously to upload files. All you need to do is supply as the target directory, the path of where the persistent volume is mounted in the container.

If you haven't as yet deployed your application, but are wanting to prepare in advance a persistent volume with all the data it needs to contain, you can still claim a persistent volume and upload the data to it. In order to do this, you will though need to deploy a dummy application against which the persistent volume can be mounted.

To create a dummy application for this purpose run the command:

oc run dummy --image centos/httpd-24-centos7

We use the oc run command as it creates just a deployment configuration and managed pod. A service is not created as we don't actually need the application we are running here, an instance of the Apache HTTPD server in this case, to actually be contactable. We are using the Apache HTTPD server purely as a means of keeping the pod running.

To monitor the startup of the pod and ensure it is deployed, run:

oc rollout status dc/dummy

Once it is running, you can see the more limited set of resources created, as compared to what would be created when using oc new-app, by running:

oc get all --selector run=dummy -o name

Now that we have a running application, we next need to claim a persistent volume and mount it against our dummy application. When doing this we assign it a claim name of data so we can refer to the claim by a set name later on. We mount the persistent volume at /mnt inside of the container, the traditional directory used in Linux systems for temporarily mounting a volume.

oc set volume dc/dummy --add --name=tmp-mount --claim-name=data --type pvc --claim-size=1G --mount-path /mnt

This will cause a new deployment of our dummy application, this time with the persistent volume mounted. Again monitor the progress of the deployment so we know when it is complete, by running:

oc rollout status dc/dummy

To confirm that the persistent volume claim was successful, you can run:

oc get pvc

With the dummy application now running, and with the persistent volume mounted, capture the name of the pod for the running application.

POD=`pod run=dummy`; echo $POD

We can now copy any files into the persistent volume, using the /mnt directory where we mounted the persistent volume, as the target directory. In this case since we are doing a one off copy, we can use the tar strategy instead of the rsync strategy.

oc rsync ./ $POD:/mnt --strategy=tar

When complete, you can validate that the files were transferred by listing the contents of the target directory inside of the container.

oc rsh $POD ls -las /mnt

If you were done with this persistent volume and perhaps needed to repeat the process with another persistent volume and with different data, you can unmount the persistent volume but retain the dummy application.

oc set volume dc/dummy --remove --name=tmp-mount

Monitor the process once again to confirm the re-deployment has completed.

oc rollout status dc/dummy

Capture the name of the current pod again:

POD=`pod run=dummy`; echo $POD

and look again at what is in the target directory. It should be empty at this point. This is because the persistent volume is no longer mounted and you are looking at the directory within the local container file system.

oc rsh $POD ls -las /mnt

If you already have an existing persistent volume claim, as we now do, you could mount the existing claimed volume against the dummy application instead. This is different to above where we both claimed a new persistent volume and mounted it to the application at the same time.

oc set volume dc/dummy --add --name=tmp-mount --claim-name=data --mount-path /mnt

Look for completion of the re-deployment:

oc rollout status dc/dummy

Capture the name of the pod:

POD=`pod run=dummy`; echo $POD

and check the contents of the target directory. The files we copied to the persistent volume should again be visible.

oc rsh $POD ls -las /mnt

When done and you want to delete the dummy application, use oc delete to delete it, using a label selector of run=dummy to ensure we only delete the resource objects related to the dummy application.

oc delete all --selector run=dummy

Check that all the resource objects have been deleted.

oc get all --selector run=dummy -o name

Although we have deleted the dummy application, the persistent volume claim still exists and can later be mounted against your actual application to which the data belongs.

oc get pvc
