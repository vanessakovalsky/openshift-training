#!/bin/bash

ROUTE_URL=$(oc get route webapp-rolling-route -o jsonpath='{.spec.host}')
NAMESPACE="rolling-update-demo"

echo "Monitoring Rolling Update for $ROUTE_URL"
echo "Starting continuous monitoring..."

# Fonction de monitoring
monitor_update() {
    local start_time=$(date +%s)
    local request_count=0
    local error_count=0
    local versions_seen=()
    
    while true; do
        request_count=$((request_count + 1))
        
        # Test de disponibilité
        response=$(curl -s -w "%{http_code}" -o /tmp/response.html "https://$ROUTE_URL" 2>/dev/null)
        http_code="${response: -3}"
        
        if [[ "$http_code" == "200" ]]; then
            # Extraire la version depuis la réponse
            version=$(grep -o 'Version: [0-9.]*' /tmp/response.html | cut -d' ' -f2)
            if [[ ! " ${versions_seen[@]} " =~ " $version " ]]; then
                versions_seen+=("$version")
                echo "[$(date '+%H:%M:%S')] Nouvelle version détectée: $version"
            fi
            echo -n "."
        else
            error_count=$((error_count + 1))
            echo "[$(date '+%H:%M:%S')] ERREUR - HTTP $http_code"
        fi
        
        # Statistiques toutes les 10 secondes
        if (( request_count % 10 == 0 )); then
            current_time=$(date +%s)
            elapsed=$((current_time - start_time))
            error_rate=$(echo "scale=2; $error_count * 100 / $request_count" | bc)
            echo ""
            echo "[$(date '+%H:%M:%S')] Stats: ${request_count} requêtes, ${error_count} erreurs (${error_rate}%), ${elapsed}s écoulées"
            echo "Versions vues: ${versions_seen[*]}"
        fi
        
        sleep 1
    done
}

# Démarrer le monitoring en arrière-plan
monitor_update &
MONITOR_PID=$!

# Fonction de nettoyage
cleanup() {
    echo ""
    echo "Arrêt du monitoring..."
    kill $MONITOR_PID 2>/dev/null
    rm -f /tmp/response.html
    exit 0
}

trap cleanup SIGINT SIGTERM

wait $MONITOR_PID