<template>
  <div class="h-full overflow-auto bg-transparent p-8">
    <!-- Header -->
    <div class="mb-6 flex flex-wrap items-end justify-between gap-4">
      <div>
        <h1 class="font-display text-3xl font-semibold text-ink tracking-tight">Branch Dashboard</h1>
        <p class="text-ink-muted text-sm mt-1">{{ branchName }}</p>
      </div>
      <div class="inline-flex p-1 bg-stone-100 rounded-xl">
        <button
          v-for="opt in ['today', 'week', 'month']"
          :key="opt"
          @click="timeframe = opt"
          :class="timeframe === opt ? 'bg-white text-ink shadow-card' : 'text-ink-muted hover:text-ink-soft'"
          class="px-3.5 py-1.5 rounded-lg text-xs font-medium capitalize transition-colors"
        >{{ opt }}</button>
      </div>
    </div>

    <!-- Key Stats -->
    <div class="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
      <div v-for="stat in statCards" :key="stat.label" class="card card-hover p-5">
        <span
          class="w-10 h-10 rounded-xl flex items-center justify-center"
          :class="stat.alert ? 'bg-amber-50 text-amber-600' : 'bg-brand-50 text-brand-600'"
        >
          <AppIcon :name="stat.icon" :size="20" />
        </span>
        <p class="text-2xl font-semibold mt-3 tracking-tight" :class="stat.alert && stat.value > 0 ? 'text-amber-600' : 'text-ink'">{{ stat.value }}</p>
        <p class="text-ink-muted text-sm mt-1">{{ stat.label }}</p>
      </div>
    </div>

    <!-- Main Dashboard Grid -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-5">
      <!-- Left Column: Sales & Payment Methods -->
      <div class="lg:col-span-2 space-y-5">
        <!-- Revenue Breakdown -->
        <div class="card p-6">
          <h3 class="font-semibold text-ink mb-5">Payment Methods</h3>
          <div class="space-y-4">
            <div v-for="(amount, method) in paymentBreakdown" :key="method" class="flex items-center justify-between">
              <div class="flex-1">
                <p class="text-sm font-medium text-ink-soft capitalize">{{ method }}</p>
                <div class="mt-1.5 h-2 bg-stone-100 rounded-full overflow-hidden">
                  <div :style="{ width: maxPayment > 0 ? (amount / maxPayment * 100) + '%' : '0' }"
                    class="h-full rounded-full transition-all" :class="paymentColors[method]"></div>
                </div>
              </div>
              <span class="ml-3 text-sm font-semibold text-ink min-w-fit tabular-nums">R{{ amount.toFixed(2) }}</span>
            </div>
          </div>
        </div>

        <!-- Top Products -->
        <div class="card p-6">
          <h3 class="font-semibold text-ink mb-5">Top 5 Products</h3>
          <div v-if="topProducts.length === 0" class="text-ink-muted text-sm">No sales data yet</div>
          <div v-else class="space-y-3">
            <div v-for="(product, i) in topProducts" :key="product.id" class="flex items-center justify-between">
              <div class="flex items-center gap-3 flex-1">
                <span class="w-6 h-6 rounded-lg bg-stone-100 text-ink-soft text-xs font-semibold flex items-center justify-center">{{ i + 1 }}</span>
                <div>
                  <p class="text-sm font-medium text-ink">{{ product.name }}</p>
                  <p class="text-xs text-ink-muted">{{ product.quantity }} sold</p>
                </div>
              </div>
              <div class="text-right">
                <p class="text-sm font-semibold text-brand-600 tabular-nums">{{ product.quantity }}</p>
                <p class="text-xs text-ink-muted tabular-nums">R{{ product.revenue.toFixed(2) }}</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Right Column: Alerts & Recent Activity -->
      <div class="space-y-5">
        <!-- Low Stock Alerts -->
        <div class="card p-6">
          <h3 class="font-semibold text-ink mb-5 flex items-center gap-2">
            <AppIcon name="alert" :size="18" class="text-amber-500" /> Low Stock
          </h3>
          <div v-if="lowStockItems.length === 0" class="text-ink-muted text-sm">All stock levels healthy</div>
          <div v-else class="space-y-2 max-h-64 overflow-y-auto">
            <div v-for="item in lowStockItems" :key="item.id" class="p-3 bg-amber-50/70 rounded-xl border border-amber-100">
              <p class="text-xs font-semibold text-amber-800">{{ item.product_name }}</p>
              <p class="text-xs text-amber-700 mt-0.5 tabular-nums">{{ item.quantity_on_hand }} / {{ item.reorder_level }} units</p>
            </div>
          </div>
        </div>

        <!-- Recent Transactions -->
        <div class="card p-6">
          <h3 class="font-semibold text-ink mb-5">Recent Sales</h3>
          <div v-if="recentSales.length === 0" class="text-ink-muted text-sm">No sales yet</div>
          <div v-else class="space-y-2 max-h-64 overflow-y-auto">
            <div v-for="tx in recentSales" :key="tx.id" class="p-2.5 bg-stone-50 rounded-xl border border-stone-100 text-xs">
              <div class="flex justify-between">
                <span class="font-mono text-ink-muted">{{ tx.receipt_number }}</span>
                <span class="font-semibold text-brand-600 tabular-nums">R{{ parseFloat(tx.total_amount).toFixed(2) }}</span>
              </div>
              <p class="text-ink-muted mt-1">{{ formatTime(tx.created_at) }}</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted } from 'vue'
