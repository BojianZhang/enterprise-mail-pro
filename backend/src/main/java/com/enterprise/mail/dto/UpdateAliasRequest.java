package com.enterprise.mail.dto;

import lombok.Data;

@Data
public class UpdateAliasRequest {
    private String displayName;
    private String description;
    private String signature;
}