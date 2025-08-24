<template>
  <el-container class="main-layout">
    <el-aside width="240px" class="sidebar">
      <div class="logo">
        <h2>企业邮件系统</h2>
      </div>
      
      <el-menu
        :default-active="activeMenu"
        class="sidebar-menu"
        :collapse="isCollapse"
        @select="handleMenuSelect"
      >
        <el-menu-item index="/compose">
          <el-icon><EditPen /></el-icon>
          <span>写邮件</span>
        </el-menu-item>
        
        <el-divider />
        
        <el-menu-item index="/inbox">
          <el-icon><Message /></el-icon>
          <span>收件箱</span>
          <el-badge v-if="unreadCount > 0" :value="unreadCount" class="menu-badge" />
        </el-menu-item>
        
        <el-menu-item index="/sent">
          <el-icon><Promotion /></el-icon>
          <span>已发送</span>
        </el-menu-item>
        
        <el-menu-item index="/drafts">
          <el-icon><Document /></el-icon>
          <span>草稿箱</span>
        </el-menu-item>
        
        <el-menu-item index="/starred">
          <el-icon><Star /></el-icon>
          <span>星标邮件</span>
        </el-menu-item>
        
        <el-menu-item index="/spam">
          <el-icon><Warning /></el-icon>
          <span>垃圾邮件</span>
        </el-menu-item>
        
        <el-menu-item index="/trash">
          <el-icon><Delete /></el-icon>
          <span>垃圾箱</span>
        </el-menu-item>
        
        <el-divider />
        
        <el-menu-item index="/aliases">
          <el-icon><User /></el-icon>
          <span>邮箱别名</span>
        </el-menu-item>
        
        <el-menu-item index="/domains">
          <el-icon><Link /></el-icon>
          <span>域名管理</span>
        </el-menu-item>
        
        <el-menu-item index="/settings">
          <el-icon><Setting /></el-icon>
          <span>设置</span>
        </el-menu-item>
      </el-menu>
    </el-aside>
    
    <el-container>
      <el-header class="header">
        <div class="header-left">
          <el-icon class="collapse-btn" @click="toggleCollapse">
            <Expand v-if="isCollapse" />
            <Fold v-else />
          </el-icon>
          
          <el-input
            v-model="searchQuery"
            placeholder="搜索邮件..."
            class="search-input"
            :prefix-icon="Search"
            @keyup.enter="handleSearch"
          />
        </div>
        
        <div class="header-right">
          <el-badge :value="notifications" class="notification-badge">
            <el-icon class="header-icon"><Bell /></el-icon>
          </el-badge>
          
          <el-dropdown @command="handleUserCommand">
            <div class="user-info">
              <el-avatar :size="32" :src="userAvatar">
                {{ userInitials }}
              </el-avatar>
              <span class="username">{{ userName }}</span>
              <el-icon><ArrowDown /></el-icon>
            </div>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item command="profile">
                  <el-icon><User /></el-icon>
                  个人资料
                </el-dropdown-item>
                <el-dropdown-item command="settings">
                  <el-icon><Setting /></el-icon>
                  设置
                </el-dropdown-item>
                <el-dropdown-item divided command="logout">
                  <el-icon><SwitchButton /></el-icon>
                  退出登录
                </el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </div>
      </el-header>
      
      <el-main class="main-content">
        <router-view v-slot="{ Component }">
          <transition name="fade-transform" mode="out-in">
            <component :is="Component" />
          </transition>
        </router-view>
      </el-main>
    </el-container>
  </el-container>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useUserStore } from '@/stores/user'
import {
  EditPen,
  Message,
  Promotion,
  Document,
  Star,
  Warning,
  Delete,
  User,
  Link,
  Setting,
  Expand,
  Fold,
  Search,
  Bell,
  ArrowDown,
  SwitchButton
} from '@element-plus/icons-vue'

const route = useRoute()
const router = useRouter()
const userStore = useUserStore()

const isCollapse = ref(false)
const searchQuery = ref('')
const unreadCount = ref(5)
const notifications = ref(3)

const activeMenu = computed(() => route.path)
const userName = computed(() => userStore.userInfo?.firstName || '用户')
const userInitials = computed(() => {
  const info = userStore.userInfo
  if (info?.firstName && info?.lastName) {
    return `${info.firstName[0]}${info.lastName[0]}`.toUpperCase()
  }
  return 'U'
})
const userAvatar = computed(() => userStore.userInfo?.avatar || '')

const toggleCollapse = () => {
  isCollapse.value = !isCollapse.value
}

const handleMenuSelect = (index: string) => {
  router.push(index)
}

const handleSearch = () => {
  // TODO: 实现搜索功能
  console.log('Search:', searchQuery.value)
}

const handleUserCommand = (command: string) => {
  switch (command) {
    case 'profile':
      router.push('/profile')
      break
    case 'settings':
      router.push('/settings')
      break
    case 'logout':
      userStore.logoutUser()
      break
  }
}
</script>

<style lang="scss" scoped>
.main-layout {
  height: 100vh;
  
  .sidebar {
    background-color: #fff;
    border-right: 1px solid #e6e6e6;
    
    .logo {
      height: 60px;
      display: flex;
      align-items: center;
      justify-content: center;
      border-bottom: 1px solid #e6e6e6;
      
      h2 {
        font-size: 18px;
        color: #333;
        margin: 0;
      }
    }
    
    .sidebar-menu {
      border: none;
      
      .menu-badge {
        position: absolute;
        right: 10px;
        top: 50%;
        transform: translateY(-50%);
      }
    }
  }
  
  .header {
    height: 60px;
    background-color: #fff;
    border-bottom: 1px solid #e6e6e6;
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 0 20px;
    
    .header-left {
      display: flex;
      align-items: center;
      
      .collapse-btn {
        font-size: 20px;
        cursor: pointer;
        margin-right: 20px;
        
        &:hover {
          color: #409eff;
        }
      }
      
      .search-input {
        width: 300px;
      }
    }
    
    .header-right {
      display: flex;
      align-items: center;
      gap: 20px;
      
      .notification-badge {
        cursor: pointer;
        
        .header-icon {
          font-size: 20px;
        }
      }
      
      .user-info {
        display: flex;
        align-items: center;
        gap: 10px;
        cursor: pointer;
        
        .username {
          color: #333;
        }
      }
    }
  }
  
  .main-content {
    background-color: #f5f5f5;
    padding: 20px;
  }
}

.fade-transform-enter-active,
.fade-transform-leave-active {
  transition: all 0.3s;
}

.fade-transform-enter-from {
  opacity: 0;
  transform: translateX(-30px);
}

.fade-transform-leave-to {
  opacity: 0;
  transform: translateX(30px);
}</style>