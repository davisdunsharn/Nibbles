<template>
  <div class="min-h-screen bg-transparent flex items-center justify-center px-4 py-10">
    <div class="w-full max-w-sm">
      <div class="text-center mb-8">
        <img src="@/assets/nibbles-logo.png" alt="Nibbles Bakery" class="h-28 w-auto object-contain mx-auto mb-3" />
        <p class="text-ink-muted text-sm tracking-[0.18em] uppercase">Set a new password</p>
      </div>

      <div class="card p-7">
        <div v-if="done" class="text-center py-4">
          <span class="w-12 h-12 rounded-2xl bg-emerald-50 text-emerald-600 flex items-center justify-center mx-auto mb-3">
            <AppIcon name="check-circle" :size="24" />
          </span>
          <p class="text-sm text-ink-soft">Your password has been updated.</p>
          <router-link to="/login" class="btn-primary w-full mt-5">Go to sign in</router-link>
        </div>

        <form v-else @submit.prevent="handleSubmit" class="space-y-4">
          <div>
            <label class="label">New password</label>
            <PasswordInput v-model="password" required minlength="8" placeholder="At least 8 characters" />
          </div>
          <div>
            <label class="label">Confirm password</label>
            <PasswordInput v-model="confirm" required minlength="8" placeholder="Re-enter password" />
          </div>

          <div v-if="error" class="flex items-start gap-2 p-3 bg-red-50 border border-red-100 rounded-xl">
            <AppIcon name="alert" :size="16" class="text-red-500 mt-0.5 flex-shrink-0" />
            <p class="text-red-600 text-sm">{{ error }}</p>
          </div>

          <button type="submit" :disabled="loading" class="btn-primary w-full py-3">
            <span v-if="loading">Updating…</span>
            <span v-else>Update password</span>
          </button>
          <router-link to="/login" class="btn-ghost w-full">Back to sign in</router-link>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useAuthStore } from '../../stores/auth'
import AppIcon from '../../components/AppIcon.vue'
import PasswordInput from '../../components/PasswordInput.vue'

const auth = useAuthStore()
const password = ref('')
const confirm = ref('')
const loading = ref(false)
const error = ref('')
const done = ref(false)

async function handleSubmit() {
  error.value = ''
  if (password.value.length < 8) { error.value = 'Password must be at least 8 characters.'; return }
  if (password.value !== confirm.value) { error.value = 'Passwords do not match.'; return }
  loading.value = true
  try {
    await auth.updatePassword(password.value)
    done.value = true
  } catch (err) {
    error.value = err.message?.includes('session')
      ? 'Your reset link has expired. Please request a new one from the sign-in page.'
      : (err.message || 'Could not update password.')
  } finally {
    loading.value = false
  }
}
</script>
