<template>
  <div class="p-6">
    <div class="mb-6">
      <h1 class="text-2xl font-bold text-nibbles-dark">Reports & AI Insights</h1>
      <p class="text-gray-500 text-sm mt-1">Business intelligence powered by Groq AI</p>
    </div>

    <!-- Stats row -->
    <div class="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
      <div v-for="stat in stats" :key="stat.label" class="bg-white rounded-xl p-4 shadow-sm border border-gray-100">
        <p class="text-2xl font-bold text-nibbles-dark">{{ stat.value }}</p>
        <p class="text-gray-500 text-sm mt-1">{{ stat.label }}</p>
      </div>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
      <!-- Top products -->
      <div class="bg-white rounded-xl p-5 shadow-sm border border-gray-100">
        <h3 class="font-semibold text-nibbles-dark mb-4">Top Products by Revenue</h3>
        <div class="space-y-3">
          <div v-for="(p, i) in topProducts" :key="p.name" class="flex items-center gap-3">
            <span class="w-5 h-5 text-xs font-bold text-gray-400 flex-shrink-0">{{ i + 1 }}</span>
            <div class="flex-1">
              <div class="flex justify-between text-sm mb-1">
                <span class="font-medium text-gray-700 truncate">{{ p.name }}</span>
                <span class="text-gray-500 ml-2 flex-shrink-0">R{{ p.revenue.toFixed(2) }}</span>
              </div>
              <div class="w-full bg-gray-100 rounded-full h-1.5">
                <div class="bg-nibbles-red h-1.5 rounded-full" :style="{ width: (p.revenue / topProducts[0]?.revenue * 100) + '%' }"></div>
              </div>
            </div>
          </div>
          <div v-if="topProducts.length === 0" class="text-gray-400 text-sm">No sales data yet.</div>
        </div>
      </div>

      <!-- Payment methods -->
      <div class="bg-white rounded-xl p-5 shadow-sm border border-gray-100">
        <h3 class="font-semibold text-nibbles-dark mb-4">Payment Methods</h3>
        <div class="space-y-3">
          <div v-for="pm in paymentMethods" :key="pm.method" class="flex items-center gap-3">
            <span class="text-xl">{{ pm.icon }}</span>
            <div class="flex-1">
              <div class="flex justify-between text-sm mb-1">
                <span class="font-medium text-gray-700 capitalize">{{ pm.method }}</span>
                <span class="text-gray-500">{{ pm.count }} transactions</span>
              </div>
              <div class="w-full bg-gray-100 rounded-full h-1.5">
                <div class="bg-nibbles-red h-1.5 rounded-full" :style="{ width: pm.pct + '%' }"></div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- AI Insights -->
    <div class="bg-white rounded-xl p-5 shadow-sm border border-gray-100">
      <div class="flex items-center justify-between mb-4">
        <div>
          <h3 class="font-semibold text-nibbles-dark">AI Demand Forecast</h3>
          <p class="text-xs text-gray-400 mt-0.5">Powered by Groq — analyses sales history to predict demand</p>
        </div>
        <button @click="runAI" :disabled="aiLoading"
          class="bg-nibbles-red text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-nibbles-red-dark disabled:opacity-60 transition-colors flex items-center gap-2">
          <span>{{ aiLoading ? '⏳' : '🤖' }}</span>
          {{ aiLoading ? 'Analysing...' : 'Run AI Analysis' }}
        </button>
      </div>

      <div v-if="aiError" class="p-4 bg-red-50 border border-red-200 rounded-lg text-red-600 text-sm mb-4">{{ aiError }}</div>

      <div v-if="!aiResult && !aiLoading" class="text-center py-8 text-gray-400">
        <p class="text-4xl mb-3">🤖</p>
        <p class="text-sm">Click "Run AI Analysis" to generate demand predictions and business insights based on your sales data.</p>
      </div>

      <div v-if="aiLoading" class="text-center py-8 text-gray-400">
        <div class="w-8 h-8 border-2 border-nibbles-red border-t-transparent rounded-full animate-spin mx-auto mb-3"></div>
        <p class="text-sm">Groq is analysing your sales patterns...</p>
      </div>

      <div v-if="aiResult" class="prose prose-sm max-w-none">
        <div class="bg-nibbles-cream rounded-xl p-5 text-gray-700 text-sm leading-relaxed whitespace-pre-wrap">{{ aiResult }}</div>
        <p class="text-xs text-gray-400 mt-3">Generated {{ aiTimestamp }}</p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '../../lib/supabase'

