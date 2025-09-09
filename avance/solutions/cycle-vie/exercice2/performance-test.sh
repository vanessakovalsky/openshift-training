#!/bin/bash
set -e

NAMESPACE="secure-storage"
TEST_FILE_SIZE="100M"

echo "⚡ Test de performance du stockage chiffré"
echo "=========================================="

# Créer un pod de test
create_test_pod() {
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: storage-performance-test
  namespace: $NAMESPACE
spec:
  restartPolicy: Never
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 1000
  containers:
  - name: test
    image: ubuntu:22.04
    command: ["sleep", "3600"]
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: false
      runAsNonRoot: true
      runAsUser: 1000
      capabilities:
        drop:
        - ALL
    volumeMounts:
    - name: test-storage
      mountPath: /test
    resources:
      requests:
        memory: "128Mi"
        cpu: "250m"
      limits:
        memory: "256Mi"
        cpu: "500m"
  volumes:
  - name: test-storage
    persistentVolumeClaim:
      claimName: performance-test-pvc
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: performance-test-pvc
  namespace: $NAMESPACE
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: encrypted-ssd
  resources:
    requests:
      storage: 1Gi
EOF

    echo "⏳ Attente du démarrage du pod de test..."
    kubectl wait --for=condition=ready pod/storage-performance-test -n $NAMESPACE --timeout=300s
}

# Test d'écriture
test_write_performance() {
    echo "📝 Test de performance d'écriture..."
    
    WRITE_TIME=$(kubectl exec storage-performance-test -n $NAMESPACE -- \
        bash -c "time dd if=/dev/zero of=/test/testfile bs=1M count=100 2>&1" | \
        grep real | awk '{print $2}')
    
    echo "  - Temps d'écriture de ${TEST_FILE_SIZE}: $WRITE_TIME"
    
    # Calculer le débit
    WRITE_THROUGHPUT=$(kubectl exec storage-performance-test -n $NAMESPACE -- \
        bash -c "dd if=/dev/zero of=/test/testfile2 bs=1M count=100 2>&1 | grep copied" | \
        awk '{print $(NF-1), $NF}')
    
    echo "  - Débit d'écriture: $WRITE_THROUGHPUT"
}

# Test de lecture
test_read_performance() {
    echo "📖 Test de performance de lecture..."
    
    READ_TIME=$(kubectl exec storage-performance-test -n $NAMESPACE -- \
        bash -c "time dd if=/test/testfile of=/dev/null bs=1M 2>&1" | \
        grep real | awk '{print $2}')
    
    echo "  - Temps de lecture de ${TEST_FILE_SIZE}: $READ_TIME"
    
    # Test de débit de lecture
    READ_THROUGHPUT=$(kubectl exec storage-performance-test -n $NAMESPACE -- \
        bash -c "dd if=/test/testfile of=/dev/null bs=1M 2>&1 | grep copied" | \
        awk '{print $(NF-1), $NF}')
    
    echo "  - Débit de lecture: $READ_THROUGHPUT"
}

# Test IOPS
test_iops() {
    echo "🚀 Test IOPS..."
    
    kubectl exec storage-performance-test -n $NAMESPACE -- \
        bash -c "apt-get update && apt-get install -y fio" > /dev/null
    
    # Test IOPS en écriture
    WRITE_IOPS=$(kubectl exec storage-performance-test -n $NAMESPACE -- \
        fio --name=random-write --ioengine=libaio --iodepth=1 --rw=randwrite \
        --bs=4k --direct=1 --size=100M --numjobs=1 --runtime=30 \
        --filename=/test/iops-test --group_reporting --output-format=json | \
        jq '.jobs[0].write.iops')
    
    echo "  - IOPS écriture: $WRITE_IOPS"
    
    # Test IOPS en lecture
    READ_IOPS=$(kubectl exec storage-performance-test -n $NAMESPACE -- \
        fio --name=random-read --ioengine=libaio --iodepth=1 --rw=randread \
        --bs=4k --direct=1 --size=100M --numjobs=1 --runtime=30 \
        --filename=/test/iops-test --group_reporting --output-format=json | \
        jq '.jobs[0].read.iops')
    
    echo "  - IOPS lecture: $READ_IOPS"
}

# Nettoyage
cleanup() {
    echo "🧹 Nettoyage..."
    kubectl delete pod storage-performance-test -n $NAMESPACE --ignore-not-found
    kubectl delete pvc performance-test-pvc -n $NAMESPACE --ignore-not-found
}

# Exécution principale
main() {
    create_test_pod
    test_write_performance
    test_read_performance
    test_iops
    cleanup
    
    echo "🎉 Test de performance terminé!"
}

# Gestion des signaux pour le nettoyage
trap cleanup EXIT

main