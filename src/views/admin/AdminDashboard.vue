<template>
  <div class="p-8">
    <div class="mb-7">
      <h1 class="font-display text-3xl font-semibold text-ink tracking-tight">Dashboard</h1>
      <p class="text-ink-muted text-sm mt-1">Overview across all Nibbles branches</p>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
      <div v-for="stat in stats" :key="stat.label" class="card card-hover p-5">
        <div class="flex items-center justify-between mb-4">
          <span class="w-10 h-10 rounded-xl bg-brand-50 text-brand-600 flex items-center justify-center">
            <AppIcon :name="stat.icon" :size="20" />
          </span>
          <span
            :class="stat.change >= 0 ? 'text-emerald-600' : 'text-red-600'"
            class="inline-flex items-center gap-0.5 text-xs font-medium"
          >
            <AppIcon :name="stat.change >= 0 ? 'arrow-up' : 'arrow-down'" :size="12" :stroke-width="2.25" />
            {{ Math.abs(stat.change) }}%
          </span>
        </div>
        <p class="text-2xl font-semibold text-ink tracking-tight">{{ stat.value }}</p>
        <p class="text-ink-muted text-sm mt-1">{{ stat.label }}</p>
      </div>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-2 gap-5 mb-5">
      <div class="card p-6">
        <h3 class="font-semibold text-ink mb-5">Branch Performance Today</h3>
        <div class="space-y-4">
          <div v-for="branch in branches" :key="branch.name" class="flex items-center gap-3">
            <div class="flex-1">
              <div class="flex justify-between text-sm mb-1.5">
                <span class="font-medium text-ink-soft">{{ branch.name }}</span>
                <span class="text-ink-muted tabular-nums">R{{ branch.revenue.toLocaleString() }}</span>
              </div>
              <div class="w-full bg-stone-100 rounded-full h-2">
                <div class="bg-brand-600 h-2 rounded-full transition-all" :style="{ width: branch.pct + '%' }"></div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="card p-6">
        <h3 class="font-semibold text-ink mb-5">Low Stock Alerts</h3>
        <div v-if="lowStock.length === 0" class="flex items-center gap-2 text-ink-muted text-sm py-2">
          <AppIcon name="check-circle" :size="16" class="text-emerald-500" />
          No alerts — all stock levels healthy.
        </div>
        <div v-else class="space-y-2">
          <div v-for="item in lowStock" :key="item.id" class="flex items-center justify-between p-3 bg-amber-50/70 border border-amber-100 rounded-xl">
            <div class="flex items-center gap-2.5">
              <AppIcon name="alert" :size="16" class="text-amber-500 flex-shrink-0" />
              <div>
                <p class="text-sm font-medium text-ink">{{ item.product }}</p>
                <p class="text-xs text-ink-muted">{{ item.branch }}</p>
              </div>
            </div>
            <span class="badge-warning">{{ item.qty }} left</span>
          </div>
        </div>
      </div>
    </div>

    <div class="card p-6">
      <h3 class="font-semibold text-ink mb-5">Recent Transactions</h3>
      <div class="overflow-x-auto">
        <table class="w-full text-sm">
          <thead>
            <tr class="text-left text-ink-muted border-b border-stone-100">
              <th class="pb-3 font-medium">Receipt</th>
              <th class="pb-3 font-medium">Branch</th>
              <th class="pb-3 font-medium">Amount</th>
              <th class="pb-3 font-medium">Payment</th>
              <th class="pb-3 font-medium">Time</th>
              <th class="pb-3 font-medium">Status</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-stone-50">
            <tr v-for="tx in recentTransactions" :key="tx.id" class="hover:bg-stone-50/70">
              <td class="py-3 font-mono text-xs text-ink-muted">{{ tx.receipt }}</td>
              <td class="py-3 text-ink-soft">{{ tx.branch }}</td>
              <td class="py-3 font-semibold text-ink tabular-nums">R{{ tx.amount }}</td>
              <td class="py-3 capitalize text-ink-soft">{{ tx.payment }}</td>
              <td class="py-3 text-ink-muted">{{ tx.time }}</td>
              <td class="py-3">
                <span :class="tx.status === 'completed' ? 'badge-success' : 'badge-danger'" class="capitalize">{{ tx.status }}</span>
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
import AppIcon from '../../components/AppIcon.vue'

const stats = ref([
  { label: "Today's Revenue", value: 'R0', icon: 'banknote', change: 0 },
  { label: 'Transactions', value: '0', icon: 'receipt', change: 0 },
  { label: 'Active Staff', value: '0', icon: 'users', change: 0 },
  { label: 'Loyalty Members', value: '0', icon: 'heart', change: 0 },
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
