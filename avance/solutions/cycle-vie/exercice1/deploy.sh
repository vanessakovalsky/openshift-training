#!/bin/bash
set -e

ENVIRONMENT=${1:-dev}
DRY_RUN=${2:-false}

echo "🚀 Déploiement de l'application sécurisée - Environnement: $ENVIRONMENT"

# Validation des prérequis
check_prerequisites() {
    echo "🔍 Vérification des prérequis..."
    
    if ! command -v kubectl &> /dev/null; then
        echo "❌ kubectl non trouvé"
        exit 1
    fi
    
    if ! command -v kustomize &> /dev/null; then
        echo "❌ kustomize non trouvé"
        exit 1
    fi
    
    echo "✅ Prérequis validés"
}

# Validation de la configuration Kustomize
validate_kustomize() {
    echo "🔍 Validation de la configuration Kustomize..."
    
    kustomize build environments/$ENVIRONMENT > /tmp/manifest-$ENVIRONMENT.yaml
    
    # Validation avec kubectl dry-run
    kubectl apply --dry-run=server -f /tmp/manifest-$ENVIRONMENT.yaml
    
    echo "✅ Configuration Kustomize validée"
}

# Déploiement 
deploy() {
    echo "📦 Déploiement via kubectl apply..."
    
    if [ "$DRY_RUN" = "true" ]; then
        echo "🔍 Mode dry-run activé - affichage de la configuration:"
        cat /tmp/manifest-$ENVIRONMENT.yaml
        return
    fi

    NAMESPACE="secure-app-$ENVIRONMENT"


    # Création du NAMESPACE
    if kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
        echo "Namespace '$NAMESPACE' already exists."
    else
    # Create namespace
        oc apply -f environments/$ENVIRONMENT/namespace.yaml
        echo "Namespace '$NAMESPACE' created."
    fi

    SERVICEACCOUNTNAME="secure-app-sa"
    
    # Ajout du compte de service 
    if oc get sa $SERVICEACCOUNTNAME -n $NAMESPACE >/dev/null 2>&1; then
        echo "ServiceAccount '$SERVICEACCOUNTNAME' already exists in namespace '$NAMESPACE'."
    else
        echo "Creating ServiceAccount '$SERVICEACCOUNTNAME' in namespace '$NAMESPACE'."
        oc create sa $SERVICEACCOUNTNAME -n $NAMESPACE
    fi
    oc adm policy add-scc-to-user anyuid system:serviceaccount:$NAMESPACE:$SERVICEACCOUNTNAME

    # Appliquer l'application 
    kubectl apply -f /tmp/manifest-$ENVIRONMENT.yaml
    
    
    echo "✅ Application déployée"
}

# Validation post-déploiement
validate_deployment() {
    if [ "$DRY_RUN" = "true" ]; then
        return
    fi
    
    echo "🔍 Validation post-déploiement..."
    
    NAMESPACE="secure-app-$ENVIRONMENT"
    
    # Attendre que les pods soient prêts
    kubectl wait --for=condition=ready pod -l app=secure-app -n $NAMESPACE --timeout=60s
    
    # Vérifier les NetworkPolicies
    NP_COUNT=$(kubectl get networkpolicies -n $NAMESPACE --no-headers | wc -l)
    if [ "$NP_COUNT" -eq 0 ]; then
        echo "❌ Aucune NetworkPolicy trouvée"
        exit 1
    fi
    
    # Test de connectivité @TODO : check why this don't work 
    # kubectl run test-pod --image=busybox --rm -i --tty -n $NAMESPACE -- nslookup secure-app-service
    
    echo "✅ Validation post-déploiement réussie"
}

# Exécution principale
main() {
    check_prerequisites
    validate_kustomize
    deploy
    validate_deployment
    
    echo "🎉 Déploiement terminé avec succès pour l'environnement: $ENVIRONMENT"
}

main