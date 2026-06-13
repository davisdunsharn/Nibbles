<template>
  <div class="p-6">
    <div class="mb-6">
      <h1 class="text-2xl font-bold text-nibbles-dark">Dashboard</h1>
      <p class="text-gray-500 text-sm mt-1">Overview across all Nibbles branches</p>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
      <div v-for="stat in stats" :key="stat.label" class="bg-white rounded-xl p-5 shadow-sm border border-gray-100">
        <div class="flex items-center justify-between mb-3">
          <span class="text-2xl">{{ stat.icon }}</span>
          <span :class="stat.change >= 0 ? 'text-green-600' : 'text-red-600'" class="text-xs font-medium">
            {{ stat.change >= 0 ? '+' : '' }}{{ stat.change }}%
          </span>
        </div>
        <p class="text-2xl font-bold text-nibbles-dark">{{ stat.value }}</p>
        <p class="text-gray-500 text-sm mt-1">{{ stat.label }}</p>
      </div>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
      <div class="bg-white rounded-xl p-5 shadow-sm border border-gray-100">
        <h3 class="font-semibold text-nibbles-dark mb-4">Branch Performance Today</h3>
        <div class="space-y-3">
          <div v-for="branch in branches" :key="branch.name" class="flex items-center gap-3">
            <div class="flex-1">
              <div class="flex justify-between text-sm mb-1">
                <span class="font-medium text-gray-700">{{ branch.name }}</span>
                <span class="text-gray-500">R{{ branch.revenue.toLocaleString() }}</span>
              </div>
              <div class="w-full bg-gray-100 rounded-full h-2">
                <div class="bg-nibbles-red h-2 rounded-full transition-all" :style="{ width: branch.pct + '%' }"></div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="bg-white rounded-xl p-5 shadow-sm border border-gray-100">
        <h3 class="font-semibold text-nibbles-dark mb-4">Low Stock Alerts</h3>
        <div v-if="lowStock.length === 0" class="text-gray-400 text-sm">No alerts — all stock levels healthy.</div>
        <div v-else class="space-y-2">
          <div v-for="item in lowStock" :key="item.id" class="flex items-center justify-between p-3 bg-red-50 rounded-lg">
            <div>
              <p class="text-sm font-medium text-gray-800">{{ item.product }}</p>
              <p class="text-xs text-gray-500">{{ item.branch }}</p>
            </div>
            <span class="text-xs font-semibold text-red-600 bg-red-100 px-2 py-1 rounded">{{ item.qty }} left</span>
          </div>
        </div>
      </div>
    </div>

    <div class="bg-white rounded-xl p-5 shadow-sm border border-gray-100">
      <h3 class="font-semibold text-nibbles-dark mb-4">Recent Transactions</h3>
      <div class="overflow-x-auto">
        <table class="w-full text-sm">
          <thead>
            <tr class="text-left text-gray-400 border-b border-gray-100">
              <th class="pb-3 font-medium">Receipt</th>
              <th class="pb-3 font-medium">Branch</th>
              <th class="pb-3 font-medium">Amount</th>
              <th class="pb-3 font-medium">Payment</th>
              <th class="pb-3 font-medium">Time</th>
              <th class="pb-3 font-medium">Status</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-50">
            <tr v-for="tx in recentTransactions" :key="tx.id" class="hover:bg-gray-50">
              <td class="py-3 font-mono text-xs text-gray-600">{{ tx.receipt }}</td>
              <td class="py-3 text-gray-700">{{ tx.branch }}</td>
              <td class="py-3 font-semibold text-nibbles-dark">R{{ tx.amount }}</td>
              <td class="py-3 capitalize text-gray-600">{{ tx.payment }}</td>
              <td class="py-3 text-gray-400">{{ tx.time }}</td>
              <td class="py-3">
                <span :class="tx.status === 'completed' ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'"
                  class="px-2 py-0.5 rounded text-xs font-medium capitalize">{{ tx.status }}</span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '../../lib/supabase'

const stats = ref([
  { label: "Today's Revenue", value: 'R0', icon: '💰', change: 0 },
  { label: 'Transactions', value: '0', icon: '🧾', change: 0 },
  { label: 'Active Staff', value: '0', icon: '👤', change: 0 },
  { label: 'Loyalty Members', value: '0', icon: '❤️', change: 0 },
])
const branches = ref([])
const lowStock = ref([])
const recentTransactions = ref([])

onMounted(async () => {
  // Load branches
  const { data: branchData } = await supabase.from('branches').select('*').eq('is_active', true)
  if (branchData) {
    branches.value = branchData.map((b, i) => ({ name: b.name, revenue: 0, pct: 0 }))
    stats.value[2].value = String(branchData.length)
  }

  // Load today's transactions
  const today = new Date().toISOString().split('T')[0]
  const { data: txData } = await supabase
    .from('transactions')
    .select('*, branches(name)')
    .gte('created_at', today)
    .order('created_at', { ascending: false })
    .limit(10)

  if (txData) {
    const total = txData.reduce((sum, t) => sum + parseFloat(t.total_amount || 0), 0)
    stats.value[0].value = `R${total.toLocaleString('en-ZA', { minimumFractionDigits: 2 })}`
    stats.value[1].value = String(txData.length)
    recentTransactions.value = txData.map(t => ({
      id: t.id,
      receipt: t.receipt_number,
      branch: t.branches?.name || '—',
      amount: parseFloat(t.total_amount).toFixed(2),
      payment: t.payment_method,
      time: new Date(t.created_at).toLocaleTimeString('en-ZA', { hour: '2-digit', minute: '2-digit' }),
      status: t.status
    }))
  }

  // Low stock alerts
  const { data: invData } = await supabase
    .from('inventory')
    .select('*, products(name), branches(name)')
    .filter('quantity_on_hand', 'lte', 'reorder_threshold')
    .limit(5)

  if (invData) {
    lowStock.value = invData.map(i => ({
      id: i.id, product: i.products?.name, branch: i.branches?.name, qty: i.quantity_on_hand
    }))
  }

  // Customer count
  const { count } = await supabase.from('customers').select('*', { count: 'exact', head: true })
  if (count !== null) stats.value[3].value = String(count)
})
</script>
