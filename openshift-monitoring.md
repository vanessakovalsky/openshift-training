# Monitorer et tracer ses applications 


Cet exercice montre comment obtenir le monitoring par défaut avec Prometheus et Grafana.

# Monitoring
Pour monitorier, Istio offre nativement le monitoring via Prometheus et Grafana
 
Note: Avant de regarder Grafana, nous avons besoin d'envoyer quelques requêtes à notre application en utilisant le Terminal 2: 
```
while true; do curl http://customer-tutorial.2886795283-80-kitek03.environments.katacoda.com; sleep .2; done
```
Vérifier la route de grafana en tapant :
```
oc get route -n istio-system
```
Maintenant que vous connaisez l'URL de Grafana, ouvrez là : http://grafana-istio-system.2886795283-80-kitek03.environments.katacoda.com/d/1/istio-dashboard?refresh=5s&orgId=1

Vous pouvez aussi vérifier la charge des services à l'adresse : http://grafana-istio-system.2886795283-80-kitek03.environments.katacoda.com/d/UbsSZTDik/istio-workload-dashboard?refresh=5s&orgId=1 


# Custom Metric
Istio permet aussi de spécifier des métriques personnalisés qui peuvent être incluses dans les dashboard Prometheus.

Ouvrir le fichier /istiofiles/recommendation_requestcount.yml
Il spécifie une règle istio qui invoque recommendationrequestcounthandlerpour chaque appel à recommendation.tutorial.svc.cluster.local
Revenons au dossier d'installation de istio :
```
cd ~/projects/istio-tutorial/
```
Ajoutons une métrique personnalisé et une règle :
```
istioctl create -f istiofiles/recommendation_requestcount.yml -n istio-system
```
S'assurer que la commande suivante tourne toujours dans le Terminal 2 :
```
while true; do curl http://customer-tutorial.2886795283-80-kitek03.environments.katacoda.com; sleep .2; done
```
Vérifier la route de prometheus en tapant :
```
oc get routes -n istio-system
```
Maintenant que vous connaisez l'URL de Prometheus, ouvrez là http://prometheus-istio-system.2886795283-80-kitek03.environments.katacoda.com/graph?g0.range_input=1m&g0.stacked=1&g0.expr=&g0.tab=0

Ajouter la métrique suivante :
```
istio_requests_total{destination_service="recommendation.tutorial.svc.cluster.local"}
```
Et cliquer sur Execute.

Note: Vous pouvez avoir besoin de rafraichir le navigateur pour que le graphique de Prometheus se mette à jour. Et vous pouvez souhaitez que l'interval soit de 5 minutes

# Tracing
Le tracage distribué implique la propagation du contexte de tracage de service en service, cela est généralement fait avec les headers HTTP des requêtes entrantes. Pour les services qui embarque les instruments du framework OpenTracing comme Opentracing-spring-cloud, cela est transparent. Pour les services qui n'embarque pas de bibliothèques OpenTracing, ce contexte de propagation doit être défini manuellement.

Comme OpenTracing est "juste" une bibliothèque d'instrument, un traceur concret est requis pour reellement enregistrer les données de tracage et les envoyer à un serveur distant. Notre client et services de préférences utilise Jaeger comme traceur concret. La plateforme Istio envoit automatiquement les données de tracage collecté à Jaeger, de sorte que nous voyons un trace impliquant les trois services, même si le service recommendation ne connait pas du tout OpenTracing ou Jaeger.

Notre client et service de préférence utilisent l'utilitaire TracerResolver d'OpenTracing, de sorte que les traceurs concrêts soit automatiquement chargé sans que le code n'est une dépendance forte à Jaeger. Etant donné que le traceur Jaeger peut tre configuré via des variables d'environnement, nous n'avons rien à fiare pour obtenir des traceurs Jaeger prêt et enregistrés avec OpenTracing. Certains cas nécessitent une configuration manuelle du traceur. Voir la documentation de Jaeger pour plus d'informations sur comment le faire.

Vérifier la route de Jaeger en tapant :
```
oc get routes -n istio-system
```
Maintenant que vous connaisez l'URL de Jaeger, ouvrez là http://tracing-istio-system.2886795283-80-kitek03.environments.katacoda.com

Sélectionner un client de la liste de service et cliquer sur Find Traces.