const stats = ref([
  { label: 'Total Revenue', value: 'R0' },
  { label: 'Total Transactions', value: '0' },
  { label: 'Avg Transaction', value: 'R0' },
  { label: 'Loyalty Members', value: '0' },
])
const topProducts = ref([])
const paymentMethods = ref([])
const aiResult = ref('')
const aiError = ref('')
const aiLoading = ref(false)
const aiTimestamp = ref('')

const GROQ_API_KEY = import.meta.env.VITE_GROQ_API_KEY

async function runAI() {
  if (!GROQ_API_KEY) { aiError.value = 'VITE_GROQ_API_KEY is not set in .env.local'; return }
  aiLoading.value = true; aiError.value = ''; aiResult.value = ''

  const { data: txLines } = await supabase
    .from('transaction_lines')
    .select('quantity, unit_price_at_sale, line_total, products(name, category), transactions(created_at, branch_id, branches(name))')
    .order('created_at', { foreignTable: 'transactions', ascending: false })
    .limit(200)

  const summary = {}
  txLines?.forEach(line => {
    const name = line.products?.name || 'Unknown'
    if (!summary[name]) summary[name] = { qty: 0, revenue: 0, category: line.products?.category }
    summary[name].qty += line.quantity
    summary[name].revenue += parseFloat(line.line_total || 0)
  })

  const topItems = Object.entries(summary).sort((a, b) => b[1].revenue - a[1].revenue).slice(0, 10)
  const salesContext = topItems.map(([name, d]) => `${name} (${d.category}): ${d.qty} units sold, R${d.revenue.toFixed(2)} revenue`).join('\n')

  try {
    const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${GROQ_API_KEY}` },
      body: JSON.stringify({
        model: 'llama3-8b-8192',
        messages: [{
          role: 'user',
          content: `You are a business analyst for Nibbles Bakery, a multi-branch bakery in Durban, South Africa.

Based on the following sales data from our system:
${salesContext}

Please provide:
1. DEMAND FORECAST: Which products are likely to need restocking soon and by how much
2. BUSINESS INSIGHTS: What the sales patterns tell us about customer behaviour
3. RECOMMENDATIONS: 2-3 specific actions the owner should take this week
4. RISK FLAGS: Any products that seem to be underperforming

Keep it practical and specific to a bakery business. Be concise but detailed.`
        }],
        max_tokens: 800,
        temperature: 0.7
      })
    })
    const data = await response.json()
    if (data.error) throw new Error(data.error.message)
    aiResult.value = data.choices[0].message.content
    aiTimestamp.value = new Date().toLocaleString('en-ZA')
  } catch (err) {
    aiError.value = `AI error: ${err.message}`
  } finally {
    aiLoading.value = false
  }
}

onMounted(async () => {
  const { data: txData } = await supabase.from('transactions').select('total_amount, payment_method').eq('status', 'completed')
  if (txData && txData.length > 0) {
    const total = txData.reduce((s, t) => s + parseFloat(t.total_amount || 0), 0)
    stats.value[0].value = `R${total.toLocaleString('en-ZA', { minimumFractionDigits: 2 })}`
    stats.value[1].value = String(txData.length)
    stats.value[2].value = `R${(total / txData.length).toFixed(2)}`
    const pmCounts = {}
    txData.forEach(t => { pmCounts[t.payment_method] = (pmCounts[t.payment_method] || 0) + 1 })
    const icons = { cash: '💵', card: '💳', split: '🔀' }
    paymentMethods.value = Object.entries(pmCounts).map(([method, count]) => ({
      method, count, icon: icons[method] || '💰', pct: (count / txData.length * 100).toFixed(0)
    }))
  }

  const { data: lineData } = await supabase.from('transaction_lines').select('quantity, line_total, products(name)')
  if (lineData) {
    const agg = {}
    lineData.forEach(l => {
      const name = l.products?.name || 'Unknown'
      if (!agg[name]) agg[name] = { name, revenue: 0 }
      agg[name].revenue += parseFloat(l.line_total || 0)
    })
    topProducts.value = Object.values(agg).sort((a, b) => b.revenue - a.revenue).slice(0, 5)
  }

  const { count } = await supabase.from('customers').select('*', { count: 'exact', head: true })
  if (count !== null) stats.value[3].value = String(count)
})
</script>
