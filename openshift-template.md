# OpenShift - Template


## Objectifs 

* Utiliser des templates OpenShift
* Créer des templates


## Pré-requis

* Se connecter avec oc login a un cluster
* Créer ou se positionner dans un projet avec `oc project`

## Présentation des Templates

Au lieu de créer les ressources une-par-une - par exemple, un pod, un service et une route - les templates permettent de créer plusieurs objet avec une seule ligne de commande. Plus que ça - ils peuvent inclure des paramètres, qui peut être optionnel, ou avoir des valeurs par défauts, ou des valeurs générés selon des règles spécifiques.

D'une certaine façon ils sont comparable à Docker compose ou  OpenStack Heat—all dans le sens ou ils fournissent des facilités pourc créers des piles d'application complète depuis zéro. Avec les tempaltes, l'administrateur de cluster peut fournir au développeur la possibilité de déplooyer des applications multi-tiers avec tous les services nécessaires.

## Visualiser les templates

Par défaut, OpenShift fournit quelques templates par défaut, appelé des Instant App et des templates de démarrage rapide (Quick Start). Ils peuvent être utiliser pour déployer des environnement d'éxecutions basées sur de nombreux langages et frameworks, comme Ruby on Rails (Ruby), Django (Python), et CakePHP (PHP). Il inclut également des template pour des moteurs de base de données SQL et NoSQL avec du stockage persistent, ce qui inclut les PersistentVolumeClaims comme l'un des objet pour fournir la persistence des données.

Les templates par défaut sont crée dans le projet `openshift` pendant l'installation. Vous pouvez les voir avec la commande suivante :

`oc get template -n openshift | cut -d' ' -f1`

```
NAME
3scale-gateway
amp-apicast-wildcard-router
amp-pvc
cakephp-mysql-example
cakephp-mysql-persistent
dancer-mysql-example
dancer-mysql-persistent
django-psql-example
django-psql-persistent
dotnet-example
dotnet-pgsql-persistent
dotnet-runtime-example
httpd-example
```

Nous avons utiliser la commande cut poru exclure les descriptions et les autres information pour la brieveté, mais vous pouvez utiliser cette commande sans cut pour voir la sortie complète.

Pour obtenir la liste des paramètres qui sont supportés par un template spécifique utiliser la commande process : 

`oc process --parameters mariadb-persistent -n openshift`

````
NAME                   DESCRIPTION       GENERATOR       VALUE
MEMORY_LIMIT           ...                               512Mi
NAMESPACE              ...                               openshift
DATABASE_SERVICE_NAME  ...                               mariadb
MYSQL_USER             ...               expression      user[A-Z0-9]{3}
MYSQL_PASSWORD         ...               expression      [a-zA-Z0-9]{16}
MYSQL_ROOT_PASSWORD    ...               expression      [a-zA-Z0-9]{16}
MYSQL_DATABASE         ...                               sampledb
MARIADB_VERSION        ...                               10.2
VOLUME_CAPACITY        ...                               1Gi

````

**Note:** Nous laissons le descriptions de paramèrest pour rendre la sortie plus lisible.

Comme vous avez remarquer, certains paramètres ont des valeurs dynamique par défaut, générées par des expresseion basé sur  Perl Compatible Regular Expressions (PCREs).

## La commande process

La commande process génère des valeurs par défaut de toutes les expresssions dynamique, rendant la définition du template prête à être utilisée pour la création des ressources, qui sera faite soit en combinant la sortie à la ocommande create ou en utilisant la commande new-app - nous verrons cela par la suite. Pour l'instant utilions la commande pour voir la liste des objets à créér :

`oc process openshift//mariadb-persistent`

```
{
    "kind": "List",
    "apiVersion": "v1",
    "metadata": {},
    "items": [
        {
            "apiVersion": "v1",
            "kind": "Secret",
            ...
            <output omitted>
            ...
            "stringData": {
                "database-name": "sampledb",
                "database-password": "tYuwInpmocV1Q1uy",
                "database-root-password": "icq5jd8bfFPWXbaK",
                "database-user": "userC7A"
            }
        },
        ...
        <output omitted>
        ...
    ]
}
```

**Note:** La commande process autorise une syntaxe alternative `<NAMESPACE>//<TEMPLATE>`. Nous l'utilisons ici dans un but de démonstration, mais vous êtes libre d'utiliser la notation plus familière -n <NAMESPACE> .

La liste est plutôt longue, nous ne montrons qu'un extait contenant la ressource Secret qui contient l'ensemble des valeurs générées sensibles qui seont utilisés par les template d'initialisation.

Pour rendre les choses plus claires, voyons les expressions qui ont générés ces valeurs dans la définition brute du template : 

`oc export template mariadb-persistent -n openshift`

Vous avez remarqué, par exemple, que MYSQL_DATABASE is sampledb, alors que MYSQL_USER commence la chaine utilisateur par trois caractères alphanumériques, comme nous l'avons vu dans la liste précédente.

## Créer un premier template

Nous allons maintenant créer notre propre template. Créer une nouvelle définition de template dans un fichier example-template.yml (à créé) avec le contenu suivant : 

<pre class="file" data-filename="example-template.yml" data-target="replace">
kind: Template
apiVersion: v1
metadata:
  name: example-template
labels:
  role: web
