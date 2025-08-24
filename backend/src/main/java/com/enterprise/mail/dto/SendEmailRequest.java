package com.enterprise.mail.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

/**
 * Request DTO for sending emails
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SendEmailRequest {
    
    @NotBlank(message = "Recipient email is required")
    @Email(message = "Invalid recipient email format")
    private String to;
    
    private String cc;
    
    private String bcc;
    
    @NotBlank(message = "Subject is required")
    @Size(max = 255, message = "Subject cannot exceed 255 characters")
    private String subject;
    
    @NotBlank(message = "Email content is required")
    private String content;
    
    private String htmlContent;
    
    private List<MultipartFile> attachments;
    
    private Long replyToId;
    
    private Boolean isImportant;
    
    private Boolean requestReadReceipt;
    
    private String priority; // HIGH, NORMAL, LOW
}