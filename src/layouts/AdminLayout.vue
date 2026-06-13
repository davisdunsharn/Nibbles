<template>
  <div class="flex h-screen bg-gray-50 overflow-hidden">
    <!-- Sidebar -->
    <aside class="w-64 bg-nibbles-dark flex flex-col flex-shrink-0">
      <div class="p-6 border-b border-gray-700">
        <div class="flex items-center gap-3">
          <div class="w-8 h-8 bg-nibbles-red rounded-lg flex items-center justify-center">
            <span class="text-white text-sm font-bold">N</span>
          </div>
          <div>
            <p class="text-white font-semibold text-sm">Nibbles Bakery</p>
            <p class="text-gray-400 text-xs">Admin Portal</p>
          </div>
        </div>
      </div>
      <nav class="flex-1 p-4 space-y-1 overflow-y-auto">
        <router-link v-for="item in navItems" :key="item.path" :to="item.path"
          class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm text-gray-400 hover:text-white hover:bg-gray-700 transition-colors"
          active-class="bg-nibbles-red text-white">
          <span class="text-lg">{{ item.icon }}</span>
          {{ item.label }}
        </router-link>
      </nav>
      <div class="p-4 border-t border-gray-700">
        <div class="flex items-center gap-3 mb-3">
          <div class="w-8 h-8 bg-gray-600 rounded-full flex items-center justify-center">
            <span class="text-white text-xs font-medium">{{ initials }}</span>
          </div>
          <div class="flex-1 min-w-0">
            <p class="text-white text-sm font-medium truncate">{{ auth.fullName }}</p>
            <p class="text-gray-400 text-xs">Administrator</p>
          </div>
        </div>
        <button @click="handleLogout" class="w-full text-left text-gray-400 hover:text-white text-xs px-3 py-2 rounded hover:bg-gray-700 transition-colors">
          Sign out
        </button>
      </div>
    </aside>
    <!-- Main -->
    <main class="flex-1 overflow-y-auto">
      <router-view />
    </main>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const auth = useAuthStore()
const router = useRouter()
const initials = computed(() => {
  const p = auth.profile
  return p ? `${p.first_name[0]}${p.last_name[0]}`.toUpperCase() : 'A'
})

const navItems = [
  { path: '/admin/dashboard', label: 'Dashboard', icon: '📊' },
  { path: '/admin/users', label: 'Users', icon: '👥' },
  { path: '/admin/branches', label: 'Branches', icon: '🏪' },
  { path: '/admin/products', label: 'Products', icon: '🍞' },
  { path: '/admin/suppliers', label: 'Suppliers', icon: '🚛' },
  { path: '/admin/iot', label: 'IoT Dashboard', icon: '📡' },
  { path: '/admin/reports', label: 'Reports & BI', icon: '📈' },
  { path: '/admin/audit', label: 'Audit Log', icon: '🔍' },
]

async function handleLogout() {
  await auth.logout()
  router.push('/login')
}
</script>
