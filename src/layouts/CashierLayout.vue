<template>
  <div class="h-screen bg-transparent flex flex-col">
    <header class="bg-ink px-6 py-3 flex items-center justify-between flex-shrink-0">
      <div class="flex items-center gap-4">
        <img src="@/assets/nibbles-logo.png" alt="Nibbles Bakery" class="h-11 w-auto object-contain" />
        <nav class="flex items-center gap-1">
          <router-link to="/cashier/pos" class="px-3 py-1.5 rounded-lg text-sm font-medium text-stone-400 hover:text-white transition-colors" active-class="!text-white bg-white/10">Point of Sale</router-link>
          <router-link to="/cashier/announcements" class="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-sm font-medium text-stone-400 hover:text-white transition-colors" active-class="!text-white bg-white/10">
            <AppIcon name="megaphone" :size="15" /> Announcements
          </router-link>
        </nav>
      </div>
      <div class="flex items-center gap-4">
        <!-- Clock in/out -->
        <button
          v-if="shiftStatus === 'scheduled' || shiftStatus === 'late'"
          @click="clock('in')" :disabled="clocking"
          class="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-emerald-500/90 hover:bg-emerald-500 text-white text-xs font-semibold transition-colors"
        ><AppIcon name="clock" :size="14" /> Clock in</button>
        <button
          v-else-if="shiftStatus === 'in_progress'"
          @click="clock('out')" :disabled="clocking"
          class="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-white/10 hover:bg-white/15 text-white text-xs font-semibold transition-colors"
        ><AppIcon name="clock" :size="14" /> Clock out</button>
        <span v-else-if="shiftStatus === 'completed'" class="flex items-center gap-1.5 text-emerald-400 text-xs font-medium">
          <AppIcon name="check-circle" :size="14" /> Shift done
        </span>
        <span v-else class="text-stone-500 text-xs">Off today</span>

        <div class="w-px h-5 bg-white/10"></div>

        <div class="flex items-center gap-2 text-stone-300 text-sm">
          <span class="w-7 h-7 bg-brand-600/90 rounded-full flex items-center justify-center text-white text-[11px] font-semibold">{{ initials }}</span>
          <span>{{ auth.fullName }}</span>
        </div>
        <button @click="handleLogout" class="flex items-center gap-1.5 text-stone-400 hover:text-white text-sm transition-colors">
          <AppIcon name="logout" :size="16" />
          Sign out
        </button>
      </div>
    </header>
    <main class="flex-1 overflow-hidden">
      <router-view />
    </main>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import { supabase } from '../lib/supabase'
import AppIcon from '../components/AppIcon.vue'
import { useToast } from '../composables/useToast'

const auth = useAuthStore()
const router = useRouter()
const toast = useToast()
const shiftStatus = ref(null) // null = no shift today
const clocking = ref(false)

const initials = computed(() => {
  const p = auth.profile
  return p ? `${p.first_name[0]}${p.last_name[0]}`.toUpperCase() : 'C'
})

async function loadShift() {
  const today = new Date().toISOString().slice(0, 10)
  const { data } = await supabase.from('shifts')
    .select('status').eq('staff_id', auth.user.id).eq('shift_date', today)
    .order('planned_start').limit(1).maybeSingle()
  shiftStatus.value = data?.status ?? 'off'
}

async function clock(action) {
  clocking.value = true
  try {
    const { data, error } = await supabase.rpc('clock_shift', { p_action: action })
    if (error) throw error
    if (!data?.ok) { toast.error(data?.message || 'Could not clock'); return }
    shiftStatus.value = data.status
    toast.success(action === 'in' ? 'Clocked in — have a great shift!' : 'Clocked out. See you next time!')
  } catch (err) {
    toast.error(err.message)
  } finally {
    clocking.value = false
  }
}

async function handleLogout() { await auth.logout(); router.push('/login') }

onMounted(loadShift)
</script>
