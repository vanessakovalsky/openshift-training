# Ajouter un stockage persistant pour Elastic

## Qu'est ce qu'OpenShift COntainer Storage (OCS) ?
ed Hat® OpenShift® Container Storage is software-defined storage for containers. Engineered as the data and storage services platform for Red Hat OpenShift, Red Hat OpenShift Container Storage helps teams develop and deploy applications quickly and efficiently across clouds.

## Ce que vous allez apprendre
In this tutorial you will learn how to create Persistent Volumes and use that for deploying Elasticsearch. You will then deploy a demo app which is a e-library search engin for 100 classic novels. Once the app is successfully deployed, you could search any word from 100 classic novels, the search is powered by Elasticsearch which is using persistent storage from OCS. The logical architecture of the app that you will deploy looks like this
https://github.com/mulbc/learn-katacoda/raw/master/persistence/persistent-elasticsearch/architecture.png

# Create Project and PVC
You have been auto logged in as admin user, verify by running oc whoami on the command line.
You can click on the above command (and all others in this scenario) to automatically copy it into the terminal and execute it.

Create a new project, that we will use throughout this scenario and create a PersistentVolumeClaim on OCS storage class which will be used by Elasticsearch pod to persist data
```
oc create -f 1_create_ns_ocs_pvc.yaml

oc project e-library
```
To verify get the Storage Class (SC) and PersistentVolumeClaim (PVC)
```
oc get pvc

oc get sc
```
With just a few lines of YAML, you have created a PVC named ocs-pv-claim on storage class ocs-storagecluster-ceph-rbd which is provisioned from OpenShift Container Storage. Elasticsearch needs persistence for its data and OpenShift Container Storage is one of the simplest and reliable option that you can choose to persist data for you apps running on OpenShift Container Platform.
Let's continue to the next section to deploy the Elasticsearch cluster.

# Deploy Elasticsearch on OCS
Apply the YAML file to deploy Elasticsearch
oc create -f 2_deploy_elasticsearch.yaml

To make Elasticsearch persistent we have defined OCS PVC under volumes section, mounted it under volumeMounts inside the deployment manifest file, as shown below. Doing this, Elasticsearch will then store all of its data on the the PersistentVolumeClaim which resides on OpenShift Container Storage.
...
    spec:
      volumes:
        - name: ocs-pv-storage
          persistentVolumeClaim:
            claimName: ocs-pv-claim
...
...
...
        volumeMounts:
          - mountPath: "/usr/share/elasticsearch/data"
            name: ocs-pv-storage
As a developer, this should be the most important stage to enable data persistence for your application. When you request PVC that are provisioned via OCS storage class, the OpenShift Container Storage subsystem make sure your application's data is persistent and reliably stored.

# Deploy app backend & frontend
Apply the YAML file to deploy application's backend API
oc create -f 3_deploy_backend_api.yaml

In order for the frontend app to reach the backend API, set BACKEND_URL environment variable as a config map, by executing the following commands
echo "env = {BACKEND_URL: 'http://$(oc get route -n e-library -o=jsonpath="{.items[0]['spec.host']}")'}" > env.js

oc create configmap -n e-library env.js --from-file=env.js

Finally deploy the frontend application
oc create -f 4_deploy_frontend_app.yaml

At this point our frontend and backend applications are deployed and are configured to use Elasticsearch

To verify execute the following commands.
oc get po,svc,route

Before you move to next step, please make sure all the pods are in Running state. If they are not, then please allow a few minutes.
oc get po,svc,route

# Ingest dataset to Elasticsearch
Let's load the text formatted dataset of 100 classic novels from the Gutenberg's collection into our Elasticsearch service.
Note : Hang Tight ! The data ingestion could take a few minutes.

oc exec -it e-library-backend-api  -n e-library -- curl -X POST http://localhost:3000/load_data

Here the ingested data is getting stored on Elasticsearch shards which are in-turn using OCS PVC for persistence.

As soon as the data is ingested, Elasticsearch will index that and make it search-able.

Grab the frontend URL and open that in your web-browser to search for any random words.

URL http://frontend-e-library.2886795278-80-simba07.environments.katacoda.com
oc get route frontend -n e-library

Elasticsearch real-time search capabilities, instantly searches a large dataset. 
Thus making it a popular choice for logging,metrics,full-text search, etc. use cases.

## Final Thoughts

Elasticsearch offers replication at per index level to provide some data resilience. 
Additional data resilience can be provided by deploying Elasticsearch on top of a reliable storage service layer such as OpenShift Container Storage 
which offers further resilience capabilities. This additional data resilience can enhance Elasticsearch service availability during broader 
infrastructure failure scenarios. Because of limited system resources available in this lab environment, we could not demonstrate the enhanced 
resiliency capabilities of Elasticsearch when deployed on OpenShift Container Storage, but you have got the idea :)

Happy Persistency \o
