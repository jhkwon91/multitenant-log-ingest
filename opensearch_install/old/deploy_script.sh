#!/bin/bash

set -e

NAMESPACE="observability"
RELEASE_NAME="opensearch"

echo "=== OpenSearch 배포 스크립트 ==="

# 1. 네임스페이스 생성
echo "1. 네임스페이스 생성..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# 2. Helm 차트 저장소 추가
echo "2. Helm 저장소 추가..."
helm repo add opensearch https://opensearch-project.github.io/helm-charts/
helm repo update

# 3. 기존 배포 삭제 (있는 경우)
echo "3. 기존 배포 확인 및 삭제..."
if helm list -n $NAMESPACE | grep -q $RELEASE_NAME; then
    echo "기존 배포 발견. 삭제 중..."
    helm uninstall $RELEASE_NAME -n $NAMESPACE
    kubectl delete pvc -n $NAMESPACE -l app.kubernetes.io/name=opensearch || true
    sleep 10
fi

# 4. OpenSearch 배포
echo "4. OpenSearch 배포 중..."
helm install $RELEASE_NAME opensearch/opensearch \
  -n $NAMESPACE \
  -f opensearch-values.yaml

# 5. Pod 시작 대기
echo "5. OpenSearch Pod 시작 대기 중..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=opensearch \
  -n $NAMESPACE --timeout=300s

echo "6. OpenSearch 상태 확인..."
kubectl get pods -n $NAMESPACE

# 7. 보안 설정 ConfigMap 생성
echo "7. 보안 설정 ConfigMap 생성..."
kubectl create configmap opensearch-security-config \
  -n $NAMESPACE \
  --from-file=internal_users.yml \
  --from-file=roles.yml \
  --from-file=roles_mapping.yml --from-literal=logs_writer_password=logs_writer \
  --dry-run=client -o yaml | kubectl apply -f -

# 8. 보안 설정 적용을 위한 Job 생성
echo "8. 보안 설정 적용 Job 생성..."
cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: opensearch-security-init
  namespace: $NAMESPACE
spec:
  template:
    spec:
      containers:
      - name: security-init
        image: opensearchproject/opensearch:latest
        command: ["/bin/bash"]
        args:
          - "-c"
          - |
            echo "Copying security config files..."
            cp /security-config/* /usr/share/opensearch/config/opensearch-security/
            
            echo "Applying security configuration..."
            cd /usr/share/opensearch/plugins/opensearch-security/tools
            ./securityadmin.sh \
              -cd /usr/share/opensearch/config/opensearch-security/ \
              -icl -nhnv \
              -cacert /usr/share/opensearch/config/root-ca.pem \
              -cert /usr/share/opensearch/config/kirk.pem \
              -key /usr/share/opensearch/config/kirk-key.pem \
              -h opensearch-cluster-master
            
            echo "Security configuration applied successfully!"
        volumeMounts:
        - name: security-config
          mountPath: /security-config
      volumes:
      - name: security-config
        configMap:
          name: opensearch-security-config
      restartPolicy: OnFailure
  backoffLimit: 3
EOF

# 9. Job 완료 대기
echo "9. 보안 설정 적용 대기 중..."
kubectl wait --for=condition=complete job/opensearch-security-init \
  -n $NAMESPACE --timeout=300s

# 10. 테스트
echo "10. 연결 테스트..."
POD_NAME=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=opensearch -o jsonpath='{.items[0].metadata.name}')

echo "Admin 사용자 테스트..."
kubectl exec -n $NAMESPACE $POD_NAME -- curl -k -u admin:admin https://localhost:9200/_cluster/health?pretty

echo ""
echo "=== 배포 완료! ==="
echo ""
echo "다음 명령어로 포트 포워딩을 설정하세요:"
echo "kubectl port-forward -n $NAMESPACE svc/opensearch-cluster-master 9200:9200"
echo ""
echo "테스트 명령어:"
echo "curl -k -u admin:admin https://localhost:9200"
echo "curl -k -u user_tenantA:user_tenantA https://localhost:9200/app-logs-tenantA-*/_search"
