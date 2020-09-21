# Transférer des fichiers dans et depuis un container avec OpenShift

Exercice original ici : https://www.katacoda.com/courses/openshift/introduction/transferring-files 

## Objectif
Apprendre à copier des fichiers dans et depuis un conteneur en fonctionnement sans reconstruire l'image du conteneur. Améliorer ça avec une fonction de surveillance qui applique automatiquement les modifications locales à un conteneur en cours de fonctionnement afin de voir immédiatement l'effet des changements sur l'application.


## Concepts
* Boucle rapid de développement pour modifier un conteneur en cours d'execution
* OpenShift Projets et Applications
* OpenShift outils oc et sa sous commande new-app

## Cas d'usage
Vous pouvez modifier une application dans un conteneur pour développer et tester avant de construire une nouvelle version de l'image de conteneur. Syncronisation automatique du conteneur avec les changements locaux rend plus rapide la boucle de développement et de tests, particulièrement dans les langages de programmations interprétés.
