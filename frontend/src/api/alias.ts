import request from '@/utils/request'
import type { Alias, CreateAliasRequest, UpdateAliasRequest, AliasListResponse } from '@/types/alias'

// 获取别名列表
export const getAliases = (params?: {
  page?: number
  size?: number
  userId?: number
}) => {
  return request.get<AliasListResponse>('/aliases', { params })
}

// 获取别名详情
export const getAliasById = (id: number) => {
  return request.get<Alias>(`/aliases/${id}`)
}

// 创建别名
export const createAlias = (data: CreateAliasRequest) => {
  return request.post<Alias>('/aliases', data)
}

// 更新别名
export const updateAlias = (id: number, data: UpdateAliasRequest) => {
  return request.put<Alias>(`/aliases/${id}`, data)
}

// 删除别名
export const deleteAlias = (id: number) => {
  return request.delete(`/aliases/${id}`)
}

// 切换别名状态
export const toggleAliasStatus = (id: number) => {
  return request.put(`/aliases/${id}/status`)
}

// 设置自动回复
export const setAutoReply = (id: number, data: {
  enabled: boolean
  subject?: string
  message?: string
}) => {
  return request.put(`/aliases/${id}/auto-reply`, data)
}

// 设置转发
export const setForwarding = (id: number, data: {
  enabled: boolean
  forwardTo?: string
}) => {
  return request.put(`/aliases/${id}/forwarding`, data)
}

// 检查别名可用性
export const checkAliasAvailability = (alias: string) => {
  return request.get<{ available: boolean }>('/aliases/check', {
    params: { alias }
  })
}