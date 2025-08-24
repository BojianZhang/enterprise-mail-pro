package com.enterprise.mail;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * Enterprise Mail System Application
 * 
 * A complete mail server solution with SMTP, IMAP, and POP3 support.
 * Features include user management, domain management, alias support,
 * and comprehensive security features.
 */
@SpringBootApplication
@EnableCaching
@EnableAsync
@EnableScheduling
public class EnterpriseMailApplication {
    
    public static void main(String[] args) {
        SpringApplication.run(EnterpriseMailApplication.class, args);
        
        System.out.println("""
            
            ======================================
            Enterprise Mail System Started
            ======================================
            API Documentation: http://localhost:8080/api/swagger-ui.html
            Health Check: http://localhost:8080/api/actuator/health
            ======================================
            
            """);
    }
}