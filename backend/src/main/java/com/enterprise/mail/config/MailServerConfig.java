package com.enterprise.mail.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

import java.util.List;

/**
 * Mail Server Configuration
 */
@Data
@Configuration
@ConfigurationProperties(prefix = "mail-server")
public class MailServerConfig {
    
    private SmtpConfig smtp = new SmtpConfig();
    private ImapConfig imap = new ImapConfig();
    private Pop3Config pop3 = new Pop3Config();
    private DomainConfig domain = new DomainConfig();
    private StorageConfig storage = new StorageConfig();
    private SecurityConfig security = new SecurityConfig();
    private MailConfig mail = new MailConfig();
    
    @Data
    public static class SmtpConfig {
        private boolean enabled = true;
        private int port = 25;
        private int securePort = 465;
        private int sslPort = 465;  // alias for securePort
        private int maxConnections = 100;
        private boolean authRequired = true;
        private boolean tlsEnabled = true;
        
        public int getSslPort() {
            return securePort;
        }
    }
    
    @Data
    public static class ImapConfig {
        private boolean enabled = true;
        private int port = 143;
        private int securePort = 993;
        private int sslPort = 993;  // alias for securePort
        private int maxConnections = 50;
        
        public int getSslPort() {
            return securePort;
        }
    }
    
    @Data
    public static class Pop3Config {
        private boolean enabled = true;
        private int port = 110;
        private int securePort = 995;
        private int sslPort = 995;  // alias for securePort
        private int maxConnections = 30;
        
        public int getSslPort() {
            return securePort;
        }
    }
    
    @Data
    public static class DomainConfig {
        private String defaultDomain = "enterprise.mail";
        private List<String> allowedDomains = List.of("enterprise.mail", "company.com");
    }
    
    @Data
    public static class StorageConfig {
        private String path = "/var/mail/storage";
        private long maxMailboxSize = 1073741824L; // 1GB
        private long maxMessageSize = 26214400L; // 25MB
    }
    
    @Data
    public static class SecurityConfig {
        private boolean dkimEnabled = true;
        private boolean spfEnabled = true;
        private boolean dmarcEnabled = true;
        private boolean spamFilterEnabled = true;
        private boolean virusScanEnabled = false;
    }
    
    @Data
    public static class MailConfig {
        @Value("${mail.host:localhost}")
        private String host;
        
        @Value("${mail.port:25}")
        private int port;
        
        @Value("${mail.username:}")
        private String username;
        
        @Value("${mail.password:}")
        private String password;
    }
}