import request from '@/utils/request'
import type { Email, SendEmailRequest, EmailListResponse, DraftRequest } from '@/types/email'

// 获取邮件列表
export const getEmails = (params?: {
  page?: number
  size?: number
  folderId?: number
  status?: string
  search?: string
}) => {
  return request.get<EmailListResponse>('/emails', { params })
}

// 获取邮件详情
export const getEmailById = (id: number) => {
  return request.get<Email>(`/emails/${id}`)
}

// 发送邮件
export const sendEmail = (data: SendEmailRequest) => {
  return request.post<Email>('/emails/send', data)
}

// 保存草稿
export const saveDraft = (data: DraftRequest) => {
  return request.post<Email>('/emails/draft', data)
}

// 删除邮件
export const deleteEmail = (id: number) => {
  return request.delete(`/emails/${id}`)
}

// 批量删除邮件
export const batchDeleteEmails = (ids: number[]) => {
  return request.delete('/emails/batch', { data: { ids } })
}

// 标记为已读
export const markAsRead = (id: number) => {
  return request.put(`/emails/${id}/read`)
}

// 标记为未读
export const markAsUnread = (id: number) => {
  return request.put(`/emails/${id}/unread`)
}

// 标记为重要
export const markAsImportant = (id: number) => {
  return request.put(`/emails/${id}/important`)
}

// 星标邮件
export const starEmail = (id: number) => {
  return request.put(`/emails/${id}/star`)
}

// 移动邮件到文件夹
export const moveEmail = (id: number, folderId: number) => {
  return request.put(`/emails/${id}/move`, { folderId })
}

// 上传附件
export const uploadAttachment = (file: File) => {
  const formData = new FormData()
  formData.append('file', file)
  return request.post('/emails/attachments', formData, {
    headers: {
      'Content-Type': 'multipart/form-data'
    }
  })
}