import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const routes = [
  { path: '/login', name: 'login', component: () => import('../views/auth/LoginView.vue'), meta: { requiresGuest: true } },
  {
    path: '/admin',
    component: () => import('../layouts/AdminLayout.vue'),
    meta: { requiresAuth: true, role: 'admin' },
    children: [
      { path: '', redirect: '/admin/dashboard' },
      { path: 'dashboard', name: 'admin-dashboard', component: () => import('../views/admin/AdminDashboard.vue') },
      { path: 'users', name: 'admin-users', component: () => import('../views/admin/UsersView.vue') },
      { path: 'branches', name: 'admin-branches', component: () => import('../views/admin/BranchesView.vue') },
      { path: 'products', name: 'admin-products', component: () => import('../views/admin/ProductsView.vue') },
      { path: 'suppliers', name: 'admin-suppliers', component: () => import('../views/admin/SuppliersView.vue') },
      { path: 'iot', name: 'admin-iot', component: () => import('../views/admin/IoTDashboard.vue') },
      { path: 'reports', name: 'admin-reports', component: () => import('../views/admin/ReportsView.vue') },
      { path: 'audit', name: 'admin-audit', component: () => import('../views/admin/AuditLog.vue') },
    ]
  },
  {
    path: '/manager',
    component: () => import('../layouts/ManagerLayout.vue'),
    meta: { requiresAuth: true, role: 'manager' },
    children: [
      { path: '', redirect: '/manager/dashboard' },
      { path: 'dashboard', name: 'manager-dashboard', component: () => import('../views/manager/ManagerDashboard.vue') },
      { path: 'inventory', name: 'manager-inventory', component: () => import('../views/manager/InventoryView.vue') },
      { path: 'orders', name: 'manager-orders', component: () => import('../views/manager/OrdersView.vue') },
      { path: 'shifts', name: 'manager-shifts', component: () => import('../views/manager/ShiftsView.vue') },
      { path: 'sales', name: 'manager-sales', component: () => import('../views/manager/SalesView.vue') },
      { path: 'customers', name: 'manager-customers', component: () => import('../views/manager/CustomersView.vue') },
    ]
  },
  {
    path: '/cashier',
    component: () => import('../layouts/CashierLayout.vue'),
    meta: { requiresAuth: true, role: 'cashier' },
    children: [
      { path: '', redirect: '/cashier/pos' },
      { path: 'pos', name: 'cashier-pos', component: () => import('../views/cashier/POSView.vue') },
    ]
  },
  { path: '/', redirect: '/login' },
  { path: '/:pathMatch(.*)*', redirect: '/login' }
]

const router = createRouter({ history: createWebHistory(), routes })

router.beforeEach(async (to) => {
  const auth = useAuthStore()
  if (auth.loading) {
    await new Promise(resolve => {
      const interval = setInterval(() => { if (!auth.loading) { clearInterval(interval); resolve() } }, 50)
    })
  }
  const isLoggedIn = !!auth.user
  const userRole = auth.role
  if (to.meta.requiresGuest && isLoggedIn) {
    if (userRole === 'admin') return '/admin'
    if (userRole === 'manager') return '/manager'
    if (userRole === 'cashier') return '/cashier'
  }
  if (to.meta.requiresAuth) {
    if (!isLoggedIn) return '/login'
    if (to.meta.role && userRole !== to.meta.role) {
      if (userRole === 'admin') return '/admin'
      if (userRole === 'manager') return '/manager'
      if (userRole === 'cashier') return '/cashier'
    }
  }
})

export default router
