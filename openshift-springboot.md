# OpensShift - Démarrer avec une application Springboot

## Objectifs :
* Apprendre à builder une application web CRUD(Create, Read, Update and Delete) avec Springboot sur OpenShift

## Comment Spring Boot est supporté sur OpenShift?

Spring est l'un des frameworks Java les plus populaires et offre une alternative au modèle de programmation Java EE. Spring est aussi un vraiment populaire pour construire des applications basée sur une architecture Microservices. Spring Boot est un outil populaire dans l'eco-système Spring qui aide à l'organisation et l'utilsiation de bibliothèques tierces avec Spring et qui fourni un mécanisme pour embarquer des éxécutables à l'initialisation, comme Apache Tomcat. Les applciations exécutables (pargois appelés jar) corresponde au modèle de conteneurs puisque dans une plateforme de conteneurs comme OpenShigt les responsabilités comme démarrer, arrêter, surveiller les applications sont gérée par la plateforme de conteneur au lieu du serveur d'applications.

Red Hat supporte pleinement Spring et Spring Boot pour l'utilisation sur la plateforme OpenShift comme une partie des Runtimes Red Hat. Red Hat fournit aussi un support complet pour Apache Tomcat, Hibernate et Apache CXF (pour les services REST) lorsqu'ils sont utilisés dans une application Spring Boot sur un Runtimes Red Hat.


## Importer le code

* Récupérer le code du projet:
`git clone https://github.com/openshift-katacoda/rhoar-getting-started && cd rhoar-getting-started/spring/spring-rhoar-intro`

## Structure de base de l'application

* Pour vous faciliter la tache, cet exercice a été créé avec u projet de base qui utilise le langage de programmation Java et l'outil de construction Apache Maven.
* Au départ le projet est presque vide et ne fait quasiment rien.
* Commençons par regarder le contenu en utilisant la commande ``tree`` dans un terminal
* Le résultat devrait être similaire à celui-ci :
```sh
.
|-- pom.xml
`-- src
    `-- main
        |-- jkube
        |   |-- credentials-secret.yml
        |   |-- deployment.yml
        |   |-- route.yml
        |`-- java
        |   `-- com
        |       `-- example
        |           |-- Application.java 
        |           |`-- service
        `-- resources
            |-- application-local.properties
            |-- application-openshift.properties
            `-- static
                |-- index.html
```

