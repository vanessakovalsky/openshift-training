# OpenShift - Travailler avec les pipelines

## Pré-requis

* Etre connecté à un cluster OpenShift
* Avoir l'opérateur Openshift Pipelines Operators (il est normalement installé sur le cluster fourni pour l'exercice), pour vérifier son installation, lancer executer le script suivant : 

```
until oc api-resources --api-group=tekton.dev | grep tekton.dev &> /dev/null
do 
 echo "Operator installation in progress..."
 sleep 5
done

echo "Operator ready"
```

* Créer un projet : `oc new-project my-pipeline-USER ` (remplacer USER par votre nom)
* Vérifier que tkn l'outil ligne de commande de tekton est install : `tkn version` ou l'installer : https://github.com/tektoncd/cli/releases


## Créer une tâche

Une tâche (`task`) définit une série d'étapes (`steps`) qui lance dans l'ordre souhaité et complète les travaux de construction. Chaque `Task` est lancé comme un Pod sur le cluster Kubernetes avec pour chaque `step` son propre conteneur. Par exemple, la tâche suivante affiche "Hello World":

```
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: hello
spec:
  steps:
    - name: say-hello
      image: registry.access.redhat.com/ubi8/ubi
      command:
        - /bin/bash
      args: ['-c', 'echo Hello World']
```

* Créer un dossier tasks `mkdir tasks`
* Copier le contenu de la tâche ci-dessus dans un fichier tasks/hello.yaml (il faut créer le fichier) et importer la dans OpenShift : `oc apply -f tasks/hello.yaml`
* Lancer la tâche avec la commande `tkn`, qui est l'outil ligne de commande pour Tekton :
`tkn task start --showlog hello`
* La sortie ressemble à l'affichage suivant : 

```
TaskRun started: hello-run-9cp8x
Waiting for logs to be available...
[say-hello] Hello World
```

## Donner des paramètres à ses tâches

Les tâches peuvent aussi prendre des paramètres. De cette manière, vous pouvez passer de nombreux paramètres utilisé dans votre tâche. Ces paramètres peuvent servir à rendre votre tâche plus générique et réutilisable dans les différents Pipelines.  Par exemple, une tâche peut être appliquer dans un manifeste Kubernetes personnalisé, comme dans l'exemple ci-dessous. Cela est nécessaire pour déployer l'image sur OpenShift dans la prochaine section. De plus, nous parlerons des `workspaces` dans l'étape des `Pipeline`

* Créer le fichier tasks/apply_manifest_task.yaml et mettre le contenu suivant à l'intérieur : 
```
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: apply-manifests
spec:
  workspaces:
  - name: source
  params:
    - name: manifest_dir
      description: The directory in source that contains yaml manifests
      type: string
      default: "k8s"
  steps:
    - name: apply
      image: quay.io/openshift/origin-cli:latest
      workingDir: /workspace/source
      command: ["/bin/bash", "-c"]
      args:
        - |-
          echo Applying manifests in $(inputs.params.manifest_dir) directory
          oc apply -f $(inputs.params.manifest_dir)
          echo -----------------------------------
```
* Créer la tâche  `apply-manifests`:

`oc create -f tasks/apply_manifest_task.yaml`{{execute}}
* Créer également le fichier tasks/update_deployment_task.yaml avec le contenu suivant : 
```
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: update-deployment
spec:
  params:
    - name: deployment
      description: The name of the deployment patch the image
      type: string
    - name: IMAGE
      description: Location of image to be patched with
      type: string
  steps:
    - name: patch
      image: quay.io/openshift/origin-cli:latest
      command: ["/bin/bash", "-c"]
      args:
        - |-
          oc patch deployment $(inputs.params.deployment) --patch='{"spec":{"template":{"spec":{
            "containers":[{
              "name": "$(inputs.params.deployment)",
              "image":"$(inputs.params.IMAGE)"
            }]
          }}}}'
```
* Créer également la tâche `update-deployment`:

`oc create -f tasks/update_deployment_task.yaml`{{execute}}

* Enfin nous créons un fichier pour le PersistentVolumeClaim pour fournir un système de ficierr à notre execution de pipeline, nous le détaillerons dans l'étape suivante. 
* Créer un fichier resources/persistent_volume_claim.yaml et coller le contenu suivant à l'intérieur : 
```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: source-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 500Mi
```
* Puis appliquer le fichier créé
`oc create -f resources/persistent_volume_claim.yaml`

* Pour visualiser les tâche crées : 

`tkn task ls`

* Vous devriez obtenir la sortie suivante : 
```
NAME                DESCRIPTION   AGE
apply-manifests                   4 seconds ago
hello                             1 minute ago
update-deployment                 3 seconds ago
```

## Créer un pipeline

