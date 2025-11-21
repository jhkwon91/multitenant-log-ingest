#!/bin/bash
set -e

# -------------------------------
# 0. Load .env variables
# -------------------------------
if [ -f .env ]; then
    export $(cat .env | grep -v '#' | awk '/=/ {print $1}')
fi

OPENSEARCH_ADMIN_PASSWORD=${OPENSEARCH_INITIAL_ADMIN_PASSWORD}
OPENSEARCH_HOST="https://localhost:9200"

echo "Waiting for OpenSearch to be fully up..."
until curl -sS -o /dev/null -k "${OPENSEARCH_HOST}"; do
    echo "OpenSearch is unavailable - sleeping"
    sleep 5
done
echo "OpenSearch is up - starting security setup..."
echo ""

# Utility function for checking resource existence
check_resource() {
    local url="$1"
    local name="$2"

    echo "[VERIFY] ${name} ..."

    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" \
        -X GET "${url}" \
        -u admin:${OPENSEARCH_ADMIN_PASSWORD} -k)

    if [ "$http_code" = "200" ]; then
        echo "[OK] ${name} exists."
    else
        echo "[ERROR] ${name} verification failed (HTTP ${http_code})"
        exit 1
    fi

    echo ""
}

# -------------------------------
# 1. Index Template
# -------------------------------
echo "--- 1. Creating Index Template ---"
curl -s -X PUT \
    "${OPENSEARCH_HOST}/_index_template/log_template" \
    -H "Content-Type: application/json" \
    -d @opensearch_templates/log_index_template.json \
    -u admin:${OPENSEARCH_ADMIN_PASSWORD} -k

check_resource "${OPENSEARCH_HOST}/_index_template/log_template" "Index Template: log_template"


# -------------------------------
# 2. Tenants
# -------------------------------
echo "--- 2. Creating Tenants ---"
TENANT_PAYLOAD='{"description": "Custom Tenant"}'

curl -s -X PUT "${OPENSEARCH_HOST}/_plugins/_security/api/tenants/tenanta" \
    -H 'Content-Type: application/json' \
    -d "${TENANT_PAYLOAD}" \
    -u admin:${OPENSEARCH_ADMIN_PASSWORD} -k

curl -s -X PUT "${OPENSEARCH_HOST}/_plugins/_security/api/tenants/tenantb" \
    -H 'Content-Type: application/json' \
    -d "${TENANT_PAYLOAD}" \
    -u admin:${OPENSEARCH_ADMIN_PASSWORD} -k

check_resource "${OPENSEARCH_HOST}/_plugins/_security/api/tenants/tenanta" "Tenant tenanta"
check_resource "${OPENSEARCH_HOST}/_plugins/_security/api/tenants/tenantb" "Tenant tenantb"


# -------------------------------
# 3. Roles from file
# -------------------------------
echo "--- 3. Creating Roles ---"

curl -s -X PUT "${OPENSEARCH_HOST}/_plugins/_security/api/roles/logs_write_role" \
    -H 'Content-Type: application/json' \
    -d @opensearch_security/role_logs_writer.json \
    -u admin:${OPENSEARCH_ADMIN_PASSWORD} -k

curl -s -X PUT "${OPENSEARCH_HOST}/_plugins/_security/api/roles/tenanta_read_role" \
    -H 'Content-Type: application/json' \
    -d @opensearch_security/role_tenanta_read.json \
    -u admin:${OPENSEARCH_ADMIN_PASSWORD} -k

curl -s -X PUT "${OPENSEARCH_HOST}/_plugins/_security/api/roles/tenantb_read_role" \
    -H 'Content-Type: application/json' \
    -d @opensearch_security/role_tenantb_read.json \
    -u admin:${OPENSEARCH_ADMIN_PASSWORD} -k

check_resource "${OPENSEARCH_HOST}/_plugins/_security/api/roles/logs_write_role" "Role logs_write_role"
check_resource "${OPENSEARCH_HOST}/_plugins/_security/api/roles/tenanta_read_role" "Role tenanta_read_role"
check_resource "${OPENSEARCH_HOST}/_plugins/_security/api/roles/tenantb_read_role" "Role tenantb_read_role"

echo "--- Creating opensearch_dashboards_user default role ---"

