<template>
  <div class="h-full overflow-auto bg-transparent">
    <div class="p-8">
      <div class="flex items-center justify-between mb-6">
        <div>
          <h1 class="font-display text-3xl font-semibold text-ink tracking-tight">Audit Log</h1>
          <p class="text-ink-muted text-sm mt-1">System activity and compliance tracking</p>
        </div>
        <button @click="refreshLogs" :disabled="loading" class="btn-secondary">
          <span v-if="loading" class="w-4 h-4 border-2 border-stone-300 border-t-brand-500 rounded-full animate-spin"></span>
          <AppIcon v-else name="refresh" :size="16" /> Refresh
        </button>
      </div>

      <!-- Filters -->
      <div class="card p-4 mb-6 flex gap-3 flex-wrap">
        <input v-model="search" type="text" placeholder="Search by user or action…" class="input flex-1 min-w-[12rem]" />
        <select v-model="filterAction" class="input w-auto">
          <option value="">All actions</option>
          <option v-for="a in actionOptions" :key="a" :value="a">{{ cap(a) }}</option>
        </select>
        <select v-model="filterEntity" class="input w-auto">
          <option value="">All entities</option>
          <option v-for="e in entityOptions" :key="e" :value="e">{{ cap(e) }}</option>
        </select>
      </div>

      <!-- Table -->
      <div class="card overflow-hidden">
        <table class="w-full text-sm">
          <thead class="bg-stone-50/60 border-b border-stone-100">
            <tr class="text-left text-ink-muted">
              <th class="px-6 py-3 font-medium">Timestamp</th>
              <th class="px-6 py-3 font-medium">User</th>
              <th class="px-6 py-3 font-medium">Action</th>
              <th class="px-6 py-3 font-medium">Entity</th>
              <th class="px-6 py-3 font-medium">Branch</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-stone-50">
            <tr v-if="loading"><td colspan="5" class="px-6 py-10 text-center text-ink-muted">Loading audit logs…</td></tr>
            <tr v-else-if="filteredLogs.length === 0"><td colspan="5" class="px-6 py-10 text-center text-ink-muted">No audit logs found.</td></tr>
            <tr v-for="log in filteredLogs" :key="log.id" class="hover:bg-stone-50/70 cursor-pointer" @click="selectedLog = log">
              <td class="px-6 py-3 text-xs text-ink-muted font-mono">{{ formatDateTime(log.created_at) }}</td>
              <td class="px-6 py-3 font-medium text-ink">{{ userName(log.user_id) }}</td>
              <td class="px-6 py-3"><span :class="actionBadge(log.action)" class="capitalize">{{ cap(log.action) }}</span></td>
              <td class="px-6 py-3 capitalize text-ink-soft">{{ (log.entity_type || '').replace('_', ' ') }}</td>
              <td class="px-6 py-3 text-ink-muted">{{ branchName(log.branch_id) }}</td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Detail modal -->
      <div v-if="selectedLog" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 px-4">
        <div class="card p-6 w-full max-w-2xl max-h-[80vh] overflow-y-auto">
          <div class="flex justify-between items-start mb-4">
            <div>
              <h2 class="font-display text-xl font-semibold text-ink">Audit Detail</h2>
              <p class="text-ink-muted text-sm">{{ formatDateTime(selectedLog.created_at) }}</p>
            </div>
            <button @click="selectedLog = null" class="text-stone-400 hover:text-ink transition-colors"><AppIcon name="x" :size="20" /></button>
          </div>
          <div class="grid grid-cols-2 gap-3 mb-4">
            <div class="p-3 bg-stone-50 rounded-xl"><p class="text-xs text-ink-muted mb-1">User</p><p class="font-medium text-ink">{{ userName(selectedLog.user_id) }}</p></div>
            <div class="p-3 bg-stone-50 rounded-xl"><p class="text-xs text-ink-muted mb-1">Action</p><p class="font-medium text-ink capitalize">{{ cap(selectedLog.action) }}</p></div>
            <div class="p-3 bg-stone-50 rounded-xl"><p class="text-xs text-ink-muted mb-1">Entity</p><p class="font-medium text-ink capitalize">{{ (selectedLog.entity_type || '—').replace('_', ' ') }}</p></div>
            <div class="p-3 bg-stone-50 rounded-xl"><p class="text-xs text-ink-muted mb-1">Branch</p><p class="font-medium text-ink">{{ branchName(selectedLog.branch_id) }}</p></div>
          </div>
          <div v-if="selectedLog.old_value" class="p-3 bg-amber-50 border border-amber-100 rounded-xl mb-2">
            <p class="text-xs text-amber-700 font-semibold mb-1">Before</p>
            <pre class="text-xs text-ink-soft overflow-auto">{{ pretty(selectedLog.old_value) }}</pre>
          </div>
          <div v-if="selectedLog.new_value" class="p-3 bg-emerald-50 border border-emerald-100 rounded-xl">
            <p class="text-xs text-emerald-700 font-semibold mb-1">After</p>
            <pre class="text-xs text-ink-soft overflow-auto">{{ pretty(selectedLog.new_value) }}</pre>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../../lib/supabase'
