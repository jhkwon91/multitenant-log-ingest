package com.example.logging.multitenant_log_ingest;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Bean;

@SpringBootApplication
public class MultitenantLogIngestApplication {

	public static void main(String[] args) {
		SpringApplication.run(MultitenantLogIngestApplication.class, args);
	}

    @Bean
    public FilterRegistrationBean<TenantContextFilter> tenantFilter() {
        FilterRegistrationBean<TenantContextFilter> bean = new FilterRegistrationBean<>();
        bean.setFilter(new TenantContextFilter());
        bean.addUrlPatterns("/api/*");
        bean.setOrder(1);
        return bean;
    }
}