curl -s -X PUT \
  "${OPENSEARCH_HOST}/_plugins/_security/api/roles/opensearch_dashboards_user" \
  -H "Content-Type: application/json" \
  -d @opensearch_security/role_dashboards_user.json \
  -u admin:${OPENSEARCH_ADMIN_PASSWORD} -k

check_resource \
  "${OPENSEARCH_HOST}/_plugins/_security/api/roles/opensearch_dashboards_user" \
  "Role: opensearch_dashboards_user"


# -------------------------------
# 4. Internal Users
# -------------------------------
echo "--- 4. Creating Internal Users ---"

curl -s -X PUT "${OPENSEARCH_HOST}/_plugins/_security/api/internalusers/logs_writer" \
    -H 'Content-Type: application/json' \
    -d @opensearch_security/user_logs_writer.json \
    -u admin:${OPENSEARCH_ADMIN_PASSWORD} -k

curl -s -X PUT "${OPENSEARCH_HOST}/_plugins/_security/api/internalusers/user_tenanta" \
    -H 'Content-Type: application/json' \
    -d @opensearch_security/user_tenanta.json \
    -u admin:${OPENSEARCH_ADMIN_PASSWORD} -k

curl -s -X PUT "${OPENSEARCH_HOST}/_plugins/_security/api/internalusers/user_tenantb" \
    -H 'Content-Type: application/json' \
    -d @opensearch_security/user_tenantb.json \
    -u admin:${OPENSEARCH_ADMIN_PASSWORD} -k

check_resource "${OPENSEARCH_HOST}/_plugins/_security/api/internalusers/logs_writer" "User logs_writer"
check_resource "${OPENSEARCH_HOST}/_plugins/_security/api/internalusers/user_tenanta" "User user_tenanta"
check_resource "${OPENSEARCH_HOST}/_plugins/_security/api/internalusers/user_tenantb" "User user_tenantb"


# -------------------------------
# 5. Role Mappings
# -------------------------------
echo "--- 5. Role Mappings ---"

curl -s -X PUT "${OPENSEARCH_HOST}/_plugins/_security/api/rolesmapping/logs_write_role" \
    -H 'Content-Type: application/json' \
    -d '{"users": ["logs_writer"]}' \
    -u admin:${OPENSEARCH_ADMIN_PASSWORD} -k

curl -s -X PUT "${OPENSEARCH_HOST}/_plugins/_security/api/rolesmapping/tenanta_read_role" \
  -H 'Content-Type: application/json' \
  -d '{"users": ["user_tenanta"]}' \
  -u admin:${OPENSEARCH_ADMIN_PASSWORD} -k


curl -s -X PUT "${OPENSEARCH_HOST}/_plugins/_security/api/rolesmapping/tenantb_read_role" \
  -H 'Content-Type: application/json' \
  -d '{"users": ["user_tenantb"]}' \
  -u admin:${OPENSEARCH_ADMIN_PASSWORD} -k

curl -s -X PUT "${OPENSEARCH_HOST}/_plugins/_security/api/rolesmapping/opensearch_dashboards_user" \
  -H 'Content-Type: application/json' \
  -d '{"users": ["user_tenanta", "user_tenantb"]}' \
  -u admin:${OPENSEARCH_ADMIN_PASSWORD} -k
  


check_resource "${OPENSEARCH_HOST}/_plugins/_security/api/rolesmapping/logs_write_role" "RoleMapping: logs_write_role"
check_resource "${OPENSEARCH_HOST}/_plugins/_security/api/rolesmapping/tenanta_read_role" "RoleMapping: tenanta_read_role"
check_resource "${OPENSEARCH_HOST}/_plugins/_security/api/rolesmapping/tenantb_read_role" "RoleMapping: tenantb_read_role"
check_resource "${OPENSEARCH_HOST}/_plugins/_security/api/rolesmapping/opensearch_dashboards_user" "RoleMapping: dashboards user"


curl -s -X PUT "https://opensearch-node1:9200/_ingest/pipeline/fluentbit-pipeline" \
    -H 'Content-Type: application/json' \
    -d '{
      "description" : "Fluent Bit Required Pipeline",
      "processors" : [
        { "set" : { "field": "pipeline_check", "value": true } } 
      ]
    }' \
    -u admin:${OPENSEARCH_ADMIN_PASSWORD} -k

echo "Security setup complete."