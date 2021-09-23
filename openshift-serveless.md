# OpenShift - Première application en Serverless

## Présentation du serverless

[serverless-main]: https://www.openshift.com/learn/topics/serverless
[amq-docs]: https://developers.redhat.com/products/amq/overview
[pipelines-main]: https://www.openshift.com/learn/topics/pipelines
[service-mesh-main]: https://www.openshift.com/learn/topics/service-mesh

In this self-paced tutorial, you will learn the basics of how to use OpenShift Serverless, which provides a development model to remove the overhead of server provisioning and maintenance from the developer.

In this tutorial, you will:
* Deploy an OpenShift Serverless `service`.
* Deploy multiple `revisions` of a service.
* Understand the `underlying compents` of a serverless service.
* Understand how Serverless is able to `scale-to-zero`.
* Run different revisions of a service via `canary` and `blue-green` deployments.
* Utilize the `knative client`.

## Why Serverless?

Deploying applications as Serverless services is becoming a popular architectural style. It seems like many organizations assume that _Functions as a Service (FaaS)_ implies a serverless architecture. We think it is more accurate to say that FaaS is one of the ways to utilize serverless, although it is not the only way. This raises a super critical question for enterprises that may have applications which could be monolith or a microservice: What is the easiest path to serverless application deployment?

The answer is a platform that can run serverless workloads, while also enabling you to have complete control of the configuration, building, and deployment. Ideally, the platform also supports deploying the applications as linux containers.

## OpenShift Serverless

In this chapter we introduce you to one such platform -- [OpenShift Serverless][serverless-main].  OpenShift Serverless helps developers to deploy and run applications that will scale up or scale to zero on-demand. Applications are packaged as OCI compliant Linux containers that can be run anywhere.  This is known as `Serving`.

![OpenShift Serving](/openshift/assets/developing-on-openshift/serverless/00-intro/knative-serving-diagram.png)

Serverless has a robust way to allow for applications to be triggered by a variety of event sources, such as events from your own applications, cloud services from multiple providers, Software as a Service (SaaS) systems and Red Hat Services ([AMQ Streams][amq-docs]).  This is known as `Eventing`.

![OpenShift Eventing](/openshift/assets/developing-on-openshift/serverless/00-intro/knative-eventing-diagram.png)

OpenShift Serverless applications can be integrated with other OpenShift services, such as OpenShift [Pipelines][pipelines-main], and [Service Mesh][service-mesh-main], delivering a complete serverless application development and deployment experience.

This tutorial will focus on the `Serving` aspect of OpenShift Serverless as the first diagram showcases.  Be on the lookout for additional tutorials to dig further into Serverless, specifically `Eventing`.

## The Environment

During this scenario, you will be using a hosted OpenShift environment that is created just for you. This environment is not shared with other users of the system. Because each user completing this scenario has their own environment, we had to make some concessions to ensure the overall platform is stable and used only for this training. For that reason, your environment will only be active for a one hour period. Keep this in mind before you get started on the content. Each time you start this training, a new environment will be created on the fly.

The OpenShift environment created for you is running version 4.7 of the OpenShift Container Platform. This deployment is a self-contained environment that provides everything you need to be successful learning the platform. This includes a preconfigured command line environment, the OpenShift web console, public URLs, and sample applications.

> **Note:** *It is possible to skip around in this tutorial.  The only pre-requisite for each section would be the initial `Prepare for Exercises` section.*
>
> *For example, you could run the `Prepare for Exercises` section immediately followed by the `Scaling` section.*

Now, let's get started!


## Pré-requis

[serverless-install-script]: https://github.com/openshift-labs/learn-katacoda/blob/master/developing-on-openshift/serverless/assets/01-prepare/install-serverless.bash
[olm-docs]: https://docs.openshift.com/container-platform/latest/operators/understanding/olm/olm-understanding-olm.html
[serving-docs]: https://github.com/knative/serving-operator#the-knativeserving-custom-resource

