<template>
  <div class="domain-container">
    <div class="domain-header">
      <h2>域名管理</h2>
      <el-button type="primary" @click="showAddDialog = true" :icon="Plus">
        添加域名
      </el-button>
    </div>
    
    <el-table :data="domains" style="width: 100%">
      <el-table-column prop="domain" label="域名" />
      <el-table-column prop="status" label="状态">
        <template #default="{ row }">
          <el-tag :type="getStatusType(row.status)">
            {{ getStatusText(row.status) }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="verified" label="验证状态">
        <template #default="{ row }">
          <el-tag :type="row.verified ? 'success' : 'warning'">
            {{ row.verified ? '已验证' : '待验证' }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="操作" width="200">
        <template #default="{ row }">
          <el-button link type="primary" @click="viewDNS(row)">DNS配置</el-button>
          <el-button link type="danger" @click="deleteDomain(row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>
    
    <!-- 添加域名对话框 -->
    <el-dialog v-model="showAddDialog" title="添加域名" width="500px">
      <el-form :model="domainForm" :rules="domainRules" ref="domainFormRef">
        <el-form-item label="域名" prop="domain">
          <el-input v-model="domainForm.domain" placeholder="例如: example.com" />
        </el-form-item>
        <el-form-item label="描述">
          <el-input v-model="domainForm.description" type="textarea" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showAddDialog = false">取消</el-button>
        <el-button type="primary" @click="addDomain">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive } from 'vue'
import { ElMessage } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'

const showAddDialog = ref(false)
const domainFormRef = ref()

const domains = ref([
  {
    id: 1,
    domain: 'enterprise.mail',
    status: 'active',
    verified: true
  }
])

const domainForm = reactive({
  domain: '',
  description: ''
})

const domainRules = {
  domain: [
    { required: true, message: '请输入域名', trigger: 'blur' },
    { pattern: /^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/, message: '域名格式不正确', trigger: 'blur' }
  ]
}

const getStatusType = (status: string) => {
  const types: any = {
    active: 'success',
    inactive: 'info',
    pending: 'warning'
  }
  return types[status] || 'info'
}

const getStatusText = (status: string) => {
  const texts: any = {
    active: '活跃',
    inactive: '未激活',
    pending: '待处理'
  }
  return texts[status] || status
}

const addDomain = async () => {
  const valid = await domainFormRef.value?.validate()
  if (!valid) return
  
  // TODO: 调用添加域名API
  ElMessage.success('域名添加成功')
  showAddDialog.value = false
}

const viewDNS = (domain: any) => {
  // TODO: 查看DNS配置
  ElMessage.info('DNS配置功能开发中')
}

const deleteDomain = (domain: any) => {
  // TODO: 删除域名
  ElMessage.success('域名已删除')
}
</script>

<style lang="scss" scoped>
.domain-container {
  background: white;
  border-radius: 4px;
  padding: 20px;
  
  .domain-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 20px;
    
    h2 {
      margin: 0;
    }
  }
}</style>