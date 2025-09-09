#!/bin/bash

source ./health-monitor.sh

NAMESPACE="rolling-update-demo"
DEPLOYMENT_NAME="webapp-rolling"
LOG_FILE="/tmp/auto-rollback.log"
ROLLBACK_COOLDOWN=300  # 5 minutes entre les rollbacks
LAST_ROLLBACK_FILE="/tmp/last_rollback"

# Fonction de notification (simulée)
send_notification() {
    local level=$1
    local message=$2
    echo "$(date): [$level] $message" | tee -a $LOG_FILE
    
    # Ici on pourrait intégrer avec Slack, email, etc.
    # curl -X POST -H 'Content-type: application/json' \
    #   --data "{\"text\":\"[$level] OpenShift Rollback: $message\"}" \
    #   $SLACK_WEBHOOK_URL
}

# Fonction de vérification du cooldown
check_rollback_cooldown() {
    if [[ -f $LAST_ROLLBACK_FILE ]]; then
        local last_rollback=$(cat $LAST_ROLLBACK_FILE)
        local current_time=$(date +%s)
        local time_diff=$((current_time - last_rollback))
        
        if [[ $time_diff -lt $ROLLBACK_COOLDOWN ]]; then
            local remaining=$((ROLLBACK_COOLDOWN - time_diff))
            send_notification "WARNING" "Rollback en cooldown, ${remaining}s restantes"
            return 1
        fi
    fi
    return 0
}

# Fonction de rollback
perform_rollback() {
    local current_version=$(oc get dc $DEPLOYMENT_NAME -o jsonpath='{.status.latestVersion}')
    local previous_version=$((current_version - 1))
    
    send_notification "CRITICAL" "Démarrage du rollback automatique du déploiement $current_version vers $previous_version"
    
    # Vérifier qu'il existe une version précédente
    if [[ $previous_version -lt 1 ]]; then
        send_notification "ERROR" "Aucune version précédente disponible pour le rollback"
        return 1
    fi
    
    # Effectuer le rollback
    if oc rollback dc/$DEPLOYMENT_NAME --to-version=$previous_version; then
        send_notification "INFO" "Rollback initié avec succès"
        
        # Attendre que le rollback soit terminé
        if oc rollout status dc/$DEPLOYMENT_NAME --timeout=300s; then
            send_notification "SUCCESS" "Rollback terminé avec succès vers la version $previous_version"
            
            # Enregistrer l'horodatage du rollback
            date +%s > $LAST_ROLLBACK_FILE
            
            # Attendre un peu puis vérifier la santé
            sleep 30
            collect_metrics
            if evaluate_health; then
                send_notification "SUCCESS" "Application stable après rollback"
                return 0
            else
                send_notification "WARNING" "Application toujours instable après rollback"
                return 1
            fi
        else
            send_notification "ERROR" "Timeout lors du rollback"
            return 1
        fi
    else
        send_notification "ERROR" "Échec de l'initiation du rollback"
        return 1
    fi
}

# Fonction de monitoring continu avec rollback automatique
start_monitoring() {
    local consecutive_failures=0
    local max_consecutive_failures=3
    
    send_notification "INFO" "Démarrage du monitoring avec rollback automatique"
    
    while true; do
        collect_metrics
        
        if evaluate_health; then
            consecutive_failures=0
            echo "$(date): Application en bonne santé"
        else
            consecutive_failures=$((consecutive_failures + 1))
            send_notification "WARNING" "Problème de santé détecté (${consecutive_failures}/${max_consecutive_failures})"
            
            if [[ $consecutive_failures -ge $max_consecutive_failures ]]; then
                if check_rollback_cooldown; then
                    send_notification "CRITICAL" "Seuil de problèmes atteint, déclenchement du rollback automatique"
                    
                    if perform_rollback; then
                        consecutive_failures=0
                    else
                        send_notification "ERROR" "Rollback automatique échoué"
                    fi
                else
                    send_notification "WARNING" "Rollback nécessaire mais en cooldown"
                fi
            fi
        fi
        
        # Pause avant la prochaine vérification
        sleep 30
    done
}

# Fonction de test de conditions dégradées
simulate_degraded_conditions() {
    send_notification "INFO" "Simulation de conditions dégradées"
    
    # Créer une version défaillante de l'application
    cat > /tmp/broken-config.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: webapp-config
  namespace: $NAMESPACE
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <head>
        <title>Broken Version</title>
    </head>
    <body>
        <h1>Version cassée - Test de rollback</h1>
        <div>Version: 999.0 (BROKEN)</div>
        <script>
            // Simuler une erreur JavaScript
            setTimeout(() => {
                throw new Error("Simulated application error");
            }, Math.random() * 5000);
            
            // Simuler de la lenteur
            for(let i = 0; i < 1000000; i++) {
                document.body.innerHTML += "";
            }
        </script>
    </body>
    </html>
EOF
    
    # Appliquer la configuration cassée
    oc apply -f /tmp/broken-config.yaml
    oc rollout latest dc/$DEPLOYMENT_NAME
    
    send_notification "INFO" "Version dégradée déployée, le monitoring devrait déclencher un rollback"
}

# Interface de ligne de commande
case "${1:-monitor}" in
    "monitor")
        start_monitoring
        ;;
    "test-degraded")
        simulate_degraded_conditions
        ;;
    "manual-rollback")
        if check_rollback_cooldown; then
            perform_rollback
        fi
        ;;
    "check-health")
        collect_metrics
        evaluate_health
        ;;
    *)
        echo "Usage: $0 {monitor|test-degraded|manual-rollback|check-health}"
        echo "  monitor        : Démarrage du monitoring avec rollback automatique"
        echo "  test-degraded  : Simulation de conditions dégradées"
        echo "  manual-rollback: Rollback manuel"
        echo "  check-health   : Vérification ponctuelle de santé"
        exit 1
        ;;
esac