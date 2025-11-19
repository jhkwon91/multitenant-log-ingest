#!/bin/bash
set -e

NAMESPACE="logging"
POD="my-opensearch-cluster-master-0"
ADMIN_PASSWORD="MyNewP@ssw0rd24!"

echo "==============================================="
echo "📌 OpenSearch 로그 템플릿 & 초기 인덱스 자동 생성"
echo "==============================================="

##########################################
# 1) 공통 템플릿 파일 생성 (Pod 내부로 직접 POST)
##########################################

echo "📌 공통 템플릿 등록(app-logs-template)"

kubectl exec -i $POD -n $NAMESPACE -- curl -k \
  -XPUT "https://localhost:9200/_index_template/app-logs-template" \
  -H "Content-Type: application/json" \
  -u "admin:$ADMIN_PASSWORD" \
  -d '{
    "index_patterns": ["app-logs-tenant-*"],
    "template": {
      "settings": {
        "index.number_of_shards": 1,
        "index.number_of_replicas": 0
      },
      "mappings": {
        "properties": {
          "@timestamp": { "type": "date" },
          "tenant_id": { "type": "keyword" },
          "service_name": { "type": "keyword" },
          "message": { "type": "text" },

          "log.level": { "type": "keyword" },
          "trace.id": { "type": "keyword" },
          "span.id": { "type": "keyword" },
          "host.name": { "type": "keyword" },
          "container.id": { "type": "keyword" },

          "attributes": { "type": "object", "enabled": false }
        }
      }
    }
  }'

echo "✅ 공통 템플릿(app-logs-template) 등록 완료"


##########################################
# 2) 초기 인덱스 생성 (템플릿 자동 적용)
##########################################

echo "📌 Tenant A 초기 인덱스 생성: app-logs-tenant-a-000001"
kubectl exec -i $POD -n $NAMESPACE -- curl -k \
  -XPUT "https://localhost:9200/app-logs-tenant-a-000001" \
  -H "Content-Type: application/json" \
  -u "admin:$ADMIN_PASSWORD" \
  -d "{}"


echo "📌 Tenant B 초기 인덱스 생성: app-logs-tenant-b-000001"
kubectl exec -i $POD -n $NAMESPACE -- curl -k \
  -XPUT "https://localhost:9200/app-logs-tenant-b-000001" \
  -H "Content-Type: application/json" \
  -u "admin:$ADMIN_PASSWORD" \
  -d "{}"


##########################################
# 3) 생성 현황 출력
##########################################

echo "📌 현재 인덱스 목록:"
kubectl exec -i $POD -n $NAMESPACE -- curl -k \
  -XGET "https://localhost:9200/_cat/indices?v" \
  -u "admin:$ADMIN_PASSWORD"

echo "🎉 모든 작업 완료!"
echo "Tenant A/B 인덱스 생성 + 템플릿 적용이 정상 완료되었습니다."

