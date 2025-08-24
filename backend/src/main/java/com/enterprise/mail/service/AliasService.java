package com.enterprise.mail.service;

import com.enterprise.mail.dto.*;
import com.enterprise.mail.entity.EmailAlias;
import com.enterprise.mail.entity.User;
import com.enterprise.mail.entity.Domain;
import com.enterprise.mail.repository.EmailAliasRepository;
import com.enterprise.mail.repository.DomainRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Alias Service - 别名管理服务
 */
@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class AliasService {
    
    private final EmailAliasRepository aliasRepository;
    private final DomainRepository domainRepository;
    private final UserService userService;
    
    /**
     * 获取用户的别名列表
     */
    public Page<AliasDto> getUserAliases(String username, Pageable pageable) {
        User user = userService.findByUsername(username)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        
        Page<EmailAlias> aliases = aliasRepository.findByUserId(user.getId(), pageable);
        return aliases.map(this::toDto);
    }
    
    /**
     * 获取别名详情
     */
    public AliasDto getAlias(Long aliasId, String username) {
        EmailAlias alias = findAliasWithPermission(aliasId, username);
        return toDto(alias);
    }
    
    /**
     * 创建别名
     */
    public AliasDto createAlias(CreateAliasRequest request, String username) {
        User user = userService.findByUsername(username)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        
        // 检查别名是否已存在
        String fullAddress = request.getAliasName() + "@" + request.getDomainName();
        if (aliasRepository.existsByAliasAddress(fullAddress)) {
            throw new IllegalArgumentException("Alias already exists: " + fullAddress);
        }
        
        // 获取域名
        Domain domain = domainRepository.findByDomainName(request.getDomainName())
                .orElseThrow(() -> new IllegalArgumentException("Domain not found"));
        
        // 创建别名
        EmailAlias alias = new EmailAlias();
        alias.setAliasAddress(fullAddress);
        alias.setDisplayName(request.getDisplayName());
        alias.setDescription(request.getDescription());
        alias.setUser(user);
        alias.setDomain(domain);
        alias.setStatus(EmailAlias.AliasStatus.ACTIVE);
        alias.setType(EmailAlias.AliasType.STANDARD);
        
        alias = aliasRepository.save(alias);
        log.info("Created alias: {} for user: {}", fullAddress, username);
        
        return toDto(alias);
    }
    
    /**
     * 更新别名
     */
    public AliasDto updateAlias(Long aliasId, UpdateAliasRequest request, String username) {
        EmailAlias alias = findAliasWithPermission(aliasId, username);
        
        if (request.getDisplayName() != null) {
            alias.setDisplayName(request.getDisplayName());
        }
        if (request.getDescription() != null) {
            alias.setDescription(request.getDescription());
        }
        if (request.getSignature() != null) {
            alias.setSignature(request.getSignature());
        }
        
        alias = aliasRepository.save(alias);
        log.info("Updated alias: {} for user: {}", alias.getAliasAddress(), username);
        
        return toDto(alias);
    }
    
    /**
     * 删除别名
     */
    public void deleteAlias(Long aliasId, String username) {
        EmailAlias alias = findAliasWithPermission(aliasId, username);
        
        // 标记为删除状态而不是物理删除
        alias.setStatus(EmailAlias.AliasStatus.DELETED);
        alias.setIsDeleted(true);
        aliasRepository.save(alias);
        
        log.info("Deleted alias: {} for user: {}", alias.getAliasAddress(), username);
    }
    
    /**
     * 启用/禁用别名
     */
    public void toggleAliasStatus(Long aliasId, Boolean enabled, String username) {
        EmailAlias alias = findAliasWithPermission(aliasId, username);
        
        alias.setStatus(enabled ? EmailAlias.AliasStatus.ACTIVE : EmailAlias.AliasStatus.INACTIVE);
        aliasRepository.save(alias);
        
        log.info("Toggled alias status: {} to {} for user: {}", 
                alias.getAliasAddress(), alias.getStatus(), username);
    }
    
    /**
     * 设置自动回复
     */
    public void setAutoReply(Long aliasId, AutoReplyRequest request, String username) {
        EmailAlias alias = findAliasWithPermission(aliasId, username);
        
        alias.setAutoReplyEnabled(request.getEnabled());
        alias.setAutoReplySubject(request.getSubject());
        alias.setAutoReplyMessage(request.getMessage());
        
        aliasRepository.save(alias);
        log.info("Set auto-reply for alias: {}", alias.getAliasAddress());
    }
    
    /**
     * 设置邮件转发
     */
    public void setForwarding(Long aliasId, ForwardingRequest request, String username) {
        EmailAlias alias = findAliasWithPermission(aliasId, username);
        
        alias.setForwardEnabled(request.getEnabled());
        alias.setForwardTo(String.join(",", request.getForwardTo()));
        
        aliasRepository.save(alias);
        log.info("Set forwarding for alias: {} to {}", 
                alias.getAliasAddress(), alias.getForwardTo());
    }
    
    /**
     * 检查别名是否可用
     */
    public boolean isAliasAvailable(String aliasName, String domainName) {
        String fullAddress = aliasName + "@" + domainName;
        return !aliasRepository.existsByAliasAddress(fullAddress);
    }
    
    /**
     * 查找别名并检查权限
     */
    private EmailAlias findAliasWithPermission(Long aliasId, String username) {
        EmailAlias alias = aliasRepository.findById(aliasId)
                .orElseThrow(() -> new IllegalArgumentException("Alias not found"));
        
        if (!alias.getUser().getUsername().equals(username)) {
            throw new IllegalArgumentException("Access denied");
        }
        
        return alias;
    }
    
    /**
     * 转换为DTO
     */
    private AliasDto toDto(EmailAlias alias) {
        AliasDto dto = new AliasDto();
        dto.setId(alias.getId());
        dto.setAliasAddress(alias.getAliasAddress());
        dto.setDisplayName(alias.getDisplayName());
        dto.setDescription(alias.getDescription());
        dto.setStatus(alias.getStatus().name());
        dto.setType(alias.getType().name());
        dto.setIsPrimary(alias.getIsPrimary());
        dto.setForwardEnabled(alias.getForwardEnabled());
        dto.setForwardTo(alias.getForwardTo());
        dto.setAutoReplyEnabled(alias.getAutoReplyEnabled());
        dto.setAutoReplySubject(alias.getAutoReplySubject());
        dto.setAutoReplyMessage(alias.getAutoReplyMessage());
        dto.setSignature(alias.getSignature());
        dto.setQuotaBytes(alias.getQuotaBytes());
        dto.setUsedBytes(alias.getUsedBytes());
        dto.setCreatedAt(alias.getCreatedAt());
        dto.setUpdatedAt(alias.getUpdatedAt());
        return dto;
    }
}