# TP corrigé : Application distribuée avec Submariner

## Objectif

Déployer une application distribuée entre deux clusters OpenShift et valider la communication inter-clusters via Submariner.

---

## 1️⃣ Préparation des clusters

### Commandes

```bash
# Vérifier accès cluster A
oc config use-context cluster-a
oc whoami
oc get nodes

# Vérifier accès cluster B
oc config use-context cluster-b
oc whoami
oc get nodes
```

### Résultat attendu

* Affichage du nom d’utilisateur admin.
* Liste des nœuds du cluster.

---

## 2️⃣ Installation de Submariner

### Étape 1 : Installer `subctl`

```bash
curl -Ls https://get.submariner.io | bash
subctl version
```

### Étape 2 : Déployer le broker sur Cluster A

```bash
oc config use-context cluster-a
subctl deploy-broker --kubeconfig ~/.kube/config --context cluster-a
```

### Étape 3 : Vérifier le broker

```bash
oc get pods -n submariner-operator
```

* Résultat attendu : pods `submariner-broker` et `submariner-gateway` en état `Running`.

### Étape 4 : Joindre les clusters

* Cluster A :

```bash
subctl join broker-info.subm --kubeconfig ~/.kube/config --context cluster-a
```

* Cluster B :

```bash
subctl join broker-info.subm --kubeconfig ~/.kube/config --context cluster-b
```

### Étape 5 : Vérification

```bash
subctl show all --kubeconfig ~/.kube/config --context cluster-a
```

* Résultat attendu :

  * Cluster A et Cluster B listés.
  * Gateways et services connectés.

---

## 3️⃣ Déploiement de l’application

### Cluster B : Backend

```bash
oc config use-context cluster-b
oc new-project backend

# Déployer PostgreSQL
oc run backend --image=quay.io/bitnami/postgresql:15.2 --env="POSTGRES_PASSWORD=admin" --env="POSTGRES_USER=user" --env="POSTGRES_DB=mydb"

# Exposer le service
oc expose pod backend --port=5432 --name=backend-svc

# Vérifier le service
oc get svc -n backend
```

**Résultat attendu :**

* Service `backend-svc` avec ClusterIP attribué.
* Pod `backend` en état `Running`.

---

### Cluster A : Frontend

```bash
oc config use-context cluster-a
oc new-project frontend

# Déployer un pod simple (ex: curl pour tester)
oc run frontend --image=curlimages/curl:8.2.1 --command -- sleep infinity

# Exposer le pod
oc expose pod frontend --port=8080 --name=frontend-svc
```

**Résultat attendu :**

* Pod `frontend` en état `Running`.
* Service `frontend-svc` exposé.

---

## 4️⃣ Test de la connectivité inter-clusters

### Étape 1 : Ping du backend depuis frontend

```bash
oc rsh -n frontend <frontend-pod-name>
ping backend-svc.backend.svc.cluster.local
```

**Résultat attendu :**

* Les paquets ping atteignent le service backend.

### Étape 2 : Connexion à PostgreSQL (optionnel)

```bash
psql -h backend-svc.backend.svc.cluster.local -U user -d mydb
```

* Mot de passe : `admin`
* Résultat attendu : connexion réussie.

---

## 5️⃣ Validation

* L’application est distribuée entre les deux clusters.
* Submariner fonctionne correctement si le frontend peut communiquer avec le backend.
* Vérification supplémentaire :

```bash
oc get pods -n submariner-operator
subctl show connections
```

---

## 6️⃣ Questions de réflexion

1. Quels avantages apporte Submariner pour le multi-cluster par rapport aux LoadBalancers classiques ?
2. Quelles contraintes réseau ou sécurité peuvent limiter Submariner ?
3. Comment chiffrer la communication inter-clusters pour la production ?

