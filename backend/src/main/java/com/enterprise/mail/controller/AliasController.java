package com.enterprise.mail.controller;

import com.enterprise.mail.dto.*;
import com.enterprise.mail.service.AliasService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Alias Controller - 别名管理
 */
@Tag(name = "Alias Management", description = "邮箱别名管理接口")
@RestController
@RequestMapping("/aliases")
@RequiredArgsConstructor
public class AliasController {
    
    private final AliasService aliasService;
    
    @Operation(summary = "获取别名列表")
    @GetMapping
    public ResponseEntity<Page<AliasDto>> getAliases(
            @AuthenticationPrincipal UserDetails userDetails,
            Pageable pageable) {
        
        Page<AliasDto> aliases = aliasService.getUserAliases(userDetails.getUsername(), pageable);
        return ResponseEntity.ok(aliases);
    }
    
    @Operation(summary = "获取别名详情")
    @GetMapping("/{id}")
    public ResponseEntity<AliasDto> getAlias(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long id) {
        
        AliasDto alias = aliasService.getAlias(id, userDetails.getUsername());
        return ResponseEntity.ok(alias);
    }
    
    @Operation(summary = "创建别名")
    @PostMapping
    public ResponseEntity<AliasDto> createAlias(
            @AuthenticationPrincipal UserDetails userDetails,
            @Valid @RequestBody CreateAliasRequest request) {
        
        AliasDto alias = aliasService.createAlias(request, userDetails.getUsername());
        return ResponseEntity.status(HttpStatus.CREATED).body(alias);
    }
    
    @Operation(summary = "更新别名")
    @PutMapping("/{id}")
    public ResponseEntity<AliasDto> updateAlias(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long id,
            @Valid @RequestBody UpdateAliasRequest request) {
        
        AliasDto alias = aliasService.updateAlias(id, request, userDetails.getUsername());
        return ResponseEntity.ok(alias);
    }
    
    @Operation(summary = "删除别名")
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteAlias(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long id) {
        
        aliasService.deleteAlias(id, userDetails.getUsername());
        return ResponseEntity.noContent().build();
    }
    
    @Operation(summary = "启用/禁用别名")
    @PutMapping("/{id}/status")
    public ResponseEntity<Void> toggleAliasStatus(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long id,
            @RequestParam Boolean enabled) {
        
        aliasService.toggleAliasStatus(id, enabled, userDetails.getUsername());
        return ResponseEntity.ok().build();
    }
    
    @Operation(summary = "设置自动回复")
    @PutMapping("/{id}/auto-reply")
    public ResponseEntity<Void> setAutoReply(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long id,
            @Valid @RequestBody AutoReplyRequest request) {
        
        aliasService.setAutoReply(id, request, userDetails.getUsername());
        return ResponseEntity.ok().build();
    }
    
    @Operation(summary = "设置邮件转发")
    @PutMapping("/{id}/forwarding")
    public ResponseEntity<Void> setForwarding(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long id,
            @Valid @RequestBody ForwardingRequest request) {
        
        aliasService.setForwarding(id, request, userDetails.getUsername());
        return ResponseEntity.ok().build();
    }
    
    @Operation(summary = "检查别名是否可用")
    @GetMapping("/check")
    public ResponseEntity<Boolean> checkAliasAvailability(
            @RequestParam String alias,
            @RequestParam String domain) {
        
        boolean available = aliasService.isAliasAvailable(alias, domain);
        return ResponseEntity.ok(available);
    }
}