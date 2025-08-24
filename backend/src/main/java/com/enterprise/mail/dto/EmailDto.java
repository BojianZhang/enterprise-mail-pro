package com.enterprise.mail.dto;

import lombok.Data;
import java.time.LocalDateTime;
import java.util.List;

@Data
public class EmailDto {
    private Long id;
    private String messageId;
    private String subject;
    private String fromAddress;
    private String fromName;
    private List<String> toAddresses;
    private List<String> ccAddresses;
    private List<String> bccAddresses;
    private String contentText;
    private String contentHtml;
    private String status;
    private String type;
    private Boolean isStarred;
    private Boolean isImportant;
    private Boolean isSpam;
    private Boolean isDraft;
    private Boolean hasAttachments;
    private Integer attachmentCount;
    private Long sizeBytes;
    private LocalDateTime sentDate;
    private LocalDateTime receivedDate;
    private String folderName;
    private List<AttachmentDto> attachments;
}