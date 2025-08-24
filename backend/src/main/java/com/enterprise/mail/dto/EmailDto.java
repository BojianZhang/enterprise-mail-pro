package com.enterprise.mail.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Date;

/**
 * Email DTO for API responses
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class EmailDto {
    private Long id;
    private String messageId;
    private String fromAddress;
    private String fromName;
    private String toAddresses;
    private String ccAddresses;
    private String bccAddresses;
    private String subject;
    private String contentText;
    private String contentHtml;
    private String status;
    private String direction;
    private Date sentDate;
    private Date receivedDate;
    private Boolean isRead;
    private Boolean isStarred;
    private Boolean isImportant;
    private Boolean hasAttachments;
    private Long sizeBytes;
    private Date createdAt;
    private Date updatedAt;
    private Long folderId;
    private String folderName;
    private Long userId;
    private String attachments;
}