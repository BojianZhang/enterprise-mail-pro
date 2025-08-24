// 别名相关类型定义

export interface Alias {
  id: number
  aliasAddress: string
  aliasName: string
  description?: string
  userId: number
  domainId: number
  domainName: string
  isActive: boolean
  isDefault: boolean
  autoReplyEnabled: boolean
  autoReplySubject?: string
  autoReplyMessage?: string
  forwardingEnabled: boolean
  forwardTo?: string
  smtpPassword?: string
  createdAt: string
  updatedAt: string
}

export interface CreateAliasRequest {
  aliasAddress: string
  aliasName: string
  description?: string
  domainId: number
  isDefault?: boolean
  autoReplyEnabled?: boolean
  autoReplySubject?: string
  autoReplyMessage?: string
  forwardingEnabled?: boolean
  forwardTo?: string
}

export interface UpdateAliasRequest {
  aliasName?: string
  description?: string
  isDefault?: boolean
  autoReplyEnabled?: boolean
  autoReplySubject?: string
  autoReplyMessage?: string
  forwardingEnabled?: boolean
  forwardTo?: string
}

export interface AliasListResponse {
  content: Alias[]
  totalElements: number
  totalPages: number
  number: number
  size: number
}