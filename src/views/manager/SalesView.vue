<template>
  <div class="h-full overflow-auto bg-transparent">
    <div class="p-8">
      <div class="flex flex-wrap items-end justify-between gap-4 mb-6">
        <div>
          <h1 class="font-display text-3xl font-semibold text-ink tracking-tight">Sales</h1>
          <p class="text-ink-muted text-sm mt-1">Performance for {{ branchName || 'your branch' }}</p>
        </div>
        <div class="flex items-center gap-2">
          <div class="inline-flex p-1 bg-stone-100 rounded-xl">
            <button v-for="opt in ['today', 'week', 'month']" :key="opt" @click="setRange(opt)"
              :class="range === opt ? 'bg-white text-ink shadow-card' : 'text-ink-muted hover:text-ink-soft'"
              class="px-3.5 py-1.5 rounded-lg text-xs font-medium capitalize transition-colors">{{ opt }}</button>
          </div>
          <button @click="exportCsv" :disabled="!transactions.length" class="btn-secondary">
            <AppIcon name="arrow-down" :size="16" /> Export
          </button>
        </div>
      </div>

      <!-- KPIs -->
      <div class="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <div v-for="k in kpis" :key="k.label" class="card p-5">
          <span class="w-10 h-10 rounded-xl bg-brand-50 text-brand-600 flex items-center justify-center"><AppIcon :name="k.icon" :size="20" /></span>
          <p class="text-2xl font-semibold text-ink mt-3 tracking-tight tabular-nums">{{ k.value }}</p>
          <p class="text-ink-muted text-sm mt-1">{{ k.label }}</p>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-5 mb-5">
        <!-- Payment methods -->
        <div class="card p-6">
          <h3 class="font-semibold text-ink mb-5">Payment Methods</h3>
          <div v-if="paymentBreakdown.length === 0" class="text-ink-muted text-sm">No sales in this period.</div>
          <div v-else class="space-y-4">
            <div v-for="pm in paymentBreakdown" :key="pm.method">
              <div class="flex justify-between text-sm mb-1.5">
                <span class="font-medium text-ink-soft capitalize">{{ pm.method }}</span>
                <span class="text-ink-muted tabular-nums">{{ money(pm.amount) }}</span>
              </div>
              <div class="h-2 bg-stone-100 rounded-full overflow-hidden">
                <div class="h-full bg-brand-500 rounded-full transition-all" :style="{ width: pm.pct + '%' }"></div>
              </div>
            </div>
          </div>
        </div>

        <!-- Top products -->
        <div class="card p-6 lg:col-span-2">
          <h3 class="font-semibold text-ink mb-5">Top Products</h3>
          <div v-if="topProducts.length === 0" class="text-ink-muted text-sm">No product sales in this period.</div>
          <div v-else class="space-y-3">
            <div v-for="(p, i) in topProducts" :key="p.name" class="flex items-center justify-between">
              <div class="flex items-center gap-3">
                <span class="w-6 h-6 rounded-lg bg-stone-100 text-ink-soft text-xs font-semibold flex items-center justify-center">{{ i + 1 }}</span>
                <div><p class="text-sm font-medium text-ink">{{ p.name }}</p><p class="text-xs text-ink-muted">{{ p.qty }} sold</p></div>
              </div>
              <span class="text-sm font-semibold text-brand-600 tabular-nums">{{ money(p.revenue) }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Transactions -->
      <div class="card overflow-hidden">
        <div class="p-5 border-b border-stone-100"><h3 class="font-semibold text-ink">Transactions</h3></div>
        <table class="w-full text-sm">
          <thead class="bg-stone-50/60 border-b border-stone-100">
            <tr class="text-left text-ink-muted">
              <th class="px-6 py-3 font-medium">Receipt</th>
              <th class="px-6 py-3 font-medium">Amount</th>
              <th class="px-6 py-3 font-medium">Payment</th>
              <th class="px-6 py-3 font-medium">Status</th>
              <th class="px-6 py-3 font-medium">Time</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-stone-50">
            <tr v-if="loading"><td colspan="5" class="px-6 py-10 text-center text-ink-muted">Loading…</td></tr>
            <tr v-else-if="transactions.length === 0"><td colspan="5" class="px-6 py-10 text-center text-ink-muted">No transactions in this period.</td></tr>
            <tr v-for="t in transactions" :key="t.id" class="hover:bg-stone-50/70">
              <td class="px-6 py-3 font-mono text-xs text-ink-muted">{{ t.receipt_number }}</td>
              <td class="px-6 py-3 font-semibold text-ink tabular-nums">{{ money(t.total_amount) }}</td>
              <td class="px-6 py-3 capitalize text-ink-soft">{{ t.payment_method }}</td>
              <td class="px-6 py-3"><span :class="t.status === 'completed' ? 'badge-success' : 'badge-danger'" class="capitalize">{{ t.status }}</span></td>
              <td class="px-6 py-3 text-ink-muted">{{ datetime(t.created_at) }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useAuthStore } from '../../stores/auth'
import { supabase } from '../../lib/supabase'
import AppIcon from '../../components/AppIcon.vue'

const auth = useAuthStore()
const range = ref('today')
const loading = ref(true)
const branchName = ref('')
const transactions = ref([])
const topProducts = ref([])

const money = (v) => `R${parseFloat(v || 0).toLocaleString('en-ZA', { minimumFractionDigits: 2 })}`
const datetime = (v) => new Date(v).toLocaleString('en-ZA', { dateStyle: 'short', timeStyle: 'short' })

function rangeStart() {
  const d = new Date()
  if (range.value === 'today') d.setHours(0, 0, 0, 0)
  else if (range.value === 'week') d.setDate(d.getDate() - 7)
  else d.setDate(d.getDate() - 30)
  return d.toISOString()
}

const completed = computed(() => transactions.value.filter(t => t.status === 'completed'))
const totalRevenue = computed(() => completed.value.reduce((s, t) => s + parseFloat(t.total_amount || 0), 0))
const avgOrder = computed(() => completed.value.length ? totalRevenue.value / completed.value.length : 0)
const itemsSold = computed(() => topProducts.value.reduce((s, p) => s + p.qty, 0))

const kpis = computed(() => [
  { label: 'Revenue', value: money(totalRevenue.value), icon: 'banknote' },
  { label: 'Transactions', value: completed.value.length, icon: 'receipt' },
  { label: 'Avg Order', value: money(avgOrder.value), icon: 'trending' },
  { label: 'Items Sold', value: itemsSold.value, icon: 'bag' },
])

const paymentBreakdown = computed(() => {
  const agg = {}
  completed.value.forEach(t => {
    const m = t.payment_method || 'cash'
    agg[m] = (agg[m] || 0) + parseFloat(t.total_amount || 0)
  })
  const max = Math.max(...Object.values(agg), 1)
  return Object.entries(agg).map(([method, amount]) => ({ method, amount, pct: (amount / max) * 100 }))
})

function setRange(r) { range.value = r; load() }

async function load() {
  loading.value = true
  try {
    const { data: tx } = await supabase
      .from('transactions')
      .select('id, receipt_number, total_amount, payment_method, status, created_at')
      .eq('branch_id', auth.branchId)
      .gte('created_at', rangeStart())
      .order('created_at', { ascending: false })
    transactions.value = tx || []

    const ids = transactions.value.filter(t => t.status === 'completed').map(t => t.id)
    if (ids.length) {
      const { data: lines } = await supabase
        .from('transaction_lines')
        .select('quantity, line_total, products(name)')
        .in('transaction_id', ids)
      const agg = {}
      ;(lines || []).forEach(l => {
        const name = l.products?.name || 'Unknown'
        if (!agg[name]) agg[name] = { name, qty: 0, revenue: 0 }
        agg[name].qty += l.quantity
        agg[name].revenue += parseFloat(l.line_total || 0)
      })
      topProducts.value = Object.values(agg).sort((a, b) => b.revenue - a.revenue).slice(0, 5)
    } else {
      topProducts.value = []
    }
  } catch (err) {
    console.error('Error loading sales:', err)
  } finally {
    loading.value = false
  }
}

function exportCsv() {
  const esc = (s) => `"${String(s ?? '').replace(/"/g, '""')}"`
  const header = ['Receipt', 'Amount', 'Payment', 'Status', 'Time'].map(esc).join(',')
  const rows = transactions.value.map(t => [t.receipt_number, t.total_amount, t.payment_method, t.status, datetime(t.created_at)].map(esc).join(','))
  const csv = [header, ...rows].join('\n')
  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `nibbles-sales-${range.value}-${new Date().toISOString().slice(0, 10)}.csv`
  a.click()
  URL.revokeObjectURL(url)
}

onMounted(async () => {
  if (auth.branchId) {
    const { data } = await supabase.from('branches').select('name').eq('id', auth.branchId).single()
    if (data) branchName.value = data.name.trim()
  }
  await load()
})
</script>
