<template>
  <div class="p-6">
    <div class="mb-6">
      <h1 class="text-2xl font-bold text-nibbles-dark">Branch Dashboard</h1>
      <p class="text-gray-500 text-sm mt-1">{{ branchName }}</p>
    </div>
    <div class="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
      <div v-for="stat in stats" :key="stat.label" class="bg-white rounded-xl p-5 shadow-sm border border-gray-100">
        <span class="text-2xl">{{ stat.icon }}</span>
        <p class="text-2xl font-bold text-nibbles-dark mt-2">{{ stat.value }}</p>
        <p class="text-gray-500 text-sm mt-1">{{ stat.label }}</p>
      </div>
    </div>
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <div class="bg-white rounded-xl p-5 shadow-sm border border-gray-100">
        <h3 class="font-semibold text-nibbles-dark mb-4">Low Stock Alerts</h3>
        <div v-if="lowStock.length === 0" class="text-gray-400 text-sm">All stock levels healthy.</div>
        <div v-else class="space-y-2">
          <div v-for="item in lowStock" :key="item.id" class="flex items-center justify-between p-3 bg-red-50 rounded-lg">
            <p class="text-sm font-medium text-gray-800">{{ item.products?.name }}</p>
            <span class="text-xs font-semibold text-red-600 bg-red-100 px-2 py-1 rounded">{{ item.quantity_on_hand }} left</span>
          </div>
        </div>
      </div>
      <div class="bg-white rounded-xl p-5 shadow-sm border border-gray-100">
        <h3 class="font-semibold text-nibbles-dark mb-4">Recent Sales</h3>
        <div v-if="recentSales.length === 0" class="text-gray-400 text-sm">No sales today yet.</div>
        <div v-else class="space-y-2">
          <div v-for="t in recentSales" :key="t.id" class="flex items-center justify-between text-sm">
            <span class="font-mono text-xs text-gray-500">{{ t.receipt_number }}</span>
            <span class="font-semibold text-nibbles-dark">R{{ parseFloat(t.total_amount).toFixed(2) }}</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '../../lib/supabase'
import { useAuthStore } from '../../stores/auth'

const auth = useAuthStore()
const branchName = ref('')
const stats = ref([
  { label: "Today's Sales", value: 'R0', icon: '💰' },
  { label: 'Transactions', value: '0', icon: '🧾' },
  { label: 'Low Stock Items', value: '0', icon: '⚠️' },
  { label: 'Staff on Shift', value: '0', icon: '👤' },
])
const lowStock = ref([])
const recentSales = ref([])

onMounted(async () => {
  if (!auth.branchId) return
  const { data: branch } = await supabase.from('branches').select('name').eq('id', auth.branchId).single()
  if (branch) branchName.value = branch.name

  const today = new Date().toISOString().split('T')[0]
  const { data: txData } = await supabase.from('transactions').select('*').eq('branch_id', auth.branchId).gte('created_at', today).order('created_at', { ascending: false })
  if (txData) {
    const total = txData.reduce((s, t) => s + parseFloat(t.total_amount || 0), 0)
    stats.value[0].value = `R${total.toFixed(2)}`
    stats.value[1].value = String(txData.length)
    recentSales.value = txData.slice(0, 5)
  }

  const { data: invData } = await supabase.from('inventory').select('*, products(name)').eq('branch_id', auth.branchId)
  if (invData) {
    const low = invData.filter(i => i.quantity_on_hand <= i.reorder_threshold)
    lowStock.value = low
    stats.value[2].value = String(low.length)
  }
})
</script>