Un `Pipeline` définit une série ordonnée de `Tasks` que vous voulez executé en fonction des entrées / sortie de chaque `Task`. De fait, les tâches ne devrait faire qu'une seule chose afin d'être réutilisable dans différents pipeline ou même au sein du même pipeline.  

Voici un exemple de la définition d'un `Pipeline`, créé en utilisant le diagramme suivant : 

![Web Console Developer](https://github.com/openshift-labs/learn-katacoda/tree/master/assets/middleware/pipelines/pipeline-diagram.png)

* Et le YAML correspondant au diagramme : 

```
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: build-and-deploy
spec:
  workspaces:
  - name: shared-workspace
  params:
  - name: deployment-name
    type: string
    description: name of the deployment to be patched
  - name: git-url
    type: string
    description: url of the git repo for the code of deployment
  - name: git-revision
    type: string
    description: revision to be used from repo of the code for deployment
    default: "master"
  - name: IMAGE
    type: string
    description: image to be build from the code
  tasks:
  - name: fetch-repository
    taskRef:
      name: git-clone
      kind: ClusterTask
    workspaces:
    - name: output
      workspace: shared-workspace
    params:
    - name: url
      value: $(params.git-url)
    - name: subdirectory
      value: ""
    - name: deleteExisting
      value: "true"
    - name: revision
      value: $(params.git-revision)
  - name: build-image
    taskRef:
      name: buildah
      kind: ClusterTask
    params:
    - name: TLSVERIFY
      value: "false"
    - name: IMAGE
      value: $(params.IMAGE)
    workspaces:
    - name: source
      workspace: shared-workspace
    runAfter:
    - fetch-repository
  - name: apply-manifests
    taskRef:
      name: apply-manifests
    workspaces:
    - name: source
      workspace: shared-workspace
    runAfter:
    - build-image
  - name: update-deployment
    taskRef:
      name: update-deployment
    workspaces:
    - name: source
      workspace: shared-workspace
    params:
    - name: deployment
      value: $(params.deployment-name)
    - name: IMAGE
      value: $(params.IMAGE)
    runAfter:
    - apply-manifests
```
* Ce pipeline aide à construire et déployer un backend/Frontedn en configurant les bonnes ressources dans le pipeline.

* Etape du pipeline : 
  1. `fetch-repository` clone le code source de l'application depuis un dépôt git en se référéant aux paramètres `git-url` et `git-revision`
  2. `build-image` construit l'image du conteneur de l'application en utilisant la tache de cluster `buildah` qui utilise [Buildah](https://buildah.io/) pour construire l'image
  3. L'image de l'application est envoyé sur un registre d'image en utilisant le paramètre `image`
  4. La nouvelle image d'applciation est déployée sur OpenShift en utilisant les tâches `apply-manifests` et `update-deployment`

Vous avez du remarquer qu'il n'y a pas de référence au dépôt git ou au registre d'image qui sont utilisés dans le pipeline. Cela est parce que les pipelins de Tekton sont conçus pour être générique et ré-utilisable dans différents environnements et étapes du cycle de vie de l'application. Les pipelines font abstraction des spécificités de du dépot de code source git et des image pour être produit comme [`PipelineResources`](https://tekton.dev/docs/pipelines/resources) ou `Params`. Lorsque l'on déclenche un pipeline, on peut fournir différents dépôt git et registre d'images qui seront utilisé pendant l'execution du pipeline.

L'ordre d'exécution des taches est déterminé par les dépendances qui sont définies entre les tâches via les inputs (entrée) et outputs (sortie) ou dans l'aordre ecplicit qui est défini via `runAfter`.

Le champ `workspaces` vous permet de définir un ou plusieurs volumes que les Tache dans le Pipeline ont besoin pendant l'execution. Vous pouvez spécifier un ou plusieurs Wordkspace dans le champ `workspaces`.

* Créer un fichier (et un dossier) pipeline/pipeline.yaml avec le contenu suivant : 
```
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: build-and-deploy
spec:
  workspaces:
  - name: shared-workspace
  params:
  - name: deployment-name
    type: string
    description: name of the deployment to be patched
  - name: git-url
    type: string
    description: url of the git repo for the code of deployment
  - name: git-revision
    type: string
    description: revision to be used from repo of the code for deployment
    default: "master"
  - name: IMAGE
    type: string
    description: image to be build from the code
  tasks:
  - name: fetch-repository
    taskRef:
      name: git-clone
      kind: ClusterTask
    workspaces:
    - name: output
      workspace: shared-workspace
    params:
    - name: url
      value: $(params.git-url)
    - name: subdirectory
      value: ""
    - name: deleteExisting
      value: "true"
    - name: revision
      value: $(params.git-revision)
  - name: build-image
    taskRef:
      name: buildah
      kind: ClusterTask
    params:
    - name: TLSVERIFY
      value: "false"
    - name: IMAGE
      value: $(params.IMAGE)
    workspaces:
    - name: source
      workspace: shared-workspace
    runAfter:
    - fetch-repository
  - name: apply-manifests
    taskRef:
      name: apply-manifests
    workspaces:
    - name: source
      workspace: shared-workspace
    runAfter:
    - build-image
  - name: update-deployment
    taskRef:
      name: update-deployment
    params:
    - name: deployment
      value: $(params.deployment-name)
    - name: IMAGE
      value: $(params.IMAGE)
    runAfter:
    - apply-manifests
```

* Créer le pipeline avec la commande suivante :

`oc create -f pipeline/pipeline.yaml`


## Déclencher un pipeline

Maintenant que le pipeline est créé, vous pouvez le déclencher pour exécuter les tâches spécifiées dans le pipeline. Cela est fait en créant un  `PipelineRun` via `tkn`.

Démarrons le pipeline pour construire et déployer notre application backent en utilisant `tkn`. En créant un  `PipelineRun` avec le nom de notre `Pipeline`, nous pouvons éfinir de nombreux arguments à notre commande comme les  `params` qui seront utilisés dans le `Pipeline`.  Par exemple, nous pouvons appliquer une requête pour le stockage avec un `persistentVolumeClaim`, tout comme définir un nom pour notre `deployment`, un dépôt git `git-url` à cloner, et une `IMAGE` à créé.

* Nous commençons par construire et déployer notre application backend en utilisant la commande suivante, avec les paramètre déjà inclus dans notre démo :

`tkn pipeline start build-and-deploy -w name=shared-workspace,claimName=source-pvc -p deployment-name=pipelines-vote-api -p git-url=https://github.com/openshift/pipelines-vote-api.git -p IMAGE=image-registry.openshift-image-registry.svc:5000/pipelines-tutorial/vote-api --showlog`

* En parallèlle, lancer un pipeline pour construire et déployer l'application frontend : 

`tkn pipeline start build-and-deploy -w name=shared-workspace,claimName=source-pvc -p deployment-name=pipelines-vote-ui -p git-url=https://github.com/openshift/pipelines-vote-ui.git -p IMAGE=image-registry.openshift-image-registry.svc:5000/pipelines-tutorial/vote-ui --showlog`

Dès que le pipeline `build-and-deploy` a démarée, un  `PipelineRun` est initialisé et des pods seront créé pour exécuter les taches qui sont définies dans le pipeline. Pour afficher la liste des pipelines, utiliser la commande suivante :

`tkn pipeline ls`

Encore une fois, noter la réutilisabilité des pipelines, et de la manière dons un `Pipeline` générique peut être déclenché avec de nombreux `params`. Nous avons démarré le pipeline `build-and-deploy`, qui est celui qui concerne les ressource du déploiement de notre application backend/frontend. Voyons la liste de nos PipelineRuns:

`tkn pipelinerun ls`

Après quelques minutes, les pipelinees devraient se terminer avec succès. 

## Accéder aux Pipeline via Web Console

Pour visualiser les `PipelineRun`, renez vous dans la section Pipelines de la  perspective développeur. De la, vous pouvez voir les détails de notre `Pipeline`, y-compris les fichier YAML que nous avons appliqué, le `PipelineRun`, les entrées personnalisés de `params`, et bien d'autres éléments:

![Web Console Pipelines](https://github.com/openshift-labs/learn-katacoda/tree/master/assets/middleware/pipelines/web-console-developer.png)


## Vérifier le déploiement

* Pour vérifier la réussite du déploiement de notre application, revenir sur la console web dans le navigateur.
* Cliquer sur le menu Topology à gauche. Vous devriez voir quelque chose ressemblant à la capture d'écran suivante : 

![Web Console Deployed](https://github.com/openshift-labs/learn-katacoda/tree/master/assets/middleware/pipelines/application-deployed.png)

* La vue Topology de la console web d'OpenShift vous aide à visualiser ce qui est déployer sur votre projet OpenShift.
Le cercle bleu foncé qui entour le cercle dans l'interface signifie qu'un conteneur a démarré et a lancer l'application. En cliquant sur l'icone de fleche comme ci-dessous, vous pouvez ouvrir l'URL de l'_ui_ dans un nouvel onglet et voir l'application fonctionner.


![Web Console URL Icon](https://github.com/openshift-labs/learn-katacoda/tree/master/assets/middleware/pipelines/url-icon.png)


## Accéder à l'application via CLI

* En plus, vous pouvez obetnir la route de l'application en utilisant la commande suivante pour accéder à l'application : 

`oc get route pipelines-vote-ui --template='http://{{.spec.host}}'`

-> Félicitations, vous avez déployer avec succès votre première application en utilsiant OpenShift Pipelines.

## Pour aller plus loin :

* Vous trouverez ici un autre exemple de pipeline CI/CD avec Tekton et ArgoCD pour un déploiement sur OpenShift : https://github.com/siamaksade/openshift-cicd-demo 