OpenShift Serverless is an OpenShift add-on that can be installed via an operator that is available within the OpenShift OperatorHub.

Some operators are able to be installed into single namespaces within a cluster and are only able to monitor resources within that namespace.  The OpenShift Serverless operator is one that installs globally on a cluster so that it is able to monitor and manage Serverless resources for every single project and user within the cluster.

You could install the Serverless operator using the *Operators* tab within the web console, or you can use the CLI tool `oc`.  In this instance, the terminal on the side is already running through an automated CLI install.  This [script can be found here][serverless-install-script].

Since the install will take some time, let's take a moment to review the installation via the web console.

> **Note:** *These steps are for informational purposes only. **Do not** follow them in this instance as there already is an automated install running in the terminal.*

## Log in and install the operator
This section is automated, so you won't need to install the operator.  If you wanted to reproduce these results on another cluster, you'd need to authenticate as an admin to complete the following steps:

![01-login](/openshift/assets/developing-on-openshift/serverless/01-prepare/01-login.png)

Cluster administrators can install the `OpenShift Serverless` operator via *Operator Hub*

![02-operatorhub](/openshift/assets/developing-on-openshift/serverless/01-prepare/02-operatorhub.png)

> **Note:** *We can inspect the details of the `serverless-operator` packagemanifest within the CLI via `oc describe packagemanifest serverless-operator -n openshift-marketplace`.*
>
> **Tip:** *You can find more information on how to add operators on the [OpenShift OLM Documentation Page][olm-docs].*

Next, our scripts will install the Serverless Operator into the `openshift-operators` project using the `stable` update channel.

![03-serverlessoperator](/openshift/assets/developing-on-openshift/serverless/01-prepare/03-serverlessoperator.png)

Open the **Installed Operators** tab and watch the **OpenShift Serverless Operator**.  The operator is installed and ready when the `Status=Succeeded`.

![05-succeeded](/openshift/assets/developing-on-openshift/serverless/01-prepare/05-succeeded.png)

> **Note:** *We can inspect the additional api resouces that the serverless operator added to the cluster via the CLI command `oc api-resources | egrep 'Knative|KIND'`*.

Next, we need to use these new resources provided by the serverless operator to install KnativeServing.

## Install KnativeServing
As per the [Knative Serving Operator documentation][serving-docs] you must create a `KnativeServing` object to install Knative Serving using the OpenShift Serverless Operator.

> **Note:** *Remember, these steps are for informational purposes only. **Do not** follow them in this instance as there already is an automated install running in the terminal.*

First we create the `knative-serving` project.

![06-kservingproject](/openshift/assets/developing-on-openshift/serverless/01-prepare/06-kservingproject.png)

Within the `knative-serving` project open the **Installed Operators** tab and the **OpenShift Serverless Operator**.  Then create an instance of **Knative Serving**.

![07-kservinginstance](/openshift/assets/developing-on-openshift/serverless/01-prepare/07-kservinginstance.png)

![08-kservinginstance](/openshift/assets/developing-on-openshift/serverless/01-prepare/08-kservinginstance.png)

Open the Knative Serving instance.  It is deployed when the **Condition** `Ready=True`.

![09-kservingready](/openshift/assets/developing-on-openshift/serverless/01-prepare/09-kservingready.png)

OpenShift Serverless should now be installed!

## Login as a Developer and Create a Project
Before beginning we should change to the non-privileged user `developer` and create a new `project` for the tutorial.

> **Note:** *Remember, these steps are for informational purposes only. **Do not** follow them in this instance as there already is an automated install running in the terminal.*

To change to the non-privileged user in our environment we login as username: `developer`, password: `developer`

Next create a new project by executing: `oc new-project serverless-tutorial`

There we go! You are all set to kickstart your serverless journey with **OpenShift Serverless**. 

Please check for the terminal output of `Serverless Tutorial Ready!` before continuing.  Once ready, click `continue` to go to the next module on how to deploy your first severless service.