import { supabase } from '../../lib/supabase'
import { useAuthStore } from '../../stores/auth'
import AppIcon from '../../components/AppIcon.vue'

const auth = useAuthStore()
const branchName = ref('')
const timeframe = ref('today')
const transactions = ref([])
const lowStockItems = ref([])
const recentSales = ref([])

const paymentColors = {
  cash: 'bg-emerald-500',
  card: 'bg-sky-500',
  split: 'bg-violet-500'
}

const statCards = computed(() => [
  { label: 'Total Sales', value: totalSales.value, icon: 'banknote' },
  { label: 'Transactions', value: totalTransactions.value, icon: 'receipt' },
  { label: 'Low Stock Items', value: lowStockCount.value, icon: 'alert', alert: true },
  { label: 'Items Sold', value: itemsSold.value, icon: 'bag' },
])

// Computed: Date range based on timeframe
const getDateRange = computed(() => {
  const end = new Date()
  const start = new Date()
  
  if (timeframe.value === 'today') {
    start.setHours(0, 0, 0, 0)
  } else if (timeframe.value === 'week') {
    start.setDate(end.getDate() - 7)
  } else if (timeframe.value === 'month') {
    start.setDate(end.getDate() - 30)
  }
  
  return {
    start: start.toISOString().split('T')[0],
    end: end.toISOString().split('T')[0]
  }
})

// Computed: Total sales
const totalSales = computed(() => {
  const total = transactions.value.reduce((sum, tx) => sum + parseFloat(tx.total_amount || 0), 0)
  return `R${total.toFixed(2)}`
})

// Computed: Total transactions
const totalTransactions = computed(() => transactions.value.length)

// Items sold + top products are loaded from transaction_lines in loadDashboardData
const itemsSold = ref(0)

// Computed: Low stock count
const lowStockCount = computed(() => lowStockItems.value.length)

// Computed: Payment breakdown
const paymentBreakdown = computed(() => {
  const breakdown = { cash: 0, card: 0, split: 0 }
  transactions.value.forEach(tx => {
    const method = tx.payment_method || 'cash'
    breakdown[method] = (breakdown[method] || 0) + parseFloat(tx.total_amount || 0)
  })
  return breakdown
})

const maxPayment = computed(() => Math.max(...Object.values(paymentBreakdown.value), 1))

const topProducts = ref([])

function formatTime(datetime) {
  return new Date(datetime).toLocaleTimeString('en-ZA', { hour: '2-digit', minute: '2-digit' })
}

async function loadDashboardData() {
  if (!auth.branchId) return
  
  try {
    // Load branch name
    const { data: branch } = await supabase.from('branches').select('name').eq('id', auth.branchId).single()
    if (branch) branchName.value = branch.name

    // Load transactions for date range
    const dateRange = getDateRange.value
    const { data: txData } = await supabase
      .from('transactions')
      .select('*')
      .eq('branch_id', auth.branchId)
      .gte('created_at', `${dateRange.start}T00:00:00`)
      .lte('created_at', `${dateRange.end}T23:59:59`)
      .order('created_at', { ascending: false })
    
    if (txData) {
      transactions.value = txData
      recentSales.value = txData.slice(0, 10)

      // Items sold + top products from transaction lines
      const ids = txData.map(t => t.id)
      if (ids.length) {
        const { data: lines } = await supabase
          .from('transaction_lines')
          .select('quantity, line_total, products(name)')
          .in('transaction_id', ids)
        let sold = 0
        const agg = {}
        ;(lines || []).forEach(l => {
          sold += l.quantity
          const name = l.products?.name || 'Unknown'
          if (!agg[name]) agg[name] = { id: name, name, quantity: 0, revenue: 0 }
          agg[name].quantity += l.quantity
          agg[name].revenue += parseFloat(l.line_total || 0)
        })
        itemsSold.value = sold
        topProducts.value = Object.values(agg).sort((a, b) => b.revenue - a.revenue).slice(0, 5)
      } else {
        itemsSold.value = 0
        topProducts.value = []
      }
    }

    // Load low stock inventory
    const { data: invData } = await supabase.rpc('get_branch_inventory', { p_branch_id: auth.branchId })
    if (invData) {
      lowStockItems.value = invData.filter(i => i.status !== 'in_stock')
    }
  } catch (error) {
    console.error('Error loading dashboard:', error)
  }
}

watch(timeframe, loadDashboardData)
onMounted(loadDashboardData)
</script>
