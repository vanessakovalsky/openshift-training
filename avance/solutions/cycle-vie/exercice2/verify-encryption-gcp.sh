#!/bin/bash

echo "=== Vérification du chiffrement des StorageClasses ==="
echo

# 1. Lister toutes les StorageClasses
echo "1. StorageClasses disponibles :"
oc get storageclass

echo
echo "=== Analyse détaillée du chiffrement ==="

# 2. Vérifier chaque StorageClass
for sc in $(oc get storageclass -o name | cut -d/ -f2); do
    echo
    echo "--- Analyse de la StorageClass: $sc ---"
    
    # Récupérer les détails
    sc_yaml=$(oc get storageclass $sc -o yaml)
    provisioner=$(echo "$sc_yaml" | yq eval '.provisioner' -)
    
    echo "Provisioner: $provisioner"
    
    # Vérifier les paramètres de chiffrement selon le provisioner
    case $provisioner in
        "ebs.csi.aws.com")
            echo "Type: AWS EBS"
            encrypted=$(echo "$sc_yaml" | yq eval '.parameters.encrypted // "non-spécifié"' -)
            kms_key=$(echo "$sc_yaml" | yq eval '.parameters.kmsKeyId // "non-spécifié"' -)
            echo "  - Chiffrement activé: $encrypted"
            echo "  - Clé KMS: $kms_key"
            ;;
        "disk.csi.azure.com")
            echo "Type: Azure Disk"
            disk_encryption=$(echo "$sc_yaml" | yq eval '.parameters.diskEncryptionSetID // "non-spécifié"' -)
            echo "  - Set de chiffrement: $disk_encryption"
            ;;
        "pd.csi.storage.gke.io")
            echo "Type: Google Cloud Disk"
            encryption_key=$(echo "$sc_yaml" | yq eval '.parameters.disk-encryption-key // "non-spécifié"' -)
            echo "  - Clé de chiffrement: $encryption_key"
            ;;
        "csi.vsphere.vmware.com")
            echo "Type: vSphere"
            policy=$(echo "$sc_yaml" | yq eval '.parameters.storagepolicyname // "non-spécifié"' -)
            echo "  - Politique de stockage: $policy"
            ;;
        *"ceph"*)
            echo "Type: Ceph/OCS"
            # Vérifier les paramètres Ceph
            encrypted=$(echo "$sc_yaml" | yq eval '.parameters.encrypted // "non-spécifié"' -)
            echo "  - Chiffrement activé: $encrypted"
            ;;
        *)
            echo "Type: Autre ($provisioner)"
            ;;
    esac
    
    # Afficher tous les paramètres
    echo "  Paramètres complets:"
    echo "$sc_yaml" | yq eval '.parameters // {}' - | sed 's/^/    /'
done

echo
echo "=== Test de création d'un PVC pour vérifier ==="
echo "Pour tester une StorageClass spécifique, utilisez :"
echo "oc apply -f - <<EOF"
echo "apiVersion: v1"
echo "kind: PersistentVolumeClaim"
echo "metadata:"
echo "  name: test-encryption-pvc"
echo "spec:"
echo "  accessModes:"
echo "    - ReadWriteOnce"
echo "  resources:"
echo "    requests:"
echo "      storage: 1Gi"
echo "  storageClassName: <nom-storageclass>"
echo "EOF"