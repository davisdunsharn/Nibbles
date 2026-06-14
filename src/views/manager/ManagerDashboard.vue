<template>
  <div class="h-full overflow-auto bg-gray-50 p-6">
    <!-- Header -->
    <div class="mb-6">
      <h1 class="text-3xl font-bold text-nibbles-dark mb-2">Branch Dashboard</h1>
      <p class="text-gray-600">{{ branchName }}</p>
      <div class="mt-3 flex gap-2">
        <button @click="timeframe = 'today'" :class="timeframe === 'today' ? 'bg-nibbles-red text-white' : 'bg-white text-gray-600 border border-gray-200'" class="px-3 py-1 rounded-lg text-xs font-medium hover:bg-gray-50 transition-colors">Today</button>
        <button @click="timeframe = 'week'" :class="timeframe === 'week' ? 'bg-nibbles-red text-white' : 'bg-white text-gray-600 border border-gray-200'" class="px-3 py-1 rounded-lg text-xs font-medium hover:bg-gray-50 transition-colors">Week</button>
        <button @click="timeframe = 'month'" :class="timeframe === 'month' ? 'bg-nibbles-red text-white' : 'bg-white text-gray-600 border border-gray-200'" class="px-3 py-1 rounded-lg text-xs font-medium hover:bg-gray-50 transition-colors">Month</button>
      </div>
    </div>

    <!-- Key Stats -->
    <div class="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
      <div class="bg-white rounded-xl p-5 shadow-sm border border-gray-100">
        <span class="text-2xl">💰</span>
        <p class="text-2xl font-bold text-nibbles-dark mt-2">{{ totalSales }}</p>
        <p class="text-gray-500 text-sm mt-1">Total Sales</p>
      </div>
      <div class="bg-white rounded-xl p-5 shadow-sm border border-gray-100">
        <span class="text-2xl">🧾</span>
        <p class="text-2xl font-bold text-nibbles-dark mt-2">{{ totalTransactions }}</p>
        <p class="text-gray-500 text-sm mt-1">Transactions</p>
      </div>
      <div class="bg-white rounded-xl p-5 shadow-sm border border-gray-100">
        <span class="text-2xl">⚠️</span>
        <p class="text-2xl font-bold text-red-600 mt-2">{{ lowStockCount }}</p>
        <p class="text-gray-500 text-sm mt-1">Low Stock Items</p>
      </div>
      <div class="bg-white rounded-xl p-5 shadow-sm border border-gray-100">
        <span class="text-2xl">🛍️</span>
        <p class="text-2xl font-bold text-nibbles-dark mt-2">{{ totalItemsSold }}</p>
        <p class="text-gray-500 text-sm mt-1">Items Sold</p>
      </div>
    </div>

    <!-- Main Dashboard Grid -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <!-- Left Column: Sales & Payment Methods -->
      <div class="lg:col-span-2 space-y-6">
        <!-- Revenue Breakdown -->
        <div class="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
          <h3 class="font-semibold text-nibbles-dark mb-4 text-lg">Payment Methods</h3>
          <div class="space-y-3">
            <div v-for="(amount, method) in paymentBreakdown" :key="method" class="flex items-center justify-between">
              <div class="flex-1">
                <p class="text-sm font-medium text-gray-700 capitalize">{{ method }}</p>
                <div class="mt-1 h-2 bg-gray-100 rounded-full overflow-hidden">
                  <div :style="{ width: maxPayment > 0 ? (amount / maxPayment * 100) + '%' : '0' }" 
                    class="h-full rounded-full transition-all" :class="paymentColors[method]"></div>
                </div>
              </div>
              <span class="ml-3 text-sm font-semibold text-nibbles-dark min-w-fit">R{{ amount.toFixed(2) }}</span>
            </div>
          </div>
        </div>

        <!-- Top Products -->
        <div class="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
          <h3 class="font-semibold text-nibbles-dark mb-4 text-lg">Top 5 Products</h3>
          <div v-if="topProducts.length === 0" class="text-gray-400 text-sm">No sales data yet</div>
          <div v-else class="space-y-3">
            <div v-for="(product, i) in topProducts" :key="product.id" class="flex items-center justify-between">
              <div class="flex-1">
                <p class="text-sm font-medium text-gray-800">{{ i + 1 }}. {{ product.name }}</p>
                <p class="text-xs text-gray-500">{{ product.quantity }} sold</p>
              </div>
              <div class="text-right">
                <p class="text-sm font-semibold text-nibbles-red">{{ product.quantity }}</p>
                <p class="text-xs text-gray-500">R{{ product.revenue.toFixed(2) }}</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Right Column: Alerts & Recent Activity -->
      <div class="space-y-6">
        <!-- Low Stock Alerts -->
        <div class="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
          <h3 class="font-semibold text-nibbles-dark mb-4">⚠️ Low Stock</h3>
          <div v-if="lowStockItems.length === 0" class="text-gray-400 text-sm">All stock levels healthy</div>
          <div v-else class="space-y-2 max-h-64 overflow-y-auto">
            <div v-for="item in lowStockItems" :key="item.id" class="p-3 bg-red-50 rounded-lg border border-red-100">
              <p class="text-xs font-semibold text-red-700">{{ item.product_name }}</p>
              <p class="text-xs text-red-600 mt-1">{{ item.quantity_on_hand }} / {{ item.reorder_level }} units</p>
            </div>
          </div>
        </div>

        <!-- Recent Transactions -->
        <div class="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
          <h3 class="font-semibold text-nibbles-dark mb-4">Recent Sales</h3>
          <div v-if="recentSales.length === 0" class="text-gray-400 text-sm">No sales yet</div>
          <div v-else class="space-y-2 max-h-64 overflow-y-auto">
            <div v-for="tx in recentSales" :key="tx.id" class="p-2 bg-gray-50 rounded border border-gray-100 text-xs">
              <div class="flex justify-between">
                <span class="font-mono text-gray-600">{{ tx.receipt_number }}</span>
                <span class="font-semibold text-nibbles-red">R{{ parseFloat(tx.total_amount).toFixed(2) }}</span>
              </div>
              <p class="text-gray-400 mt-1">{{ formatTime(tx.created_at) }}</p>
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
import { useAuthStore } from '../../stores/auth'

const auth = useAuthStore()
const branchName = ref('')
const timeframe = ref('today')
const transactions = ref([])
const lowStockItems = ref([])
const recentSales = ref([])

const paymentColors = {
  cash: 'bg-green-500',
  card: 'bg-blue-500',
  split: 'bg-purple-500'
}

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

// Computed: Total items sold
const totalItemsSold = computed(() => {
  const { data: lines } = supabase.from('transaction_lines').select('quantity').in('transaction_id', transactions.value.map(t => t.id))
  return 0 // Placeholder - will be calculated in data load
})

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

// Computed: Top products
const topProducts = computed(() => {
  const productMap = {}
  
  // Aggregate sales data
  transactions.value.forEach(tx => {
    // This would need transaction_lines join - for now return placeholder
  })
  
  return Object.values(productMap)
    .sort((a, b) => b.revenue - a.revenue)
    .slice(0, 5)
})

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

onMounted(loadDashboardData)
</script>
