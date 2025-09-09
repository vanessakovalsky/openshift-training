#!/bin/bash

ENVIRONMENT=${1:-dev}
NAMESPACE="secure-app-$ENVIRONMENT"

echo "🔐 Validation des politiques de sécurité - Environnement: $ENVIRONMENT"
echo "================================================================"

# Vérification des SecurityContexts
validate_security_context() {
    echo "🔍 Validation des Security Contexts..."
    
    # Vérifier runAsNonRoot
    NON_ROOT=$(kubectl get pods -n $NAMESPACE -o jsonpath='{.items[*].spec.securityContext.runAsNonRoot}')
    if [[ "$NON_ROOT" != *"true"* ]]; then
        echo "❌ Pods ne s'exécutent pas avec runAsNonRoot"
        return 1
    fi
    
    # Vérifier readOnlyRootFilesystem
    READONLY_FS=$(kubectl get pods -n $NAMESPACE -o jsonpath='{.items[*].spec.containers[*].securityContext.readOnlyRootFilesystem}')
    if [[ "$READONLY_FS" != *"true"* ]]; then
        echo "❌ Filesystem root n'est pas en lecture seule"
        return 1
    fi
    
    echo "✅ Security Contexts validés"
}

# Vérification des NetworkPolicies
validate_network_policies() {
    echo "🔍 Validation des Network Policies..."
    
    NP_COUNT=$(kubectl get networkpolicies -n $NAMESPACE --no-headers | wc -l)
    
    if [ "$ENVIRONMENT" = "prod" ]; then
        if [ "$NP_COUNT" -lt 2 ]; then
            echo "❌ Environnement PROD doit avoir au moins 2 NetworkPolicies"
            return 1
        fi
    else
        if [ "$NP_COUNT" -eq 0 ]; then
            echo "❌ Aucune NetworkPolicy trouvée"
            return 1
        fi
    fi
    
    echo "✅ Network Policies validées ($NP_COUNT trouvées)"
}

# Vérification des Resource Limits
validate_resources() {
    echo "🔍 Validation des Resource Limits..."
    
    # Vérifier que tous les containers ont des limits
    PODS_WITHOUT_LIMITS=$(kubectl get pods -n $NAMESPACE -o json | jq -r '
        .items[] | 
        select(.spec.containers[] | .resources.limits == null) |
        .metadata.name
    ')
    
    if [ -n "$PODS_WITHOUT_LIMITS" ]; then
        echo "❌ Pods sans resource limits: $PODS_WITHOUT_LIMITS"
        return 1
    fi
    
    echo "✅ Resource Limits validées"
}

# Test de pénétration basique
security_test() {
    echo "🔍 Tests de sécurité basiques..."
    
    # Tester l'accès aux métadatas EC2 (si sur AWS)
    kubectl run security-test --image=busybox --rm -i --tty -n $NAMESPACE -- \
        wget -q --timeout=5 -O- http://169.254.169.254/latest/meta-data/ || echo "✅ Accès métadatas bloqué"
    
    # Tester l'accès au filesystem host
    kubectl run security-test --image=busybox --rm -i --tty -n $NAMESPACE -- \
        ls /host 2>&1 | grep -q "No such file" && echo "✅ Accès filesystem host bloqué"
    
    echo "✅ Tests de sécurité basiques terminés"
}

# Rapport de conformité
generate_compliance_report() {
    echo "📊 Génération du rapport de conformité..."
    
    REPORT_FILE="security-report-$ENVIRONMENT-$(date +%Y%m%d-%H%M%S).json"
    
    kubectl get pods -n $NAMESPACE -o json | jq '{
        environment: "'$ENVIRONMENT'",
        namespace: "'$NAMESPACE'",
        timestamp: now,
        pods: [
            .items[] | {
                name: .metadata.name,
                securityContext: .spec.securityContext,
                containers: [
                    .spec.containers[] | {
                        name: .name,
                        securityContext: .securityContext,
                        resources: .resources
                    }
                ]
            }
        ]
    }' > $REPORT_FILE
    
    echo "📄 Rapport sauvegardé: $REPORT_FILE"
}

# Exécution principale
main() {
    validate_security_context || exit 1
    validate_network_policies || exit 1
    validate_resources || exit 1
    security_test
    generate_compliance_report
    
    echo "🎉 Validation de sécurité terminée avec succès!"
}

main