#!/bin/bash
set -e

NAMESPACE="secure-storage"
STORAGE_CLASS="encrypted-ssd"

echo "🔐 Vérification du chiffrement des volumes AWS EBS"
echo "================================================="

# Fonction pour vérifier le chiffrement d'un volume EBS
verify_ebs_encryption() {
    local pv_name=$1
    echo "🔍 Vérification du volume: $pv_name"
    
    # Récupérer l'ID du volume EBS
    VOLUME_ID=$(kubectl get pv $pv_name -o jsonpath='{.spec.csi.volumeHandle}')
    
    if [ -z "$VOLUME_ID" ]; then
        echo "❌ Impossible de récupérer l'ID du volume"
        return 1
    fi
    
    echo "📦 Volume EBS ID: $VOLUME_ID"
    
    # Vérifier le chiffrement via AWS CLI
    ENCRYPTION_STATUS=$(aws ec2 describe-volumes \
        --volume-ids $VOLUME_ID \
        --query 'Volumes[0].Encrypted' \
        --output text)
    
    KMS_KEY_ID=$(aws ec2 describe-volumes \
        --volume-ids $VOLUME_ID \
        --query 'Volumes[0].KmsKeyId' \
        --output text)
    
    if [ "$ENCRYPTION_STATUS" = "True" ]; then
        echo "✅ Volume chiffré avec la clé KMS: $KMS_KEY_ID"
        return 0
    else
        echo "❌ Volume NON chiffré"
        return 1
    fi
}

# Lister tous les PV utilisant la StorageClass chiffrée
echo "🔍 Recherche des volumes utilisant la StorageClass: $STORAGE_CLASS"
PV_LIST=$(kubectl get pv -o json | jq -r --arg sc "$STORAGE_CLASS" '
    .items[] | 
    select(.spec.storageClassName == $sc) | 
    .metadata.name
')

if [ -z "$PV_LIST" ]; then
    echo "❌ Aucun volume trouvé avec la StorageClass: $STORAGE_CLASS"
    exit 1
fi

# Vérifier chaque volume
FAILED_COUNT=0
TOTAL_COUNT=0

for PV in $PV_LIST; do
    TOTAL_COUNT=$((TOTAL_COUNT + 1))
    if ! verify_ebs_encryption "$PV"; then
        FAILED_COUNT=$((FAILED_COUNT + 1))
    fi
    echo ""
done

echo "📊 Résumé:"
echo "  - Volumes vérifiés: $TOTAL_COUNT"
echo "  - Volumes chiffrés: $((TOTAL_COUNT - FAILED_COUNT))"
echo "  - Volumes non-chiffrés: $FAILED_COUNT"

if [ $FAILED_COUNT -eq 0 ]; then
    echo "🎉 Tous les volumes sont correctement chiffrés!"
    exit 0
else
    echo "❌ Certains volumes ne sont pas chiffrés!"
    exit 1
fi