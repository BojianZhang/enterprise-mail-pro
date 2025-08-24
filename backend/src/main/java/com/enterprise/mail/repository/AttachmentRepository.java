package com.enterprise.mail.repository;

import com.enterprise.mail.entity.Attachment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AttachmentRepository extends JpaRepository<Attachment, Long> {
    
    List<Attachment> findByEmailId(Long emailId);
    
    List<Attachment> findByEmailIdAndIsInline(Long emailId, Boolean isInline);
    
    void deleteByEmailId(Long emailId);
}