<template>
  <div class="inbox-container">
    <div class="inbox-header">
      <h2>收件箱</h2>
      <div class="inbox-actions">
        <el-button @click="refreshEmails" :icon="Refresh">刷新</el-button>
        <el-button @click="markAllAsRead" :icon="Check">全部标记已读</el-button>
      </div>
    </div>
    
    <div class="inbox-toolbar">
      <el-checkbox
        v-model="selectAll"
        @change="handleSelectAll"
        :indeterminate="isIndeterminate"
      />
      
      <el-button-group>
        <el-button :icon="Delete" @click="deleteSelected" :disabled="!hasSelected">
          删除
        </el-button>
        <el-button :icon="Warning" @click="markAsSpam" :disabled="!hasSelected">
          垃圾邮件
        </el-button>
        <el-button :icon="Star" @click="toggleStar" :disabled="!hasSelected">
          星标
        </el-button>
      </el-button-group>
      
      <el-select v-model="filter" placeholder="筛选" style="width: 120px">
        <el-option label="全部" value="all" />
        <el-option label="未读" value="unread" />
        <el-option label="已读" value="read" />
        <el-option label="星标" value="starred" />
      </el-select>
    </div>
    
    <div class="email-list">
      <el-table
        :data="emails"
        @selection-change="handleSelectionChange"
        row-key="id"
        style="width: 100%"
      >
        <el-table-column type="selection" width="40" />
        
        <el-table-column width="40">
          <template #default="{ row }">
            <el-icon
              :class="['star-icon', { starred: row.starred }]"
              @click="toggleEmailStar(row)"
            >
              <StarFilled v-if="row.starred" />
              <Star v-else />
            </el-icon>
          </template>
        </el-table-column>
        
        <el-table-column prop="from" label="发件人" width="200">
          <template #default="{ row }">
            <div class="email-from">
              <span :class="{ unread: !row.read }">{{ row.fromName || row.from }}</span>
            </div>
          </template>
        </el-table-column>
        
        <el-table-column prop="subject" label="主题">
          <template #default="{ row }">
            <div class="email-subject" @click="openEmail(row)">
              <span :class="{ unread: !row.read }">{{ row.subject }}</span>
              <span class="email-preview">{{ row.preview }}</span>
            </div>
          </template>
        </el-table-column>
        
        <el-table-column prop="attachments" width="40">
          <template #default="{ row }">
            <el-icon v-if="row.hasAttachments">
              <Paperclip />
            </el-icon>
          </template>
        </el-table-column>
        
        <el-table-column prop="date" label="时间" width="150">
          <template #default="{ row }">
            <span class="email-date">{{ formatDate(row.date) }}</span>
          </template>
        </el-table-column>
      </el-table>
      
      <el-pagination
        v-model:current-page="currentPage"
        v-model:page-size="pageSize"
        :total="total"
        :page-sizes="[20, 50, 100]"
        layout="total, sizes, prev, pager, next"
        @size-change="handleSizeChange"
        @current-change="handlePageChange"
        style="margin-top: 20px"
      />
    </div>
    
    <!-- 邮件详情对话框 -->
    <el-dialog
      v-model="emailDialogVisible"
      :title="currentEmail?.subject"
      width="70%"
      top="5vh"
    >
      <div class="email-detail" v-if="currentEmail">
        <div class="email-header">
          <div class="email-info">
            <p><strong>发件人：</strong>{{ currentEmail.from }}</p>
            <p><strong>收件人：</strong>{{ currentEmail.to }}</p>
            <p><strong>时间：</strong>{{ formatDateTime(currentEmail.date) }}</p>
          </div>
        </div>
        <div class="email-content" v-html="currentEmail.content"></div>
      </div>
      
      <template #footer>
        <el-button @click="replyEmail">回复</el-button>
        <el-button @click="forwardEmail">转发</el-button>
        <el-button type="danger" @click="deleteEmail">删除</el-button>
        <el-button @click="emailDialogVisible = false">关闭</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed } from 'vue'
import { ElMessage } from 'element-plus'
import {
  Refresh,
  Check,
  Delete,
  Warning,
  Star,
  StarFilled,
  Paperclip
} from '@element-plus/icons-vue'
import dayjs from 'dayjs'

