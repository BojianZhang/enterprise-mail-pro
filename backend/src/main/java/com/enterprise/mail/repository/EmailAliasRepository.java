package com.enterprise.mail.repository;

import com.enterprise.mail.entity.EmailAlias;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface EmailAliasRepository extends JpaRepository<EmailAlias, Long> {
    
    Optional<EmailAlias> findByAliasAddress(String aliasAddress);
    
    Page<EmailAlias> findByUserId(Long userId, Pageable pageable);
    
    List<EmailAlias> findByUserId(Long userId);
    
    List<EmailAlias> findByDomainId(Long domainId);
    
    boolean existsByAliasAddress(String aliasAddress);
}