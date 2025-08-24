package com.enterprise.mail.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.util.HashSet;
import java.util.Set;

/**
 * Domain entity for managing email domains
 */
@Entity
@Table(name = "domains")
@Data
@EqualsAndHashCode(callSuper = true)
public class Domain extends BaseEntity {
    
    @Column(unique = true, nullable = false, length = 255)
    private String domainName;
    
    @Column(length = 500)
    private String description;
    
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private DomainStatus status = DomainStatus.PENDING;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "verification_method")
    private VerificationMethod verificationMethod;
    
    @Column(name = "verification_token", length = 100)
    private String verificationToken;
    
    @Column(name = "is_verified")
    private Boolean isVerified = false;
    
    @Column(name = "is_default")
    private Boolean isDefault = false;
    
    @Column(name = "catch_all_enabled")
    private Boolean catchAllEnabled = false;
    
    @Column(name = "catch_all_email")
    private String catchAllEmail;
    
    // DNS Records
    @Column(name = "mx_record", columnDefinition = "TEXT")
    private String mxRecord;
    
    @Column(name = "spf_record", columnDefinition = "TEXT")
    private String spfRecord;
    
    @Column(name = "dkim_selector", length = 100)
    private String dkimSelector;
    
    @Column(name = "dkim_public_key", columnDefinition = "TEXT")
    private String dkimPublicKey;
    
    @Column(name = "dkim_private_key", columnDefinition = "TEXT")
    private String dkimPrivateKey;
    
    @Column(name = "dmarc_record", columnDefinition = "TEXT")
    private String dmarcRecord;
    
    // Limits
    @Column(name = "max_users")
    private Integer maxUsers = 100;
    
    @Column(name = "max_aliases_per_user")
    private Integer maxAliasesPerUser = 10;
    
    @Column(name = "max_storage_gb")
    private Integer maxStorageGb = 100;
    
    @ManyToMany(mappedBy = "domains")
    private Set<User> users = new HashSet<>();
    
    @OneToMany(mappedBy = "domain", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private Set<EmailAlias> aliases = new HashSet<>();
    
    public enum DomainStatus {
        ACTIVE, INACTIVE, PENDING, SUSPENDED
    }
    
    public enum VerificationMethod {
        DNS_TXT, DNS_CNAME, FILE_UPLOAD, META_TAG
    }
}