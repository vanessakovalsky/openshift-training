# Monitorer et tracer ses applications 

Exercice original : https://www.katacoda.com/courses/openshift/servicemesh/3-monitoring-tracing 

Cet exercice montre comment obtenir le monitoring par défaut avec Prometheus et Graphana.

# Monitoring
For monitoring, Istio offers out of the box monitoring via Prometheus and Grafana.

Note: Before we take a look at Grafana, we need to send some requests to our application using on Terminal 2: 
```
while true; do curl http://customer-tutorial.2886795283-80-kitek03.environments.katacoda.com; sleep .2; done
```
Check the grafana route by typing 
```
oc get route -n istio-system
```
Now that you know the URL of Grafana, access it at http://grafana-istio-system.2886795283-80-kitek03.environments.katacoda.com/d/1/istio-dashboard?refresh=5s&orgId=1

You can also check the workload of the services at http://grafana-istio-system.2886795283-80-kitek03.environments.katacoda.com/d/UbsSZTDik/istio-workload-dashboard?refresh=5s&orgId=1 


# Custom Metric
Istio also allows you to specify custom metrics which can be seen inside of the Prometheus dashboard.

Look at the file /istiofiles/recommendation_requestcount.yml

It specifies an istio rule that invokes the recommendationrequestcounthandler for every invocation to recommendation.tutorial.svc.cluster.local

Let's go back to the istio installation folder:
```
cd ~/projects/istio-tutorial/
```
Now, add the custom metric and rule.

Execute 
```
istioctl create -f istiofiles/recommendation_requestcount.yml -n istio-system
```
Make sure that the following command is running on Terminal 2 
```
while true; do curl http://customer-tutorial.2886795283-80-kitek03.environments.katacoda.com; sleep .2; done
```
Check the prometheus route by typing 
```
oc get routes -n istio-system
```
Now that you know the URL of Prometheus, access it at http://prometheus-istio-system.2886795283-80-kitek03.environments.katacoda.com/graph?g0.range_input=1m&g0.stacked=1&g0.expr=&g0.tab=0

Add the following metric:
```
istio_requests_total{destination_service="recommendation.tutorial.svc.cluster.local"}
```
and select Execute:



Note: You may have to refresh the browser for the Prometheus graph to update. And you may wish to make the interval 5m (5 minutes) as seen in the screenshot above.
