import { createRouter, createWebHistory, RouteRecordRaw } from 'vue-router'
import { useUserStore } from '@/stores/user'
import NProgress from 'nprogress'
import 'nprogress/nprogress.css'

const routes: RouteRecordRaw[] = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('@/views/Login.vue'),
    meta: { requiresAuth: false }
  },
  {
    path: '/register',
    name: 'Register',
    component: () => import('@/views/Register.vue'),
    meta: { requiresAuth: false }
  },
  {
    path: '/',
    component: () => import('@/layouts/MainLayout.vue'),
    meta: { requiresAuth: true },
    children: [
      {
        path: '',
        redirect: '/inbox'
      },
      {
        path: 'inbox',
        name: 'Inbox',
        component: () => import('@/views/mail/Inbox.vue'),
        meta: { title: '收件箱' }
      },
      {
        path: 'compose',
        name: 'Compose',
        component: () => import('@/views/mail/Compose.vue'),
        meta: { title: '写邮件' }
      },
      {
        path: 'sent',
        name: 'Sent',
        component: () => import('@/views/mail/Sent.vue'),
        meta: { title: '已发送' }
      },
      {
        path: 'drafts',
        name: 'Drafts',
        component: () => import('@/views/mail/Drafts.vue'),
        meta: { title: '草稿箱' }
      },
      {
        path: 'trash',
        name: 'Trash',
        component: () => import('@/views/mail/Trash.vue'),
        meta: { title: '垃圾箱' }
      },
      {
        path: 'spam',
        name: 'Spam',
        component: () => import('@/views/mail/Spam.vue'),
        meta: { title: '垃圾邮件' }
      },
      {
        path: 'starred',
        name: 'Starred',
        component: () => import('@/views/mail/Starred.vue'),
        meta: { title: '星标邮件' }
      },
      {
        path: 'aliases',
        name: 'Aliases',
        component: () => import('@/views/alias/AliasList.vue'),
        meta: { title: '邮箱别名' }
      },
      {
        path: 'domains',
        name: 'Domains',
        component: () => import('@/views/domain/DomainList.vue'),
        meta: { title: '域名管理' }
      },
      {
        path: 'settings',
        name: 'Settings',
        component: () => import('@/views/settings/Settings.vue'),
        meta: { title: '设置' }
      },
      {
        path: 'profile',
        name: 'Profile',
        component: () => import('@/views/profile/Profile.vue'),
        meta: { title: '个人资料' }
      }
    ]
  },
  {
    path: '/:pathMatch(.*)*',
    name: 'NotFound',
    component: () => import('@/views/NotFound.vue')
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// 路由守卫
router.beforeEach(async (to, from, next) => {
  NProgress.start()
  
  const userStore = useUserStore()
  const requiresAuth = to.meta.requiresAuth !== false
  
  if (requiresAuth && !userStore.isAuthenticated) {
    next('/login')
  } else if (!requiresAuth && userStore.isAuthenticated && (to.path === '/login' || to.path === '/register')) {
    next('/')
  } else {
    next()
  }
})

router.afterEach(() => {
  NProgress.done()
})

export default router