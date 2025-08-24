package com.enterprise.mail.dto;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class AliasDto {
    private Long id;
    private String aliasAddress;
    private String displayName;
    private String description;
    private String status;
    private String type;
    private Boolean isPrimary;
    private Boolean forwardEnabled;
    private String forwardTo;
    private Boolean autoReplyEnabled;
    private String autoReplySubject;
    private String autoReplyMessage;
    private String signature;
    private Long quotaBytes;
    private Long usedBytes;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}