* Certains fichiers ont été préparés pour vous. Ils ressemblent beaucoup à ceux fournit lors de la génération d'un projet vide depuis la page : [Spring Initializr](https://start.spring.io). 
* Un des fichiers qui diffère est le `pom.xml`. Ouvrez-le et examiner le de plus près (mais ne changer rien pour l'instant)
* Noter que nous n'utilisons pas le BOM (Bill of material) par défaut qu'un projet standard de Spring Boot utilise. A la place, nous utilison un BOM fournit par Red Hat comme morceau du projet  [Snowdrop](http://snowdrop.me/).

```xml
  <dependencyManagement>
    <dependencies>
      <dependency>
        <groupId>me.snowdrop</groupId>
        <artifactId>spring-boot-bom</artifactId>
        <version>${spring-boot.bom.version}</version>
        <type>pom</type>
        <scope>import</scope>
      </dependency>
    </dependencies>
  </dependencyManagement>
```

* Nous utilions ce BOM pour être sûr que les versions que nous utilisons comme celle de Apache Tomcat, sont celle que Red Hat supporte.

**1. Ajouter web (Apache Tomcat) à l'application**

Puisque la majorité de nos applications sont des applications web, nous avons besoin d'utiliser un conteneur de servlet comme Apache Tomcat ou Undertow. Puisque Red Hat support Apache Tomcat (e.g., security patches, bug fixes, etc.), nous l'utiliserons.

>**NOTE:** Undertow est un autre projet open source qui est maintenu par Red Hat et pour lequel Red Hat a prévu d'ajouter le supporte rapidement.

Pour ajouter Apache tomcat à notre projet, nous devons simplement ajouter les lignes suivantes au fichier ``pom.xml``

<pre class="file" data-filename="pom.xml" data-target="insert" data-marker="<!-- TODO: Add web (tomcat) dependency here -->">
    &lt;dependency&gt;
      &lt;groupId&gt;org.springframework.boot&lt;/groupId&gt;
      &lt;artifactId&gt;spring-boot-starter-web&lt;/artifactId&gt;
    &lt;/dependency&gt;
</pre>

**2. Tester l'application en local**

En développant l'application, nous voudrons tester et vérifier les modificatio à différentes étapes. Pour cela, en local nous utilisons le plugin maven `spring-boot`.

Lancer l'application avec la commande suivante : 

``mvn spring-boot:run``

**3. Verifier l'application**

Pour commencer, ouvrir un navigateur, et aller sur l'adresse local sur le port 8080. 

Vous devriez avoir une page HTML qui ressemble à celle-ci :

![Local Web Browser Tab](/openshift/assets/middleware/rhoar-getting-started-spring/web-page.png)

Comme vous l'avez surement deviné, l'application que nous construitons est un dépôt de fruit  qui permet de créer, lire, mettre à jour et supprimer différents type de fruit.


> **NOTE:** Aucun des bouton ne fonctionnes à cette etape car aucun service n'est implémenté encore, mais nous allons le faire rapidement.

**4. Arrêter l'application**

Avant de continuer, pensez à arrêter l'application en appuyant sur 
 <kbd>CTRL</kbd>+<kbd>C</kbd> dans le terminal!


## Lire le contenu dans une base de données

Dans la première étape, vous avez appris à démarrer notre projet. Dans cet étape nous allons maintenant ajouter des fonctionnalités à notre application de panier de fruits pour afficher du contenu depuis la base de données.

**1. Ajouter JPA (Hibernate) à l'application**

Puisque notre application (comme la plupart) a besoin d'accéder à une base de données pour lire et stocker les entrées de fruit, nous avons besoin d'ajouter l'API de Persistence de Java à notre projet.
 
La mise en place par défaut dans Spring Boot est faite avec Hibernate qui a été testé comme une partie des Runtimes Red Hat.

>**NOTE:** Hibernate est un autre projet open source qui est maintenu par Red Hat et qui sera bienôt ajouté en production dans les Runtimes Red Hat. 

Pour ajouter Hibernate à notre projet, nous avons besoin d'ajouter les lignes suivantes au fichier ``pom.xml``

<pre class="file" data-filename="pom.xml" data-target="insert" data-marker="<!-- TODO: Add JPA dependency here -->">
    &lt;dependency&gt;
      &lt;groupId&gt;org.springframework.boot&lt;/groupId&gt;
      &lt;artifactId&gt;spring-boot-starter-data-jpa&lt;/artifactId&gt;
    &lt;/dependency&gt;
</pre>

Lorsque nous testons en local ou en lançant les tests, nous avons aussi besoin d'une base de données locale. H2 est une petite base de données en mémoire qui est parfaite pour tester mais non recommandés en environnement de production. Pour ajouter H2 ajouter la dépendance suivante au commentaire `<!-- TODO: ADD H2 database dependency here -->` dans le profile locale.

<pre class="file" data-filename="pom.xml" data-target="insert" data-marker="<!-- TODO: ADD H2 database dependency here -->">
        &lt;dependency&gt;
          &lt;groupId&gt;com.h2database&lt;/groupId&gt;
          &lt;artifactId&gt;h2&lt;/artifactId&gt;
          &lt;scope&gt;runtime&lt;/scope&gt;
        &lt;/dependency&gt;</pre>


**2. Créer une classe d'entité**

Nous allons mettre en palce une classe d'Entité qui représente un fruit. Cette classe est utilisé pour faire correspondre notre objet au schéma de la base de données.

Pour commencer, nous avons besoin de créer un fichier de classe Java. Pour cela ajouter un fichier Fruit.java dans le dossier  ``src/main/java/com/example/service/`` et ouvrir le fichier.

Puis, copier le contenu ci-dessous dans le fichier :

<pre class="file" data-filename="src/main/java/com/example/service/Fruit.java" data-target="replace">
package com.example.service;

import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;

@Entity
public class Fruit {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    private String name;

    public Fruit() {
    }

    public Fruit(String type) {
        this.name = type;
    }

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }
}
</pre>


 **3.Créer une classe de dépôt pour notre contenu**

Ce dépôt doit fournir les méthodes pour insérer, mettre-à-jour, sélecitonner et supprimer les fruits de la base de données. Nous utilisons Spring Data qui fournit pour nous de nombreuses lignes d code. Tout ce que nous avons à faire est d'ajouter une interface qui étend l'interface `CrudRepository<Fruit, Integer>` fournie par  Spring Data.

Commençons par créer un fichier de classe de java. Pour cela ajouter un fichier FruitRepository.java dans le dossier  ``src/main/java/com/example/service/`` et ouvrir le fichier.

Puis, copier le contenu ci-dessous dans le fichier : 

<pre class="file" data-filename="src/main/java/com/example/service/FruitRepository.java" data-target="replace">
package com.example.service;

import org.springframework.data.repository.CrudRepository;

public interface FruitRepository extends CrudRepository&lt;Fruit, Integer&gt; {
}
</pre>

**4. Peupler la base de données avec du contenu initial**

Pour pré-remplir la base de données, Hibernet offre une fonctionnalité qui permet de fournir un fichier SQL qui remplit le contenu

Pour commencer, créer un fichier SQL. Pour cela créer un fichier vide `import.sql` dans  ``src/main/resources/`` et l'ouvrir

Puis, copier le contenu ci-dessous dans le fichier :

<pre class="file" data-filename="src/main/resources/import.sql" data-target="replace">
insert into fruit (name) values ('Cherry');
insert into fruit (name) values ('Apple');
insert into fruit (name) values ('Banana');
</pre>

**5. Ajouter une classe de test**

Pour vérifier que nous pouvons utiliser le `FruitRepository` pour rechercher et stocker des objets fruits, nous créons une classe de test.

Pour commencer, créer un fichier de classe Java. Pour cela créer un fichier vide `ApplicationTest.java` dans  ``src/test/java/com/example/`` et l'ouvrir

Puis, copier le contenu ci-dessous dans le fichier :

<pre class="file" data-filename="src/test/java/com/example/ApplicationTest.java" data-target="replace">
package com.example;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.Optional;

import org.junit.jupiter.api.Test;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

import com.example.service.Fruit;
import com.example.service.FruitRepository;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Transactional
public class ApplicationTest {

    @Autowired
    private FruitRepository fruitRepository;

    @Test
    public void testGetAll() {
        assertThat(this.fruitRepository.findAll())
          .isNotNull()
          .hasSize(3);
    }

    @Test
    public void getOne() {
        assertThat(this.fruitRepository.findById(1))
          .isNotNull()
          .isPresent();
    }

    @Test
    public void updateAFruit() {
        Optional&lt;Fruit&gt; apple = this.fruitRepository.findById(2);

        assertThat(apple)
          .isNotNull()
          .isPresent()
          .get()
          .extracting(Fruit::getName)
          .isEqualTo("Apple");

        Fruit theApple = apple.get();
        theApple.setName("Green Apple");
        this.fruitRepository.save(theApple);

        assertThat(this.fruitRepository.findById(2))
          .isNotNull()
          .isPresent()
          .get()
          .extracting(Fruit::getName)
          .isEqualTo("Green Apple");
    }

    @Test
    public void createAndDeleteAFruit() {
        int orangeId = this.fruitRepository.save(new Fruit("Orange")).getId();
        Optional&lt;Fruit&gt; orange = this.fruitRepository.findById(orangeId);
        assertThat(orange)
          .isNotNull()
          .isPresent();

        this.fruitRepository.delete(orange.get());

        assertThat(this.fruitRepository.findById(orangeId))
          .isNotNull()
          .isNotPresent();
    }

    @Test
    public void getWrongId() {
        assertThat(this.fruitRepository.findById(9999))
          .isNotNull()
          .isNotPresent();
    }
}

</pre>

Prenez le temps de lire les tests. Le test `testGetAll` renvoit tous les fruits du dépôt, qui devraient être 3 au vu du contenu du fichier  `import.sql`. Le test `getOne` retrouve le fruit avec l'ID 1 (e.g., the Cherry) et vérifie qu'il n'est pas nul. Le test `getWrongId` vérifie que lorsque nous essayons de récupérer un fruit avec un ID qui n'existe pas le retour du dépôt est bien nul.

**6. Lancer et vérifier**

Nous pouvons maintenant tester que notre  `FruitRepository` peut se connecter à la source de données et récupérer les données en lançant l'application via la commande suivante :

``mvn verify``

Vous devriez avoir comme retour : 

```
Results :

Tests run: 5, Failures: 0, Errors: 0, Skipped: 0
```

## Créer un service REST pour l'application web des fruits


**1. Ajouter un service**

Pour commencer, créer un fichier de classe Java. Pour cela créer un fichier vide `FruitController.java` dans  ``src/test/java/com/example/service/`` et l'ouvrir

Puis, copier le contenu ci-dessous dans le fichier :

<pre class="file" data-filename="src/main/java/com/example/service/FruitController.java" data-target="replace">
package com.example.service;

import java.util.Objects;

import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/fruits")
public class FruitController {

    private final FruitRepository repository;

    public FruitController(FruitRepository repository) {
        this.repository = repository;
    }

    @GetMapping(produces = MediaType.APPLICATION_JSON_VALUE)
    public Iterable&lt;Fruit&gt; getAll() {
        return this.repository.findAll();
    }

//TODO: Add additional service calls here
}
</pre>

Prenez une minute et lisez le `FruitController`. Pour l'instant il est très simple et n'a qu'une méthode qui expose un endpoint pour les requêtes HTTP GET pour le chemin `/api/fruits`, comme spécifié dans l'annotation de la classe `@RequestMapping(value = "/api/fruits")`. Nous devrions maintenant pouvoir voir une liste de fruits sur la page web.

**2. Tester le service depuis un navigateur en local **

Lancer l'application en executant la commande ci-dessous :

``mvn spring-boot:run -DskipTests``=

>**NOTE:** Nous inogrons les tests pour accélérer le démarrage et car nous n'avons aucun test pour le service REST. Veuillez noter que le `spring-boot-crud-booster` [here](https://github.com/snowdrop/spring-boot-crud-booster) a des cas de tests pour REST, étudiez les si vous êtes intéressés.

Afin de gagnez du temps, nous ne créons pas les cas de tests pour le service et ne faisons les tests que dans le navigateur web.

Lorsque la console indique que Spring est démarré et fonctionne, se rendre sur la page web dans le navigateur local.

![Local Web Browser Tab](/openshift/assets/middleware/rhoar-getting-started-spring/web-browser-tab.png)


Si tout fonctionne correctement, la page web devrait ressembler à ça : 

![Fruit List](/openshift/assets/middleware/rhoar-getting-started-spring/fruit-list.png)

Appuyer <kbd>CTRL</kbd>+<kbd>C</kbd> pour arrêter l'application.

**3. Créer des services additionnels pour la mise à jour, la création et la suppresion**

Ajouter les méthodes suivantes au Controleur Fruit à la place du marker TODO.

<pre class="file" data-filename="src/main/java/com/example/service/FruitController.java" data-target="insert" data-marker="//TODO: Add additional service calls here">
    @ResponseStatus(HttpStatus.CREATED)
    @PostMapping(consumes = MediaType.APPLICATION_JSON_VALUE, produces = MediaType.APPLICATION_JSON_VALUE)
    public Fruit post(@RequestBody(required = false) Fruit fruit) {
        verifyCorrectPayload(fruit);

        return this.repository.save(fruit);
    }

    @GetMapping(path = "/{id}", produces = MediaType.APPLICATION_JSON_VALUE)
    public Fruit get(@PathVariable("id") Integer id) {
        verifyFruitExists(id);

        return this.repository.findById(id).orElse(null);
    }

    @PutMapping(path = "/{id}", consumes = MediaType.APPLICATION_JSON_VALUE, produces = MediaType.APPLICATION_JSON_VALUE)
    public Fruit put(@PathVariable("id") Integer id, @RequestBody(required = false) Fruit fruit) {
        verifyFruitExists(id);
        verifyCorrectPayload(fruit);

        fruit.setId(id);
        return this.repository.save(fruit);
    }

    @ResponseStatus(HttpStatus.NO_CONTENT)
    @DeleteMapping("/{id}")
    public void delete(@PathVariable("id") Integer id) {
        verifyFruitExists(id);

        this.repository.deleteById(id);
    }

    private void verifyFruitExists(Integer id) {
        if (!this.repository.existsById(id)) {
            throw new RuntimeException(String.format("Fruit with id=%d was not found", id));
        }
    }

    private void verifyCorrectPayload(Fruit fruit) {
        if (Objects.isNull(fruit)) {
            throw new RuntimeException("Fruit cannot be null");
        }

        if (!Objects.isNull(fruit.getId())) {
            throw new RuntimeException("Id field must be generated");
        }
    }
</pre>


**4. Lancer et vérifier**

Lancer et démarrer de nouveau l'applciation :

``mvn spring-boot:run -DskipTests``

Maintenant que tous les services sont mis en place, nous pouvoir voir les fruits sur une page mais aussi les mettre à jour, les créer ou les supprimer.

Lors

Lorsque la console indique que Spring est démarré et fonctionne, se rendre sur la page web dans le navigateur local.


Si tout fonctionne correctement, la page web devrait ressembler à ça : 
![Local Web Browser Tab](/openshift/assets/middleware/rhoar-getting-started-spring/web-browser-tab.png)


Appuyer <kbd>CTRL</kbd>+<kbd>C</kbd> pour arrêter l'application.


## Deployer sur OpenShift Application Platform

Faire tourner une base de donnée H2 en local est un bon choix, mais maintenant que nous bougeons sur une plateforme de conteneur nous voulons utiliser une base de données plus orientée production, et pour ça nous allons utiliser PostgreSQL. 

Avant de déployer l'application sur openShift et de vérifier qu'elle fonctionne correctement, il y a quelques points à traiter. Nous evons d'abord ajouter un driver pour la base de données PostgreSQL que nous allons utiliser, et aussi ajouter des points de contrôle pour que OpenShift puisse détecter correctement si notre application fonctionne.

**1. Créer la base de données**

Comme c'est votre projet personnel, vous devez créer une instance de base de données à laquelle votre application peut se connnecté. Dans un environnement partagé, cela serait fait pour vous, c'est pour cela que nous ne le déployons pas comme une partie de l'application. Cela est cependant très simple dans OpenShift. Tout ce qui est nécessaire est d'éxecuter la commande suivante : 

``oc new-app -e POSTGRESQL_USER=luke \
             -e POSTGRESQL_PASSWORD=secret \
             -e POSTGRESQL_DATABASE=my_data \
             openshift/postgresql:12-el8 \
             --name=my-database``{{execute}}

**2. Vérifier la configuration de la base de données**

Prenez le temps d'étudier ``src/main/jkube/deployment.yml``

Comme vous pouvez le voir ce fichier défini différents éléments qui sont nécessaire pour notre déploiement. Il utilise aussi le nom d'utilisateur et le mot de passe depuis un Secret Kubernetes
. Pour cet environnement nous fournissons le secret dans ce fichier ``src/main/jkube/credentials-secret.yml``, cependant dans un environnement de production il vous serait fournis par l'équipe Ops.

Maintenant voyons le fichier ``src/main/resources/application-openshift.properties``

Dans ce fichier, nous utilisons la configuration depuis le fichier `deployment.yml` pour lire le nom d'utilisateur, le mot de passe et les autres détails de connexion. 

**3. Ajouter le driver de base de données PostgreSQL**

Pour l'instant notre application a seulement utilisé une base de données H2, nous avons besoin d'une dépendance au driver PostgreSQL. Nous le faisons en ajouter une dépendance au runtime dans le profile `openshift` du fichier ``pom.xml``.

<pre class="file" data-filename="pom.xml" data-target="insert" data-marker="<!-- TODO: ADD PostgreSQL database dependency here -->">
        &lt;dependency&gt;
          &lt;groupId&gt;org.postgresql&lt;/groupId&gt;
          &lt;artifactId&gt;postgresql&lt;/artifactId&gt;
          &lt;scope&gt;runtime&lt;/scope&gt;
        &lt;/dependency&gt;
</pre>


**4. Ajouter un point de contrôle**

Nous avons également besoin d'un point de contrôle pour que OpenShift puisse détecter si notre application répond correctement. Spring Boot fournit une fonctionnalité pratique appelée Actuator, qui exepose des données de contrôles sur le chemin `/health`. Tout ce que nous avons à faire est d'ajouter la dépendance suivante dans le fichier ``pom.xml``sur le commentaire **TODO**.

<pre class="file" data-filename="pom.xml" data-target="insert" data-marker="<!-- TODO: ADD Actuator dependency here -->">
    &lt;dependency&gt;
      &lt;groupId&gt;org.springframework.boot&lt;/groupId&gt;
      &lt;artifactId&gt;spring-boot-starter-actuator&lt;/artifactId&gt;
    &lt;/dependency&gt;
</pre>

**5. Deployer l'application sur OpenShift**

Executer la commande suivante pour déployer l'application sur OpenShift :

``mvn package oc:deploy -Popenshift -DskipTests``

Cette étape peut prendre du temps qui dépend du build Maven et du déploiement OpenShift. Après que le build soit complet vous pouvez vérifier que tout est démarré en lançant la commande suivante :

``oc rollout status dc/spring-getting-started``

Vous pouvez aussi aller sur la console web OpenShift et cliquer sur la route.

Assurez-vous que vous pouvez ajouter, modifier et supprimer des fruits en utilisant l'application web.

Vous savez maintenant déployer une application Spring Boot utilisant une base de donnée sur  OpenShift Container Platform.

