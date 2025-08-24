package com.enterprise.mail.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * Email Attachment entity
 */
@Entity
@Table(name = "email_attachments")
@Data
@EqualsAndHashCode(callSuper = true)
public class EmailAttachment extends BaseEntity {
    
    @Column(nullable = false, length = 255)
    private String filename;
    
    @Column(name = "original_filename", length = 255)
    private String originalFilename;
    
    @Column(name = "content_type", length = 100)
    private String contentType;
    
    @Column(name = "size_bytes")
    private Long sizeBytes;
    
    @Column(name = "storage_path", length = 500)
    private String storagePath;
    
    @Column(name = "content_id", length = 255)
    private String contentId;
    
    @Column(name = "is_inline")
    private Boolean isInline = false;
    
    @Column(name = "checksum", length = 64)
    private String checksum;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "email_id", nullable = false)
    private Email email;
}