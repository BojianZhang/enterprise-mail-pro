package com.enterprise.mail.repository;

import com.enterprise.mail.entity.Domain;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface DomainRepository extends JpaRepository<Domain, Long> {
    
    Optional<Domain> findByDomainName(String domainName);
    
    boolean existsByDomainName(String domainName);
    
    Optional<Domain> findByIsDefaultTrue();
}