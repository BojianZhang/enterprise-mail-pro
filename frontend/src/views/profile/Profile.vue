<template>
  <div class="profile-container">
    <h2>个人资料</h2>
    
    <el-row :gutter="20">
      <el-col :span="8">
        <div class="avatar-section">
          <el-upload
            class="avatar-uploader"
            action="#"
            :show-file-list="false"
            :auto-upload="false"
            :on-change="handleAvatarChange"
          >
            <el-avatar :size="120" :src="profileForm.avatar">
              {{ userInitials }}
            </el-avatar>
            <div class="avatar-upload-text">点击上传头像</div>
          </el-upload>
        </div>
      </el-col>
      
      <el-col :span="16">
        <el-form :model="profileForm" :rules="profileRules" ref="profileFormRef" label-width="100px">
          <el-form-item label="用户名">
            <el-input v-model="profileForm.username" disabled />
          </el-form-item>
          
          <el-form-item label="邮箱">
            <el-input v-model="profileForm.email" disabled />
          </el-form-item>
          
          <el-form-item label="名字" prop="firstName">
            <el-input v-model="profileForm.firstName" />
          </el-form-item>
          
          <el-form-item label="姓氏" prop="lastName">
            <el-input v-model="profileForm.lastName" />
          </el-form-item>
          
          <el-form-item label="电话" prop="phone">
            <el-input v-model="profileForm.phone" />
          </el-form-item>
          
          <el-form-item label="部门">
            <el-input v-model="profileForm.department" />
          </el-form-item>
          
          <el-form-item label="职位">
            <el-input v-model="profileForm.position" />
          </el-form-item>
          
          <el-form-item>
            <el-button type="primary" @click="saveProfile">保存资料</el-button>
            <el-button @click="resetForm">重置</el-button>
          </el-form-item>
        </el-form>
      </el-col>
    </el-row>
    
    <el-divider />
    
    <div class="storage-section">
      <h3>存储空间</h3>
      <el-progress
        :percentage="storagePercentage"
        :color="storageColor"
        :stroke-width="20"
        text-inside
      />
      <p>已使用 {{ formatBytes(storageUsed) }} / {{ formatBytes(storageTotal) }}</p>
    </div>
    
    <el-divider />
    
    <div class="account-section">
      <h3>账户信息</h3>
      <el-descriptions :column="2" border>
        <el-descriptions-item label="账户类型">
          <el-tag>{{ accountType }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="账户状态">
          <el-tag type="success">正常</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="注册时间">
          {{ registrationDate }}
        </el-descriptions-item>
        <el-descriptions-item label="最后登录">
          {{ lastLogin }}
        </el-descriptions-item>
        <el-descriptions-item label="邮箱别名数">
          {{ aliasCount }}
        </el-descriptions-item>
        <el-descriptions-item label="域名数">
          {{ domainCount }}
        </el-descriptions-item>
      </el-descriptions>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed } from 'vue'
import { ElMessage } from 'element-plus'
import { useUserStore } from '@/stores/user'

const userStore = useUserStore()
const profileFormRef = ref()

const profileForm = reactive({
  username: 'admin',
  email: 'admin@enterprise.mail',
  firstName: 'System',
  lastName: 'Administrator',
  phone: '',
  department: 'IT',
  position: '系统管理员',
  avatar: ''
})

const profileRules = {
  firstName: [
    { required: true, message: '请输入名字', trigger: 'blur' }
  ],
  lastName: [
    { required: true, message: '请输入姓氏', trigger: 'blur' }
  ],
  phone: [
    { pattern: /^1[3-9]\d{9}$/, message: '请输入正确的手机号', trigger: 'blur' }
  ]
}

const storageUsed = ref(536870912) // 512MB
const storageTotal = ref(1073741824) // 1GB
const aliasCount = ref(3)
const domainCount = ref(1)
const accountType = ref('企业版')
const registrationDate = ref('2024-01-01')
const lastLogin = ref('2024-01-15 10:30:00')

const userInitials = computed(() => {
  return `${profileForm.firstName[0]}${profileForm.lastName[0]}`.toUpperCase()
})

const storagePercentage = computed(() => {
  return Math.round((storageUsed.value / storageTotal.value) * 100)
})

const storageColor = computed(() => {
  const percentage = storagePercentage.value
  if (percentage < 50) return '#13ce66'
  if (percentage < 80) return '#ffba00'
  return '#ff4949'
})

const formatBytes = (bytes: number) => {
  if (bytes === 0) return '0 Bytes'
  const k = 1024
  const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i]
}

const handleAvatarChange = (file: any) => {
  // TODO: 处理头像上传
  ElMessage.info('头像上传功能开发中')
}

const saveProfile = async () => {
  const valid = await profileFormRef.value?.validate()
  if (!valid) return
  
  // TODO: 调用保存个人资料API
  ElMessage.success('个人资料已保存')
}

const resetForm = () => {
  profileFormRef.value?.resetFields()
}
</script>

<style lang="scss" scoped>
.profile-container {
  background: white;
  border-radius: 4px;
  padding: 20px;
  
  h2 {
    margin-top: 0;
    margin-bottom: 20px;
  }
  
  h3 {
    margin-bottom: 15px;
  }
  
  .avatar-section {
    text-align: center;
    padding: 20px;
    
    .avatar-uploader {
      cursor: pointer;
      
      .avatar-upload-text {
        margin-top: 10px;
        color: #999;
        font-size: 12px;
      }
    }
  }
  
  .storage-section {
    padding: 20px 0;
    
    p {
      margin-top: 10px;
      color: #666;
    }
  }
  
  .account-section {
    padding: 20px 0;
  }
}</style>