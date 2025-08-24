// 邮件相关类型定义

export interface Email {
  id: number
  messageId: string
  fromAddress: string
  fromName: string
  toAddresses: string
  ccAddresses?: string
  bccAddresses?: string
  subject: string
  contentText: string
  contentHtml?: string
  status: EmailStatus
  direction: EmailDirection
  sentDate: string
  receivedDate?: string
  isRead: boolean
  isStarred: boolean
  isImportant: boolean
  hasAttachments: boolean
  sizeBytes: number
  folderId: number
  folderName: string
  userId: number
  attachments?: Attachment[]
  createdAt: string
  updatedAt: string
}

export enum EmailStatus {
  UNREAD = 'UNREAD',
  READ = 'READ',
  SENT = 'SENT',
  DRAFT = 'DRAFT',
  DELETED = 'DELETED'
}

export enum EmailDirection {
  SENT = 'SENT',
  RECEIVED = 'RECEIVED'
}

export interface SendEmailRequest {
  to: string
  cc?: string
  bcc?: string
  subject: string
  content: string
  htmlContent?: string
  attachments?: File[]
  replyToId?: number
  isImportant?: boolean
  requestReadReceipt?: boolean
  priority?: 'HIGH' | 'NORMAL' | 'LOW'
}

export interface DraftRequest {
  to?: string
  cc?: string
  bcc?: string
  subject?: string
  content?: string
  htmlContent?: string
}

export interface EmailListResponse {
  content: Email[]
  totalElements: number
  totalPages: number
  number: number
  size: number
}

export interface Attachment {
  id: number
  fileName: string
  originalFileName: string
  contentType: string
  fileSize: number
  downloadUrl: string
  uploadDate: string
}