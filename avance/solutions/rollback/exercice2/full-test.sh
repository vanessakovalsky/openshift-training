#!/bin/bash

NAMESPACE="rolling-update-demo"

echo "=== Test Complet Rolling Update + Rollback Automatisé ==="

# Vérifier que l'application est déployée
if ! oc get dc webapp-rolling -n $NAMESPACE &>/dev/null; then
    echo "ERREUR: Application non déployée. Exécutez d'abord l'exercice 1."
    exit 1
fi

echo "1. Vérification de l'état initial..."
./auto-rollback.sh check-health

echo -e "\n2. Démarrage du monitoring en arrière-plan..."
./auto-rollback.sh monitor &
MONITOR_PID=$!

# Fonction de nettoyage
cleanup() {
    echo -e "\nArrêt du monitoring..."
    kill $MONITOR_PID 2>/dev/null
    wait $MONITOR_PID 2>/dev/null
}
trap cleanup EXIT

echo -e "\n3. Attente de stabilisation (30s)..."
sleep 30

echo -e "\n4. Déclenchement des conditions dégradées..."
./auto-rollback.sh test-degraded

echo -e "\n5. Observation du rollback automatique (180s)..."
sleep 180

echo -e "\n6. Vérification finale de l'état..."
./auto-rollback.sh check-health

echo -e "\n=== Test terminé ==="