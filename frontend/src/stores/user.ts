import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { login, register, logout, refreshToken } from '@/api/auth'
import { LoginRequest, RegisterRequest, UserInfo } from '@/types/user'
import { ElMessage } from 'element-plus'
import router from '@/router'

export const useUserStore = defineStore('user', () => {
  const token = ref<string>(localStorage.getItem('token') || '')
  const refreshTokenValue = ref<string>(localStorage.getItem('refreshToken') || '')
  const userInfo = ref<UserInfo | null>(null)

  const isAuthenticated = computed(() => !!token.value)

  const setToken = (newToken: string, newRefreshToken?: string) => {
    token.value = newToken
    localStorage.setItem('token', newToken)
    
    if (newRefreshToken) {
      refreshTokenValue.value = newRefreshToken
      localStorage.setItem('refreshToken', newRefreshToken)
    }
  }

  const clearToken = () => {
    token.value = ''
    refreshTokenValue.value = ''
    userInfo.value = null
    localStorage.removeItem('token')
    localStorage.removeItem('refreshToken')
  }

  const loginUser = async (loginData: LoginRequest) => {
    try {
      const response = await login(loginData)
      setToken(response.token, response.refreshToken)
      userInfo.value = {
        id: response.id,
        username: response.username,
        email: response.email,
        firstName: response.firstName,
        lastName: response.lastName,
        role: response.role
      }
      ElMessage.success('登录成功')
      router.push('/')
      return response
    } catch (error: any) {
      ElMessage.error(error.message || '登录失败')
      throw error
    }
  }

  const registerUser = async (registerData: RegisterRequest) => {
    try {
      const response = await register(registerData)
      ElMessage.success('注册成功，请登录')
      router.push('/login')
      return response
    } catch (error: any) {
      ElMessage.error(error.message || '注册失败')
      throw error
    }
  }

  const logoutUser = async () => {
    try {
      await logout()
    } catch (error) {
      // 即使logout失败也要清理本地token
    } finally {
      clearToken()
      router.push('/login')
      ElMessage.success('已退出登录')
    }
  }

  const refreshUserToken = async () => {
    try {
      const response = await refreshToken(refreshTokenValue.value)
      setToken(response.token, response.refreshToken)
      return response
    } catch (error) {
      clearToken()
      router.push('/login')
      throw error
    }
  }

  const checkAuth = async () => {
    if (token.value && !userInfo.value) {
      try {
        const { getUserInfo } = await import('@/api/user')
        const info = await getUserInfo()
        userInfo.value = info
      } catch (error) {
        clearToken()
      }
    }
  }

  return {
    token,
    userInfo,
    isAuthenticated,
    loginUser,
    registerUser,
    logoutUser,
    refreshUserToken,
    checkAuth,
    setToken,
    clearToken
  }
})