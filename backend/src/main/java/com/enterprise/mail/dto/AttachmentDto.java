package com.enterprise.mail.dto;

import lombok.Data;

@Data
public class AttachmentDto {
    private Long id;
    private String filename;
    private String originalFilename;
    private String contentType;
    private Long sizeBytes;
    private String downloadUrl;
    private Boolean isInline;
}