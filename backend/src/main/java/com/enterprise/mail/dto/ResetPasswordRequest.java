package com.enterprise.mail.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class ResetPasswordRequest {
    
    @NotBlank(message = "重置令牌不能为空")
    private String token;
    
    @NotBlank(message = "新密码不能为空")
    @Size(min = 6, message = "密码长度不能小于6位")
    private String password;
}