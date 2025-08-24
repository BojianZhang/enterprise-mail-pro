import request from '@/utils/request'
import { LoginRequest, RegisterRequest, LoginResponse, UserInfo } from '@/types/user'

export const login = (data: LoginRequest): Promise<LoginResponse> => {
  return request({
    url: '/auth/login',
    method: 'post',
    data
  })
}

export const register = (data: RegisterRequest): Promise<UserInfo> => {
  return request({
    url: '/auth/register',
    method: 'post',
    data
  })
}

export const logout = (): Promise<void> => {
  return request({
    url: '/auth/logout',
    method: 'post'
  })
}

export const refreshToken = (token: string): Promise<LoginResponse> => {
  return request({
    url: '/auth/refresh',
    method: 'post',
    headers: {
      'Authorization': `Bearer ${token}`
    }
  })
}

export const validateToken = (): Promise<boolean> => {
  return request({
    url: '/auth/validate',
    method: 'get'
  })
}