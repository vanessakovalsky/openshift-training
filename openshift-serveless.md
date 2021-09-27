# OpenShift - Première application en Serverless

## Présentation du serverless

[serverless-main]: https://www.openshift.com/learn/topics/serverless
[amq-docs]: https://developers.redhat.com/products/amq/overview
[pipelines-main]: https://www.openshift.com/learn/topics/pipelines
[service-mesh-main]: https://www.openshift.com/learn/topics/service-mesh

Le serverless fournit un modèle de développement qui s'affranchit du provisionning et de la maintenance des serveurs pour les developpeurs.

## Objectifs
Dans cet exercice vous aller apprendre à :
* Deployer un `service` OpenShift Serverless .
* Deployer de multiple `revisions` d'un service.
* Comprenndre les `underlying compents`  d'un service serverless.
* Comprendre comment le Serverless est capable de `scale-to-zero`.
* Lancer différentes révision d'un service via des déploiements `canary` et `blue-green`.
* Utiliser le `knative client`.

## Pourquoi le Serverless?

Deployer des applications en tant que services Serverless est devenu un style d'architecture populaire. Il semble que de nombreuses organisation assume que le _Functions as a Service (FaaS)_ implique une architecture serverless. Nous pensons, qu'il est plus juste de dire que  FaaS est une des manières d'utiliser le serverless, mais que ce n'est pas la seule.Cela poste une question cruciale pour les entreprises qui ont des applications qui peuvent être monolitique ou en microservice : Quel est le moyen le plus simple pour aller sur du déploiement d'application serverless?

La réponse est une plateforme qui peut lancer des charges de travail serverless, mais qui permet aussi d'avoir le contrôle complet sur la configuration, la construction et le déploiement. Idealement, la plateforme supporte aussi le deploiement d'application en tant que conteneurs Linux.

## OpenShift Serverless

Dans ce chapitre, nous vous présentons une telle plateforme -- [OpenShift Serverless][serverless-main].  OpenShift Serverless aide les développeurs à déployer et faire tourner des applications qui sont mise à l'échelle ver le haut ou redescendu à 0 à la demande. Les applications sont des packet conforme à la norme OCI pour les conteneurs Linux qui peuvent tourner n'importe où. Cela est connu comme `Serving`.

![OpenShift Serving](/openshift/assets/developing-on-openshift/serverless/00-intro/knative-serving-diagram.png)

Serverless est une manière robuste de permettre aux applications d'être déclenché par une diversité de souce d'évènement, comme des évènements venant de vos propres applications, de services cloud de différents fournisseurs, de systèmes Software as a Service (SaaS) et de Service Red Hat ([AMQ Streams][amq-docs]).  Cela s'appelle l' `Eventing`.

![OpenShift Eventing](/openshift/assets/developing-on-openshift/serverless/00-intro/knative-eventing-diagram.png)

Les applications OpenShift Serverless peuvent être intégrés aux autres services OpenShift, comme OpenShift [Pipelines][pipelines-main], et [Service Mesh][service-mesh-main], pour délivrer une expérience de développement et de déploiement complète pour les applications serverless.


## Pré-requis

* Se connecter à oc et créer un projet
 `oc new-project serverless-tutorial`

## Créer un service

[ocp-serving-components]: https://docs.openshift.com/container-platform/4.7/serverless/architecture/serverless-serving-architecture.html


## Explore Serving

Prenons le temps de regarder les nouvelles ressources d'API disponible dans le cluster avec `Serving`: 
`oc api-resources --api-group serving.knative.dev`

> **Note:** *Au lieu de chercher `api-resource` dans la sortie  `KnativeServing` en utilisant `grep`, nous filtrons `APIGROUP` sur `serving.knative.dev`.*

Le module Serving est constitué de différentes pièces. Ce pièces sont listée dans la sortie de la commande précédente :  `configurations`, `revisions`, `routes`, et `services`.  La ressource d'api `knativeservings` existe, et nous avons déjà créé une instance KnativeServing. 

