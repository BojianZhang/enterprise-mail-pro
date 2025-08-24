package com.enterprise.mail.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * Email Rule entity for filtering and organizing emails
 */
@Entity
@Table(name = "email_rules")
@Data
@EqualsAndHashCode(callSuper = true)
public class EmailRule extends BaseEntity {
    
    @Column(nullable = false, length = 100)
    private String name;
    
    @Column(length = 500)
    private String description;
    
    @Column(name = "is_active")
    private Boolean isActive = true;
    
    @Column(name = "priority")
    private Integer priority = 0;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "condition_type", nullable = false)
    private ConditionType conditionType;
    
    @Column(name = "condition_field", length = 50)
    private String conditionField;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "condition_operator")
    private ConditionOperator conditionOperator;
    
    @Column(name = "condition_value", length = 500)
    private String conditionValue;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "action_type", nullable = false)
    private ActionType actionType;
    
    @Column(name = "action_value", length = 500)
    private String actionValue;
    
    @Column(name = "stop_processing")
    private Boolean stopProcessing = false;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "alias_id", nullable = false)
    private EmailAlias alias;
    
    public enum ConditionType {
        FROM, TO, SUBJECT, BODY, HEADER, SIZE, HAS_ATTACHMENT
    }
    
    public enum ConditionOperator {
        CONTAINS, NOT_CONTAINS, EQUALS, NOT_EQUALS, STARTS_WITH, ENDS_WITH, GREATER_THAN, LESS_THAN
    }
    
    public enum ActionType {
        MOVE_TO_FOLDER, DELETE, MARK_AS_READ, MARK_AS_SPAM, FORWARD_TO, AUTO_REPLY, ADD_LABEL, SET_IMPORTANCE
    }
}