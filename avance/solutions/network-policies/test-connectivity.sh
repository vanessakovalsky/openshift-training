#!/bin/bash
# test-network-connectivity.sh

NAMESPACE=$1
SOURCE_POD=$2
TARGET_SERVICE=$3
TARGET_PORT=$4

echo "Testing network connectivity..."
echo "Source: $SOURCE_POD in $NAMESPACE"
echo "Target: $TARGET_SERVICE:$TARGET_PORT"

# Test de connectivité -> necessite que netcat soit installé dans le conteneur source 
RESULT=$(oc exec -n $NAMESPACE deployment/$SOURCE_POD -- \
  nc -zv $TARGET_SERVICE $TARGET_PORT 2>&1)

if echo "$RESULT" | grep -q "succeeded"; then
    echo "✅ Connection successful"
    echo "$RESULT"
else
    echo "❌ Connection failed"
    echo "$RESULT"
    
    # Debug information
    echo ""
    echo "Debug information:"
    echo "1. Source pod labels:"
    oc get pod -n $NAMESPACE -l app=$SOURCE_POD --show-labels
    
    echo "2. Target service:"
    oc get service -n $NAMESPACE $TARGET_SERVICE
    
    echo "3. Active NetworkPolicies:"
    oc get networkpolicies -n $NAMESPACE
fi