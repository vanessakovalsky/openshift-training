# Solution pour exercice network policies


## Déploiements des fichiers YAML

* Les fichiers YAML sont dans le répertoire `avance/solutions/network-policies/yaml`.
* Pour appliquer les fichiers YAML, utilisez la commande suivante dans le terminal :

  ```bash
  oc apply -f avance/solutions/network-policies/yaml/01-namespace-dev-wordpress-vanessa.yaml
  oc create sa wp-sa -n dev-wordpress-vanessa
  oc adm policy add-scc-to-user anyuid system:serviceaccount:dev-wordpress-vanessa:wp-sa
  oc apply -f avance/solutions/network-policies/yaml/
  ```
* Il est nécessaire pour wordpress qui nécessite d'utiliser le port 80 de créer un compte de service et de lui associer le scc anyuid