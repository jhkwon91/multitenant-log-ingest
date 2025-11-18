#!/bin/bash
set -e

NAMESPACE="observability"
OPENSEARCH_POD="my-opensearch-cluster-master-0"
# Admin 비밀번호는 opensearch-values.yaml에서 설정된 값으로 대체해야 합니다.
ADMIN_PASSWORD="MyNewP@ssw0rd24!" 

echo "--- OpenSearch 초기 인덱스 생성 시작 ---"

# 1. Tenant A 초기 인덱스 생성
echo "생성 중: app-logs-tenant-a"
kubectl exec -it $OPENSEARCH_POD -n $NAMESPACE -- curl -k -XPUT "https://localhost:9200/app-logs-tenant-a" \
  -H "Content-Type: application/json" -u "admin:$ADMIN_PASSWORD" -d "{}"

# 2. Tenant B 초기 인덱스 생성
echo "생성 중: app-logs-tenant-b"
kubectl exec -it $OPENSEARCH_POD -n $NAMESPACE -- curl -k -XPUT "https://localhost:9200/app-logs-tenant-b" \
  -H "Content-Type: application/json" -u "admin:$ADMIN_PASSWORD" -d "{}"

echo -e "\n--- 🎉 초기 인덱스 생성이 완료되었습니다. ---"

# 참고: 인덱스 템플릿은 이 스크립트가 아닌, 별도의 스크립트나 과정을 통해 미리 적용되어 있어야 합니다.
