# OpenShift - Travailler avec les pipelines

## Pré-requis

OpenShift Pipelines are an OpenShift add-on that can be installed via an operator that is available in the OpenShift OperatorHub.


You can either install the operator using the OpenShift Pipelines Operator in the web console or by using the CLI tool `oc`. Let's log in to our cluster to make changes and install the operator. You can do so by running:

`oc login -u admin -p admin`{{execute}}

This will log you in using the credentials:

* **Username:** ``admin``
* **Password:** ``admin``

## Installing the OpenShift Pipelines Operator in Web Console

You can install OpenShift Pipelines using the Operator listed in the OpenShift Container Platform OperatorHub. When you install the OpenShift Pipelines Operator, the Custom Resources (CRs) required for the Pipelines configuration are automatically installed along with the Operator.

Firstly, switch to the _Console_ and login to the OpenShift web console using the same credentials you used above.

![Web Console Login](../../assets/middleware/pipelines/web-console-login.png)

In the _Administrator_ perspective of the web console, navigate to Operators → OperatorHub. You can see the list of available operators for OpenShift provided by Red Hat as well as a community of partners and open-source projects.

Use the _Filter by keyword_ box to search for `OpenShift Pipelines Operator` in the catalog. Click the _OpenShift Pipelines Operator_ tile.

![Web Console Hub](../../assets/middleware/pipelines/web-console-hub.png)

Read the brief description of the Operator on the _OpenShift Pipelines Operator_ page. Click _Install_.

Select _All namespaces on the cluster (default)_ for installation mode & _Automatic_ for the approval strategy. Click Subscribe!

![Web Console Login](../../assets/middleware/pipelines/web-console-settings.png)

Be sure to verify that the OpenShift Pipelines Operator has installed through the Operators → Installed Operators page.

## Installing the OpenShift Pipelines Operator using the CLI

You can install OpenShift Pipelines Operator from the OperatorHub using the CLI.

First, you'll want to create a Subscription object YAML file to subscribe a namespace to the OpenShift Pipelines Operator, for example, `subscription.yaml` as shown below:

```
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: openshift-pipelines-operator
  namespace: openshift-operators 
spec:
  channel: stable
  name: openshift-pipelines-operator-rh
  source: redhat-operators
  sourceNamespace: openshift-marketplace
```

This YAML file defines various components, such as the `channel` specifying the channel name where we want to subscribe, `name` being the name of our Operator, and `source` being the CatalogSource that provides the operator. For your convenience, we've placed this exact file in your `/operator` local folder. 

You can now create the Subscription object similar to any OpenShift object.

`oc apply -f operator/subscription.yaml`{{execute}}

## Verify installation

The OpenShift Pipelines Operator provides all its resources under a single API group: tekton.dev. This operation can take a few seconds; you can run the following script to monitor the progress of the installation.

```
until oc api-resources --api-group=tekton.dev | grep tekton.dev &> /dev/null
do 
 echo "Operator installation in progress..."
 sleep 5
done

echo "Operator ready"
```

* Créer un projet


## Créer une tâche

A [`Task`](tasks.md) defines a series of `steps` that run in a desired order and complete a set amount of build work. Every `Task` runs as a Pod on your Kubernetes cluster with each `step` as its own container. For example, the following `Task` outputs "Hello World":

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

Apply this Task to your cluster just like any other Kubernetes object. Then run it using `tkn`, the CLI tool for Tekton.

`oc apply -f tasks/hello.yaml`{{execute}}

`tkn task start --showlog hello`{{execute}}

The output will look similar to the following:

```
TaskRun started: hello-run-9cp8x
Waiting for logs to be available...
[say-hello] Hello World
```

In the next section, you will examine the task definitions that will be needed for our pipeline.

## Donner des paramètres à ses tâches

Tasks can also take parameters. This way, you can pass various flags to be used in this Task. These `params` can be instrumental in making your Tasks more generic and reusable across Pipelines. For example, a `Task` could apply a custom Kubernetes manifest, like the example below. This will be needed for deploying an image on OpenShift in our next section. In addition, we'll cover the `workspaces` during our `Pipeline` step.

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

Create the `apply-manifests` task:

`oc create -f tasks/apply_manifest_task.yaml`{{execute}}

We'll also create a `update-deployment` task, which can be seen with a `cat` command:

`oc create -f tasks/update_deployment_task.yaml`{{execute}}

Finally, we can create a PersistentVolumeClaim to provide the filesystem for our pipeline execution, explained more in the next step:

`oc create -f resources/persistent_volume_claim.yaml`{{execute}}