// 模拟数据
const emails = ref([
  {
    id: 1,
    from: 'john@example.com',
    fromName: 'John Doe',
    to: 'me@enterprise.mail',
    subject: '项目进度更新',
    preview: '关于本周的项目进度，我想和您同步一下...',
    content: '<p>关于本周的项目进度，我想和您同步一下...</p>',
    date: new Date(),
    read: false,
    starred: false,
    hasAttachments: true
  },
  {
    id: 2,
    from: 'alice@example.com',
    fromName: 'Alice Smith',
    to: 'me@enterprise.mail',
    subject: '会议安排',
    preview: '下周二的会议时间需要调整...',
    content: '<p>下周二的会议时间需要调整...</p>',
    date: new Date(Date.now() - 86400000),
    read: true,
    starred: true,
    hasAttachments: false
  }
])

const currentPage = ref(1)
const pageSize = ref(20)
const total = ref(100)
const filter = ref('all')
const selectAll = ref(false)
const isIndeterminate = ref(false)
const selectedEmails = ref<any[]>([])
const emailDialogVisible = ref(false)
const currentEmail = ref<any>(null)

const hasSelected = computed(() => selectedEmails.value.length > 0)

const refreshEmails = () => {
  ElMessage.success('邮件列表已刷新')
}

const markAllAsRead = () => {
  emails.value.forEach(email => {
    email.read = true
  })
  ElMessage.success('已全部标记为已读')
}

const handleSelectAll = (val: boolean) => {
  if (val) {
    selectedEmails.value = [...emails.value]
  } else {
    selectedEmails.value = []
  }
  isIndeterminate.value = false
}

const handleSelectionChange = (val: any[]) => {
  selectedEmails.value = val
  const checkedCount = val.length
  selectAll.value = checkedCount === emails.value.length
  isIndeterminate.value = checkedCount > 0 && checkedCount < emails.value.length
}

const deleteSelected = () => {
  ElMessage.success(`已删除 ${selectedEmails.value.length} 封邮件`)
  selectedEmails.value = []
}

const markAsSpam = () => {
  ElMessage.success(`已将 ${selectedEmails.value.length} 封邮件标记为垃圾邮件`)
  selectedEmails.value = []
}

const toggleStar = () => {
  selectedEmails.value.forEach(email => {
    email.starred = !email.starred
  })
  ElMessage.success('已更新星标状态')
}

const toggleEmailStar = (email: any) => {
  email.starred = !email.starred
}

const openEmail = (email: any) => {
  currentEmail.value = email
  email.read = true
  emailDialogVisible.value = true
}

const replyEmail = () => {
  ElMessage.info('回复功能开发中')
}

const forwardEmail = () => {
  ElMessage.info('转发功能开发中')
}

const deleteEmail = () => {
  ElMessage.success('邮件已删除')
  emailDialogVisible.value = false
}

const formatDate = (date: Date) => {
  return dayjs(date).format('MM-DD HH:mm')
}

const formatDateTime = (date: Date) => {
  return dayjs(date).format('YYYY-MM-DD HH:mm:ss')
}

const handleSizeChange = (val: number) => {
  pageSize.value = val
}

const handlePageChange = (val: number) => {
  currentPage.value = val
}
</script>

<style lang="scss" scoped>
.inbox-container {
  background: white;
  border-radius: 4px;
  padding: 20px;
  
  .inbox-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 20px;
    
    h2 {
      margin: 0;
    }
  }
  
  .inbox-toolbar {
    display: flex;
    align-items: center;
    gap: 10px;
    margin-bottom: 20px;
    padding: 10px;
    background: #f5f5f5;
    border-radius: 4px;
  }
  
  .email-list {
    .star-icon {
      cursor: pointer;
      color: #ccc;
      
      &.starred {
        color: #f56c6c;
      }
      
      &:hover {
        color: #f56c6c;
      }
    }
    
    .email-from {
      .unread {
        font-weight: bold;
      }
    }
    
    .email-subject {
      cursor: pointer;
      
      .unread {
        font-weight: bold;
      }
      
      .email-preview {
        color: #999;
        margin-left: 10px;
      }
    }
    
    .email-date {
      color: #666;
      font-size: 12px;
    }
  }
  
  .email-detail {
    .email-header {
      border-bottom: 1px solid #e6e6e6;
      padding-bottom: 10px;
      margin-bottom: 20px;
      
      .email-info {
        p {
          margin: 5px 0;
        }
      }
    }
    
    .email-content {
      min-height: 200px;
      line-height: 1.6;
    }
  }
}</style>