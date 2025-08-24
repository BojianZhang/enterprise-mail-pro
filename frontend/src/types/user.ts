export interface LoginRequest {
  username: string
  password: string
}

export interface RegisterRequest {
  username: string
  email: string
  password: string
  firstName: string
  lastName: string
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
  createdAt?: string
  updatedAt?: string
}