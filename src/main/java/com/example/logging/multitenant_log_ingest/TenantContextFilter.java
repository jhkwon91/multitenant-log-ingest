package com.example.logging.multitenant_log_ingest;

import org.slf4j.MDC;
import jakarta.servlet.*;
import jakarta.servlet.http.HttpServletRequest;
import java.io.IOException;

public class TenantContextFilter implements Filter {

    private static final String TENANT_ID_KEY = "tenantId";

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest httpRequest = (HttpServletRequest) request;
        String tenantId = extractTenantIdFromPath(httpRequest.getRequestURI());

        try {
            if (tenantId != null) {
                MDC.put(TENANT_ID_KEY, tenantId);
            }
            chain.doFilter(request, response);
        } finally {
            MDC.remove(TENANT_ID_KEY);
        }
    }

    private String extractTenantIdFromPath(String path) {
        if (path == null) return null;

        String[] segments = path.split("/");
        if (segments.length > 2 && "api".equals(segments[1])) {
            return segments[2]; // /api/tenantA/log → tenantA
        }
        return null;
    }
}

