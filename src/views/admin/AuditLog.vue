<template>
  <div class="p-6">
    <div class="mb-6">
      <h1 class="text-2xl font-bold text-nibbles-dark">Audit Log</h1>
      <p class="text-gray-500 text-sm mt-1">Full system activity trail — append only</p>
    </div>
    <div class="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
      <div class="p-4 border-b border-gray-100 flex gap-3">
        <input v-model="search" type="text" placeholder="Search actions or entities..." class="flex-1 px-4 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-nibbles-red" />
      </div>
      <div class="divide-y divide-gray-50 max-h-screen overflow-y-auto">
        <div v-if="loading" class="p-8 text-center text-gray-400">Loading audit log...</div>
        <div v-else-if="filtered.length === 0" class="p-8 text-center text-gray-400">No audit entries found.</div>
        <div v-for="entry in filtered" :key="entry.id" class="px-4 py-3 hover:bg-gray-50 flex items-start gap-4">
          <div class="w-8 h-8 bg-gray-100 rounded-lg flex items-center justify-center flex-shrink-0 mt-0.5">
            <span class="text-sm">{{ actionIcon(entry.action) }}</span>
          </div>
          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-2 flex-wrap">
              <span class="text-sm font-medium text-gray-800">{{ entry.action }}</span>
              <span class="text-xs text-gray-400">on</span>
              <span class="text-xs font-mono bg-gray-100 px-1.5 py-0.5 rounded text-gray-600">{{ entry.entity_type }}</span>
            </div>
            <p class="text-xs text-gray-400 mt-0.5">{{ entry.user_profiles?.first_name }} {{ entry.user_profiles?.last_name }} · {{ formatDate(entry.created_at) }}</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../../lib/supabase'
const logs = ref([]); const loading = ref(true); const search = ref('')
const filtered = computed(() => { if (!search.value) return logs.value; return logs.value.filter(l => l.action?.includes(search.value) || l.entity_type?.includes(search.value)) })
function actionIcon(action) { if (!action) return '📋'; if (action.includes('create') || action.includes('insert')) return '➕'; if (action.includes('update')) return '✏️'; if (action.includes('delete')) return '🗑️'; if (action.includes('login')) return '🔐'; return '📋' }
function formatDate(d) { return new Date(d).toLocaleString('en-ZA') }
onMounted(async () => { loading.value = true; const { data } = await supabase.from('audit_log').select('*, user_profiles(first_name, last_name)').order('created_at', { ascending: false }).limit(100); if (data) logs.value = data; loading.value = false })
</script>
