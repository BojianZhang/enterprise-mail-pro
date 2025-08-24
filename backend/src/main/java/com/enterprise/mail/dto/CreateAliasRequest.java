package com.enterprise.mail.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Data;

@Data
public class CreateAliasRequest {
    
    @NotBlank(message = "别名不能为空")
    @Pattern(regexp = "^[a-zA-Z0-9._-]+$", message = "别名格式不正确")
    private String aliasName;
    
    @NotBlank(message = "域名不能为空")
    private String domainName;
    
    private String displayName;
    
    private String description;
    
    private String signature;
}