## Créer un service

[ocp-serving-components]: https://docs.openshift.com/container-platform/4.7/serverless/architecture/serverless-serving-architecture.html

At the end of this chapter you will be able to:
- Deploy your very first application as an OpenShift Serverless `Service`.
- Learn the underlying components of a Serverless Service, such as: `configurations`, `revisions`, and `routes`.
- Watch the service `scale to zero`.
- `Delete` the Serverless Service.

Now that we have OpenShift Serverless installed on the cluster, we can deploy our first Serverless application, creating a Knative service. But before doing that, let's explore the Serving module.

## Explore Serving
Let's take a moment to explore the new API resources available in the cluster since installing `Serving`.

Like before, we can see what `api-resources` are available now by running: `oc api-resources --api-group serving.knative.dev`{{execute}}

> **Note:** *Before we searched for any `api-resource` which had `KnativeServing` in any of the output using `grep`.  In this section we are filtering the `APIGROUP` which equals `serving.knative.dev`.*

The Serving module consists of a few different pieces.  These pieces are listed in the output of the previous command: `configurations`, `revisions`, `routes`, and `services`.  The `knativeservings` api-resource was existing, and we already created an instance of it to install KnativeServing. 

```bash
NAME              SHORTNAMES      APIGROUP              NAMESPACED   KIND
configurations    config,cfg      serving.knative.dev   true         Configuration
knativeservings   ks              serving.knative.dev   true         KnativeServing
revisions         rev             serving.knative.dev   true         Revision
routes            rt              serving.knative.dev   true         Route
services          kservice,ksvc   serving.knative.dev   true         Service
```

The diagram below shows how each of the components of the Serving module fit together.

![Serving](/openshift/assets/developing-on-openshift/serverless/02-serving/serving.png)

We will discuss what each one of these new resources are used for in the coming sections.  Let's start with `services`.

## OpenShift Serverless Services
As discussed in the [OpenShift Serverless Documentation][ocp-serving-components], a **Knative Service Resource** automatically manages the whole lifecycle of a serverless workload on a cluster. It controls the creation of other objects to ensure that an app has a route, a configuration, and a new revision for each update of the service. Services can be defined to always route traffic to the latest revision or to a pinned revision.

Before deploying your first Serverless Service, let us take a moment to understand it's structure:

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

We now are deploying an instance of a `Service` that is provided by `serving.knative.dev`.  In our simple example we define a container `image` and the paths for `health checking` of the service.  We also provided the `name` and `namespace`.

## Deploy the Serverless Service
To deploy the service we could deploy the yaml above by executing `oc apply -n serverless-tutorial -f 02-serving/service.yaml`, but one of the best features of serverless is the ability to deploy and work with serverless resources without ever working with yaml.  In this tutorial we will use the `kn` CLI tool to work with serverless. 

To deploy the service execute:
```bash
kn service create greeter \
   --image quay.io/rhdevelopers/knative-tutorial-greeter:quarkus \
   --namespace serverless-tutorial
```{{execute}}

> **Note:** *The equivalent yaml for the service above can be seen by executing: `cat 02-serving/service.yaml`{{execute}}*.

Watch the status using the commands:
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

