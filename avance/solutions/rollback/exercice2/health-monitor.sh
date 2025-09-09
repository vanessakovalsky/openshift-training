#!/bin/bash

NAMESPACE="rolling-update-demo"
ROUTE_URL=$(oc get route webapp-rolling-route -o jsonpath='{.spec.host}')
LOG_FILE="/tmp/health-monitor.log"
METRICS_FILE="/tmp/metrics.json"

# Configuration des seuils
ERROR_RATE_THRESHOLD=10  # 10% d'erreurs max
RESPONSE_TIME_THRESHOLD=2000  # 2 secondes max
MIN_SUCCESS_RATE=90  # 90% de succès minimum
MONITORING_WINDOW=60  # 60 secondes de fenêtre d'observation

# Initialisation
echo "$(date): Démarrage du monitoring de santé" >> $LOG_FILE

# Fonction de collecte de métriques
collect_metrics() {
    local window_start=$(date +%s)
    local total_requests=0
    local successful_requests=0
    local failed_requests=0
    local total_response_time=0
    local max_response_time=0
    local current_deployment=""
    
    echo "Collecte de métriques sur $MONITORING_WINDOW secondes..."
    
    while [[ $(($(date +%s) - window_start)) -lt $MONITORING_WINDOW ]]; do
        local request_start=$(date +%s%3N)
        
        # Effectuer la requête avec timeout
        local http_code=$(curl -s -w "%{http_code}" -m 5 -o /dev/null "https://$ROUTE_URL" 2>/dev/null)
        local request_end=$(date +%s%3N)
        local response_time=$((request_end - request_start))
        
        total_requests=$((total_requests + 1))
        total_response_time=$((total_response_time + response_time))
        
        if [[ $response_time -gt $max_response_time ]]; then
            max_response_time=$response_time
        fi
        
        if [[ "$http_code" == "200" ]]; then
            successful_requests=$((successful_requests + 1))
        else
            failed_requests=$((failed_requests + 1))
            echo "$(date): Échec de requête - HTTP $http_code" >> $LOG_FILE
        fi
        
        sleep 1
    done
    
    # Calculer les métriques
    local success_rate=0
    local error_rate=0
    local avg_response_time=0
    
    if [[ $total_requests -gt 0 ]]; then
        success_rate=$(echo "scale=2; $successful_requests * 100 / $total_requests" | bc)
        error_rate=$(echo "scale=2; $failed_requests * 100 / $total_requests" | bc)
        avg_response_time=$(echo "scale=2; $total_response_time / $total_requests" | bc)
    fi
    
    # Récupérer l'ID du déploiement actuel
    current_deployment=$(oc get dc webapp-rolling -o jsonpath='{.status.latestVersion}')
    
    # Sauvegarder les métriques
    cat > $METRICS_FILE << EOF
{
    "timestamp": "$(date -Iseconds)",
    "deployment_version": "$current_deployment",
    "total_requests": $total_requests,
    "successful_requests": $successful_requests,
    "failed_requests": $failed_requests,
    "success_rate": $success_rate,
    "error_rate": $error_rate,
    "avg_response_time": $avg_response_time,
    "max_response_time": $max_response_time,
    "thresholds": {
        "error_rate_threshold": $ERROR_RATE_THRESHOLD,
        "response_time_threshold": $RESPONSE_TIME_THRESHOLD,
        "min_success_rate": $MIN_SUCCESS_RATE
    }
}
EOF
    
    echo "Métriques collectées: Success Rate: $success_rate%, Error Rate: $error_rate%, Avg Response Time: ${avg_response_time}ms"
}

# Fonction d'évaluation de la santé
evaluate_health() {
    local success_rate=$(jq -r '.success_rate' $METRICS_FILE)
    local error_rate=$(jq -r '.error_rate' $METRICS_FILE)
    local avg_response_time=$(jq -r '.avg_response_time' $METRICS_FILE)
    
    local health_issues=()
    
    # Vérification du taux d'erreur
    if (( $(echo "$error_rate > $ERROR_RATE_THRESHOLD" | bc -l) )); then
        health_issues+=("ERROR_RATE_HIGH: $error_rate% > $ERROR_RATE_THRESHOLD%")
    fi
    
    # Vérification du taux de succès
    if (( $(echo "$success_rate < $MIN_SUCCESS_RATE" | bc -l) )); then
        health_issues+=("SUCCESS_RATE_LOW: $success_rate% < $MIN_SUCCESS_RATE%")
    fi
    
    # Vérification du temps de réponse
    if (( $(echo "$avg_response_time > $RESPONSE_TIME_THRESHOLD" | bc -l) )); then
        health_issues+=("RESPONSE_TIME_HIGH: ${avg_response_time}ms > ${RESPONSE_TIME_THRESHOLD}ms")
    fi
    
    if [[ ${#health_issues[@]} -eq 0 ]]; then
        echo "HEALTHY"
        return 0
    else
        echo "UNHEALTHY: ${health_issues[*]}"
        return 1
    fi
}

# Exporter les fonctions pour utilisation dans d'autres scripts
export -f collect_metrics
export -f evaluate_health

# Si le script est exécuté directement
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    collect_metrics
    evaluate_health
fi