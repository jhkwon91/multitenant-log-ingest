#!/bin/bash

NAMESPACE="logging"
OPENSEARCH_POD="my-opensearch-cluster-master-0" # OpenSearch Pod 이름 확인 필요
CONFIG_DIR="./config"
ADMIN_PASSWORD="S3cUr3Pa55w0rd123!" # admin 사용자의 초기 비밀번호

# 1. 네임스페이스 및 Pod 상태 확인
if ! kubectl get pod $OPENSEARCH_POD -n $NAMESPACE &> /dev/null; then
  echo "Error: OpenSearch Pod $OPENSEARCH_POD not found in namespace $NAMESPACE."
  exit 1
fi

echo "--- 1. Security 설정 ConfigMap 생성 중 ---"
# 기존 ConfigMap이 있다면 삭제 후 새로 생성
kubectl delete configmap opensearch-security-config -n $NAMESPACE --ignore-not-found=true

kubectl create configmap opensearch-security-config -n $NAMESPACE \
  --from-file=$CONFIG_DIR/internal_users.yml \
  --from-file=$CONFIG_DIR/roles.yml \
  --from-file=$CONFIG_DIR/roles_mapping.yml

echo "--- 2. ConfigMap을 Pod 내부 임시 경로에 복사 중 ---"
# ConfigMap의 내용을 Pod 내부 임시 디렉토리로 복사
kubectl exec -it $OPENSEARCH_POD -n $NAMESPACE -- mkdir -p /tmp/security-config
kubectl cp $CONFIG_DIR/internal_users.yml $NAMESPACE/$OPENSEARCH_POD:/tmp/security-config/internal_users.yml
kubectl cp $CONFIG_DIR/roles.yml $NAMESPACE/$OPENSEARCH_POD:/tmp/security-config/roles.yml
kubectl cp $CONFIG_DIR/roles_mapping.yml $NAMESPACE/$OPENSEARCH_POD:/tmp/security-config/roles_mapping.yml


echo "--- 3. securityadmin 툴을 사용하여 설정 적용 중 ---"
# securityadmin 툴 실행 명령.
# -cd: 설정 파일 디렉토리
# -cacert, -cert, -key: TLS 통신에 필요한 인증서 파일 경로 (Helm Chart가 기본 경로에 생성함)
# -h: 호스트 주소 (localhost:9200)
# -nhnv: 호스트 이름 검증 비활성화 (Minikube 환경에서 필수)
# -icl: 클러스터 내부 인증서 설정 파일 경로


# JKS 옵션 제거, PEM 옵션만 남기고, 인증서 파일 이름 확인 (kirk.pem, kirk-key.pem)
kubectl exec -it $OPENSEARCH_POD -n $NAMESPACE -- bash -c " \
/usr/share/opensearch/plugins/opensearch-security/tools/securityadmin.sh \
-cacert /usr/share/opensearch/config/root-ca.pem \
-cert /usr/share/opensearch/config/kirk.pem \
-key /usr/share/opensearch/config/kirk-key.pem \
-h localhost \
-p 9200 \
-nhnv \
-icl \
-f /tmp/security-config/internal_users.yml \
-f /tmp/security-config/roles.yml \
-f /tmp/security-config/roles_mapping.yml" # -cd 옵션 대신 -f 옵션으로 파일 3개만 지정


if [ $? -eq 0 ]; then
  echo "--- 🎉 OpenSearch Security 설정이 성공적으로 적용되었습니다. ---"
else
  echo "--- ❌ OpenSearch Security 설정 적용 중 오류가 발생했습니다. ---"
fi

echo "--- 4. 임시 디렉토리 정리 ---"
kubectl exec -it $OPENSEARCH_POD -n $NAMESPACE -- rm -rf /tmp/security-config
