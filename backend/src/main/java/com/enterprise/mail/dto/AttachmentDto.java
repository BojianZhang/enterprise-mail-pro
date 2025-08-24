package com.enterprise.mail.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Date;

/**
 * Attachment DTO for file uploads
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AttachmentDto {
    private Long id;
    private String fileName;
    private String originalFileName;
    private String contentType;
    private Long fileSize;
    private String storagePath;
    private String downloadUrl;
    private Date uploadDate;
    private Long emailId;
    private Long userId;
    private String checksum;
    private Boolean isInline;
    private String contentId;
}