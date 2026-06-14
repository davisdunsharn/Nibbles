<template>
  <div class="min-h-screen bg-nibbles-cream flex items-center justify-center px-4">
    <div class="w-full max-w-md">
      <div class="bg-white rounded-2xl shadow-lg p-8">
        <div class="text-center mb-8">
          <div class="h-16 mx-auto mb-4 flex items-center justify-center">
            <img src="@/assets/nibbles-logo.png" alt="Nibbles Bakery" class="h-14 object-contain bg-transparent" />
          </div>
          <h1 class="text-3xl font-bold text-nibbles-dark tracking-tight">Nibbles Bakery</h1>
          <p class="text-gray-500 text-sm mt-2 font-medium">Management System</p>
        </div>

        <form @submit.prevent="handleLogin">
          <div class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Email address</label>
              <input
                v-model="email"
                type="email"
                required
                placeholder="you@nibblesbakery.co.za"
                class="w-full px-4 py-3 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-nibbles-red focus:border-transparent text-sm"
              />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Password</label>
              <input
                v-model="password"
                type="password"
                required
                placeholder="••••••••"
                class="w-full px-4 py-3 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-nibbles-red focus:border-transparent text-sm"
              />
            </div>
          </div>

          <div v-if="error" class="mt-4 p-3 bg-red-50 border border-red-200 rounded-lg">
            <p class="text-red-600 text-sm">{{ error }}</p>
          </div>

          <button
            type="submit"
            :disabled="loading"
            class="mt-6 w-full bg-nibbles-red hover:bg-nibbles-red-dark text-white font-semibold py-3 rounded-lg transition-colors disabled:opacity-60 disabled:cursor-not-allowed"
          >
            <span v-if="loading">Signing in...</span>
            <span v-else>Sign in</span>
          </button>
        </form>

        <p class="text-center text-xs text-gray-400 mt-6">
          Access by invitation only. Contact your administrator.
        </p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../../stores/auth'

const router = useRouter()
const auth = useAuthStore()
const email = ref('')
const password = ref('')
const loading = ref(false)
const error = ref('')

async function handleLogin() {
  loading.value = true
  error.value = ''
  try {
    const profile = await auth.login(email.value, password.value)
    if (profile?.role === 'admin') router.push('/admin')
    else if (profile?.role === 'manager') router.push('/manager')
    else if (profile?.role === 'cashier') router.push('/cashier')
    else { error.value = 'Account setup incomplete. Contact your administrator.'; await auth.logout() }
  } catch (err) {
    error.value = err.message === 'Invalid login credentials' ? 'Incorrect email or password.' : err.message
  } finally {
    loading.value = false
  }
}
</script>
