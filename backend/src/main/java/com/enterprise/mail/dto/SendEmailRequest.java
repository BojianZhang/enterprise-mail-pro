package com.enterprise.mail.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;
import java.util.List;

@Data
public class SendEmailRequest {
    
    @NotBlank(message = "收件人不能为空")
    @Email(message = "收件人邮箱格式不正确")
    private String to;
    
    private List<String> cc;
    
    private List<String> bcc;
    
    @NotBlank(message = "邮件主题不能为空")
    private String subject;
    
    private String contentText;
    
    private String contentHtml;
    
    private List<Long> attachmentIds;
    
    private String aliasId;
    
    private Boolean saveToSent = true;
}