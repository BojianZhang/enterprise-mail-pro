package com.enterprise.mail.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.beans.factory.annotation.Value;
import lombok.RequiredArgsConstructor;

import java.util.Arrays;
import java.util.List;

/**
 * Enhanced security configuration with proper CORS, CSP, and security headers
 */
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
@RequiredArgsConstructor
public class EnhancedSecurityConfig {
    
    private final JwtAuthenticationFilter jwtAuthenticationFilter;
    private final JwtAuthenticationEntryPoint jwtAuthenticationEntryPoint;
    
    @Value("${cors.allowed-origins:http://localhost:3000}")
    private String allowedOrigins;
    
    @Value("${security.enable-csrf:false}")
    private boolean enableCsrf;
    
    @Value("${security.enable-frame-options:true}")
    private boolean enableFrameOptions;
    
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        // Basic security configuration
        http.cors(cors -> cors.configurationSource(corsConfigurationSource()))
            .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .exceptionHandling(exception -> exception.authenticationEntryPoint(jwtAuthenticationEntryPoint));
        
        // CSRF configuration
        if (!enableCsrf) {
            http.csrf(csrf -> csrf.disable());
        }
        
        // Security headers
        http.headers(headers -> {
            headers.contentSecurityPolicy(csp -> 
                csp.policyDirectives("default-src 'self'; " +
                    "script-src 'self' 'unsafe-inline' 'unsafe-eval'; " +
                    "style-src 'self' 'unsafe-inline'; " +
                    "img-src 'self' data: https:; " +
                    "font-src 'self' data:; " +
                    "connect-src 'self'; " +
                    "frame-ancestors 'none';"));
            
            if (enableFrameOptions) {
                headers.frameOptions(frame -> frame.sameOrigin());
            }
            
            headers.xssProtection(xss -> xss.enable());
            headers.contentTypeOptions(content -> content.disable());
        });
        
        // Authorization rules
        http.authorizeHttpRequests(auth -> auth
            // Public endpoints
            .requestMatchers("/api/auth/login", "/api/auth/register", "/api/auth/forgot-password").permitAll()
            .requestMatchers("/api/auth/reset-password", "/api/auth/verify-reset-token").permitAll()
            .requestMatchers("/api/actuator/health", "/api/actuator/info").permitAll()
            .requestMatchers("/api/docs/**", "/swagger-ui/**", "/v3/api-docs/**").permitAll()
            
            // Admin endpoints
            .requestMatchers("/api/admin/**").hasRole("ADMIN")
            .requestMatchers("/api/users/**").hasAnyRole("ADMIN", "USER")
            
            // All other endpoints require authentication
            .anyRequest().authenticated()
        );
        
        // Add JWT filter
        http.addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);
        
        return http.build();
    }
    
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOrigins(Arrays.asList(allowedOrigins.split(",")));
        configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"));
        configuration.setAllowedHeaders(Arrays.asList("Authorization", "Content-Type", "X-Requested-With"));
        configuration.setExposedHeaders(Arrays.asList("X-Total-Count", "X-Page-Number", "X-Page-Size"));
        configuration.setAllowCredentials(true);
        configuration.setMaxAge(3600L);
        
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/api/**", configuration);
        return source;
    }
}