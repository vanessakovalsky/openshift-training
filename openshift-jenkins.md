# OpenShift - Pipeline avec Jenkins

## Objectifs 

* Créer un pipeline avec Jenkins pour l'intégration continue
* Déployer en continue avec le pipeline Kenkins sur OpenShhift

## Pré-requis

* Cloner le dépôt : https://github.com/siamaksade/openshift-jenkins-demo.git 
* Se connecter au cluster OpenShift
* Executer les commande suivante en remplacant USER par votre nom : 
```
./scripts/provision.sh --projet-suffix USER deploy
```

* A l'aide de la console web, aller voir l'ensemble des ressources créés dans le projet cicd-USER
**Note** Le pod pour Sonarqube n'a pas démarré en raison d'un problème d'image. Ce n'est pas gênant, et nous permet de manipuler le Jenkinsfile.

* Les informations de connexions des différents outils :
    Gogs: gogs/gogs
    Nexus: admin/admin123
    SonarQube: admin/admin




## Créer votre premier Pipeline CI/CD

Aller maintenant voir dans le Jenkins (en obtenant la route via la console ou via les commandes vues auparavant).

* Connecter vous à l'aide de votre compte Openshift
* Aller dans votre projet 
* Aller ans la configuration du projet et étudier le contenu du Jenkinsfile : 
```groovy
def mvnCmd = "mvn -s configuration/cicd-settings-nexus3.xml"

pipeline {
  agent {
    label 'maven'
  }
  stages {
    stage('Build App') {
      steps {
        git branch: 'eap-7', url: 'http://gogs:3000/gogs/openshift-tasks.git'
        sh "${mvnCmd} install -DskipTests=true"
      }
    }
    stage('Test') {
      steps {
        sh "${mvnCmd} test"
        step([$class: 'JUnitResultArchiver', testResults: '**/target/surefire-reports/TEST-*.xml'])
      }
    }
    stage('Code Analysis') {
      steps {
        script {
          sh "${mvnCmd} install sonar:sonar -Dsonar.host.url=http://sonarqube:9000 -DskipTests=true"
        }
      }
    }
    stage('Archive App') {
      steps {
        sh "${mvnCmd} deploy -DskipTests=true -P nexus3"
      }
    }
    stage('Build Image') {
      steps {
        sh "cp target/openshift-tasks.war target/ROOT.war"
        script {
          openshift.withCluster() {
            openshift.withProject(env.DEV_PROJECT) {
              openshift.selector("bc", "tasks").startBuild("--from-file=target/ROOT.war", "--wait=true")
            }
          }
        }
      }
    }
    stage('Deploy DEV') {
      steps {
        script {
          openshift.withCluster() {
            openshift.withProject(env.DEV_PROJECT) {
              openshift.selector("dc", "tasks").rollout().latest();
            }
          }
        }
      }
    }
    stage('Promote to STAGE?') {
      agent {
        label 'skopeo'
      }
      steps {
        timeout(time:15, unit:'MINUTES') {
            input message: "Promote to STAGE?", ok: "Promote"
        }

        script {
          openshift.withCluster() {
            if (env.ENABLE_QUAY.toBoolean()) {
              withCredentials([usernamePassword(credentialsId: "${openshift.project()}-quay-cicd-secret", usernameVariable: "QUAY_USER", passwordVariable: "QUAY_PWD")]) {
                sh "skopeo copy docker://quay.io//tasks-app:latest docker://quay.io//tasks-app:stage --src-creds \"$QUAY_USER:$QUAY_PWD\" --dest-creds \"$QUAY_USER:$QUAY_PWD\" --src-tls-verify=false --dest-tls-verify=false"
              }
            } else {
              openshift.tag("${env.DEV_PROJECT}/tasks:latest", "${env.STAGE_PROJECT}/tasks:stage")
            }
          }
        }
      }
    }
    stage('Deploy STAGE') {
      steps {
        script {
          openshift.withCluster() {
            openshift.withProject(env.STAGE_PROJECT) {
              openshift.selector("dc", "tasks").rollout().latest();
            }
          }
        }
      }
    }
  }
}
```

* Lancer un premier build, pour les paramètres, mettre les nom de votre projet (dev-USER et stage-USER)

**Note** Le premier build peut prendre beaucoup de temps

* Le build devrait échouer car l'image utiliser pour sonarqube n'est pas correcte

* Pour permettre au build de continuer, aller dans la configuration du build et remplacer les lignes : 
```       
 script {
          sh "${mvnCmd} install sonar:sonar -Dsonar.host.url=http://sonarqube:9000 -DskipTests=true"
        }

```
par : 
```
    catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
        sh "${mvnCmd} install sonar:sonar -Dsonar.host.url=http://sonarqube:9000 -DskipTests=true"
        sh "exit 1"
    } 
```
* Relancer un build

## Vérifier le résultat du build
* Nous pouvons vérifier différents éléments de notre build Jenkins
    * La présence de l'artefact dans le dépôt Nexus
    * Le fait que l'application se soit bien déployé dans le projet dev-USER 
    * Le fait que l'application se soit bien déployé dans le projet stage-USER

* En cas d'erreur liée au déploiement, il est probable que votre premier déploiement n'est pas été totalement terminé avant que votre build n'essaie d'un relancer un autre. OpenShift ne pouvant faire qu'un seul déploiement à la fois sur la même ressource, il génère une erreur.

## Créer votre propre pipeline

* A partir de l'application Fruits vue dans l'exercice openshift-springboot, définir les étapes de CI nécessaire et mettre en place votre propre pipeline pour Jenkins.
* Vous aurez besoin des éléments suivants : 
    * un Jenkinsfile
    * un buildconfig
    * un deploymentconfig pour votre application avec le service et la route associée 
    * un ou des projets pour déployés votre application dans différents environnements
    


