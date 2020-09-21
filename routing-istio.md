# Définir un routing avec Istio

Exercice original ici : https://www.katacoda.com/courses/openshift/servicemesh/4-simple-routerules 

Cet exercice montre comment Istio peut être utiliser pour contrôler les routes avec des règles simples.

# Modification do code source de recommandation
IMPORTANT: Ne pas essayer de modifier des fichiers ou de lancer des commandes avant que le curseur du terminal ne deviennent disponible..

Nous allons tester avec des règles de routing Istio de faire un changement sur RecommendationsController.java.

Ouvrir /recommendation/java/vertx/src/main/java/com/redhat/developer/demos/recommendation/RecommendationVerticle.java dans l'éditor. Faite la modification suviante : 
```java
    private static final String RESPONSE_STRING_FORMAT = "recommendation v2 from '%s': %d\n";
```
Note: Le fichier est sauvegardé automatiquement.

Allez maintenant dans le dossier recommendations
```shell
cd ~/projects/istio-tutorial/recommendation/java/vertx
```
Assurer vous que le fichier a été modifié :
```
git diff
```
Compiler le projet avec les modifications effectuées :
```
mvn package
```

## Créer l'image docker recommendation:v2.

Nous allons maintenant créer une nouvelle image qui utilise cette v2. Le tag v2 pendant le build de docker est important. 
Executer la commande : 
```
docker build -t example/recommendation:v2 .
```
Vous pouvez vérifier que l'image a bien été créée avec la commande : 
```
docker images | grep recommendation
```

## Créer le second déploiement avec sidecar proxy
Il y a aussin 2nd dfichier deployment.yml dans lequel il faut mettre les bon labels.
Executer :
```
oc apply -f <(istioctl kube-inject -f ../../kubernetes/Deployment-v2.yml) -n tutorial
```
Pour voir la création des pods, executer : 
```
oc get pods -w
```
Une fois que le pod recommendation est prêt (la colonne READY affiche 2/2), vous pouvez appuyer sur  CTRL+C.

Tester le endpoint: 
```
curl http://customer-tutorial.2886795293-80-cykoria05.environments.katacoda.com
```
Vous aimerez voir : "customer => preference => recommendation v2 from '2819441432-5v22s': 1"  puisque par défaut vous avez round-robin load-balancing lorsqu'il y a plus d'un pod derrière un Service.

Vous aimerez voir : "customer => preference => recommendation v1 from '99634814-d2z2t': 3", où '99634814-d2z2t' est le pod qui execute la V1 et le 3 est le nombre de fois où le endpoint a été accédé.

Envoyer plusieurs requêtes sur le Terminal 2 pour voir leurs réponses :
```
while true; do curl http://customer-tutorial.2886795293-80-cykoria05.environments.katacoda.com; sleep .5; done
```
Le comportement par défaut de Kubernetes/Openshift est de load-balancer round-robin sur les différents pods derrière un seul Service. Ajouter un autre replica du déploiement recommendations-v2

```
oc scale --replicas=2 deployment/recommendation-v2
```
Attendre quelques secondes que le pod recommendation:v2 devienne disponible et executer :
```
oc get pods -w
```
Une fois que le pod recommendation est prêt (la colonne READY affiche 2/2), vous pouvez appuyer sur  CTRL+C.

Assurez vous que la commande suivante tourne dans le terminal 2 : 
```
while true; do curl http://customer-tutorial.2886795293-80-cykoria05.environments.katacoda.com; sleep .5; done
```
Vous verrez deux requêtes pour la v2 pour chaque requête de la v1

Revenir à un seul replica du déploiement recommendation-v2 :
```
oc scale --replicas=1 deployment/recommendation-v2
```
Dans le Terminal 2, vous verrez les requêtes être balancé round-robin entre la v1 et la v2

# Tous les utilisateurs sur recommendation:v2

Ouvrir le fichier istiofiles/destination-rule-recommendation-v1-v2.yml.

Ouvrir le fichier istiofiles/virtual-service-recommendation-v2.yml.

Noter que le DestinationRule ajoute un nom à chaque version de notre déploiement recommendation, et que VirtualService spécifique que la destination sera le déploiement recommendation avec le nom version-v2

