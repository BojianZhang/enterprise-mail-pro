<template>
  <div class="alias-container">
    <div class="alias-header">
      <h2>邮箱别名管理</h2>
      <el-button type="primary" @click="showCreateDialog = true" :icon="Plus">
        创建别名
      </el-button>
    </div>
    
    <el-table :data="aliases" style="width: 100%">
      <el-table-column prop="alias" label="别名地址" />
      <el-table-column prop="displayName" label="显示名称" />
      <el-table-column prop="status" label="状态">
        <template #default="{ row }">
          <el-tag :type="row.status === 'active' ? 'success' : 'info'">
            {{ row.status === 'active' ? '启用' : '禁用' }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="操作" width="200">
        <template #default="{ row }">
          <el-button link type="primary" @click="editAlias(row)">编辑</el-button>
          <el-button link type="danger" @click="deleteAlias(row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>
    
    <!-- 创建别名对话框 -->
    <el-dialog v-model="showCreateDialog" title="创建邮箱别名" width="500px">
      <el-form :model="aliasForm" :rules="aliasRules" ref="aliasFormRef">
        <el-form-item label="别名地址" prop="alias">
          <el-input v-model="aliasForm.alias" placeholder="例如: john.doe">
            <template #append>@enterprise.mail</template>
          </el-input>
        </el-form-item>
        <el-form-item label="显示名称" prop="displayName">
          <el-input v-model="aliasForm.displayName" placeholder="显示名称" />
        </el-form-item>
        <el-form-item label="描述">
          <el-input v-model="aliasForm.description" type="textarea" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showCreateDialog = false">取消</el-button>
        <el-button type="primary" @click="createAlias">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive } from 'vue'
import { ElMessage } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'

const showCreateDialog = ref(false)
const aliasFormRef = ref()

const aliases = ref([
  {
    id: 1,
    alias: 'admin@enterprise.mail',
    displayName: '管理员',
    status: 'active'
  }
])

const aliasForm = reactive({
  alias: '',
  displayName: '',
  description: ''
})

const aliasRules = {
  alias: [
    { required: true, message: '请输入别名地址', trigger: 'blur' },
    { pattern: /^[a-zA-Z0-9._-]+$/, message: '别名格式不正确', trigger: 'blur' }
  ],
  displayName: [
    { required: true, message: '请输入显示名称', trigger: 'blur' }
  ]
}

const createAlias = async () => {
  const valid = await aliasFormRef.value?.validate()
  if (!valid) return
  
  // TODO: 调用创建别名API
  ElMessage.success('别名创建成功')
  showCreateDialog.value = false
}

const editAlias = (alias: any) => {
  // TODO: 编辑别名
}

const deleteAlias = (alias: any) => {
  // TODO: 删除别名
  ElMessage.success('别名已删除')
}
</script>

<style lang="scss" scoped>
.alias-container {
  background: white;
  border-radius: 4px;
  padding: 20px;
  
  .alias-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 20px;
    
    h2 {
      margin: 0;
    }
  }
}</style>