```{{execute}}

A successful service deployment will show the following `greeter` pods:

```shell
NAME                                        READY   STATUS    RESTARTS   AGE
greeter-6vzt6-deployment-5dc8bd556c-42lqh   2/2     Running   0          11s
```

> **Question:** *If you run the watch script too late you might not see any pods running or being created after a few loops and will have to escape out of the watch with `CTRL+C`.  I'll let you think about why this happens.  Continue on for now and validate the deployment.*

## Check out the deployment
As discussed in the [OpenShift Serverless Documentation][ocp-serving-components], Serverless Service deployments will create a few required serverless resources.  We will dive into each of them below.

### Service
We can see the Serverless Service that we just created by executing: `kn service list`{{execute}}

The output should be similar to:

```bash
NAME      URL                                                     LATEST            AGE     CONDITIONS   READY   REASON
greeter   http://greeter-serverless-tutorial.[[HOST_SUBDOMAIN]]-80-[[KATACODA_HOST]].environments.katacoda.com  greeter-fyrxn-1   6m28s   3 OK / 3     True    
```

> **Note:** *It also is possible to use the `oc` command to see the serverless resources, to see the services execute: `oc get -n serverless-tutorial services.serving.knative.dev`{{execute}}*

The Serverless `Service` gives us information about it's `URL`, it's `LATEST` revision, it's `AGE`, and it's status for each service we have deployed.  It is also important to see that `READY=True` to validate that the service has deployed successfully even if there were no pods running in the previous section.

It also is possible to `describe` a specific service to gather detailed information about that service by executing: `kn service describe greeter`{{execute}}

The output should be similar to:
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

> **Note:** *Most resources can be `described` via the `kn` tool.  Be sure to check them out while continuing along the tutorial.*

Next, we will inspect the `Route`.  Routes manage the ingress and URL into the service.

> *How is it possible to have a service deployed and `Ready` but no pods are running for that service?*
>
> See a hint by inspecting the `READY` column from `oc get deployment`{{execute}}

### Route
As the [OpenShift Serverless Documentation][ocp-serving-components] explains, a `Route` resource maps a network endpoint to one or more Knative revisions. It is possible to manage the traffic in several ways, including fractional traffic and named routes.  Currently, since our service is new, we have only one revision to direct our users to -- in later sections we will show how to manage multiple revisions at once using a `Canary Deployment Pattern`.

We can see the route by executing: `kn route list`{{execute}}

See the `NAME` of the route, the `URL`, as well as if it is `READY`:
```bash
NAME      URL                                                     READY
greeter   http://greeter-serverless-tutorial.[[HOST_SUBDOMAIN]]-80-[[KATACODA_HOST]].environments.katacoda.com  True
```

### Revision
Lastly, we can inspect the `Revisions`.  As per the [OpenShift Serverless Documentation][ocp-serving-components], a `Revision` is a point-in-time snapshot of the code and configuration for each modification made to the workload. Revisions are immutable objects and can be retained for as long as needed. Cluster administrators can modify the `revision.serving.knative.dev` resource to enable automatic scaling of Pods in an OpenShift Container Platform cluster.

Before inspecting revisions, update the image of the service by executing:
```bash
kn service update greeter \
   --image quay.io/rhdevelopers/knative-tutorial-greeter:latest \
   --namespace serverless-tutorial
```{{execute}}.

> **Note:** *Updating the image of the service will create a new revision, or point-in-time snapshot of the workload.*
 
We can see the revision by executing: `kn revision list`{{execute}}

The output should be similar to:
```bash
NAME              SERVICE   TRAFFIC   TAGS   GENERATION   AGE     CONDITIONS   READY   REASON
greeter-qxcrc-2   greeter   100%             2            6m35s   3 OK / 4     True    
greeter-fyrxn-1   greeter                    1            33m     3 OK / 4     True   
```

Here we can see each revision and details including the percantage of `TRAFFIC` it is receiving.  We can also see the generational number of this revision, **which is incremented on each update of the service**.

### Invoke the Service
Now that we have seen a a few of the underlying resouces that get created when deploying a Serverless Service, we can test the deployment.  To do so we will need to use the URL returned by the serverless route.  To invoke the service we can execute the command `curl http://greeter-serverless-tutorial.[[HOST_SUBDOMAIN]]-80-[[KATACODA_HOST]].environments.katacoda.com`{{execute}}

The service will return a response like **Hi  greeter => '6fee83923a9f' : 1**

> **NOTE:** *You can also open this in your own local browser to test the service!*

### Scale to Zero
The `greeter` service will automatically scale down to zero if it does not get request for approximately 90 seconds.  Try watching the service scaling down by executing `oc get pods -n serverless-tutorial -w`{{execute}}