import AppIcon from '../../components/AppIcon.vue'

const logs = ref([])
const users = ref({})
const branches = ref({})
const loading = ref(true)
const search = ref('')
const filterAction = ref('')
const filterEntity = ref('')
const selectedLog = ref(null)

const cap = (s) => (s ? s.charAt(0).toUpperCase() + s.slice(1).replace('_', ' ') : '')
const userName = (id) => users.value[id] || 'System'
const branchName = (id) => (id ? (branches.value[id] || '—') : 'All branches')
const pretty = (v) => { try { return JSON.stringify(v, null, 2) } catch { return String(v) } }

const actionOptions = computed(() => [...new Set(logs.value.map(l => l.action).filter(Boolean))].sort())
const entityOptions = computed(() => [...new Set(logs.value.map(l => l.entity_type).filter(Boolean))].sort())

const filteredLogs = computed(() =>
  logs.value.filter(l => {
    const hay = `${userName(l.user_id)} ${l.action} ${l.entity_type}`.toLowerCase()
    const matchSearch = !search.value || hay.includes(search.value.toLowerCase())
    const matchAction = !filterAction.value || l.action === filterAction.value
    const matchEntity = !filterEntity.value || l.entity_type === filterEntity.value
    return matchSearch && matchAction && matchEntity
  })
)

function actionBadge(action) {
  return {
    create: 'badge-success',
    update: 'badge bg-sky-50 text-sky-700',
    delete: 'badge-danger',
    void: 'badge-danger',
    login: 'badge bg-violet-50 text-violet-700',
    payment: 'badge-warning',
    restock: 'badge bg-emerald-50 text-emerald-700',
  }[action] || 'badge-neutral'
}
function formatDateTime(d) {
  return new Date(d).toLocaleString('en-ZA', { dateStyle: 'short', timeStyle: 'short' })
}

async function refreshLogs() {
  loading.value = true
  try {
    const [{ data: logData }, { data: userData }, { data: branchData }] = await Promise.all([
      supabase.from('audit_log').select('*').order('created_at', { ascending: false }).limit(500),
      supabase.from('user_profiles').select('id, first_name, last_name'),
      supabase.from('branches').select('id, name'),
    ])
    logs.value = logData || []
    users.value = Object.fromEntries((userData || []).map(u => [u.id, `${u.first_name} ${u.last_name}`]))
    branches.value = Object.fromEntries((branchData || []).map(b => [b.id, b.name.trim()]))
  } catch (err) {
    console.error('Error loading audit logs:', err.message)
  } finally {
    loading.value = false
  }
}

onMounted(refreshLogs)
</script>
