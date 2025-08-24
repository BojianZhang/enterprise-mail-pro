export interface LoginRequest {
  username: string
  password: string
  rememberMe?: boolean
}

export interface RegisterRequest {
  username: string
  email: string
  password: string
  firstName: string
  lastName: string
  confirmPassword?: string
}

export interface LoginResponse {
  token: string
  refreshToken: string
  id?: number
  username: string
  email: string
  firstName: string
  lastName: string
  role: string
  expiresIn?: number
}

export interface UserInfo {
  id: number
  username: string
  email: string
  firstName: string
  lastName: string
  phoneNumber?: string
  avatar?: string
  role: string
  status?: string
  emailVerified?: boolean
  storageQuota?: number
  storageUsed?: number
  department?: string
  position?: string
  createdAt?: string
  updatedAt?: string
  lastLoginAt?: string
  permissions?: string[]
}

export interface UpdateProfileRequest {
  firstName?: string
  lastName?: string
  email?: string
  phoneNumber?: string
  department?: string
  position?: string
  avatar?: string
}

export interface ChangePasswordRequest {
  oldPassword: string
  newPassword: string
  confirmPassword: string
}

export interface ResetPasswordRequest {
  token: string
  newPassword: string
  confirmPassword: string
}

export interface UserListResponse {
  content: UserInfo[]
  totalElements: number
  totalPages: number
  number: number
  size: number
}

export interface UserNotification {
  id: number
  userId: number
  title: string
  content: string
  type: NotificationType
  isRead: boolean
  createdAt: string
  readAt?: string
}

export enum NotificationType {
  INFO = 'INFO',
  WARNING = 'WARNING',
  ERROR = 'ERROR',
  SUCCESS = 'SUCCESS',
  EMAIL_RECEIVED = 'EMAIL_RECEIVED',
  EMAIL_SENT = 'EMAIL_SENT',
  SYSTEM = 'SYSTEM'
}

export interface NotificationSettings {
  emailNotifications: boolean
  pushNotifications: boolean
  smsNotifications: boolean
  newEmailAlert: boolean
  importantEmailAlert: boolean
  systemUpdateAlert: boolean
}

export interface UserPermission {
  id: number
  name: string
  code: string
  description?: string
  category: string
}