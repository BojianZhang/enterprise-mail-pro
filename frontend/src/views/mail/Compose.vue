<template>
  <div class="compose-container">
    <div class="compose-header">
      <h2>写邮件</h2>
    </div>
    
    <el-form ref="emailFormRef" :model="emailForm" :rules="emailRules" class="email-form">
      <el-form-item prop="to">
        <el-input
          v-model="emailForm.to"
          placeholder="收件人"
          :prefix-icon="User"
        />
      </el-form-item>
      
      <el-form-item prop="cc">
        <el-input
          v-model="emailForm.cc"
          placeholder="抄送"
          :prefix-icon="User"
        />
      </el-form-item>
      
      <el-form-item prop="bcc">
        <el-input
          v-model="emailForm.bcc"
          placeholder="密送"
          :prefix-icon="User"
        />
      </el-form-item>
      
      <el-form-item prop="subject">
        <el-input
          v-model="emailForm.subject"
          placeholder="主题"
          :prefix-icon="Document"
        />
      </el-form-item>
      
      <el-form-item prop="content">
        <div class="editor-container">
          <el-input
            v-model="emailForm.content"
            type="textarea"
            :rows="15"
            placeholder="邮件内容"
          />
        </div>
      </el-form-item>
      
      <el-form-item>
        <el-upload
          class="upload-demo"
          action="#"
          :auto-upload="false"
          multiple
          :file-list="fileList"
        >
          <el-button :icon="Paperclip">添加附件</el-button>
        </el-upload>
      </el-form-item>
      
      <el-form-item>
        <el-button type="primary" @click="sendEmail" :icon="Promotion">
          发送
        </el-button>
        <el-button @click="saveDraft" :icon="Document">
          保存草稿
        </el-button>
        <el-button @click="resetForm" :icon="Delete">
          清空
        </el-button>
      </el-form-item>
    </el-form>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive } from 'vue'
import { ElMessage } from 'element-plus'
import { User, Document, Paperclip, Promotion, Delete } from '@element-plus/icons-vue'

const emailFormRef = ref()
const fileList = ref([])

const emailForm = reactive({
  to: '',
  cc: '',
  bcc: '',
  subject: '',
  content: ''
})

const emailRules = {
  to: [
    { required: true, message: '请输入收件人', trigger: 'blur' },
    { type: 'email', message: '请输入正确的邮箱地址', trigger: 'blur' }
  ],
  subject: [
    { required: true, message: '请输入邮件主题', trigger: 'blur' }
  ],
  content: [
    { required: true, message: '请输入邮件内容', trigger: 'blur' }
  ]
}

const sendEmail = async () => {
  const valid = await emailFormRef.value?.validate()
  if (!valid) return
  
  // 调用发送邮件API
  try {
    const response = await fetch('/api/emails/send', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${localStorage.getItem('token')}`
      },
      body: JSON.stringify(emailForm.value)
    })
    if (response.ok) {
      ElMessage.success('邮件已发送')
      resetForm()
    } else {
      ElMessage.error('邮件发送失败')
    }
  } catch (error) {
    ElMessage.error('邮件发送失败')
  }
}

const saveDraft = async () => {
  // 调用保存草稿API
  try {
    const response = await fetch('/api/emails/drafts', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${localStorage.getItem('token')}`
      },
      body: JSON.stringify(emailForm.value)
    })
    if (response.ok) {
      ElMessage.success('已保存到草稿箱')
    } else {
      ElMessage.error('草稿保存失败')
    }
  } catch (error) {
    ElMessage.error('草稿保存失败')
  }
}

const resetForm = () => {
  emailFormRef.value?.resetFields()
  fileList.value = []
}
</script>

<style lang="scss" scoped>
.compose-container {
  background: white;
  border-radius: 4px;
  padding: 20px;
  
  .compose-header {
    margin-bottom: 20px;
    
    h2 {
      margin: 0;
    }
  }
  
  .email-form {
    max-width: 800px;
    
    .editor-container {
      width: 100%;
    }
  }
}</style>