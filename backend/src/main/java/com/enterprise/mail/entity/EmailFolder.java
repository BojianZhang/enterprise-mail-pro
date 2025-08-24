package com.enterprise.mail.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * Email Folder entity for organizing emails
 */
@Entity
@Table(name = "email_folders")
@Data
@EqualsAndHashCode(callSuper = true)
public class EmailFolder extends BaseEntity {
    
    @Column(nullable = false, length = 100)
    private String name;
    
    @Column(length = 500)
    private String description;
    
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private FolderType type = FolderType.CUSTOM;
    
    @Column(name = "icon", length = 50)
    private String icon;
    
    @Column(name = "color", length = 7)
    private String color;
    
    @Column(name = "sort_order")
    private Integer sortOrder = 0;
    
    @Column(name = "is_system")
    private Boolean isSystem = false;
    
    @Column(name = "unread_count")
    private Integer unreadCount = 0;
    
    @Column(name = "total_count")
    private Integer totalCount = 0;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "parent_id")
    private EmailFolder parent;
    
    public enum FolderType {
        INBOX, SENT, DRAFTS, TRASH, SPAM, ARCHIVE, CUSTOM
    }
}