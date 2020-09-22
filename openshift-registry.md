# Utiliser le registre de conteneurs OpenShift

exercice original : https://www.katacoda.com/courses/openshift/subsystems/container-internals-lab-2-0-part-3

Cette exercice est axé sur la compréhension de à quoi sert un registre de conteneurs et comment il fonctionne .

A la fin de cet exercice vous serez capable de :

* Evaluer la qualité d'un registre de conteneurs
* Evaler la qualité d'un dépôt de conteneurs
* Partager vos images en utilisant des registres publics et privés


# Comprendre les base de la confiance - la qualité et la provenance

L'objectif de cet exercice est de comprendre les bases de la confiance lorsqu'il s'agit de serveur de registres et de depôts.
Cela nécessite de la qualité et de contrôler la provenance - ce qui est juste une manière élégante de dire :

1. Vous devez télécharger un élément de confiance
2. Vous devez télécharger depuis une source sûre

Chacun de ces éléments est nécessaire, mais aucun ne suffit seul. Cela est vrai depuis que l'on télécharge des images ISO pour les distributions Linux.
Afin d'évaluer les bibliothèques ou le code open source, les paquets pré-construits (RPMs ou Debs), les images de conteneurs, nous devons :

1. determiner si nous voulons faire confiance à l'image en évaluant la qualité du code, les personnes, et les organisations impliquées dans le projet. Si le projet a assez d'historique, d'investissement et qu'il fonctionne pour nous, nous commençons à lui faire confiance.

2. determiner si nous voulons faire confiance au registre, en comprenant les qualité de ses relations avec les projets de confiance - si nous téléchargeons quelque chose depuis le dépôt Github officiel, nous lui faisons plus confiance que depuis un fork d'un utilisateur Haxor5579. Cela est vrai pour les sites miroirs des ISOS et pour les dépôts d'images construites par les personne qui ne sont pas affiliées avec le code sous-jacent ou les paquets.

Il y a de nombreux exemples ou les gens ignore d'un de ces deux principes et sont hackés. 

## Objet de confiance
Du point de vue de la sécurité, il est mieux de vérifier à distance et de déterminer si nous pouvons faire confiance à une image avant de la télécharger, de l'ouvrir et de la mettre en cache dans le stockage local de notre moteur de conteneur. Chaque fois que vous téléchargez une image, et l'exposer au gestionnaire de l'engin de contôle, vous vous exposez à des attaques potentielles. Commençons par faire une inspection à distance avec Skopeo (on ne peut pas le faire avec Docker à cause de la nature du client/serveur): 
```
skopeo inspect docker://registry.fedoraproject.org/fedora
```
Etudions le JSON. Il n'y a rien à l'intérieur qui nous aide à déterminer si nous faisons confiance au dépôt. Il "dit" qu'il a été créé par le projet Fedora ("vendor": "Fedora Project") mais nous n'avons aucune idée de si cela est vrai. Nous devons avancer pour vérifier si nous faisons confiance à la source, puis déterminer si nous pouvons faire confiance à l'objet.

## Source sûre 

