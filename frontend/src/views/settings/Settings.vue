<template>
  <div class="settings-container">
    <h2>设置</h2>
    
    <el-tabs v-model="activeTab">
      <el-tab-pane label="常规设置" name="general">
        <el-form :model="generalSettings" label-width="120px">
          <el-form-item label="语言">
            <el-select v-model="generalSettings.language">
              <el-option label="中文" value="zh-CN" />
              <el-option label="English" value="en" />
            </el-select>
          </el-form-item>
          
          <el-form-item label="时区">
            <el-select v-model="generalSettings.timezone">
              <el-option label="北京时间 (GMT+8)" value="Asia/Shanghai" />
              <el-option label="UTC" value="UTC" />
            </el-select>
          </el-form-item>
          
          <el-form-item label="主题">
            <el-radio-group v-model="generalSettings.theme">
              <el-radio label="light">浅色</el-radio>
              <el-radio label="dark">深色</el-radio>
              <el-radio label="auto">跟随系统</el-radio>
            </el-radio-group>
          </el-form-item>
          
          <el-form-item>
            <el-button type="primary" @click="saveGeneralSettings">保存设置</el-button>
          </el-form-item>
        </el-form>
      </el-tab-pane>
      
      <el-tab-pane label="邮件设置" name="email">
        <el-form :model="emailSettings" label-width="120px">
          <el-form-item label="签名">
            <el-input
              v-model="emailSettings.signature"
              type="textarea"
              :rows="4"
              placeholder="邮件签名"
            />
          </el-form-item>
          
          <el-form-item label="自动回复">
            <el-switch v-model="emailSettings.autoReply" />
          </el-form-item>
          
          <el-form-item label="回复内容" v-if="emailSettings.autoReply">
            <el-input
              v-model="emailSettings.autoReplyContent"
              type="textarea"
              :rows="4"
              placeholder="自动回复内容"
            />
          </el-form-item>
          
          <el-form-item label="转发邮件">
            <el-switch v-model="emailSettings.forward" />
          </el-form-item>
          
          <el-form-item label="转发地址" v-if="emailSettings.forward">
            <el-input v-model="emailSettings.forwardAddress" placeholder="转发邮箱地址" />
          </el-form-item>
          
          <el-form-item>
            <el-button type="primary" @click="saveEmailSettings">保存设置</el-button>
          </el-form-item>
        </el-form>
      </el-tab-pane>
      
      <el-tab-pane label="安全设置" name="security">
        <el-form :model="securitySettings" label-width="120px">
          <el-form-item label="两步验证">
            <el-switch v-model="securitySettings.twoFactor" />
          </el-form-item>
          
          <el-form-item label="修改密码">
            <el-button @click="showPasswordDialog = true">修改密码</el-button>
          </el-form-item>
          
          <el-form-item label="登录历史">
            <el-button @click="viewLoginHistory">查看登录历史</el-button>
          </el-form-item>
          
          <el-form-item label="会话管理">
            <el-button @click="manageSessions">管理会话</el-button>
          </el-form-item>
        </el-form>
      </el-tab-pane>
      
      <el-tab-pane label="过滤规则" name="filters">
        <div class="filter-section">
          <el-button type="primary" @click="showFilterDialog = true" :icon="Plus">
            添加规则
          </el-button>
          
          <el-table :data="filterRules" style="margin-top: 20px">
            <el-table-column prop="name" label="规则名称" />
            <el-table-column prop="condition" label="条件" />
            <el-table-column prop="action" label="动作" />
            <el-table-column label="状态">
              <template #default="{ row }">
                <el-switch v-model="row.enabled" />
              </template>
            </el-table-column>
            <el-table-column label="操作">
              <template #default="{ row }">
                <el-button link type="primary" size="small">编辑</el-button>
                <el-button link type="danger" size="small">删除</el-button>
              </template>
            </el-table-column>
          </el-table>
        </div>
      </el-tab-pane>
    </el-tabs>
    
    <!-- 修改密码对话框 -->
    <el-dialog v-model="showPasswordDialog" title="修改密码" width="400px">
      <el-form :model="passwordForm" :rules="passwordRules" ref="passwordFormRef">
        <el-form-item label="当前密码" prop="oldPassword">
          <el-input v-model="passwordForm.oldPassword" type="password" show-password />
        </el-form-item>
        <el-form-item label="新密码" prop="newPassword">
          <el-input v-model="passwordForm.newPassword" type="password" show-password />
        </el-form-item>
        <el-form-item label="确认密码" prop="confirmPassword">
          <el-input v-model="passwordForm.confirmPassword" type="password" show-password />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showPasswordDialog = false">取消</el-button>
        <el-button type="primary" @click="changePassword">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive } from 'vue'
import { ElMessage } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'

const activeTab = ref('general')
const showPasswordDialog = ref(false)
const showFilterDialog = ref(false)
const passwordFormRef = ref()

const generalSettings = reactive({
  language: 'zh-CN',
  timezone: 'Asia/Shanghai',
  theme: 'light'
})

const emailSettings = reactive({
  signature: '',
  autoReply: false,
  autoReplyContent: '',
  forward: false,
  forwardAddress: ''
})

const securitySettings = reactive({
  twoFactor: false
})

const passwordForm = reactive({
  oldPassword: '',
  newPassword: '',
  confirmPassword: ''
})

const filterRules = ref([
  {
    id: 1,
    name: '垃圾邮件过滤',
    condition: '主题包含"广告"',
    action: '移至垃圾箱',
    enabled: true
  }
])

const passwordRules = {
  oldPassword: [
    { required: true, message: '请输入当前密码', trigger: 'blur' }
  ],
  newPassword: [
    { required: true, message: '请输入新密码', trigger: 'blur' },
    { min: 6, message: '密码长度不能小于6位', trigger: 'blur' }
  ],
  confirmPassword: [
    { required: true, message: '请确认密码', trigger: 'blur' },
    {
      validator: (rule: any, value: any, callback: any) => {
        if (value !== passwordForm.newPassword) {
          callback(new Error('两次输入密码不一致'))
        } else {
          callback()
        }
      },
      trigger: 'blur'
    }
  ]
}

const saveGeneralSettings = () => {
  ElMessage.success('常规设置已保存')
}

const saveEmailSettings = () => {
  ElMessage.success('邮件设置已保存')
}

const changePassword = async () => {
  const valid = await passwordFormRef.value?.validate()
  if (!valid) return
  
  // TODO: 调用修改密码API
  ElMessage.success('密码修改成功')
  showPasswordDialog.value = false
}

const viewLoginHistory = () => {
  ElMessage.info('登录历史功能开发中')
}

const manageSessions = () => {
  ElMessage.info('会话管理功能开发中')
}
</script>

<style lang="scss" scoped>
.settings-container {
  background: white;
  border-radius: 4px;
  padding: 20px;
  
  h2 {
    margin-top: 0;
    margin-bottom: 20px;
  }
  
  .filter-section {
    padding: 20px 0;
  }
}</style>