You can take a look at the tasks you created using the [Tekton CLI](https://github.com/tektoncd/cli/releases):

`tkn task ls`{{execute}}

You should see similar output to this:

```
NAME                DESCRIPTION   AGE
apply-manifests                   4 seconds ago
hello                             1 minute ago
update-deployment                 3 seconds ago
```

In the next section, you will create a pipeline that takes the source code of an application from GitHub and then builds and deploys it on OpenShift.

## Créer un pipeline

A `Pipeline` defines an ordered series of `Tasks` that you want to execute along with the corresponding inputs and outputs for each `Task`. In fact, tasks should do one single thing so you can reuse them across pipelines or even within a single pipeline.

Below is an example definition of a `Pipeline`, created using the following diagram:

![Web Console Developer](../../assets/middleware/pipelines/pipeline-diagram.png)

Below is a YAML file that represents the above pipeline:

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

This pipeline helps you to build and deploy backend/frontend, by configuring the right resources to the pipeline.

Pipeline Steps:

  1. `fetch-repository` clones the source code of the application from a git repository by referring (`git-url` and `git-revision` param)
  2. `build-image` builds the container image of the application using the `buildah` clustertask
  that uses [Buildah](https://buildah.io/) to build the image
  3. The application image is pushed to an image registry by referring (`image` param)
  4. The new application image is deployed on OpenShift using the `apply-manifests` and `update-deployment` tasks

You might have noticed that there are no references to the git repository or the image registry it will be pushed to in the pipeline. That's because pipeline in Tekton is designed to be generic and re-usable across environments and stages through the application's lifecycle. Pipelines abstract away the specifics of the git
source repository and image to be produced as [`PipelineResources`](https://tekton.dev/docs/pipelines/resources) or `Params`. When triggering a pipeline, you can provide different git repositories and image registries to be used during pipeline execution.

The execution order of task is determined by dependencies that are defined between the tasks via inputs and outputs as well as explicit orders that are defined via `runAfter`.

`workspaces` field allows you to specify one or more volumes that each Task in the Pipeline requires during execution. You specify one or more Workspaces in the `workspaces` field.

Create the pipeline by running the following:

`oc create -f pipeline/pipeline.yaml`{{execute}}

In the next section, you will focus on creating a trigger to execute the tasks specified in the pipeline.

## Déclencher un pipeline

Now that the pipeline is created, you can trigger it to execute the tasks specified in the pipeline. This is done by creating a `PipelineRun` via `tkn`.

# Trigger a Pipeline via CLI

Let's start a pipeline to build and deploy our backend application using `tkn`. By creating a `PipelineRun` with the name of our applied `Pipeline`, we can define various arguments to our command like `params` that will be used in the `Pipeline`.  For example, we can apply a request for storage with a `persistentVolumeClaim`, as well as define a name for our `deployment`, `git-url` repository to be cloned, and `IMAGE` to be created.

We'll first build and deploy our backend application using the following command, with the params already included for our specific demo:

`tkn pipeline start build-and-deploy -w name=shared-workspace,claimName=source-pvc -p deployment-name=pipelines-vote-api -p git-url=https://github.com/openshift/pipelines-vote-api.git -p IMAGE=image-registry.openshift-image-registry.svc:5000/pipelines-tutorial/vote-api --showlog`{{execute}}

Similarly, start a pipeline to build and deploy the frontend application:

`tkn pipeline start build-and-deploy -w name=shared-workspace,claimName=source-pvc -p deployment-name=pipelines-vote-ui -p git-url=https://github.com/openshift/pipelines-vote-ui.git -p IMAGE=image-registry.openshift-image-registry.svc:5000/pipelines-tutorial/vote-ui --showlog`{{execute}}

As soon as you start the `build-and-deploy` pipeline, a `PipelineRun` will be instantiated and pods will be created to execute the tasks that are defined in the pipeline. To display a list of Pipelines, use the following command:

`tkn pipeline ls`{{execute}}

Again, notice the reusability of pipelines, and how one generic `Pipeline` can be triggered with various `params`. We've started the `build-and-deploy` pipeline, with relevant pipeline resources to deploy backend/frontend application using a single pipeline. Let's list our PipelineRuns:

`tkn pipelinerun ls`{{execute}}

After a few minutes, the pipeline should finish successfully!

`tkn pipelinerun ls`{{execute}}

## Access Pipeline via Web Console

To view the `PipelineRun` visually, visit the Pipelines section of the developer perspective. From here, you can see the details of our `Pipeline`, including the YAML file we've applied, the `PipelineRun`, input custom `params`, and more:

![Web Console Pipelines](../../assets/middleware/pipelines/web-console-developer.png)

Congrats! Your `Pipeline` has successfully ran, and the final step will provide instructions on how to access the deployed image.

## Vérifier le déploiement

To verify a successful deployment for our application, head back out to the web console by clicking on the Console at the center top of the workshop in your browser.

Click on the Topology tab on the left side of the web console. You should see something similar to what is shown in the screenshot below:

![Web Console Deployed](../../assets/middleware/pipelines/application-deployed.png)

The Topology view of the OpenShift web console helps to show what is deployed out to your OpenShift project visually. As mentioned earlier, the dark blue lining around the _ui_ circle means that a container has started up and running the _api_ application. By clicking on the arrow icon as shown below, you can open the URL for _ui_ in a new tab and see the application running.

![Web Console URL Icon](../../assets/middleware/pipelines/url-icon.png)

After clicking on the icon, you should see the application running in a new tab.

## Accessing application via CLI

In addition, you can get the route of the application by executing the following command to access the application.

`oc get route pipelines-vote-ui --template='http://{{.spec.host}}'`{{execute}}

Congratulations! You have successfully deployed your first application using OpenShift Pipelines.
