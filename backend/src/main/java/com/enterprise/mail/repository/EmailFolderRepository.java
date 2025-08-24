package com.enterprise.mail.repository;

import com.enterprise.mail.entity.EmailFolder;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface EmailFolderRepository extends JpaRepository<EmailFolder, Long> {
    
    List<EmailFolder> findByUserId(Long userId);
    
    Optional<EmailFolder> findByUserIdAndType(Long userId, EmailFolder.FolderType type);
    
    Optional<EmailFolder> findByUserIdAndName(Long userId, String name);
    
    List<EmailFolder> findByUserIdOrderBySortOrder(Long userId);
}