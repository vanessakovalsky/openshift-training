# Monitorer une application Springboot sur OpenShift

## Objectifs : 

Cet exercice a pour objectifs 
* De vous permettre de surveiller une application springboot
* De créer / modifier les probes utiles au monitoring

##  Importer le code

Récupérons le code que nous allons utiliser. Lancer les commandes suivants pour cloner le projet exemple :

` git clone https://github.com/openshift-katacoda/rhoar-getting-started && cd rhoar-getting-started/spring/spring-monitoring`

## Présentation de la structure de base de l'application

Pour faciliter l'exercice, un projet en Java et utilisant l'outil de build Apache Maven est fourni.

**1. Tester l'application localement**

En développant l'application nous voulons pouvoir la tester et vérifier les modification à différentes étapes. Une des méthodes pour le faire est d'utiliser le plugin maven `spring-boot`.

Lancer l'application en exécutant la commande suivante : 

``mvn spring-boot:run``

Une fois que lancement est terminé, ouvrir l'application dans votre navigateur (http://[IP-LOCALE]:8080) et aller sur le endpoint `/fruits` .

Vous devriez voir une page HTML avec un message de bienvenu  `Success` qui ressemble à :

![Success]([https://github.com/openshift-labs/learn-katacoda/tree/master/assets/middleware/rhoar-monitoring/landingPage.png](https://github.com/openshift-labs/learn-katacoda/blob/master/assets/middleware/rhoar-monitoring/landingPage.png?raw=true))

Si vous voyez cette page, vous avez réusssi à démarrer l'application. Si ce n'est pas le cas, regarder les logs dans le terminales. Spring boot ajoute plusieurs couche d'aide pour récupérer les erreurs communes et affiche des messages d'aide utile dans la console.

**2. Arrêter l'application**

Avant de continuer, pensez à arrêter l'application en appuyant sur 
 <kbd>CTRL</kbd>+<kbd>C</kbd> dans le terminal! tem

# Deployer sur OpenShift Application Platform
**1. Deployer l'application sur OpenShift**

Vérifier que vous êtes connecté à OpenShift avec la commande : 

``oc whoami``


Créons un projet que vous utiliserez pour vos applications (ou utilisez un projet que vous avez déjà)

``oc new-project dev --display-name="Dev - Spring Boot App"``{

Executer la commande suivante pour déployer l'application sur OpenShift :

``mvn package oc:deploy -Popenshift -DskipTests``

Cette etape peut prendre du temps pour que Maven construise l'applciation et que l'application se déploit sur OpenShift; Après la complétion du build vous pouvez vérifier que tout est ok en lançant la commande suivante : 

``oc status``
 
**2. Utiliser une Route pour atteindre l'application depuis internet** 

Maintenant que l'application est déployée sur OpenShift, comment les utilisateurs peuvent t'il y accéder ? La réponse est via une **Route**. En utilisant une route, nous somme capable d'exposer nos services et d'autoriser des connexions externes sur un nom de domaine connu. Ouvrir la console OpenShift et voir la route qui a été créé pour notre application dans votre projet.

![Routes](https://github.com/openshift-labs/learn-katacoda/tree/master/assets/middleware/rhoar-monitoring/routes.png)

Cliquer sur le lien route dans la colonne _Location_ column depuis l'écran et aller sur le endpoints `/fruits`.

Vous devriez voir la même page `Success` que nous avons vu lors des tests en local.

![Success](https://github.com/openshift-labs/learn-katacoda/tree/master/assets/middleware/rhoar-monitoring/landingPage.png)


## Ajouter des points de contrôle (Health Checks)

Maintenant que notre projet a été déployé sur OpenShift and que nous avons vérifié que pouvions atteindre notre endpoint, il est temps d'ajouter des point de contrôle à l'application.

**1. Visualiser les points de contrôle**

Notre application est maintenant en fonctionnement sur OpenShift et accessible à tous les utilisateurs. Cependant comment gerons nous une erreur dans l'application ? Sans constamment vérifier manuellement l'application, il n'y a aucun moyen de savoir quand l'applications crashe. Heureuseument OpenShift peut gérer ce problèmes en utilisants des sondes (probes).

Il y a deux type de sondes que nous pouvons créés : une `liveness probe` et une `readiness probe`. La donde de vie (liveness probe) est utilisé pour vérifier si le conteneur fonctionne encore. La sonde de préparation (readiness probes) est utilisée poru déterminer si le conteneur est prêt à recevoir des requêtes. Nous allons créé un point de contrôle avec une sonde de vie que l'on utilisera pour garder une trace de la santé de notre application.

Notre point de contrôle interrogera de manière continu l'application pour s'assurer que l'application fonctionne correctement. Si la vérification échoue, OpenShift sera alerté et redémarrera le conteneur et fera tourner une nouvelle instance. Pour en savoir plus [ici](https://docs.openshift.com/container-platform/4.8/applications/application-health.html).

Comme un manque de point de contrôle peut causer des problèmes sur les conteneurs s'ils crashent, OpenShift vous alertera avec un message d'alerte si votre projet n'en dispose pas.

Dans la perpective 'developer', cliquer sur le menu _Topology_ et sélectionner votre déploiement. Vous devriez voir quelque chose comme ça : 

![Missing Health Checks](https://github.com/openshift-labs/learn-katacoda/tree/master/assets/middleware/rhoar-monitoring/healthChecks.png)

Comme nous avons une application >Spring Boot, nous avons une option facile pour la mise ne place des point de contrôle. Nous pouvons nous appuyer sur la bibliothèque `Spring Actuator`.

**2. Add Health Checks with Actuator**

Spring Actuator est un projet qui expose des données de santé sur le chemin d'API `/actuator/health` qui sont collecté pendant l'execution de l'application automatiquement. Tout ce que nous avons à faire est d'activer cettte fonctionnalité en ajoutant la dépendance suivante au fichier  ``pom.xml`` sur le commentaire **TODO**.

<pre class="file" data-filename="pom.xml" data-target="insert" data-marker="<!-- TODO: Add Actuator dependency here -->">
    &lt;dependency&gt;
      &lt;groupId&gt;org.springframework.boot&lt;/groupId&gt;
      &lt;artifactId&gt;spring-boot-starter-actuator&lt;/artifactId&gt;
    &lt;/dependency&gt;
</pre>

Noter que le message d'alerte précédent à propos des points de contrôle manquant n'est plus présent. C'est parce que nous avons ajouter la dépendance à notre fichier `pom.xml`. Ajouter cette dépendance à déclencher via jkube la création de sonde  Readiness/Liveness pour OpenShift. Ces sondes requêteront périodiquement le nouveau endpoint health pour s'assurer que l'application fonctionne toujours.

Lancer la commande suivante pour redployer l'application sur OpenShift : 

``mvn package oc:deploy -Popenshift -DskipTests``

Maintenant que nous avons ajouté Spring Actuator, nous pouvons accéder au endpoint fournit `/actuator/health`. Nous pouvons naviguer vers ce endpoint depuis notre page d'accueil en ajoutant  `/actuator/health` à l'URL. 

Vous devriez voir la réponse suivante, qui confirme que notre application répond et fonctionne correctement :

```json 
{"status":"UP"}
```

OpenShift interrogera de manière continu ce endpoint pour déterminer si une action est nécessaire pour maintenir la santé du conteneur.

**3.Les autres endpoints de Spring Actuator pour la surveillance**

Le endpoint `/actuator/health` n'est pas le seule endpoint que  Spring Actuator fournit nativement. Nous allons regarder les différents endpoints pour voir lesquels peuvent nous aider à surveiller nos applications déployés recemment, particulièrement les endpoints `/metrics` et `/beans`. Une liste de tous les autres endpoints de Spring Actuator endpoints peut être trouvée [ici](https://docs.spring.io/spring-boot/docs/current/reference/html/production-ready-endpoints.html).

Contrairement au endpoint `/actuator/health` certains de ces endpoints peuvent retourner des données sensibles et nécessite une authentification. Pour se simplifier la vie, nous enlèverons ces impératifs de sécurité pour atteindre les endpoints, mais cela n'est pas recommandé dans un environnement de production avec des données sensibles. Ouvrir le fichier ``src/main/resources/application.properties`` et ajouter le code suivant pour désactiver les sécurités :

<pre class="file" data-filename="src/main/resources/application.properties" data-target="insert" data-marker="# TODO: Add Security preference here">
management.endpoints.web.exposure.include=*  
</pre>

Puis nous redéployons l'application avec : 

``mvn package oc:deploy -Popenshift -DskipTests``

Nous pouvons maintenant atteindre le endpoint `/actuator/metrics` et obtenir la liste des types de métriques qui nous sont accessibles :

```json
{"names":["jvm.memory.max","jvm.threads.states","process.files.max","jvm.gc.memory.promoted","system.load.average.1m","jvm.memory.used","jvm.gc.max.data.size","jvm.memory.committed","system.cpu.count","logback.events","http.server.requests","tomcat.global.sent","jvm.buffer.memory.used","tomcat.sessions.created","jvm.threads.daemon","system.cpu.usage","jvm.gc.memory.allocated","tomcat.global.request.max","tomcat.global.request","tomcat.sessions.expired","jvm.threads.live","jvm.threads.peak","tomcat.global.received","process.uptime","tomcat.sessions.rejected","process.cpu.usage","tomcat.threads.config.max","jvm.classes.loaded","jvm.classes.unloaded","tomcat.global.error","tomcat.sessions.active.current","tomcat.sessions.alive.max","jvm.gc.live.data.size","tomcat.threads.current","process.files.open","jvm.buffer.count","jvm.gc.pause","jvm.buffer.total.capacity","tomcat.sessions.active.max","tomcat.threads.busy","process.start.time"]}
```

Nous pouvons aller sur  `/acutuator/metrics/[metric-name]`. Par exemple, cliquer ajouter à votre URL local `/actuator/metrics/jvm.memory.max` pour obtenir la métrique jvm.memory.max.
Cela affiche les différents types de données de métriques à propos de la JVM : 


```json
{"name":"jvm.memory.max","description":"The maximum amount of memory in bytes that can be used for memory management","baseUnit":"bytes","measurements":[{"statistic":"VALUE","value":2.543321088E9}],"availableTags":[{"tag":"area","values":["heap","nonheap"]},{"tag":"id","values":["Compressed Class Space","PS Survivor Space","PS Old Gen","Metaspace","PS Eden Space","Code Cache"]}]}
```

En plus des différents endpoints de surveillance, nous avons aussi accès au endpoint d'information comme  `/actuator/beans`, qui affichera la liste des éléments de configuration de l'application. Spring Actuator fournit de nombreux endpoints d'information par dessus les endpoints de surveillance qui peuvent fournir des informations utiles à propos de l'application Spring deplotée et qui peuvent être utile lors du debug d'application sur OpenShift.

-> Félicitations, vous avez inclus un point de contrôle dans votre application Spring Boot qui fonctionne sur the OpenShift Container Platform.
