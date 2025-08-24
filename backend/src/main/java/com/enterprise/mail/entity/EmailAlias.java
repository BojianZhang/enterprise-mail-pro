package com.enterprise.mail.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.util.HashSet;
import java.util.Set;

/**
 * Email Alias entity for managing email aliases
 */
@Entity
@Table(name = "email_aliases")
@Data
@EqualsAndHashCode(callSuper = true)
public class EmailAlias extends BaseEntity {
    
    @Column(name = "alias_address", unique = true, nullable = false, length = 255)
    private String aliasAddress;
    
    @Column(name = "display_name", length = 255)
    private String displayName;
    
    @Column(length = 500)
    private String description;
    
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private AliasStatus status = AliasStatus.ACTIVE;
    
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private AliasType type = AliasType.STANDARD;
    
    @Column(name = "is_primary")
    private Boolean isPrimary = false;
    
    @Column(name = "forward_enabled")
    private Boolean forwardEnabled = false;
    
    @Column(name = "forward_to", length = 500)
    private String forwardTo; // Comma-separated email addresses
    
    @Column(name = "auto_reply_enabled")
    private Boolean autoReplyEnabled = false;
    
    @Column(name = "auto_reply_subject", length = 255)
    private String autoReplySubject;
    
    @Column(name = "auto_reply_message", columnDefinition = "TEXT")
    private String autoReplyMessage;
    
    @Column(name = "signature", columnDefinition = "TEXT")
    private String signature;
    
    @Column(name = "smtp_password", length = 255)
    private String smtpPassword;
    
    @Column(name = "quota_bytes")
    private Long quotaBytes = 1073741824L; // 1GB default
    
    @Column(name = "used_bytes")
    private Long usedBytes = 0L;
    
    @Column(name = "max_send_per_day")
    private Integer maxSendPerDay = 500;
    
    @Column(name = "sent_today")
    private Integer sentToday = 0;
    
    @Column(name = "catch_all")
    private Boolean catchAll = false;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "domain_id", nullable = false)
    private Domain domain;
    
    @OneToMany(mappedBy = "alias", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private Set<Email> emails = new HashSet<>();
    
    @OneToMany(mappedBy = "alias", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private Set<EmailRule> rules = new HashSet<>();
    
    public enum AliasStatus {
        ACTIVE, INACTIVE, SUSPENDED, DELETED
    }
    
    public enum AliasType {
        STANDARD, TEMPORARY, HACKERONE, CATCH_ALL
    }
}