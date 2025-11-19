function route_app_and_tenant(tag, timestamp, record)
    
    local tenant = record["tenantId"]
    local date_suffix = os.date("-%Y.%m.%d")


    
    -- tenantId가 없거나 비어 있으면 드롭
    if not tenant or tenant == "" then
        -- print("Dropping log: tenantId missing.")
        return -1, timestamp, record
    end

    -- *** 디버깅 출력 시작 ***
    print("--- [LUA DEBUG] ---")
    print("Record Keys: " .. table.concat(collect_keys(record), ", "))
    print("Extracted tenantId: " .. tostring(tenant))
    -- *** 디버깅 출력 끝 ***

    -- 2. tenantId 기반 라우팅 및 인덱스 이름 설정
    if tenant == "tenantA" then
        record["__opensearch_index"] = "logs-tenantA" .. date_suffix
        print("Routing to Index: " .. record["__opensearch_index"])
        return 1, timestamp, record

    elseif tenant == "tenantB" then
        record["__opensearch_index"] = "logs-tenantB" .. date_suffix
        print("Routing to Index: " .. record["__opensearch_index"])
        return 1, timestamp, record

    else
        -- 정의되지 않은 테넌트는 드롭
        print("Dropping log: Unknown tenant (" .. tostring(tenant) .. ")")
        return -1, timestamp, record
    end
end

-- 디버깅을 위해 테이블 키를 문자열로 모으는 헬퍼 함수
function collect_keys(t)
    local keys = {}
    for k, _ in pairs(t) do
        table.insert(keys, k)
    end
    return keys
end