Try invoking the service again using the `curl` from earlier to see the service scaling back up from zero.

> **Question:** *Do you see now why the pod might not have been running earlier? The service scaled to zero before you checked!*

## Delete the Service
We can easily delete our service by executing: `kn service delete greeter`{{execute}}

Awesome! You have successfully deployed your very first serverless service using OpenShift Serverless. In the next chapter we will go a bit deeper in understanding how to distribute traffic between multiple revisions of the same service.


## Distribution de trafic

At the end of this step you will be able to:
- Provide a custom `name` to the deployment
- Configure a service to use a `blue-green` deployment pattern

Serverless services always route traffic to the **latest** revision of the deployment. In this section we will learn a few different ways to split the traffic between revisions in our service.

## Revision Names
By default, Serverless generates random revision names for the service that is based on using the Serverless service’s `metadata.name` as a prefix.

The following service deployment uses the same greeter service as the last section in the tutorial except it is configured with an arbitrary revision name.

Let's deploy the greeter service again, but this time set its **revision name** to `greeter-v1` by executing:
```bash
kn service create greeter \
   --image quay.io/rhdevelopers/knative-tutorial-greeter:quarkus \
   --namespace serverless-tutorial \
   --revision-name greeter-v1
```{{execute}} 

> **Note:** *The equivalent yaml for the service above can be seen by executing: `cat 03-traffic-distribution/greeter-v1-service.yaml`{{execute}}*.

Next, we are going to update the greeter service to add a message prefix environment variable and change the revision name to `greeter-v2`.  Do so by executing:
```bash
kn service update greeter \
   --image quay.io/rhdevelopers/knative-tutorial-greeter:quarkus \
   --namespace serverless-tutorial \
   --revision-name greeter-v2 \
   --env MESSAGE_PREFIX=GreeterV2
```{{execute}} 

> **Note:** *The equivalent yaml for the service above can be seen by executing: `cat 03-traffic-distribution/greeter-v2-service.yaml`{{execute}}*.

See that the two greeter services have deployed successfully by executing `kn revision list`{{execute}}

The last command should output two revisions, `greeter-v1` and `greeter-v2`:

```bash
NAME         SERVICE   TRAFFIC   TAGS   GENERATION   AGE    CONDITIONS   READY   REASON
greeter-v2   greeter   100%             2            4m5s   3 OK / 4     True    
greeter-v1   greeter                    1            14m    3 OK / 4     True 
```

> **Note:** *It is important to notice that by default the latest revision will replace the previous by receiving 100% of the traffic.*

## Blue-Green Deployment Patterns
Serverless offers a simple way of switching 100% of the traffic from one Serverless service revision (blue) to another newly rolled out revision (green).  We can rollback to a previous revision if any new revision (e.g. green) has any unexpected behaviors.

With the deployment of `greeter-v2` serverless automatically started to direct 100% of the traffic to `greeter-v2`. Now let us assume that we need to roll back `greeter-v2` to `greeter-v1` for some reason.

Update the greeter service by executing:
```bash
kn service update greeter \
   --traffic greeter-v1=100 \
   --tag greeter-v1=current \
   --tag greeter-v2=prev \
   --tag @latest=latest
```{{execute}}

The above service definition creates three sub-routes(named after traffic tags) to the existing `greeter` route.
- **current**: The revision will receive 100% of the traffic distribution
- **prev**: The previously active revision, which will now receive no traffic
- **latest**: The route pointing to the latest service deployment, here we change the default configuration to receive no traffic.

> **Note:** *Be sure to notice the special tag: `latest` in our configuration above.  In the configuration we defined 100% of the traffic be handled by `greeter-v1`.*
>
> *Using the latest tag allows changing the default behavior of services to route 100% of the traffic to the latest revision.*

We can validate the service traffic tags by executing: `kn route describe greeter`{{execute}}

The output should be similar to:

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