IL y a de nombreuses discussions autour de la signature d'image, mais en réalité, la plupart des gens ne vérifie pas les images de conteneurs avec leurs signatures. Ce qu'ils font est lié au SSL pour déterminé s'ils font confiance à la source, puis décider s'il font confiance à l'image du conteneur.
Utilisons cette connaissance pour faire une évaluation rapide du registre officielle de Fedora :
```
curl -I https://registry.fedoraproject.org
```
Noter que le certificat SSL echoue à passer le modèle. Cela vient du fait que le certificat racine Digicert root CA n'est pas dans /etc/pki dans cette machine d'exercice. Sur RHEL et Fedora, ce certificat est distribué par défaut et le certificat SSL du registre pour registry.fedoraproject.org passe le modèle. Donc pour cet exercice, vous devez me faire confiance, je l'ai testé :) Si vous êtes sur un machine avec Fedora ou Red Hat Enterprise Linux avec les bonnes clés, la sortie ressemble à cela :
```
HTTP/2 200 
date: Thu, 25 Apr 2019 17:50:25 GMT
server: Apache/2.4.39 (Fedora)
strict-transport-security: max-age=31536000; includeSubDomains; preload
x-frame-options: SAMEORIGIN
x-xss-protection: 1; mode=block
x-content-type-options: nosniff
referrer-policy: same-origin
last-modified: Thu, 25 Apr 2019 17:25:08 GMT
etag: "1d6ab-5875e1988dd3e"
accept-ranges: bytes
content-length: 120491
apptime: D=280
x-fedora-proxyserver: proxy10.phx2.fedoraproject.org
x-fedora-requestid: XMHzYeZ1J0RNEOvnRANX3QAAAAE
content-type: text/html
```
Même sans le certificat racine CA installé, on peut distinguer que le certificat est validé et géré par Red, ce qui aide un peu : 
```
curl 2>&1 -kvv https://registry.fedoraproject.org | grep subject
```
Réflechissez à ce que nous venons de faire. Meme une validation visuelle du certificat nous donne un niveau minimum de confiance dans le serveur de registre. Dans les scénario réél, rappelez-vous que c'est le boulot du moteur de conteneur de vérifier ces certificats. Cela signifie que l'administrateur système doit distribuer les bons certificats CA en production. Maintenant que nous avons inspecté le certificat, nous pouvons récupérer de manière sécurisé le dépôt de confiance (parce que nous faisons confiance au projet Fedora qui l'a construit) depuis le serveur de registre de confiance (parce que nous savons qu'il est géré par Fedora/Red Hatà :
```
podman pull registry.fedoraproject.org/fedora
```
Continuons avec l'évaluation de dépôt et de serveurs de registres plus délicat.

# Evaluer la confiance - Images et  serveur de Registre
L'objectif de cet exercice est d'apprendre à évaluer les images de conteurs et les serveurs de registre.

## Evaluer les Images

Démarrons avec ce que nous savoans déjà, il y a souvent une distribution Linux pleinement fonctionnelle dans une image de conteneur. C'est parce qu'il est utile d'utiliser des paquets existants et des arbres de dépendances déjà créé pour cela. Cela est vrai que la distribution tourne sur un bare metal, une machine virtuelle ou une image de conteneur. Il est également important de considérer la qualité, la fréquence et la facilité de mise à jours dans les images de conteneurs.

Pour analiser la qualité, nous utilisons des outils existants - ce qui est un autre avantage à utilsier des images de conteneurs basées sur des distributions Linux. Pour démonter cela, examinons des images de quatre distribution Linux différente - CentOS, Fedora, Ubuntu, et Red Hat Enterprise Linux. Chacune fournit différent niveau d'informations :

## CentOS
```
podman run -it docker.io/centos:7.0.1406 yum updateinfo
```
CentOs ne fournit pas d'Errata pour la mise à jour des paquets, donc cette commande ne renvoit aucune information. Cela rend difficile de faire correspondre les CVEs au paquets RPM. Ce qui, à son tour, rend difficile de mettre à jour le paquet qui est affecté par un CVE. Finalement, ce manque d'information rend difficile de noter l'image de conteneu pour la qualité. Une solution de contournement basique est de tout mettre à jour, mais même en le faisant, vous n'êtes pas sûr à 100% que les CVEs sont patchés.

## Fedora
```
podman run -it registry.fedoraproject.org/fedora dnf updateinfo
```
Fedora fournit des informations décentes pour les mises à jour de paquets, mais ne les lies pas au CVEs non plus. Les résultats varient en fonction du jour, mais la sortie ressemble à celle-ci :
```
Last metadata expiration check: 0:00:07 ago on Mon Oct  8 16:22:46 2018.
Updates Information Summary: available
    5 Security notice(s)
        1 Moderate Security notice(s)
        2 Low Security notice(s)
    5 Bugfix notice(s)
    2 Enhancement notice(s)
```
## Ubuntu
```
podman run -it docker.io/ubuntu:trusty-20170330 /bin/bash -c "apt-get update && apt list --upgradable"
```
Ubuntu fournit des informations d'un même niveau de qualité que Fedora, mais là aussi on ne fais pas facilement la correspondance avec les CVEs. Le resultat de cette images spécifique devrait toujours être le même car nous avons récupérer une vielle image à dessein pour la démonstration..

## Red Hat Enterprise Linux
```
podman run -it registry.access.redhat.com/ubi7/ubi:7.6-73 yum updateinfo security
```
Malheureusement, nous n'avons pas la licence Red Hat nécessaire pour analyser l'Image de Base Universel de Red Hat en ligne de commande, mais la sortie devrait ressembler à ça dans RHEL ou dans OpenShift :
```
RHSA-2019:0679 Important/Sec. libssh2-1.4.3-12.el7_6.2.x86_64
RHSA-2019:0710 Important/Sec. python-2.7.5-77.el7_6.x86_64
RHSA-2019:0710 Important/Sec. python-libs-2.7.5-77.el7_6.x86_64
```
Noter que la colonne RHSA indique l'Errata et son niveau d'importance. Cette errata peut être utilisé pour faire la correspondace à un CVE particulier donnant à vous et à vos équipe de sécurité confiance dans l'image de conteneur qui est patche pour chaque CVE particulier. Même sans licence Red Hat, nous pouvons analyser la qualité des images Red Hat en regardant le Catalog de COntenuers Red Hat et en utilisant l'index de santé des conteneurs :

Cliquer: [Red Hat Enterprise Universal Base Image 7](https://catalog.redhat.com/software/containers/registry/registry.access.redhat.com/repository/ubi7/ubi?tag=7.6-73)


## Evaluer registres

Maintenant que nous avons jeter un oeil sur plusieurs images de conteneurs, nous pouvons commencer à jeter un oeil sur leur provenance et comment
elles sont construites - nous allons évaluer quatre serveurs de registre - Fedora, podmanHub, Bitnami et le Red Hat Container Catalog:

## Fedora Registry
Cliquer: [registry.fedoraproject.org](https://registry.fedoraproject.org/)
The Fedora registry provides a very basic experience. You know that it is operated by the Fedora project, so the security should be pretty 
similar to the ISOs you download. That said, there are no older versions of images, and there is really no stated policy about how often the 
images are patched, updated, or released.

## podmanHub
Cliquer: https://hub.podman.com/_/centos/
podmanHub fournit des images "officielles" pour de nombreux composants logiciels incluant des choses comme CentOS, Ubuntu, Wordpress, et PHP. Disons le, il n'y pas de définition standard du sens de "oficielle". Chaque dépôt semble avoir ses propres process, règles, planning, cycles de vie et tests. Il n'y a pas de compréhension partagé de ce qu'est une image officielle fournit à un utilisateur. Les utilisateurs doivent évaluer chaque dépôt par eux-mêmes et déterminer s'ils croient qu'il est connecté au projet principal.

## Bitnami
Cliquer: https://bitnami.com/containers
Similaire à podmanHub, il n'y a pas beaucoup d'information liants ces depôts aux projets principaux. Il n'y a même pas de compréhension clair sur les tags disponible, ou qui doivent tre utilisé. Encore une fois, pas de police d'information et les utilisateurs doivent se débrouiller au milieu des depôt Github avec leur propre comprehension de comment il sont construit et s'il y a des cycles de vies avec une garanties sur les versions. Vous devez faire confiance à Bitami pour construire des conteneurs de la manière dont vous les voulez ...

## Red Hat Container Catalog
Cliquer: https://access.redhat.com/containers
Le Red Hat Container catalog est paramètré d'une manière totalement différence des autres serveurs de registres. Il y a de très nombreuses informations pour chaque dépôt. Fouillez et remarquer comme cette image particulière a un warning associé. Pour cet exercice, nous allons volontairement chercher une vieille image avec des failles connus. C'est parce que les images de conteneurs vieillissent comme le fromage, pas le vin. La confiannce est lié au temps, et l'age des images de conteneur comme des serveurs indiquent qu'ils sont rarement ou jamais patchés. 

Regardon maintenant le score de chaque tag dans le Container Health Index qui est disponile. Remarquez que plus le tag est récent, meilleur est la lettre de grade. Le Red Hat Container Catalog et le Container Health Index montre clairement que les images les plus récentes ont moins de failles et leur attribue une meilleur lettre de grade. Pour comprendre complètement les critères de score, lire l'article [Knowkledge Base Article](https://access.redhat.com/articles/2803031). C'est une capacité complète unique qui est fournit par le Red Hat Container Catalogue puisque les erratas d'image de conteneur sont produit de manière subordonnée au CVEs.


# Analyzing Storage and Graph Drivers
Dans cet exercie, nous allons nous concentrer sur comment les moteurs de conteneurs mettent en cache les dépôts sur l'hôt de conteneur. Il y a un minimum de connaissances requises - lorsque l'on "pull" une image de conteneur, chaque couche est mise en cache localement, et mappé dans un système de fichier partagé- par exemple overlay2 ou devicemapper. Cela implique que la mise en cache de l'image de conteneur en loca a été faite en tant qu'opération root. Cela implique aussi, que si l'on pull ou commit une nouvelle couche avec un mot de passe à l'intérieur, tout le monde sur le système peut le voir, même s'il n'est jamais pousser sur un serveur de registre.

Commençons avec un regard rapide sur Docker et Podman, pour voir la différence de stockage :
```
docker info 2>&1 | grep -E 'Storage | Root'
```
Noter le driver utilisé et étudions les images stockées dans  /var/lib/docker:
```
tree /var/lib/docker/
```
Regardons maintenant un moteur de conteneur différent appelé podman. Il récupère les mêmes, OCI compliant, images compatibles docker, mais il ytilise un 
driver et un stockage différent sur le système.
```
podman info | grep -A3 Graph
```
Vous devez vous demandez ce qu'est le d_type ? Pour faire simple, c'est une option du système de fichier qui peut être supporté pour que l'overlay2 fonctionne correctement en tant que stockage pour les images de conteneurs et les conteneurs en cours d'execution. Regardons maintenant le stockage actuel utilisé par podman :
```
tree /var/lib/containers/storage
```
Maintenant récupérons une image et vérifions que les fichiers sont au bon endroit dans le système de fichier
```
podman pull registry.access.redhat.com/ubi7/ubi
cat $(find /var/lib/containers/storage | grep redhat-release | tail -n 1)
```
Avec Docker et Podman, ainsi que la plupart de moteurs de conteneurs de la planet, les couches d'image sont mappé une par une dans des sortes de stockage, avec des snapshots par devicemapper, ou des dossier dans overlay2.

Cela a des implications sur la manières dont on déplace des images de conteneurs d'un registre à l'autre. Vous devez d'abord la récupérer en local et la mettre en cache. Puis vous devez lui donner un tag avec une URL, un Namespace, un Repository et un Tag que vous voulez dans le nouveau registre. Puis vous devez la pousser. 
This has implications on how you move container images from one registry to another. First, you have to pull it and cache it locally. 
Then you have to tag it with the URL, Namespace, Repository and Tag that you want in the new regsitry. Finally, you have to push it. 


