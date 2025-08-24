-- Create database if not exists
CREATE DATABASE IF NOT EXISTS mail_system CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE mail_system;

-- Create indexes for better performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_emails_user_id ON emails(user_id);
CREATE INDEX idx_emails_message_id ON emails(message_id);
CREATE INDEX idx_emails_sent_date ON emails(sent_date);
CREATE INDEX idx_emails_folder_id ON emails(folder_id);
CREATE INDEX idx_email_aliases_user_id ON email_aliases(user_id);
CREATE INDEX idx_email_aliases_domain_id ON email_aliases(domain_id);
CREATE INDEX idx_domains_domain_name ON domains(domain_name);

-- Insert default admin user (password: admin123456)
INSERT INTO users (username, email, password, first_name, last_name, role, status, email_verified, created_at, updated_at, is_deleted, version)
VALUES ('admin', 'admin@enterprise.mail', '$2a$10$YourHashedPasswordHere', 'System', 'Administrator', 'SUPER_ADMIN', 'ACTIVE', true, NOW(), NOW(), false, 0);

-- Insert default domain
INSERT INTO domains (domain_name, description, status, is_verified, is_default, created_at, updated_at, is_deleted, version)
VALUES ('enterprise.mail', 'Default system domain', 'ACTIVE', true, true, NOW(), NOW(), false, 0);

-- Create system folders for admin user
INSERT INTO email_folders (name, type, is_system, user_id, created_at, updated_at, is_deleted, version)
SELECT 'Inbox', 'INBOX', true, id, NOW(), NOW(), false, 0 FROM users WHERE username = 'admin'
UNION ALL
SELECT 'Sent', 'SENT', true, id, NOW(), NOW(), false, 0 FROM users WHERE username = 'admin'
UNION ALL
SELECT 'Drafts', 'DRAFTS', true, id, NOW(), NOW(), false, 0 FROM users WHERE username = 'admin'
UNION ALL
SELECT 'Trash', 'TRASH', true, id, NOW(), NOW(), false, 0 FROM users WHERE username = 'admin'
UNION ALL
SELECT 'Spam', 'SPAM', true, id, NOW(), NOW(), false, 0 FROM users WHERE username = 'admin'
UNION ALL
SELECT 'Archive', 'ARCHIVE', true, id, NOW(), NOW(), false, 0 FROM users WHERE username = 'admin';