> **Note:** *The equivalent yaml for the service above can be seen by executing: `cat 03-traffic-distribution/service-pinned.yaml`{{execute}}*.

The configuration change we issued above does not create any new `configuration`, `revision`, or `deployment` as there was no application update (e.g. image tag, env var, etc).  When calling the service without the sub-route, Serverless scales up the `greeter-v1`, as our configuration specifies and the service responds with the text `Hi greeter ⇒ '9861675f8845' : 1`.

We can check that `greeter-v1` is receiving 100% of the traffic now to our main route by executing: `curl http://greeter-serverless-tutorial.[[HOST_SUBDOMAIN]]-80-[[KATACODA_HOST]].environments.katacoda.com`{{execute}}

> **Challenge:** *As a test, route all of the traffic back to `greeter-v2` (green).*

Congrats! You now are able to apply a a `blue-green` deployment pattern using Serverless.  In the next section we will look at `canary release` deployments.

## Déployer en canary

At the end of this step you will be able to:
- Configure a service to use a `Canary Release` deployment pattern

> **Note:** *If you did not complete the previous Traffic Distribution section please execute both of the following commands:*

```bash
kn service create greeter --image quay.io/rhdevelopers/knative-tutorial-greeter:quarkus --namespace serverless-tutorial --revision-name greeter-v1
kn service update greeter --image quay.io/rhdevelopers/knative-tutorial-greeter:quarkus --namespace serverless-tutorial --revision-name greeter-v2 --env MESSAGE_PREFIX=GreeterV2
```{{execute}}

## Applying a Canary Release Pattern
A Canary release is more effective when looking to reduce the risk of introducing new features. Using this type of deployment model allows a more effective feature-feedback loop before rolling out the change to the entire user base.  Using this deployment approach with Serverless allows splitting the traffic between revisions in increments as small as 1%.

To see this in action, apply the following service update that will split the traffic 80% to 20% between `greeter-v1` and `greeter-v2` by executing:
```bash
kn service update greeter \
   --traffic greeter-v1=80 \
   --traffic greeter-v2=20 \
   --traffic @latest=0
```{{execute}}

In the service configuration above see the 80/20 split between v1 and v2 of the greeter service.  Also see that the current service is set to receive 0% of the traffic using the `latest` tag.

> **Note:** *The equivalent yaml for the service above can be seen by executing: `cat 04-canary-releases/greeter-canary-service.yaml`{{execute}}

As in the previous section on Applying Blue-Green Deployment Pattern deployments, the command will not create a new configuration, revision, or deployment.

To observe the new traffic distribution execute the following:

```bash
# ./assets/04-canary-releases/poll-svc-10.bash

#!/usr/bin/env bash
for run in {1..10}
do
  curl http://greeter-serverless-tutorial.[[HOST_SUBDOMAIN]]-80-[[KATACODA_HOST]].environments.katacoda.com
done
```{{execute}}

80% of the responses are returned from greeter-v1 and 20% from greeter-v2. See the listing below for sample output:

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

Also notice that two pods are running, representing both greeter-v1 and greeter-v2: `oc get pods -n serverless-tutorial`{{execute}}

```bash
NAME                                     READY   STATUS    RESTARTS   AGE
greeter-v1-deployment-5dc8bd556c-42lqh   2/2     Running   0          29s
greeter-v2-deployment-1dc2dd145c-41aab   2/2     Running   0          20s
```

> **Note:** *If we waited too long to execute the preceding command we might have noticed the services scaling to zero!*
>
> **Challenge:** *As a challenge, adjust the traffic distribution percentages and observe the responses by executing the `poll-svc-10.bash` script again.*

## Delete the Service

We will need to cleanup the project for our next section by executing: `kn service delete greeter`{{execute}}

Congrats! You now are able to apply a few different deployment patterns using Serverless.  In the next section we will see how we dig a little deeper into the scaling components of Serverless.


## Mise à l'echelle

