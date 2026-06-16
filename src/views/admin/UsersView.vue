<template>
  <div class="p-8">
    <div class="flex items-center justify-between mb-6">
      <div>
        <h1 class="font-display text-3xl font-semibold text-ink tracking-tight">Users</h1>
        <p class="text-ink-muted text-sm mt-1">Manage staff accounts across all branches</p>
      </div>
      <button @click="showModal = true" class="btn-primary">
        <AppIcon name="plus" :size="16" :stroke-width="2.25" />
        Add User
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
              <div class="flex gap-2">
                <button @click="editUser(u)" class="text-xs text-blue-600 hover:text-blue-800 font-semibold">Edit</button>
                <button @click="deleteUser(u)" class="text-xs text-red-600 hover:text-red-800 font-semibold">Delete</button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- User Modal -->
    <div v-if="showModal" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 px-4">
      <div class="bg-white rounded-2xl p-6 w-full max-w-md">
        <h2 class="text-lg font-bold text-nibbles-dark mb-4">{{ editingId ? 'Edit User' : 'Create New User' }}</h2>
        <form @submit.prevent="saveUser" class="space-y-4">
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
          <div v-if="!editingId">
            <label class="block text-sm font-medium text-gray-700 mb-1">Email address</label>
            <input v-model="form.email" type="email" required class="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-nibbles-red" />
          </div>
          <div v-if="!editingId">
            <label class="block text-sm font-medium text-gray-700 mb-1">Temporary password</label>
            <PasswordInput v-model="form.password" required minlength="8" />
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
          <div>
            <label class="flex items-center">
              <input v-model="form.is_active" type="checkbox" class="w-4 h-4 text-nibbles-red rounded focus:ring-nibbles-red" />
              <span class="ml-2 text-sm text-gray-700">Active</span>
            </label>
          </div>
          <div v-if="formError" class="p-3 bg-red-50 border border-red-200 rounded-lg text-red-600 text-sm">{{ formError }}</div>
          <div class="flex gap-3 pt-2">
            <button type="button" @click="closeModal" class="flex-1 px-4 py-2 border border-gray-200 rounded-lg text-sm font-medium text-gray-600 hover:bg-gray-50">Cancel</button>
            <button type="submit" :disabled="creating" class="flex-1 bg-nibbles-red text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-nibbles-red-dark disabled:opacity-60">
              {{ creating ? 'Saving...' : editingId ? 'Update' : 'Create User' }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- Delete confirmation modal -->
    <div v-if="showDeleteConfirm" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 px-4">
      <div class="bg-white rounded-2xl p-6 w-full max-w-sm">
        <h2 class="text-lg font-bold text-nibbles-dark mb-2">Delete User?</h2>
        <p class="text-gray-600 mb-6">Are you sure you want to delete <span class="font-semibold">{{ deleteItem?.first_name }} {{ deleteItem?.last_name }}</span>? This cannot be undone.</p>
        <div class="flex gap-3">
          <button @click="showDeleteConfirm = false" class="flex-1 px-4 py-2 border border-gray-200 rounded-lg text-sm text-gray-600 hover:bg-gray-50">
            Cancel
          </button>
          <button @click="confirmDelete" :disabled="deleting" class="flex-1 bg-red-600 text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-red-700 disabled:opacity-60">
            {{ deleting ? 'Deleting...' : 'Delete' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../../lib/supabase'
import { useToast } from '../../composables/useToast'
import AppIcon from '../../components/AppIcon.vue'
import PasswordInput from '../../components/PasswordInput.vue'

const toast = useToast()
const users = ref([])
const branchList = ref([])
const loading = ref(true)
const search = ref('')
const filterRole = ref('')
const showModal = ref(false)
const showDeleteConfirm = ref(false)
const creating = ref(false)
const deleting = ref(false)
const formError = ref('')
const editingId = ref(null)
const deleteItem = ref(null)
const form = ref({ first_name: '', last_name: '', email: '', password: '', role: '', branch_id: '', is_active: true })

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

async function saveUser() {
  creating.value = true
  formError.value = ''
  try {
    if (editingId.value) {
      // Update existing user
      const { error } = await supabase.from('user_profiles').update({
        first_name: form.value.first_name,
        last_name: form.value.last_name,
        role: form.value.role,
        branch_id: form.value.branch_id || null,
        is_active: form.value.is_active
      }).eq('id', editingId.value)
      
      if (error) throw error
    } else {
      // Create new user
      const { data: sessionData } = await supabase.auth.getSession()
      if (!sessionData.session) throw new Error('Not authenticated')

      const response = await fetch(
        `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/create-user`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${sessionData.session.access_token}`
          },
          body: JSON.stringify({
            email: form.value.email,
            password: form.value.password,
            first_name: form.value.first_name,
            last_name: form.value.last_name,
            role: form.value.role,
            branch_id: form.value.branch_id || null
          })
        }
      )

      const result = await response.json()
      if (!response.ok) throw new Error(result.error || 'Failed to create user')
    }
    
    closeModal()
    await loadData()
    toast.success(editingId.value ? 'User updated' : 'User created')
  } catch (err) {
    formError.value = err.message
    toast.error(err.message)
  } finally {
    creating.value = false
  }
}

function editUser(user) {
  editingId.value = user.id
  form.value = {
    first_name: user.first_name,
    last_name: user.last_name,
    email: user.email || '',
    password: '',
    role: user.role,
    branch_id: user.branch_id || '',
    is_active: user.is_active
  }
  showModal.value = true
}

function deleteUser(user) {
  deleteItem.value = user
  showDeleteConfirm.value = true
}

async function confirmDelete() {
  if (!deleteItem.value) return
  deleting.value = true
  try {
    const { error } = await supabase.from('user_profiles').delete().eq('id', deleteItem.value.id)
    if (error) throw error
    showDeleteConfirm.value = false
    deleteItem.value = null
    await loadData()
    toast.success('User deleted')
  } catch (err) {
    toast.error(err.message)
  } finally {
    deleting.value = false
  }
}

async function toggleStatus(user) {
  const { error } = await supabase.from('user_profiles').update({ is_active: !user.is_active }).eq('id', user.id)
  if (!error) user.is_active = !user.is_active
}

function closeModal() {
  showModal.value = false
  editingId.value = null
  formError.value = ''
  form.value = { first_name: '', last_name: '', email: '', password: '', role: '', branch_id: '', is_active: true }
}

onMounted(loadData)
</script>
