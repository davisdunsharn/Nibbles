<template>
  <div class="p-6">
    <div class="flex items-center justify-between mb-6">
      <div>
        <h1 class="text-2xl font-bold text-nibbles-dark">Users</h1>
        <p class="text-gray-500 text-sm mt-1">Manage staff accounts across all branches</p>
      </div>
      <button @click="showModal = true" class="bg-nibbles-red text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-nibbles-red-dark transition-colors">
        + Add User
      </button>
    </div>

    <div class="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
      <div class="p-4 border-b border-gray-100 flex gap-3">
        <input v-model="search" type="text" placeholder="Search by name or email..."
          class="flex-1 px-4 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-nibbles-red" />
        <select v-model="filterRole" class="px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-nibbles-red">
          <option value="">All roles</option>
          <option value="admin">Admin</option>
          <option value="manager">Manager</option>
          <option value="cashier">Cashier</option>
        </select>
      </div>
      <table class="w-full text-sm">
        <thead>
          <tr class="text-left text-gray-400 border-b border-gray-100 bg-gray-50">
            <th class="px-4 py-3 font-medium">Name</th>
            <th class="px-4 py-3 font-medium">Role</th>
            <th class="px-4 py-3 font-medium">Branch</th>
            <th class="px-4 py-3 font-medium">Created</th>
            <th class="px-4 py-3 font-medium">Status</th>
            <th class="px-4 py-3 font-medium">Actions</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-50">
          <tr v-if="loading"><td colspan="6" class="px-4 py-8 text-center text-gray-400">Loading...</td></tr>
          <tr v-else-if="filteredUsers.length === 0"><td colspan="6" class="px-4 py-8 text-center text-gray-400">No users found.</td></tr>
          <tr v-for="u in filteredUsers" :key="u.id" class="hover:bg-gray-50">
            <td class="px-4 py-3">
              <div class="flex items-center gap-3">
                <div class="w-8 h-8 bg-nibbles-red rounded-full flex items-center justify-center">
                  <span class="text-white text-xs font-medium">{{ u.first_name[0] }}{{ u.last_name[0] }}</span>
                </div>
                <div>
                  <p class="font-medium text-gray-800">{{ u.first_name }} {{ u.last_name }}</p>
                </div>
              </div>
            </td>
            <td class="px-4 py-3">
              <span :class="roleClass(u.role)" class="px-2 py-0.5 rounded text-xs font-medium capitalize">{{ u.role }}</span>
            </td>
            <td class="px-4 py-3 text-gray-600">{{ u.branches?.name || '— All branches' }}</td>
            <td class="px-4 py-3 text-gray-400">{{ formatDate(u.created_at) }}</td>
            <td class="px-4 py-3">
              <span :class="u.is_active ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'"
                class="px-2 py-0.5 rounded text-xs font-medium">{{ u.is_active ? 'Active' : 'Inactive' }}</span>
            </td>
            <td class="px-4 py-3">
              <button @click="toggleStatus(u)" class="text-xs text-gray-500 hover:text-nibbles-red transition-colors">
                {{ u.is_active ? 'Deactivate' : 'Activate' }}
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Create User Modal -->
    <div v-if="showModal" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 px-4">
      <div class="bg-white rounded-2xl p-6 w-full max-w-md">
        <h2 class="text-lg font-bold text-nibbles-dark mb-4">Create New User</h2>
        <form @submit.prevent="createUser" class="space-y-4">
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">First name</label>
              <input v-model="form.first_name" type="text" required class="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-nibbles-red" />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Last name</label>
              <input v-model="form.last_name" type="text" required class="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-nibbles-red" />
            </div>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Email address</label>
            <input v-model="form.email" type="email" required class="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-nibbles-red" />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Temporary password</label>
            <input v-model="form.password" type="password" required minlength="8" class="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-nibbles-red" />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Role</label>
            <select v-model="form.role" required class="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-nibbles-red">
              <option value="">Select role</option>
              <option value="manager">Manager</option>
              <option value="cashier">Cashier</option>
            </select>
          </div>
          <div v-if="form.role !== 'admin'">
            <label class="block text-sm font-medium text-gray-700 mb-1">Branch</label>
            <select v-model="form.branch_id" :required="form.role !== ''" class="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-nibbles-red">
              <option value="">Select branch</option>
              <option v-for="b in branchList" :key="b.id" :value="b.id">{{ b.name }}</option>
            </select>
          </div>
          <div v-if="formError" class="p-3 bg-red-50 border border-red-200 rounded-lg text-red-600 text-sm">{{ formError }}</div>
          <div class="flex gap-3 pt-2">
            <button type="button" @click="closeModal" class="flex-1 px-4 py-2 border border-gray-200 rounded-lg text-sm font-medium text-gray-600 hover:bg-gray-50">Cancel</button>
            <button type="submit" :disabled="creating" class="flex-1 bg-nibbles-red text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-nibbles-red-dark disabled:opacity-60">
              {{ creating ? 'Creating...' : 'Create User' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../../lib/supabase'

const users = ref([])
const branchList = ref([])
const loading = ref(true)
const search = ref('')
const filterRole = ref('')
const showModal = ref(false)
const creating = ref(false)
const formError = ref('')
const form = ref({ first_name: '', last_name: '', email: '', password: '', role: '', branch_id: '' })

const filteredUsers = computed(() => {
  return users.value.filter(u => {
    const matchSearch = !search.value || `${u.first_name} ${u.last_name}`.toLowerCase().includes(search.value.toLowerCase())
    const matchRole = !filterRole.value || u.role === filterRole.value
    return matchSearch && matchRole
  })
})

function roleClass(role) {
  return { admin: 'bg-purple-100 text-purple-700', manager: 'bg-blue-100 text-blue-700', cashier: 'bg-green-100 text-green-700' }[role] || ''
}

function formatDate(d) { return new Date(d).toLocaleDateString('en-ZA') }

async function loadData() {
  loading.value = true
  const { data } = await supabase.from('user_profiles').select('*, branches(name)').order('created_at', { ascending: false })
  if (data) users.value = data
  const { data: b } = await supabase.from('branches').select('id, name').eq('is_active', true)
  if (b) branchList.value = b
  loading.value = false
}

async function toggleStatus(user) {
  const { error } = await supabase.from('user_profiles').update({ is_active: !user.is_active }).eq('id', user.id)
  if (!error) user.is_active = !user.is_active
}

async function createUser() {
  creating.value = true
  formError.value = ''
  try {
    const { data, error } = await supabase.auth.admin.createUser({
      email: form.value.email,
      password: form.value.password,
      email_confirm: true
    })
    if (error) throw error
    const { error: profileError } = await supabase.from('user_profiles').insert({
      id: data.user.id,
      first_name: form.value.first_name,
      last_name: form.value.last_name,
      role: form.value.role,
      branch_id: form.value.branch_id || null,
      is_active: true
    })
    if (profileError) throw profileError
    closeModal()
    await loadData()
  } catch (err) {
    formError.value = err.message
  } finally {
    creating.value = false
  }
}

function closeModal() {
  showModal.value = false
  formError.value = ''
  form.value = { first_name: '', last_name: '', email: '', password: '', role: '', branch_id: '' }
}

onMounted(loadData)
</script>