[apachebench]: https://httpd.apache.org/docs/2.4/programs/ab.html 
[learn-katacoda]: https://github.com/openshift-labs/learn-katacoda

At the end of this chapter you will be able to:
- Understand `scale-to-zero` in depth and why it’s important.
- Understand how to configure the `scale-to-zero-grace-period`.
- Understand types of `autoscaling strategies`.
- Enable `concurrency based autoscaling`.
- Configure a `minimum number of replicas` for a service.
- Configure a `Horizontal Pod Autoscaler` for a service.

## In depth: Scaling to Zero
As you might recall from the `Deploying your Service` section of the tutorial, Scale-to-zero is one of the main properties of Serverless. After a defined time of idleness *(called the `stable-window`)* a revision is considered inactive, which causes a few things to happen.  First off, all routes pointing to the now inactive revision will be pointed to the so-called **activator**. 

![serving-flow](/openshift/assets/developing-on-openshift/serverless/05-scaling/serving-flow.png)

The name `activator` is somewhat misleading these days.  Originally it used to activate inactive revisions, hence the name.  Today its primary responsibilites are to receive and buffer requests for revisions that are inactive as well as report metrics to the autoscaler.  

After the revision has been deemed idle, by not receiving any traffic during the `stable-window`, the revision will be marked inactive.  If **scaling to zero** is enabled then there is an additional grace period before the inactive revision terminates, called the `scale-to-zero-grace-period`.  When **scaling to zero** is enabled the total termination period is equal to the sum of both the `stable-window` (default=60s) and `scale-to-zero-grace-period` (default=30s) = default=90s.

If we try to access the service while it is scaled to zero the activator will pick up the request(s) and buffer them until the **Autoscaler** is able to quickly create pods for the given revision.

> **Note:** *You might have noticed an initial lag when trying to access your service.  The reason for that delay is highly likely that your request is being held by the activator!*

First login as an administrator for the cluster: `oc login -u admin -p admin`{{execute}}

It is possible to see the default configurations of the autoscaler by executing: `oc -n knative-serving describe cm config-autoscaler`{{execute}}

Here we can see the `stable-window`, `scale-to-zero-grace-period`, a `enable-scale-to-zero`, amongst other settings.

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

In this tutorial leave the configuration as-is, but if there were reasons to change them it is possible to edit this configmap as needed.

> **Tip:** Another, possibly better, way to make those changes would be to add configuration to the `KnativeServing` instance that was applied in the `Prepare for Exercises` section early in this tutorial.
>
> Open and inspect that yaml by executing: `cat 01-prepare/serving.yaml`{{execute}}
>
> There are other settings of Serverless available.  It is possible to describe other configmaps in the `knative-serving` project to find them.
>
> Explore what all is available by running: `oc get cm -n knative-serving`{{execute}}

Now, log back in as the developer as we do not need elevated privileges to continue: `oc login -u developer -p developer`{{execute}}

## Minimum Scale
By default, Serverless Serving allows for 100 concurrent requests into each revision and allows the service to scale down to zero.  This property optimizes the application as it does not use any resources for running idle processes!  This is the out of the box configuration, and it works quite well depending on the needs of the specific application.

Sometimes application traffic is unpredictable, bursting often, and when the app is scaled to zero it takes some time to come back up -- giving a slow start to the first users of the app.

To solve for this, services are able to be configured to allow a few processes to sit idle, waiting for the initial users.  This is configured by specifying a minimum scale for the service via an the annotation `autoscaling.knative.dev/minScale`.

> **Note:** *You can also limit your maximum pods using `autoscaling.knative.dev/maxScale`*

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

In the definition above the minimum scale is configured to 2 and the maximum scale to 5 via two annotations.

Since serverless allows deploying without yaml we will continue to use the `kn` command instead of the above yaml service definition.

