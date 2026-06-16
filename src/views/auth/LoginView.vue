<template>
  <div class="min-h-screen bg-transparent flex items-center justify-center px-4 py-10">
    <div class="w-full max-w-sm">
      <div class="text-center mb-8">
        <img src="@/assets/nibbles-logo.png" alt="Nibbles Bakery" class="h-28 w-auto object-contain mx-auto mb-3" />
        <p class="text-ink-muted text-sm tracking-[0.18em] uppercase">Management System</p>
      </div>

      <div class="card p-7">
        <!-- Sign in -->
        <form v-if="mode === 'login'" @submit.prevent="handleLogin" class="space-y-4">
          <div>
            <label class="label">Email address</label>
            <input v-model="email" type="email" required placeholder="you@nibblesbakery.co.za" class="input" />
          </div>
          <div>
            <div class="flex items-center justify-between mb-1.5">
              <label class="label mb-0">Password</label>
              <button type="button" @click="switchMode('forgot')" class="text-xs font-medium text-brand-600 hover:text-brand-700">Forgot password?</button>
            </div>
            <PasswordInput v-model="password" required placeholder="••••••••" />
          </div>

          <div v-if="error" class="flex items-start gap-2 p-3 bg-red-50 border border-red-100 rounded-xl">
            <AppIcon name="alert" :size="16" class="text-red-500 mt-0.5 flex-shrink-0" />
            <p class="text-red-600 text-sm">{{ error }}</p>
          </div>

          <button type="submit" :disabled="loading" class="btn-primary w-full py-3">
            <span v-if="loading">Signing in…</span>
            <span v-else>Sign in</span>
          </button>
        </form>

        <!-- Forgot password -->
        <form v-else @submit.prevent="handleReset" class="space-y-4">
          <div>
            <h2 class="font-display text-lg font-semibold text-ink">Reset your password</h2>
            <p class="text-ink-muted text-sm mt-1">Enter your email and we'll send a secure reset link.</p>
          </div>
          <div>
            <label class="label">Email address</label>
            <input v-model="email" type="email" required placeholder="you@nibblesbakery.co.za" class="input" />
          </div>

          <div v-if="error" class="flex items-start gap-2 p-3 bg-red-50 border border-red-100 rounded-xl">
            <AppIcon name="alert" :size="16" class="text-red-500 mt-0.5 flex-shrink-0" />
            <p class="text-red-600 text-sm">{{ error }}</p>
          </div>
          <div v-if="notice" class="flex items-start gap-2 p-3 bg-emerald-50 border border-emerald-100 rounded-xl">
            <AppIcon name="check-circle" :size="16" class="text-emerald-500 mt-0.5 flex-shrink-0" />
            <p class="text-emerald-700 text-sm">{{ notice }}</p>
          </div>

          <button type="submit" :disabled="loading" class="btn-primary w-full py-3">
            <span v-if="loading">Sending…</span>
            <span v-else>Send reset link</span>
          </button>
          <button type="button" @click="switchMode('login')" class="btn-ghost w-full">Back to sign in</button>
        </form>
      </div>

      <p class="text-center text-xs text-ink-muted mt-6">
        Access by invitation only. Contact your administrator.
      </p>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../../stores/auth'
import AppIcon from '../../components/AppIcon.vue'
import PasswordInput from '../../components/PasswordInput.vue'

const router = useRouter()
const auth = useAuthStore()
const mode = ref('login')
const email = ref('')
const password = ref('')
const loading = ref(false)
const error = ref('')
const notice = ref('')

function switchMode(m) { mode.value = m; error.value = ''; notice.value = '' }

function friendlyError(msg) {
  if (!msg) return 'Something went wrong. Please try again.'
  if (msg === 'Invalid login credentials') return 'Incorrect email or password.'
  if (msg.includes('Email not confirmed')) return 'This account is not yet confirmed. Contact your administrator.'
  if (msg.includes('rate limit') || msg.includes('Too many')) return 'Too many attempts. Please wait a moment and try again.'
  return msg
}

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
    error.value = friendlyError(err.message)
  } finally {
    loading.value = false
  }
}

async function handleReset() {
  loading.value = true
  error.value = ''
  notice.value = ''
  try {
    await auth.resetPassword(email.value)
    notice.value = `If an account exists for ${email.value}, a password reset link is on its way. Check your inbox (and spam).`
  } catch (err) {
    error.value = friendlyError(err.message)
  } finally {
    loading.value = false
  }
}
</script>
