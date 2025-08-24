import request from '@/utils/request'

export interface ForgotPasswordRequest {
  email: string
}

export interface ResetPasswordRequest {
  token: string
  password: string
}

export const forgotPassword = (data: ForgotPasswordRequest): Promise<any> => {
  return request({
    url: '/auth/forgot-password',
    method: 'post',
    data
  })
}

export const resetPassword = (data: ResetPasswordRequest): Promise<any> => {
  return request({
    url: '/auth/reset-password',
    method: 'post',
    data
  })
}

export const verifyResetToken = (token: string): Promise<{ valid: boolean }> => {
  return request({
    url: '/auth/verify-reset-token',
    method: 'get',
    params: { token }
  })
}