Deploy the service by executing:
```bash
kn service create prime-generator \
   --namespace serverless-tutorial \
   --annotation autoscaling.knative.dev/minScale=2 \
   --annotation autoscaling.knative.dev/maxScale=5 \
   --image quay.io/rhdevelopers/prime-generator:v27-quarkus
```{{execute}}

See that the `prime-generator` is deployed and it will never be scaled outside of 2-5 pods available by checking: `oc get pods -n serverless-tutorial`{{execute}}

This now guarantee that there will always be at least two instances available at all times to provide the service with no initial lag at the cost of consuming additional resources.  Next, test the service won't scale past 5.

To load the service we will use [apachebench (ab)][apachebench].  We will configure `ab` to send 2550 total requests `-n 2550`, of which 850 will be performed concurrently each time `-c 850`.  Immediatly after we will show the deployments in the project to be able to see the number of pods running.

`ab -n 2550 -c 850 -t 60 "http://prime-generator-serverless-tutorial.[[HOST_SUBDOMAIN]]-80-[[KATACODA_HOST]].environments.katacoda.com/?sleep=3&upto=10000&memload=100" && oc get deployment -n serverless-tutorial`{{execute}}

> **Note:** *This might take a few moments!*

Notice that `5/5` pods should be marked as `READY`, confirming the max scale.

## AutoScaling
As mentioned before, Serverless by default will scale up when there are 100 concurrent requests coming in at one time.  This scaling factor might work well for some applications, but not all -- fortunately this is a tuneable factor!  In some cases you might notice that a given app is not using its resources too effectively as each request is CPU-bound.

To help with this, it is possible to adjust the service to scale up sooner, say 50 concurrent requests via configuring an annotation of `autoscaling.knative.dev/target`.

Update the prime-generator service by executing:
```bash
kn service update prime-generator \
   --annotation autoscaling.knative.dev/target=50
```{{execute}}

> **Note:** *The equivalent yaml for the service above can be seen by executing: `cat 05-scaling/service-50.yaml`{{execute}}*.

Again test the scaling by loading the service.  This time send 275 concurrent requests totaling 1100.

`ab -n 1100 -c 275 -t 60 "http://prime-generator-serverless-tutorial.[[HOST_SUBDOMAIN]]-80-[[KATACODA_HOST]].environments.katacoda.com/?sleep=3&upto=10000&memload=100" && oc get deployment -n serverless-tutorial`{{execute}}

Notice that at least 6 pods should be up and running.  There might be more than 6 as `ab` could be overloading the amount of concurrent workers at one time.

This will work well, but given that this application is CPU-bound instead of request bound we might want to choose a different autoscaling class that is based on CPU load to be able to manage scaling more effectively.

## HPA AutoScaling
CPU based autoscaling metrics are achieved using something called a Horizontal Pod Autoscaler (HPA).  In this example we want to scale up when the service starts using 70% of the CPU.  Do this by adding three new annotations to the service: `autoscaling.knative.dev/{metric,target,class}`

Update the prime-generator service by executing:
```bash
kn service update prime-generator \
   --annotation autoscaling.knative.dev/minScale- \
   --annotation autoscaling.knative.dev/maxScale- \
   --annotation autoscaling.knative.dev/target=70 \
   --annotation autoscaling.knative.dev/metric=cpu \
   --annotation autoscaling.knative.dev/class=hpa.autoscaling.knative.dev
```{{execute}}

> **Note:** *Notice that the above `kn` command removes, adds, and updates existing annotations to the service.  To delete use `—annotation name-`.*
>
> *Getting the service to scale on the large CPU nodes that this tutorial is running on is relatively hard.  If you have any ideas to see this in action put an issue in at [this tutorial's github][learn-katacoda]*
>
> *The equivalent yaml for the service above can be seen by executing: `cat 05-scaling/service-hpa.yaml`{{execute}}*.


## Delete the Service

Cleanup the project using: `kn service delete prime-generator`{{execute}}

Congrats! You are now a Serverless Scaling Expert!  We can now adjust and tune Serverless scaling using concurrency or CPU based HPAs.
