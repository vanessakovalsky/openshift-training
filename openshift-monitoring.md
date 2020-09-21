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

#T racing
Distributed Tracing involves propagating the tracing context from service to service, usually done by sending certain incoming HTTP headers downstream to outbound requests. For services embedding a OpenTracing framework instrumentations such as opentracing-spring-cloud, this might be transparent. For services that are not embedding OpenTracing libraries, this context propagation needs to be done manually.

As OpenTracing is "just" an instrumentation library, a concrete tracer is required in order to actually capture the tracing data and report it to a remote server. Our customer and preference services ship with Jaeger as the concrete tracer. the Istio platform automatically sends collected tracing data to Jaeger, so that we are able to see a trace involving all three services, even if our recommendation service is not aware of OpenTracing or Jaeger at all.

Our customer and preference services are using the TracerResolver facility from OpenTracing, so that the concrete tracer can be loaded automatically without our code having a hard dependency on Jaeger. Given that the Jaeger tracer can be configured via environment variables, we don’t need to do anything in order to get a properly configured Jaeger tracer ready and registered with OpenTracing. That said, there are cases where it’s appropriate to manually configure a tracer. Refer to the Jaeger documentation for more information on how to do that.

Check the Jaeger route by typing 
```
oc get routes -n istio-system
```
Now that you know the URL of Jaeger, access it at http://tracing-istio-system.2886795283-80-kitek03.environments.katacoda.com

Select customer from the list of services and click on Find Traces:
