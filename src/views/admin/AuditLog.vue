<template>
  <div class="h-full overflow-auto bg-gray-50">
    <div class="p-6">
      <div class="mb-6">
        <h1 class="text-3xl font-bold text-nibbles-dark mb-2">Audit Log</h1>
        <p class="text-gray-600">System activity and compliance tracking</p>
      </div>

      <!-- Filters -->
      <div class="bg-white rounded-xl p-4 mb-6 flex gap-3 flex-wrap">
        <input v-model="search" type="text" placeholder="Search by user or action..." 
          class="flex-1 min-w-xs px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-nibbles-red" />
        <select v-model="filterAction" class="px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-nibbles-red">
          <option value="">All Actions</option>
          <option value="create">Create</option>
          <option value="update">Update</option>
          <option value="delete">Delete</option>
          <option value="login">Login</option>
          <option value="payment">Payment</option>
        </select>
        <select v-model="filterEntity" class="px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-nibbles-red">
          <option value="">All Entities</option>
          <option value="transaction">Transactions</option>
          <option value="product">Products</option>
          <option value="user">Users</option>
          <option value="inventory">Inventory</option>
        </select>
        <button @click="refreshLogs" class="px-4 py-2 bg-nibbles-red text-white rounded-lg text-sm font-semibold hover:bg-nibbles-red-dark transition-colors">
          🔄 Refresh
        </button>
      </div>

      <!-- Audit logs table -->
      <div class="bg-white rounded-xl overflow-hidden shadow">
        <table class="w-full text-sm">
          <thead class="bg-gray-50 border-b border-gray-200">
            <tr>
              <th class="px-6 py-3 text-left font-semibold text-gray-700">Timestamp</th>
              <th class="px-6 py-3 text-left font-semibold text-gray-700">User</th>
              <th class="px-6 py-3 text-left font-semibold text-gray-700">Action</th>
              <th class="px-6 py-3 text-left font-semibold text-gray-700">Entity</th>
              <th class="px-6 py-3 text-left font-semibold text-gray-700">Description</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="loading" class="border-b border-gray-200">
              <td colspan="5" class="px-6 py-8 text-center text-gray-500">Loading audit logs...</td>
            </tr>
            <tr v-else-if="filteredLogs.length === 0" class="border-b border-gray-200">
              <td colspan="5" class="px-6 py-8 text-center text-gray-500">No audit logs found</td>
            </tr>
            <tr v-for="log in filteredLogs" :key="log.id" class="border-b border-gray-200 hover:bg-gray-50 cursor-pointer" @click="selectedLog = log">
              <td class="px-6 py-4 text-xs text-gray-500 font-mono">{{ formatDateTime(log.created_at) }}</td>
              <td class="px-6 py-4 text-sm font-medium text-gray-800">{{ log.user_name || 'System' }}</td>
              <td class="px-6 py-4">
                <span :class="actionBadgeClass(log.action_type)" class="px-2 py-1 rounded-full text-xs font-semibold capitalize">
                  {{ log.action_type }}
                </span>
              </td>
              <td class="px-6 py-4 text-sm capitalize text-gray-600">{{ log.entity_type }}</td>
              <td class="px-6 py-4 text-sm text-gray-700 max-w-xs truncate">{{ log.description }}</td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Log details modal -->
      <div v-if="selectedLog" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 px-4">
        <div class="bg-white rounded-2xl p-6 w-full max-w-2xl max-h-96 overflow-y-auto">
          <div class="flex justify-between items-start mb-4">
            <div>
              <h2 class="text-lg font-bold text-nibbles-dark">Audit Details</h2>
              <p class="text-gray-600 text-sm">{{ formatDateTime(selectedLog.created_at) }}</p>
            </div>
            <button @click="selectedLog = null" class="text-gray-400 hover:text-gray-600 text-2xl">✕</button>
          </div>

          <div class="space-y-4">
            <div class="grid grid-cols-2 gap-4">
              <div class="p-3 bg-gray-50 rounded-lg">
                <p class="text-xs text-gray-600 mb-1">User</p>
                <p class="font-semibold text-gray-800">{{ selectedLog.user_name || 'System' }}</p>
              </div>
              <div class="p-3 bg-gray-50 rounded-lg">
                <p class="text-xs text-gray-600 mb-1">Action</p>
                <p class="font-semibold capitalize text-gray-800">{{ selectedLog.action_type }}</p>
              </div>
              <div class="p-3 bg-gray-50 rounded-lg">
                <p class="text-xs text-gray-600 mb-1">Entity Type</p>
                <p class="font-semibold capitalize text-gray-800">{{ selectedLog.entity_type }}</p>
              </div>
              <div class="p-3 bg-gray-50 rounded-lg">
                <p class="text-xs text-gray-600 mb-1">Entity ID</p>
                <p class="font-mono text-xs text-gray-800">{{ selectedLog.entity_id || '—' }}</p>
              </div>
            </div>

            <div class="p-3 bg-gray-50 rounded-lg">
              <p class="text-xs text-gray-600 mb-2">Description</p>
              <p class="text-gray-800">{{ selectedLog.description }}</p>
            </div>

            <div v-if="selectedLog.changes" class="p-3 bg-blue-50 rounded-lg border border-blue-100">
              <p class="text-xs text-blue-700 font-semibold mb-2">Changes</p>
              <pre class="text-xs text-blue-900 overflow-auto max-h-32">{{ JSON.stringify(selectedLog.changes, null, 2) }}</pre>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../../lib/supabase'

const logs = ref([])
const loading = ref(true)
const search = ref('')
const filterAction = ref('')
const filterEntity = ref('')
const selectedLog = ref(null)

const filteredLogs = computed(() => {
  return logs.value.filter(log => {
    const matchSearch = !search.value || 
      (log.user_name?.toLowerCase().includes(search.value.toLowerCase())) ||
      (log.description?.toLowerCase().includes(search.value.toLowerCase()))
    const matchAction = !filterAction.value || log.action_type === filterAction.value
    const matchEntity = !filterEntity.value || log.entity_type === filterEntity.value
    return matchSearch && matchAction && matchEntity
  })
})

function actionBadgeClass(action) {
  const classes = {
    create: 'bg-green-100 text-green-800',
    update: 'bg-blue-100 text-blue-800',
    delete: 'bg-red-100 text-red-800',
    login: 'bg-purple-100 text-purple-800',
    logout: 'bg-gray-100 text-gray-800',
    payment: 'bg-yellow-100 text-yellow-800'
  }
  return classes[action] || 'bg-gray-100 text-gray-800'
}

function formatDateTime(datetime) {
  return new Date(datetime).toLocaleString('en-ZA', {
    dateStyle: 'short',
    timeStyle: 'short'
  })
}

async function refreshLogs() {
  loading.value = true
  try {
    const { data, error } = await supabase
      .from('audit_logs')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(500)

    if (error) throw error

    logs.value = data || []
  } catch (err) {
    console.error('Error loading audit logs:', err.message)
  } finally {
    loading.value = false
  }
}

onMounted(refreshLogs)
</script>
