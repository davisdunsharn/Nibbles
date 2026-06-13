<template>
  <div class="h-screen bg-gray-100 flex flex-col">
    <header class="bg-nibbles-dark px-6 py-3 flex items-center justify-between">
      <div class="flex items-center gap-3">
        <div class="w-7 h-7 bg-nibbles-red rounded flex items-center justify-center">
          <span class="text-white text-xs font-bold">N</span>
        </div>
        <span class="text-white font-semibold text-sm">Nibbles POS</span>
      </div>
      <div class="flex items-center gap-4">
        <span class="text-gray-300 text-sm">{{ auth.fullName }}</span>
        <button @click="handleLogout" class="text-gray-400 hover:text-white text-xs transition-colors">Sign out</button>
      </div>
    </header>
    <main class="flex-1 overflow-hidden">
      <router-view />
    </main>
  </div>
</template>

<script setup>
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
const auth = useAuthStore()
const router = useRouter()
async function handleLogout() { await auth.logout(); router.push('/login') }
</script>
