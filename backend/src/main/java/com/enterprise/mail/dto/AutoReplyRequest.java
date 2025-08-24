package com.enterprise.mail.dto;

import lombok.Data;

@Data
public class AutoReplyRequest {
    private Boolean enabled;
    private String subject;
    private String message;
}