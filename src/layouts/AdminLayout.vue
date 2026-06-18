<template>
  <div class="flex h-screen bg-transparent overflow-hidden">
    <!-- Sidebar -->
    <aside class="w-64 bg-ink flex flex-col flex-shrink-0">
      <div class="px-5 py-6 border-b border-white/10">
        <div class="flex flex-col items-center text-center gap-2.5">
          <img src="@/assets/nibbles-logo.png" alt="Nibbles Bakery" class="h-16 w-auto object-contain" />
          <p class="text-stone-400 text-[11px] font-medium tracking-[0.18em] uppercase">Admin Portal</p>
        </div>
      </div>

      <nav class="flex-1 px-3 py-4 space-y-0.5 overflow-y-auto">
        <router-link
          v-for="item in navItems"
          :key="item.path"
          :to="item.path"
          class="nav-link"
          active-class="!bg-brand-600 !text-white shadow-sm"
        >
          <AppIcon :name="item.icon" :size="18" />
          {{ item.label }}
        </router-link>
      </nav>

      <div class="p-3 border-t border-white/10">
        <div class="flex items-center gap-3 px-2 py-2">
          <div class="w-9 h-9 bg-brand-600/90 rounded-full flex items-center justify-center flex-shrink-0">
            <span class="text-white text-xs font-semibold">{{ initials }}</span>
          </div>
          <div class="flex-1 min-w-0">
            <p class="text-white text-sm font-medium truncate">{{ auth.fullName }}</p>
            <p class="text-stone-400 text-xs">Administrator</p>
          </div>
        </div>
        <button
          @click="handleLogout"
          class="mt-1 w-full flex items-center gap-2 text-stone-400 hover:text-white text-sm px-3 py-2 rounded-xl hover:bg-white/5 transition-colors"
        >
          <AppIcon name="logout" :size="16" />
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
import AppIcon from '../components/AppIcon.vue'

const auth = useAuthStore()
const router = useRouter()
const initials = computed(() => {
  const p = auth.profile
  return p ? `${p.first_name[0]}${p.last_name[0]}`.toUpperCase() : 'A'
})

const navItems = [
  { path: '/admin/dashboard', label: 'Dashboard', icon: 'dashboard' },
  { path: '/admin/users', label: 'Users', icon: 'users' },
  { path: '/admin/branches', label: 'Branches', icon: 'store' },
  { path: '/admin/products', label: 'Products', icon: 'croissant' },
  { path: '/admin/suppliers', label: 'Suppliers', icon: 'truck' },
  { path: '/admin/iot', label: 'IoT Dashboard', icon: 'radio' },
  { path: '/admin/reports', label: 'Reports & BI', icon: 'chart' },
  { path: '/admin/audit', label: 'Audit Log', icon: 'audit' },
  { path: '/admin/announcements', label: 'Announcements', icon: 'megaphone' },
]

async function handleLogout() {
  await auth.logout()
  router.push('/login')
}
</script>
