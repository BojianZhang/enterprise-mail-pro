package com.enterprise.mail.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.util.Date;
import java.util.HashSet;
import java.util.Set;

/**
 * Email entity for storing email messages
 */
@Entity
@Table(name = "emails",
    indexes = {
        @Index(name = "idx_email_user_status", columnList = "user_id, status"),
        @Index(name = "idx_email_folder", columnList = "folder_id"),
        @Index(name = "idx_email_sent_date", columnList = "sent_date"),
        @Index(name = "idx_email_from_address", columnList = "from_address"),
        @Index(name = "idx_email_subject", columnList = "subject"),
        @Index(name = "idx_email_message_id", columnList = "message_id")
    }
)
@Data
@EqualsAndHashCode(callSuper = true)
public class Email extends BaseEntity {
    
    @Column(name = "message_id", unique = true, nullable = false, length = 255)
    private String messageId;
    
    @Column(name = "subject", length = 500)
    private String subject;
    
    @Column(name = "from_address", nullable = false, length = 255)
    private String fromAddress;
    
    @Column(name = "from_name", length = 255)
    private String fromName;
    
    @Column(name = "to_addresses", columnDefinition = "TEXT")
    private String toAddresses; // JSON array of addresses
    
    @Column(name = "cc_addresses", columnDefinition = "TEXT")
    private String ccAddresses; // JSON array of addresses
    
    @Column(name = "bcc_addresses", columnDefinition = "TEXT")
    private String bccAddresses; // JSON array of addresses
    
    @Column(name = "reply_to", length = 255)
    private String replyTo;
    
    @Column(name = "content_text", columnDefinition = "LONGTEXT")
    private String contentText;
    
    @Column(name = "content_html", columnDefinition = "LONGTEXT")
    private String contentHtml;
    
    @Column(name = "raw_content", columnDefinition = "LONGTEXT")
    private String rawContent;
    
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private EmailStatus status = EmailStatus.UNREAD;
    
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private EmailType type = EmailType.RECEIVED;
    
    @Column(name = "is_starred")
    private Boolean isStarred = false;
    
    @Column(name = "is_important")
    private Boolean isImportant = false;
    
    @Column(name = "is_spam")
    private Boolean isSpam = false;
    
    @Column(name = "is_draft")
    private Boolean isDraft = false;
    
    @Column(name = "has_attachments")
    private Boolean hasAttachments = false;
    
    @Column(name = "attachment_count")
    private Integer attachmentCount = 0;
    
    @Column(name = "size_bytes")
    private Long sizeBytes = 0L;
    
    @Column(name = "sent_date")
    @Temporal(TemporalType.TIMESTAMP)
    private Date sentDate;
    
    @Column(name = "received_date")
    @Temporal(TemporalType.TIMESTAMP)
    private Date receivedDate;
    
    @Column(name = "spam_score")
    private Double spamScore;
    
    @Column(name = "virus_scan_result", length = 100)
    private String virusScanResult;
    
    @Column(name = "dkim_valid")
    private Boolean dkimValid;
    
    @Column(name = "spf_result", length = 50)
    private String spfResult;
    
    @Column(name = "dmarc_result", length = 50)
    private String dmarcResult;
    
    @Column(name = "headers", columnDefinition = "TEXT")
    private String headers; // JSON object of email headers
    
    @Column(name = "labels", length = 500)
    private String labels; // Comma-separated labels
    
    @Column(name = "thread_id", length = 100)
    private String threadId;
    
    @Column(name = "in_reply_to", length = 255)
    private String inReplyTo;
    
    @Column(name = "references", columnDefinition = "TEXT")
    private String references;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "alias_id")
    private EmailAlias alias;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "folder_id")
    private EmailFolder folder;
    
    @OneToMany(mappedBy = "email", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private Set<EmailAttachment> attachments = new HashSet<>();
    
    public enum EmailStatus {
        UNREAD, READ, REPLIED, FORWARDED, DELETED
    }
    
    public enum EmailType {
        RECEIVED, SENT, DRAFT
    }
}