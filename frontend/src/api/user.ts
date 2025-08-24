import request from '@/utils/request'
import type { UserInfo, UpdateProfileRequest } from '@/types/user'

export const getUserInfo = () => {
  return request.get<UserInfo>('/users/profile')
}

export const updateProfile = (data: UpdateProfileRequest) => {
  return request.put<UserInfo>('/users/profile', data)
}

export const changePassword = (data: {
  oldPassword: string
  newPassword: string
}) => {
  return request.post('/users/change-password', data)
}

export const uploadAvatar = (file: File) => {
  const formData = new FormData()
  formData.append('avatar', file)
  return request.post('/users/avatar', formData, {
    headers: { 'Content-Type': 'multipart/form-data' }
  })
}

export const getUserList = (params?: {
  page?: number
  size?: number
  search?: string
  role?: string
}) => {
  return request.get('/users', { params })
}

export const getUserById = (id: number) => {
  return request.get(`/users/${id}`)
}

export const updateUser = (id: number, data: any) => {
  return request.put(`/users/${id}`, data)
}

export const deleteUser = (id: number) => {
  return request.delete(`/users/${id}`)
}

export const resetUserPassword = (id: number) => {
  return request.post(`/users/${id}/reset-password`)
}

export const enableUser = (id: number) => {
  return request.put(`/users/${id}/enable`)
}

export const disableUser = (id: number) => {
  return request.put(`/users/${id}/disable`)
}

export const getUserPermissions = () => {
  return request.get('/users/permissions')
}

export const getUserNotifications = () => {
  return request.get('/users/notifications')
}

export const markNotificationAsRead = (id: number) => {
  return request.put(`/users/notifications/${id}/read`)
}

export const updateNotificationSettings = (data: {
  emailNotifications: boolean
  pushNotifications: boolean
  smsNotifications: boolean
}) => {
  return request.put('/users/notification-settings', data)
}