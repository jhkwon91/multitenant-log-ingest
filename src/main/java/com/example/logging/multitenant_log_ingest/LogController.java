package com.example.logging.multitenant_log_ingest;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/{tenantId}")
public class LogController {
    private static final Logger logger = LoggerFactory.getLogger(LogController.class);

    @PostMapping("/log")
    public String generateLog(@PathVariable String tenantId, @RequestBody String message) {
        logger.info("Received log for tenant {}: {}", tenantId, message);
        return "Log accepted for " + tenantId;
    }
}