message: You chose to deploy ${WEB_SERVER}
objects:
  - kind: Pod
    apiVersion: v1
    metadata:
      name: example-pod
    spec:
      containers:
        - name: ${WEB_SERVER}
          image: ${WEB_SERVER}
  - kind: Service
    apiVersion: v1
    metadata:
      name: example-svc
    spec:
      ports:
        - port: 80
      selector:
        role: web
  - kind: Route
    apiVersion: v1
    metadata:
      name: example-route
    spec:
      to:
        kind: Service
        name: example-svc
parameters:
  - name: WEB_SERVER
    displayName: Web Server
    description: Web server image to use
    value: nginx
</pre>


**Note**
Bien que dans notre cas le paramètre message est utilisé de façon rudimentaire, dans des templates plus complexes, son but est de dure à l'utilisateur comment utiliser le usernames, password, URL du template qui seront générés. 

Ce template peut être utilisé pour crée trois ressources :

- Un pod executant un serveur web, que vous pouvez choisir en surchargeant le paramètre WEB_SERVER. Par defaut, cela sera nginx.
- Un service qui redirige le traffic entrant vers le pod.
- Une route pour les accès externes.

Nous pouvons processer la définition et passer le la liste de ressources  du résultat à la commande create, mais une stratégie standard est de créer d'abord un template depuis sa définition : 
`oc create -f example-template.yml`

## Utiliser son propre template

Essayons de processer notre template : 
`oc process --parameters example-template`

```
NAME       DESCRIPTION             GENERATOR         VALUE
WEB_SERVER Web server image to use                   nginx
```

Vous voyez le seul paramètre avec sa valeur par défaut et la description que vous avez renseigner plus tôt.

Il est temps de créer une pile de ressources depuis notre template. Cela peut être fait soit en chainant la sortie de la commande process, ce que nous avons mentionné plus tôt, ou en utilisant la commande new-app. Commençons avec l'approche traditionnelle :
`oc process example-template | oc create -f -`

Comme vosu pouvez le voir, la commande `create` prend seulement la liste des ressources et envoit la requête de crétion une-par-une à l'API, donc la sortie est similaire à celle que vous auriez eu en créant les trois ressources séparément manuellement. 

Une autre façon d'initialiser un template vous donne plus d'informations sur ce qu'il se passe. Commençons par suppriemr les premières ressources :
`oc delete all --all`

Nous n'avons pas besoin de supprimer le template, car il ne va pas changé. Nous pouvons maintenant utiliser la commande `new-app` : 

`oc new-app --template=example-template`

```
--> Deploying template "myproject/example-template" to project myproject

     example-template
     ---------
You chose to deploy nginx

     * With parameters:
        * Web Server=nginx

--> Creating resources ...
    pod "example-pod" created
    service "example-svc" created
    route "example-route" created
--> Success
    Access your application via route 'example-route-advanced.openshift.example.com' 
    Run 'oc status' to view your app.

`oc status
In project advanced on server https://172.24.0.11:8443

http://example-route-advanced.openshift.example.com (svc/example-svc)
  pod/example-pod runs nginx
```

As you can see, we created the pod, fronted it with the service, and exposed it through the route in just a single command. Notice that you don't need to run the oc get route  command to find out what URL your application is accessible through—it all shows in the output.

Let's see if our web server is reachable through curl:
`curl -I example-route-default.[[HOST_SUBDOMAIN]]-80-[[KATACODA_HOST]].environments.katacoda.com`{{execute}}

```
HTTP/1.1 200 OK
Server: nginx/1.15.1
```

Note
We used the -I parameter of the curl command to see only response headers, which is enough to check the responsiveness of the server and ensure that it doesn't dump raw HTML into the console. Also, just as before, we used -H option to request a specific application from OpenShift's router.

You can easily delete all of the resources and instantiate the template again, but this time with another web server image, such as Apache:
`oc delete all --all`{{execute}}


## Déployer son template


`oc new-app --template=example-template -p WEB_SERVER=httpd`{{execute}}

```
--> Deploying template "myproject/example-template" to project myproject

     example-template
     ---------
You chose to deploy httpd
...
<output omitted>
...
    Access your application via route 'example-route-advanced.openshift.example.com' 
    Run 'oc status' to view your app.
```

`curl -I example-route-advanced.[[HOST_SUBDOMAIN]]-80-[[KATACODA_HOST]].environments.katacoda.com`{{execute}}

## Rollback 

You can also perform a reverse operation—creating a template from existing resources. To do that, use the export command:
`oc export all --as-template=exported-template > exported-template.yml`{{execute}}

Let's delete our resources to prevent any conflicts:
`oc delete all --all`{{execute}}


And recreate them from the exported template:
`oc new-app -f exported-template.yml`{{execute}}

```
--> Deploying template "advanced/exported-template" for "exported-template.yml" to project advanced

--> Creating resources ...
    route "example-route" created
    pod "example-pod" created
    service "example-svc" created
--> Success
    Access your application via route 'example-route-advanced.openshift.example.com' 
    Run 'oc status' to view your app.
```

**Note:** You might have noticed that the web server was exposed through the same URL as before. This is because the exported template was created from already instantiated resources with all parameters resolved to values, so OpenShift has no way of knowing which fields were parameterized. You can also infer this from the output of the process command, which will show you that all the fields are already initialized. So, strictly speaking, this isn't a fully reverse operation, but it can be used for backups.

Now that we are finished, let's do a clean-up:
`oc delete all --all`{{execute}}

`oc delete template/example-template`{{execute}}