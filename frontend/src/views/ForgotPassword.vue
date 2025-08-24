<template>
  <div class="forgot-password-container">
    <div class="forgot-password-card">
      <div class="forgot-password-header">
        <h1>忘记密码</h1>
        <p>请输入您的邮箱地址，我们将发送密码重置链接</p>
      </div>
      
      <el-form
        ref="forgotFormRef"
        :model="forgotForm"
        :rules="forgotRules"
        class="forgot-form"
        v-if="!emailSent"
      >
        <el-form-item prop="email">
          <el-input
            v-model="forgotForm.email"
            placeholder="请输入注册邮箱"
            size="large"
            :prefix-icon="Message"
          />
        </el-form-item>
        
        <el-form-item>
          <el-button
            type="primary"
            size="large"
            :loading="loading"
            @click="handleSubmit"
            style="width: 100%"
          >
            发送重置链接
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
          title="邮件已发送"
          sub-title="密码重置链接已发送到您的邮箱，请查收"
        >
          <template #extra>
            <el-button type="primary" @click="backToLogin">返回登录</el-button>
            <el-button @click="resendEmail">重新发送</el-button>
          </template>
        </el-result>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { Message, ArrowLeft } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'
import { forgotPassword } from '@/api/password'

const router = useRouter()
const forgotFormRef = ref()
const loading = ref(false)
const emailSent = ref(false)
const savedEmail = ref('')

const forgotForm = reactive({
  email: ''
})

const forgotRules = {
  email: [
    { required: true, message: '请输入邮箱地址', trigger: 'blur' },
    { type: 'email', message: '请输入正确的邮箱地址', trigger: 'blur' }
  ]
}

const handleSubmit = async () => {
  const valid = await forgotFormRef.value?.validate()
  if (!valid) return
  
  loading.value = true
  
  try {
    await forgotPassword({ email: forgotForm.email })
    savedEmail.value = forgotForm.email
    emailSent.value = true
    ElMessage.success('密码重置链接已发送到您的邮箱')
  } catch (error: any) {
    ElMessage.error(error.message || '发送失败，请稍后重试')
  } finally {
    loading.value = false
  }
}

const backToLogin = () => {
  router.push('/login')
}

const resendEmail = async () => {
  loading.value = true
  
  try {
    await forgotPassword({ email: savedEmail.value })
    ElMessage.success('重置链接已重新发送')
  } catch (error: any) {
    ElMessage.error(error.message || '发送失败，请稍后重试')
  } finally {
    loading.value = false
  }
}
</script>

<style lang="scss" scoped>
.forgot-password-container {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  
  .forgot-password-card {
    width: 450px;
    padding: 40px;
    background: white;
    border-radius: 8px;
    box-shadow: 0 20px 60px rgba(0, 0, 0, 0.1);
    
    .forgot-password-header {
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