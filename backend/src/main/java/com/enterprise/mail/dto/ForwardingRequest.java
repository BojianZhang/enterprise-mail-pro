package com.enterprise.mail.dto;

import lombok.Data;
import java.util.List;

@Data
public class ForwardingRequest {
    private Boolean enabled;
    private List<String> forwardTo;
}