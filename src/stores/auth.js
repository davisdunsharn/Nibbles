import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '../lib/supabase'

export const useAuthStore = defineStore('auth', () => {
  const user = ref(null)
  const profile = ref(null)
  const loading = ref(true)

  const isAdmin = computed(() => profile.value?.role === 'admin')
  const isManager = computed(() => profile.value?.role === 'manager')
  const isCashier = computed(() => profile.value?.role === 'cashier')
  const branchId = computed(() => profile.value?.branch_id)
  const role = computed(() => profile.value?.role)
  const fullName = computed(() => profile.value ? `${profile.value.first_name} ${profile.value.last_name}` : '')

  async function fetchProfile(userId) {
    const { data, error } = await supabase
      .from('user_profiles')
      .select('*')
      .eq('id', userId)
      .single()
    if (error) { console.error('Profile fetch error:', error); return null }
    return data
  }

  async function init() {
    loading.value = true
    const { data: { session } } = await supabase.auth.getSession()
    if (session?.user) {
      user.value = session.user
      profile.value = await fetchProfile(session.user.id)
    }
    supabase.auth.onAuthStateChange(async (event, session) => {
      if (session?.user) {
        user.value = session.user
        profile.value = await fetchProfile(session.user.id)
      } else {
        user.value = null
        profile.value = null
      }
    })
    loading.value = false
  }

  async function login(email, password) {
    const { data, error } = await supabase.auth.signInWithPassword({ email, password })
    if (error) throw error
    profile.value = await fetchProfile(data.user.id)
    return profile.value
  }

  async function logout() {
    await supabase.auth.signOut()
    user.value = null
    profile.value = null
  }

  return { user, profile, loading, isAdmin, isManager, isCashier, branchId, role, fullName, init, login, logout }
})
