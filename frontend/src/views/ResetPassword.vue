<template>
  <div class="reset-password-container">
    <div class="reset-password-card">
      <div class="reset-password-header">
        <h1>重置密码</h1>
        <p>请输入您的新密码</p>
      </div>
      
      <el-form
        ref="resetFormRef"
        :model="resetForm"
        :rules="resetRules"
        class="reset-form"
        v-if="!passwordReset"
      >
        <el-form-item prop="password">
          <el-input
            v-model="resetForm.password"
            type="password"
            placeholder="新密码"
            size="large"
            show-password
            :prefix-icon="Lock"
          />
        </el-form-item>
        
        <el-form-item prop="confirmPassword">
          <el-input
            v-model="resetForm.confirmPassword"
            type="password"
            placeholder="确认新密码"
            size="large"
            show-password
            :prefix-icon="Lock"
          />
        </el-form-item>
        
        <el-form-item>
          <div class="password-strength">
            <span>密码强度：</span>
            <el-progress
              :percentage="passwordStrength"
              :color="strengthColor"
              :show-text="false"
              :stroke-width="6"
            />
            <span :style="{ color: strengthColor }">{{ strengthText }}</span>
          </div>
        </el-form-item>
        
        <el-form-item>
          <el-button
            type="primary"
            size="large"
            :loading="loading"
            @click="handleReset"
            style="width: 100%"
          >
            重置密码
          </el-button>
        </el-form-item>
        
        <el-form-item>
          <div class="form-footer">
            <router-link to="/login" class="link">
              <el-icon><ArrowLeft /></el-icon>
              返回登录
            </router-link>
          </div>
        </el-form-item>
      </el-form>
      
      <div v-else class="success-message">
        <el-result
          icon="success"
          title="密码重置成功"
          sub-title="您的密码已成功重置，请使用新密码登录"
        >
          <template #extra>
            <el-button type="primary" @click="goToLogin">立即登录</el-button>
          </template>
        </el-result>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { Lock, ArrowLeft } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'
import { resetPassword, verifyResetToken } from '@/api/password'

const router = useRouter()
const route = useRoute()
const resetFormRef = ref()
const loading = ref(false)
const passwordReset = ref(false)
const resetToken = ref('')

const resetForm = reactive({
  password: '',
  confirmPassword: ''
})

const validatePassword = (rule: any, value: any, callback: any) => {
  if (value === '') {
    callback(new Error('请输入密码'))
  } else if (value.length < 6) {
    callback(new Error('密码长度不能小于6位'))
  } else {
    callback()
  }
}

const validateConfirmPassword = (rule: any, value: any, callback: any) => {
  if (value === '') {
    callback(new Error('请再次输入密码'))
  } else if (value !== resetForm.password) {
    callback(new Error('两次输入密码不一致'))
  } else {
    callback()
  }
}

const resetRules = {
  password: [
    { required: true, validator: validatePassword, trigger: 'blur' }
  ],
  confirmPassword: [
    { required: true, validator: validateConfirmPassword, trigger: 'blur' }
  ]
}

// 计算密码强度
const passwordStrength = computed(() => {
  const password = resetForm.password
  if (!password) return 0
  
  let strength = 0
  if (password.length >= 6) strength += 25
  if (password.length >= 8) strength += 25
  if (/[a-z]/.test(password) && /[A-Z]/.test(password)) strength += 25
  if (/[0-9]/.test(password)) strength += 12.5
  if (/[^a-zA-Z0-9]/.test(password)) strength += 12.5
  
  return Math.min(100, strength)
})

const strengthColor = computed(() => {
  const strength = passwordStrength.value
  if (strength < 40) return '#f56c6c'
  if (strength < 70) return '#e6a23c'
  return '#67c23a'
})

const strengthText = computed(() => {
  const strength = passwordStrength.value
  if (strength < 40) return '弱'
  if (strength < 70) return '中'
  return '强'
})

onMounted(async () => {
  // 从URL获取重置令牌
  resetToken.value = route.query.token as string || ''
  
  if (!resetToken.value) {
    ElMessage.error('无效的重置链接')
    router.push('/login')
    return
  }
  
  // 验证令牌是否有效
  try {
    const { valid } = await verifyResetToken(resetToken.value)
    if (!valid) {
      ElMessage.error('重置链接已过期或无效')
      router.push('/forgot-password')
    }
  } catch (error) {
    ElMessage.error('验证失败，请重新申请')
    router.push('/forgot-password')
  }
})

const handleReset = async () => {
  const valid = await resetFormRef.value?.validate()
  if (!valid) return
  
  loading.value = true
  
  try {
    await resetPassword({
      token: resetToken.value,
      password: resetForm.password
    })
    passwordReset.value = true
    ElMessage.success('密码重置成功')
  } catch (error: any) {
    ElMessage.error(error.message || '密码重置失败，请重试')
  } finally {
    loading.value = false
  }
}

const goToLogin = () => {
  router.push('/login')
}
</script>

<style lang="scss" scoped>
.reset-password-container {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  
  .reset-password-card {
    width: 450px;
    padding: 40px;
    background: white;
    border-radius: 8px;
    box-shadow: 0 20px 60px rgba(0, 0, 0, 0.1);
    
    .reset-password-header {
      text-align: center;
      margin-bottom: 40px;
      
      h1 {
        font-size: 28px;
        color: #333;
        margin-bottom: 10px;
      }
      
      p {
        color: #666;
        font-size: 14px;
      }
    }
    
    .password-strength {
      display: flex;
      align-items: center;
      gap: 10px;
      
      span {
        font-size: 14px;
        color: #666;
        
        &:last-child {
          font-weight: bold;
        }
      }
      
      :deep(.el-progress) {
        flex: 1;
      }
    }
    
    .form-footer {
      text-align: center;
      
      .link {
        color: #409eff;
        text-decoration: none;
        display: inline-flex;
        align-items: center;
        gap: 5px;
        
        &:hover {
          text-decoration: underline;
        }
      }
    }
    
    .success-message {
      padding: 20px 0;
    }
  }
}</style>