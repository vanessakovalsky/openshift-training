# Définir un routing avec Istio

This scenario shows how Istio can be used to control route based on some simple rules.

Modify Recommendation source code
IMPORTANT: Do not attempt to edit the files or run any command before the Terminal cursor becomes available.

We can experiment with Istio routing rules by making a change to RecommendationsController.java.

Open /recommendation/java/vertx/src/main/java/com/redhat/developer/demos/recommendation/RecommendationVerticle.java in the editor. Now make the following modification.

    private static final String RESPONSE_STRING_FORMAT = "recommendation v2 from '%s': %d\n";
Note: The file is saved automatically.

Now go to the recommendations folder cd ~/projects/istio-tutorial/recommendation/java/vertx

Make sure that the file has changed: git diff.

Compile the project with the modifications that you did.

mvn package

Create the recommendation:v2 docker image.
We will now create a new image using v2. The v2tag during the docker build is significant.

Execute docker build -t example/recommendation:v2 .

You can check the image that was create by typing docker images | grep recommendation

Create a second deployment with sidecar proxy
There is also a 2nd deployment.yml file to label things correctly

Execute: oc apply -f <(istioctl kube-inject -f ../../kubernetes/Deployment-v2.yml) -n tutorial

To watch the creation of the pods, execute oc get pods -w

Once that the recommendation pod READY column is 2/2, you can hit CTRL+C.

Test the customer endpoint: curl http://customer-tutorial.2886795293-80-cykoria05.environments.katacoda.com

You likely see "customer => preference => recommendation v2 from '2819441432-5v22s': 1" as by default you get round-robin load-balancing when there is more than one Pod behind a Service.

You likely see "customer => preference => recommendation v1 from '99634814-d2z2t': 3", where '99634814-d2z2t' is the pod running v1 and the 3 is basically the number of times you hit the endpoint.

Send several requests on Terminal 2 to see their responses

while true; do curl http://customer-tutorial.2886795293-80-cykoria05.environments.katacoda.com; sleep .5; done

The default Kubernetes/OpenShift behavior is to round-robin load-balance across all available pods behind a single Service. Add another replica of recommendations-v2 Deployment.

oc scale --replicas=2 deployment/recommendation-v2

Wait the second recommendation:v2 pod to become available, execute oc get pods -w

Once that the recommendation pod READY column is 2/2, you can hit CTRL+C.

Make sure that the following command is running on Terminal 2 while true; do curl http://customer-tutorial.2886795293-80-cykoria05.environments.katacoda.com; sleep .5; done

You will see two requests for v2 for each one of v1.

Scale back to a single replica of the recommendation-v2 deployment:

oc scale --replicas=1 deployment/recommendation-v2

On Terminal 2, you will see requests being round-robin balanced between v1 and v2.

All users to recommendation:v2
Open the file istiofiles/destination-rule-recommendation-v1-v2.yml.

Open the file istiofiles/virtual-service-recommendation-v2.yml.

Note that the DestinationRule adds a name to each version of our recommendation deployments, and VirtualService specifies that the destination will be the recommendation deployment with name version-v2.

Let's apply these files.

istioctl create -f ~/projects/istio-tutorial/istiofiles/destination-rule-recommendation-v1-v2.yml -n tutorial
istioctl create -f ~/projects/istio-tutorial/istiofiles/virtual-service-recommendation-v2.yml -n tutorial

Make sure that the following command is running on Terminal 2 while true; do curl http://customer-tutorial.2886795293-80-cykoria05.environments.katacoda.com; sleep .2; done

You should only see v2 being returned.

All users to recommendation:v1
Open the file /istiofiles/virtual-service-recommendation-v1.yml.

Note that it specifies that the destination will be the recommendation deployment with the name version-v1.

Let's replace the VirtualService.

istioctl replace -f ~/projects/istio-tutorial/istiofiles/virtual-service-recommendation-v1.yml -n tutorial

Note: We used replace instead of create since we are overlaying the previous VirtualService.

Make sure that the following command is running on Terminal 2 while true; do curl http://customer-tutorial.2886795293-80-cykoria05.environments.katacoda.com; sleep .2; done

you should only see v1 being returned.

Explore the VirtualService object
You can check the existing route rules by typing istioctl get virtualservice. It will show that we only have a VirtualService object called recommendations. The name has been specified in the VirtualService metadata.

You can check the contents of this VirtualService by executing istioctl get virtualservice recommendation -o yaml -n tutorial

All users to recommendation v1 and v2
We can now send requests to both v1 and v2 by simply removing the rule:

istioctl delete virtualservice recommendation -n tutorial

Make sure that the following command is running on Terminal 2 while true; do curl http://customer-tutorial.2886795293-80-cykoria05.environments.katacoda.com; sleep .2; done

You should be able to see the default behavior of round-robin balancing between v1 and v2 being returned.

Canary deployment: Split traffic between v1 and v2
Think about the following scenario: Push v2 into the cluster but slowing send end-user traffic to it, if you continue to see success, continue shifting more traffic over time.

Let's now how we would create a VirtualService that sends 90% of requests to v1 and 10% to v2.

Take a look at the file /istiofiles/virtual-service-recommendation-v1_and_v2.yml

It specifies that recommendation with name version-v1 will have a weight of 90, and recommendation with name version-v2 will have a weight of 10.

Create this VirtualService: istioctl create -f ~/projects/istio-tutorial/istiofiles/virtual-service-recommendation-v1_and_v2.yml -n tutorial

Make sure that the following command is running on Terminal 2 while true; do curl http://customer-tutorial.2886795293-80-cykoria05.environments.katacoda.com; sleep .2; done

You should see a rate of 90/10 between v1 and v2.

Recommendations 75/25
Let's change the routing weight to be 75/25 by applying the following file /istiofiles/virtual-service-recommendation-v1_and_v2_75_25.yml

Replace the previously created VirtualService with: oc replace -f ~/projects/istio-tutorial/istiofiles/virtual-service-recommendation-v1_and_v2_75_25.yml -n tutorial

Make sure that the following command is running on Terminal 2 while true; do curl http://customer-tutorial.2886795293-80-cykoria05.environments.katacoda.com; sleep .2; done

You should see a rate of 75/25 between v1 and v2.

Clean up
You can remove the VirtualService called recommendation to have the load balacing behavior back:

istioctl delete virtualservice recommendation -n tutorial

On Terminal 2 you should see v1 and v2 being returned in a 50/50 round-robin load-balancing.