```bash
NAME              SHORTNAMES      APIGROUP              NAMESPACED   KIND
configurations    config,cfg      serving.knative.dev   true         Configuration
knativeservings   ks              serving.knative.dev   true         KnativeServing
revisions         rev             serving.knative.dev   true         Revision
routes            rt              serving.knative.dev   true         Route
services          kservice,ksvc   serving.knative.dev   true         Service
```

Le diagramme ci-dssous montre comment chaque composant du module Serving interagit avec les autres.

![Serving](/openshift/assets/developing-on-openshift/serverless/02-serving/serving.png)



## OpenShift Serverless Services

Un **Knative Service Resource** gère automatiquelement le cycle de vie en entier d'une charge de travail serverless sur un cluster. Il contrôle la création des autres objets pour s'assurer que l'application a une route, une configuration, une nouvelle révision pour chaque mise à jour du service. Les services peuvent être définis pour diriger toujours le trafic sur la dernière révision ou sur une révision spécifique..

* Voyons la structure d'un Service Serverless : 


```yaml
# ./assets/02-serving/service.yaml

apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: greeter
  namespace: serverless-tutorial
spec:
  template:
    spec:
      containers:
      - image: quay.io/rhdevelopers/knative-tutorial-greeter:quarkus
        livenessProbe:
          httpGet:
            path: /healthz
        readinessProbe:
          httpGet:
            path: /healthz

```

* Nous allons maintenant déployer une instance d'un  `Service` qui est fourni par `serving.knative.dev`. Dans notre exemple simple nous avons définie une image de conteneur et le cheminde`health checking` du service. Nous fournissons aussi le  `name` et le `namespace`.

## Deployer le Service Serverless

Pour déployer le service, nous pouvons déployer le YAML ci-dessus en executant (en ayant auparavant créer le fichier et mis le contenu ci-dessus à l'intérieur): 
`oc apply -n serverless-tutorial -f service.yaml`, 
mais une des meilleurs fonctionnalité du serverless est la capacité de se déployer et de fonctionner sans ressource serverless sans même travailler avec yaml. Pour cela nous allons utiliser l'outil CLI 'kn' (https://github.com/knative/client) pour travailler avec le serverless. 

* Pour déployer le service exécuter :
```bash
kn service create greeter \
   --image quay.io/rhdevelopers/knative-tutorial-greeter:quarkus \
   --namespace serverless-tutorial
```

* Pour voir le statut, utiliser la commande : 
```bash
# ./assets/02-serving/watch-service.bash

#!/usr/bin/env bash
while : ;
do
  output=`oc get pod -n serverless-tutorial`
  echo "$output"
  if [ -z "${output##*'Running'*}" ] ; then echo "Service is ready."; break; fi;
  sleep 5
done

```
* Un déploiement réussi montre les pods `greeter` : 


```shell
NAME                                        READY   STATUS    RESTARTS   AGE
greeter-6vzt6-deployment-5dc8bd556c-42lqh   2/2     Running   0          11s
```

## Vérifier le deploiement

Comme expliqué, les déploiements de Service Serverlle créé peut de ressource requises. Nous allons voir chacune des ressources.

### Service

* Nous pouvons voir le Service Serverless qui a été créé en executant :`kn service list`

* La sortie devrait être similaire à :

```bash
NAME      URL                                                     LATEST            AGE     CONDITIONS   READY   REASON
greeter   http://greeter-serverless-tutorial.[[HOST_SUBDOMAIN]]-80-[[KATACODA_HOST]].environments.katacoda.com  greeter-fyrxn-1   6m28s   3 OK / 3     True    
```

> **Note:** *Il est aussi possible d'utiliser la commande `oc` pour voir les ressources serverless, pour voir les services lancer :  `oc get -n serverless-tutorial services.serving.knative.dev`*

* Le `Service` Serverless nous donne des informations sur son `URL`, sa dernière(`LATEST`) revision, son `AGE`, et son status pour chaque service que nous avons déployé. Il est aussi important de voir que `READY=True` valide que le service a été déployé avec succès même si aucun pod ne fonctionne.

* Il est aussi possible de décrire un service spécifique pour collecter des informations détaillées sur ce service en exécutant : `kn service describe greeter`

* La sortie devrait être similaire à :
```bash
Name:       greeter
Namespace:  serverless-tutorial
Age:        15m
URL:        http://greeter-serverless-tutorial.[[HOST_SUBDOMAIN]]-80-[[KATACODA_HOST]].environments.katacoda.com

Revisions:  
  100%  @latest (greeter-fyrxn-1) [1] (15m)
        Image:  quay.io/rhdevelopers/knative-tutorial-greeter:quarkus (pinned to 767e2f)

Conditions:  
  OK TYPE                   AGE REASON
  ++ Ready                  14m 
  ++ ConfigurationsReady    14m 
  ++ RoutesReady            14m 
```

> **Note:** *La plupart des ressources peuvent être décrite via l'outil `kn`. N'hésitez pas à l'utiliser pour la suite de l'exercice.*

> *Comment cela est possible d'avoir un service déployé et  `Ready` mais aucun pods en fonctionnement pour ce service?*
>
> Un début de réponse en regardant la colonne `READY` de la commande `oc get deployment`

### Route

Une ressource `Route` fait correspondre un endpoint réseau à un ou plusieurs révisions Knative. Il est possible de gérer le trafic de différentes façons, ce qui inclut le trafic fractionné et les routes nommés. Pour l'instant comme notre service est nouveau, nous n'avons qu'une seule révision sur laquelle nos utilisateurs sont dirigés -- plus tard, nous verrons comment gérer les révisions multiples en utilisant `Canary Deployment Pattern`.

* Nous pouvons voir les route en exécutant :  `kn route list`

* Voir le `NAME`de la route, l'URL et si elle est `READY`:
```bash
NAME      URL                                                     READY
greeter   http://greeter-serverless-tutorial.[[HOST_SUBDOMAIN]]-80-[[KATACODA_HOST]].environments.katacoda.com  True
```

### Revision

Une  `Revision` est un enregistrement d'un instant donné du code et de la configuration pour chaque modification faite sur la charge de travail. Les révisions sont des objets immuables et peuvent être stockés aussi longtemps que nécessaire. Les administrateur de cluster peuvent modifier la ressource :  `revision.serving.knative.dev` pour rendre disponible la mise à l'échelle automatique des Pods dans le cluster OpenShift Container Platform.

* Avant d'inspecter les révisions, mettont à jour l'image du service en exécutant : 
```bash
kn service update greeter \
   --image quay.io/rhdevelopers/knative-tutorial-greeter:latest \
   --namespace serverless-tutorial
```

> **Note:** *Mettre à jour l'image du service créer une nouvelle révision, ou un enregistrement d'un moment donné de la charge de travail.*
 
* On peut voir les révisions en exécutant : `kn revision list`

* La sortie devrait être similaire à :
```bash
NAME              SERVICE   TRAFFIC   TAGS   GENERATION   AGE     CONDITIONS   READY   REASON
greeter-qxcrc-2   greeter   100%             2            6m35s   3 OK / 4     True    
greeter-fyrxn-1   greeter                    1            33m     3 OK / 4     True   
```

* Nous pouvons alors voir chaque révision et leurs détails, ce qui inclue le pourcentage de `TRAFFIC` qu'elle reçoit. Nous pouvons aussi voir le numéro généré de cette révision, **qui est incrémenté à chaque mise à jour du service**.


### Utiliser le Service

Maintenant que nous avons vu les ressources qui ont été créé lors du déploiement du Service Serverless, nous pouvons tester le déploiement. Pour le faire nous avons besoin de l'URL renvoyée par la route serverless. Celle-ci peut être trouver dans la console web dans le menu Serverless puis en cliquant sur son service.
Pour appeler le service, nous executons la commande : 
`curl [URL-DU-SERVICE]`

Le service renvoit une réponse comme celle-ci : **Hi  greeter => '6fee83923a9f' : 1**

> **NOTE:** *Vous pouvez également ouvrir l'URL dans un navigateur pour tester le service!*

### Descendre à Zero
Le service `greeter` redescendra automatiquement à zero s'il n'est pas appelé pendant environ 90 secondes. Essayer de surveiller la descente du service en exécutant la commande : `oc get pods -n serverless-tutorial -w`

Une fois la descente effectuer, vous pouvez appeler de nouveau le service pour voir le service de nouveau initialisé un pod, puis redescendre 90 secondes plus tard.

> **Question:** *Savez vous pourquoi le pod n'a pas été exécuté avant ? Le service était redescendu à zero avant que vous ne vérifiez!*

### Supprimer le Service

Nous pouvons facilement supprimer le service en exécutant :  `kn service delete greeter`


## Distribution de trafic

Les services Serverless dirige toujours le trafic vers la dernière (**latest**) révision du déploiement. Voyons comment nous pouvons partager le trafic entre différentes révisions dans notre service.

## Nom de Revision

Par défaut, Serverless génère un nom de révision aléatoire pour le service qui est basé sur l'utilisation du `metadata.name` du service Serverless comme préfix.

Le déploiemnt du service suivant utilisera le même service que dans la section précédente sauf qu'un nom arbitraire a été configuré pour les noms de révisions.

* Déployons de nouveau le service greeter, mais cette fois si définisson son **revision name** à `greeter-v1` en exécutant :
```bash
kn service create greeter \
   --image quay.io/rhdevelopers/knative-tutorial-greeter:quarkus \
   --namespace serverless-tutorial \
   --revision-name greeter-v1
```

* Nous allons maintenant mettre à jour le service et ajouter un message de prefix en tant que variable d'environnement et de changer le nom de la révision par  `greeter-v2`. Pour ça utiliser la commande :
```bash
kn service update greeter \
   --image quay.io/rhdevelopers/knative-tutorial-greeter:quarkus \
   --namespace serverless-tutorial \
   --revision-name greeter-v2 \
   --env MESSAGE_PREFIX=GreeterV2
``` 

* Voyons les deux services greeter déployés correctement avec la commande :  `kn revision list`

* La dernière commande devrait montrer deux révisions,  `greeter-v1` et `greeter-v2`:

```bash
NAME         SERVICE   TRAFFIC   TAGS   GENERATION   AGE    CONDITIONS   READY   REASON
greeter-v2   greeter   100%             2            4m5s   3 OK / 4     True    
greeter-v1   greeter                    1            14m    3 OK / 4     True 
```

> **Note:** *Il est important de noter que par défaut la dernière révision remplace la précédente en recevant 100% du trafic.*

## Modèle de déploiement Blue-Green 

Le Serverless offre un moyen simple de basculer 100% du trafic d'une révision de service Serverless (blue) vers une nouvelle révision (green). Nous pouvons revenirs à une précédente révision si la nouvelle révision a des comportements inattendu.

Avec le déploiement du serverless `greeter-v2` le trafic a été automatiquement dirigé à 100% vers `greeter-v2`. Maintenant nous décisions que nous devons revenir de  `greeter-v2` à `greeter-v1` pour différentes raisons.

* Mettre à jour le service greeter en exécutant :
```bash
kn service update greeter \
   --traffic greeter-v1=100 \
   --tag greeter-v1=current \
   --tag greeter-v2=prev \
   --tag @latest=latest
```
* La définition du service précédente crée 3 sous-routes (nommé par la suite tags de trafic) pour la route existante `greeter`.
- **current**: La révision qui recevra 100% de la distribution du trafic
- **prev**: La révision active précédente, qui ne reçoit actuellement aucun trafic
- **latest**: La route pointe vers le dernier déploiement de service, ici nous changeaons la configuration par défaut pour qu'il ne reçoivent aucun trafic.

> **Note:** *Noter bien le tag spécial `latest` dans notre configuration. Dans cette configuration nous avons définis que 100% du trafic serait géré par `greeter-v1`.*
>
> *Utiliser le tag latest peret de changer le comportement par défaut des services de diriger 100% du trafic vers la dernière revision.*

* Nous pouvons valider le trafic du service en executant : `kn route describe greeter`

* La sortie devrait être similaire à :

```bash
Name:       greeter
Namespace:  serverless-tutorial
Age:        1m
URL:        http://greeter-serverless-tutorial.[[HOST_SUBDOMAIN]]-80-[[KATACODA_HOST]].environments.katacoda.com
Service:    greeter

Traffic Targets:  
    0%  @latest (greeter-v2) #latest
        URL:  http://latest-greeter-serverless-tutorial.[[HOST_SUBDOMAIN]]-80-[[KATACODA_HOST]].environments.katacoda.com
  100%  greeter-v1 #current
        URL:  http://current-greeter-serverless-tutorial.[[HOST_SUBDOMAIN]]-80-[[KATACODA_HOST]].environments.katacoda.com
    0%  greeter-v2 #prev
        URL:  http://prev-greeter-serverless-tutorial.[[HOST_SUBDOMAIN]]-80-[[KATACODA_HOST]].environments.katacoda.com

Conditions:  
  OK TYPE                  AGE REASON
  ++ Ready                 23s 
  ++ AllTrafficAssigned     1m 
  ++ IngressReady          23s 
```

* Le changement de configuration n'a pas créé de nouveau `configuration`, `revision`, ou `deployment` pas plus que les mise à jour de l'application (e.g. image tag, env var, etc).   Lorsque nous appelons le service avec une sous-route, Serverless met à l'echelle `greeter-v1`, comme notre configuration l'indique et le service répond avec le texte `Hi greeter ⇒ '9861675f8845' : 1`.

* Nous pouvons vérifier que `greeter-v1` reçoit 100% du trafic maintenant sur notre route principal en executant :  `curl [URL-DU-SERVICE]`

> **Challenge:** *Diriger tout le trafic de novueau sur `greeter-v2` (green).*

-> Félicitations, vous savez faire un déploiement de type bleu-vert. 

## Déployer avec la stratégie Canary

Nous allons maintenant mettre en place un déploiement en Canary avec un partage du trafic.

## Appliquer un modèle de déploiement Canary

Un déploiement Canary est souvent plus efficace lorsque l'on cherche à réduire le risque d'introduire de novuelle fonctionnalité. Utiliser ce type de modèle de déploiement permet de manière plus effcicace d'obtenir des retours sur les fonctionnalités avant de les déployer pour l'ensemble des utilisateurs. En utilisant cette approche de déploiement avec le Serverless qui permet de partager le trafic entre les révisions avec un incrément de  1%.

* Pour le voir en action, appliquer la mise à jour de service qui sépare le trafic à 80% pour `greeter-v1` et 20% pour `greeter-v2` en executant : 
```bash
kn service update greeter \
   --traffic greeter-v1=80 \
   --traffic greeter-v2=20 \
   --traffic @latest=0
```

* Dans la configuration de service ci-dessus, on partage 80/20 entre la v1 et la v2 du service greeter. Voyez aussi que le service actuel est défini pour recevoir 0% du trafic en utilisant le tag `latest`.

Comme lors de l'application du modèle de déploiement Bleu-vert, la commande ne crée pas de nouvel configuration, révision ou déploiement.

* Pour observer la nouvelle distribution du trafic exécuter la commande suivante :

```bash
# ./assets/04-canary-releases/poll-svc-10.bash

#!/usr/bin/env bash
for run in {1..10}
do
  curl http://greeter-serverless-tutorial.[[HOST_SUBDOMAIN]]-80-[[KATACODA_HOST]].environments.katacoda.com
done
```

* 80% des réponses sont renvoyé depuis greeter-v1 et 20% depuis greeter-v2. Voir la liste ci-dessous comme exemple de sortie :

```bash
Hi  greeter => '6fee83923a9f' : 1
Hi  greeter => '6fee83923a9f' : 2
Hi  greeter => '6fee83923a9f' : 3
GreeterV2  greeter => '4d1c551aac4f' : 1
Hi  greeter => '6fee83923a9f' : 4
Hi  greeter => '6fee83923a9f' : 5
Hi  greeter => '6fee83923a9f' : 6
GreeterV2  greeter => '4d1c551aac4f' : 2
Hi  greeter => '6fee83923a9f' : 7
Hi  greeter => '6fee83923a9f' : 8
```

* Noter aussi, que deux pods sont en cours d'execution, représentant à la fois greeter-v1 et greeteer-v2 : `oc get pods -n serverless-tutorial`

```bash
NAME                                     READY   STATUS    RESTARTS   AGE
greeter-v1-deployment-5dc8bd556c-42lqh   2/2     Running   0          29s
greeter-v2-deployment-1dc2dd145c-41aab   2/2     Running   0          20s
```

> **Challenge:** *Ajuster la distribution des pourcentages et observer les réponses en éxécutant de nouveau le script ci-dessous :*
```bash
#!/usr/bin/env bash
for run in {1..10}
do
  curl http://greeter-serverless-tutorial.[[HOST_SUBDOMAIN]]-80-[[KATACODA_HOST]].environments.katacoda.com
done
```

### Supprimer le Service

* Nous avons besoin de nettoyer le projet pour notre prochaine partie en exécutant : `kn service delete greeter`

-> Félicitations! Vous savez maintenant appliquer quelques modèles différents de déploiement en utilisant Serverless. 


## Mise à l'echelle

[apachebench]: https://httpd.apache.org/docs/2.4/programs/ab.html 

Cette partie permet de comprendre la mise à l'échelle et de configurer la mise à l'échelle.


## Descente à zero en profondeur

Comme vous devez vous rappeler depuis la partie `Déployer son Service`, Scale-to-zero est une des principal propriétés du Serverless. Après un temps défini d'inactivités *(appelé `stable-windows`) une révision est considéré comme inactive, ce qui déclenche quelques actions. La première, toutes les routes pointent maintenant sur la révision inactive pointeront sur le bien-nommé **activator**. 

![serving-flow](/openshift/assets/developing-on-openshift/serverless/05-scaling/serving-flow.png)

Le nom `activator` est quelque chose de mal-compris de nos jours. 0 l'origine il était utilisé pour activer les révisions inactive, d'où ce nom. Aujourd'hui, sa responsabilité premièe est de recevoir et de mettre en tampon les requêtes pour les révisions qui sont inactive tout comme les métriques envoyer à l'autoscaler.  

Après que la révision est tourné au ralenti, en ne recevant plus de trafic durant le `stable-window`, la révision sera marquée comme inactive.  Si le **scaling to zero** est activé alors, après une periode supplémentaire de grâce, la révision inactive sera terminée, appelée le `scale-to-zero-grace-period`. Lorsque le **scaling to zero** est activé, la période totale de mise hors ligne est égale à la somme de `stable-window` (defaut=60s) et `scale-to-zero-grace-period` (defaut=30s) = defaut=90s.

Si nous essayons d'accéder au service lorsqu'il est à zéro l'activateur récupère la requête et la met en tampon jusqu'à ce que l' **Autoscaler** soit disponible pour crée les pods de la révision prévue.

> **Note:** *Vous devez avoir remarquer le temps de latence initiales lorsque vous essayer d'accéder à votre service. La raison de ce délais est que votre requête est traité par l'activator!*

* Il est possible de voir la configurations par défaut de l'autoscaler en executant : `oc -n knative-serving describe cm config-autoscaler`

* Nous voyons ici le `stable-window`, `scale-to-zero-grace-period`, un `enable-scale-to-zero`, parmis d'autres nombreux paramètres.

```bash
...
# When operating in a stable mode, the autoscaler operates on the
# average concurrency over the stable window.
# Stable window must be in whole seconds.
stable-window: "60s"
...
# Scale to zero feature flag
enable-scale-to-zero: "true"
...
# Scale to zero grace period is the time an inactive revision is left
# running before it is scaled to zero (min: 30s).
scale-to-zero-grace-period: "30s"
...
```
* Dans cet exercice, nous laissons la configuration tel quel, mais s'il y a des raisons de la changer, il est posssible d'étider ce configmap comme nécessaire.


> **Tip:** Une autre, possiblement meilleur, manière de faire changer les changes serait d'ajouter la configuration à l'instance `KnativeServing` qui est instance est utilisée dans cet exercice.
>
> Ouvrer et étudier ce yaml en éxecutant : `cat 01-prepare/serving.yaml`
>
> Il y a d'autres paramètres du Serverless disponible. Il est possible de décrire les autres configmaps d'un projet  `knative-serving` pour les trouver.
>
> Explorer tous ceux disponible en exécutant : `oc get cm -n knative-serving`


## Minimum Scale

Par défaut, le Serving Serverless permet 100 requêtes concurrente pour chaque révision et permet au service de se mettre à l'echelle jusqu'à zero. Ces propriété optimise l'application pour qu'elle n'utilise aucune ressource avec l'utilisation de processus inactif. C'est la configuratino par défaut, et elle fonctionne correctement en fonction du besoin spécifique de l'application.

Parfois le trafic est imprévisible, éclaté souvent, et lorsque l'app est à l'échelle zero cela prend du tempspour revenir -- donnant un départ lent aux premiers utilisateurs de l'app.

Pour résoudre cela, les services sont capable d'être configuré pour permettre à quelque processus de rester inactif, en attente des premiers utilisateus. Cela est configuré en spécifiant une mise à l'échelle minimum pour le service via une  annotation `autoscaling.knative.dev/minScale`.

> **Note:** *Vous pouvez auss limiter le nombre de pods maximum en utilisant `autoscaling.knative.dev/maxScale`*

```yaml
# ./assets/05-scaling/service-min-max-scale.yaml

apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: prime-generator
  namespace: serverless-tutorial
spec:
  template:
    metadata:
      annotations:
        # the minimum number of pods to scale down to
        autoscaling.knative.dev/minScale: "2"
        # the maximum number of pods to scale up to
        autoscaling.knative.dev/maxScale: "5"
    spec:
      containers:
        - image: quay.io/rhdevelopers/prime-generator:v27-quarkus
          livenessProbe:
            httpGet:
              path: /healthz
          readinessProbe:
            httpGet:
              path: /healthz

```

Dans la définition ci-dessus, l'échelle minimum est configuré à 2 et le maximum à 5 via deux annotations.

Puisque le serverless permet le déploiement sans yaml nous utiliserons la commande `kn` à la place de la définition de service en yaml ci-dessus.

* Deployer le service en exécutant :
```bash
kn service create prime-generator \
   --namespace serverless-tutorial \
   --annotation autoscaling.knative.dev/minScale=2 \
   --annotation autoscaling.knative.dev/maxScale=5 \
   --image quay.io/rhdevelopers/prime-generator:v27-quarkus
```

* Pour voir si le `prime-generator` est déployée et ne sera jamais mis à l'échelle en dehors de 2-5 pods disponibles : : `oc get pods -n serverless-tutorial`

* Cela garantit qu'il y aura toujours au moins deux instances disponibles de tout temps pour fournir le service sans temps de latence intiale au coût de la consommation de ressources supplémentaires. Nous allons maintenant tester que le service ne dépasse pas les 5 pods.

* Pour charger le service, nous utiliserons [apachebench (ab)](https://httpd.apache.org/docs/2.4/fr/programs/ab.html).  Nous configurerons `ab` pour envoyer 2550 requêtes au total`-n 2550`, sur laquelle 850 seront faites en même temps à chaque fois `-c 850`. Immediatement après nous regarderons le déploiement dans le projet pour voir le nombre de pods qui fonctionne.

`ab -n 2550 -c 850 -t 60 "http://[URL-DU-SERVICE]/?sleep=3&upto=10000&memload=100" && oc get deployment -n serverless-tutorial`

> **Note:** *Cela peu prendre quelques instants!*

Noter que `5/5` pods devraient être marqué comme `READY`, conformément à la mise l'échelle max.

## AutoScaling (mise à l'échelle automatique)

Comme mentionné précédemment, le Serverless par défaut se met à l'échelle vers le haut lorsqu'il y a 100 requêtes concurrente au même moment. Ce facteur de mise à l'échelle devrait fonctionner très bien pour certaines application, mais pas pour toute -- heuresement c'est un facteur modifiable! Dans certains cas vous pourrez constater qu'une application donné n'utilise pas ses ressources de manière très efficace puisque chaque requête est CPU-bound.

Pour vous aider avec ça, il est possible de déclencher la mise à l'échelle plus tôt du service, disons 50 requêtes concurrentes en ajustant la configuration via une annotation `autoscaling.knative.dev/target`.

* Mettre à jour le service prime-generator en exécutant :
```bash
kn service update prime-generator \
   --annotation autoscaling.knative.dev/target=50
```

* Nous allons de nouveau tester la mise à l'échelle en chargeant le service. Cette fois-ci nous envoyons 275 requêtes concurrente sur un total de 1100.

`ab -n 1100 -c 275 -t 60 "http://[URL-DU-SERVICE]/?sleep=3&upto=10000&memload=100" && oc get deployment -n serverless-tutorial`

* Noter que au moins 6 pods devrait être initialisé et fonctionné. Il devrait y en avoir plus que 6 car `ab` peut faire de la surcharge du nombre de workers concurrents au même moment.

* Cela fonctionne bien, mais étant donné que cette application est CPU-bound au lieu de lié au requête nous devrions choisir une classe de mise à l'échelle automatique différente qui est basée sur la charge du CPU pour être capable de gérer la mise à l'échelle plus efficacement.

## HPA AutoScaling

La mise à l'échelle automatique basée sur les métriques de CPU sont faites par quelquechose appelé Horizontal Pod Autoscaler (HPA).  Dans cet exemple, nous voulons mettre à l'échelle vers le haut lorsque le services démarré utilise 70% du CPU. Pour faire cela, nous ajoutons trois nouvelles annotations au service : `autoscaling.knative.dev/{metric,target,class}`

* Mettre à jour le service prime-generator en exécutant :
```bash
kn service update prime-generator \
   --annotation autoscaling.knative.dev/minScale- \
   --annotation autoscaling.knative.dev/maxScale- \
   --annotation autoscaling.knative.dev/target=70 \
   --annotation autoscaling.knative.dev/metric=cpu \
   --annotation autoscaling.knative.dev/class=hpa.autoscaling.knative.dev
```

> **Note:** *Noter que la commande `kn` ci-dessus supprime, ajoute ou met à jour les annotations du service. Pour supprimer utiliser `—annotation name-`.*
>
> *Noter qu'il est très difficile avec ce service de déclencher la mise à l'échelle. N'hésitez pas à ouvrir une issue ou une pull request si vous avez un moyen simple de le déclencher.*
>


## Supprimer Service

* Nettoyer le projet en utilisant : `kn service delete prime-generator`

-> Félicitations! Vous savez maintenant finement ajuster et personnaliser la mise à l'échelle du serverless en utilisant les requêtes concurrentes ou la base CPU avec les HPA.