Appliquons les fichiers
```
istioctl create -f ~/projects/istio-tutorial/istiofiles/destination-rule-recommendation-v1-v2.yml -n tutorial
istioctl create -f ~/projects/istio-tutorial/istiofiles/virtual-service-recommendation-v2.yml -n tutorial
```
S'assurer que la commande suivante tourne dans le Terminal 2
```
while true; do curl http://customer-tutorial.2886795293-80-cykoria05.environments.katacoda.com; sleep .2; done
```
Vous ne devriez voir que la v2 qui est renvoyée.

# Tous les utilisateurs sur recommendation:v1

Ouvrir le fichier /istiofiles/virtual-service-recommendation-v1.yml.

Noter que comme spécifié la destination sera le déploiement recommendation avec le nom version-v1

Remplaçons le VirtualService.
```
istioctl replace -f ~/projects/istio-tutorial/istiofiles/virtual-service-recommendation-v1.yml -n tutorial
```
NB : Nous avons remplacer au lieu de créer puisque nous surchargons le précédent VirtualService

S'assurer que la commande suivante tourne dans le Terminal 2
```
while true; do curl http://customer-tutorial.2886795293-80-cykoria05.environments.katacoda.com; sleep .2; done
```
Vous ne devriez avoir que la V1 qui est renvoyée.

## Explore the VirtualService object
Vous pouvez vérifier les règles existantes sur les routes avec la commande :
```
istioctl get virtualservice
```
Cela montrer seuleemtn un objet VirtualService appelé recommendations. Le nom a été spécifié dans les métadonnées du VirtualService

Vous pouvez voir le contenu du VirtualService en executant : 
```
istioctl get virtualservice recommendation -o yaml -n tutorial
```
# Tous les utilisateurs sur recommendation v1 et v2
Vous pouvez maintenant envoyer les requêtes sur la v1 et la v2 en retirant la règle :
```
istioctl delete virtualservice recommendation -n tutorial
```
S'assurer que la commande suivante tourne dans le Terminal 2
```
while true; do curl http://customer-tutorial.2886795293-80-cykoria05.environments.katacoda.com; sleep .2; done
```
Vous devriez avoir le comportement par défaut avec les requêtes balancé round-robin entre la v1 et la v2

# Déploiement Canary : Partager le trafic entre v1 et v2
Penser au scénario suivant : La V2 est poussé sur le cluster mais le trafic est envoyé lentement pour les utilisateurs finaux, si vous continuer pour voir la réussite, continuer à faire flisser plus de trafic avec le temps

Voyons comment créer un VirtualService qui envoie 90% des requêtes à la v1 et 10% à la v2.

Ouvrir et lire le fichier /istiofiles/virtual-service-recommendation-v1_and_v2.yml

Il spécifie que recommendation avec le nom version-v1 a un poid de 90 et recommendation avec le nom version-v2 a un poid de 10.
Créer le VirtualService :
```
istioctl create -f ~/projects/istio-tutorial/istiofiles/virtual-service-recommendation-v1_and_v2.yml -n tutorial
```
S'assurer que la commande suivante tourne dans le Terminal 2
```
while true; do curl http://customer-tutorial.2886795293-80-cykoria05.environments.katacoda.com; sleep .2; done
```
Vous devriez voir un taux de 90/10 entre v1 et v2.

## Recommendations 75/25
Changeaons le poid du routing pour 75/25 en appliquant le fichier suivant /istiofiles/virtual-service-recommendation-v1_and_v2_75_25.yml
Remplacer le VirtualService créé précedemment avec : 
```
oc replace -f ~/projects/istio-tutorial/istiofiles/virtual-service-recommendation-v1_and_v2_75_25.yml -n tutorial
```
S'assurer que la commande suivante tourne dans le Terminal 2
```
while true; do curl http://customer-tutorial.2886795293-80-cykoria05.environments.katacoda.com; sleep .2; done
```
Vous devriez voir un taux de 75/25 entre v1 et v2.

## Clean up
Vous pouvez supprimer le VirtualService appelé recommendation pour récupérer le comportement standard du loadbalancing:
```
istioctl delete virtualservice recommendation -n tutorial
```
Dans le Terminal 2 vous devriez voir v1 et v2 renvoyé des resultats à 50/50
