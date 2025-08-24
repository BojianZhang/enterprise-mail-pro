<template>
  <div class="sent-container">
    <div class="sent-header">
      <h2>已发送</h2>
      <el-button @click="refreshList" :icon="Refresh">刷新</el-button>
    </div>
    
    <el-table :data="sentEmails" style="width: 100%">
      <el-table-column prop="to" label="收件人" width="200" />
      <el-table-column prop="subject" label="主题" />
      <el-table-column prop="date" label="发送时间" width="150">
        <template #default="{ row }">
          {{ formatDate(row.date) }}
        </template>
      </el-table-column>
      <el-table-column label="操作" width="100">
        <template #default="{ row }">
          <el-button link type="primary" @click="viewEmail(row)">查看</el-button>
        </template>
      </el-table-column>
    </el-table>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { Refresh } from '@element-plus/icons-vue'
import dayjs from 'dayjs'

const sentEmails = ref([
  {
    id: 1,
    to: 'user@example.com',
    subject: '会议通知',
    date: new Date()
  }
])

const refreshList = () => {
  // TODO: 刷新列表
}

const viewEmail = (email: any) => {
  // TODO: 查看邮件详情
}

const formatDate = (date: Date) => {
  return dayjs(date).format('YYYY-MM-DD HH:mm')
}
</script>

<style lang="scss" scoped>
.sent-container {
  background: white;
  border-radius: 4px;
  padding: 20px;
  
  .sent-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 20px;
    
    h2 {
      margin: 0;
    }
  }
}</style>