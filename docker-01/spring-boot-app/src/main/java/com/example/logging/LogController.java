package com.example.logging;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class LogController {

    private static final Logger logger = LoggerFactory.getLogger(LogController.class);

    @GetMapping("/api/{tenantId}")
    public String receiveLog(@PathVariable String tenantId) {

        // 1) MDC에 tenantId 저장 (JSON 로그에 포함됨)
        MDC.put("tenantId", tenantId);

        try {
            String message = "Processing request for log event";
            logger.info("Received log for tenant {}: {}", tenantId, message);

            // 데모용 WARN 로그
            if (tenantId.equals("tenantA")) {
                logger.warn("Potential issue detected in Tenant A processing.");
            }

            return "Log received and processed for tenant: " + tenantId;

        } finally {
            // 요청 종료 후 MDC 클리어 (메모리 누수 방지)
            MDC.clear();
        }
    }
}