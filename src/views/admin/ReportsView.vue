<template>
  <div class="h-full overflow-auto bg-transparent">
    <div class="p-8 max-w-[1400px] mx-auto">
      <!-- Header -->
      <div class="flex flex-wrap items-end justify-between gap-4 mb-7">
        <div>
          <div class="flex items-center gap-2.5">
            <span class="w-10 h-10 rounded-2xl bg-gradient-to-br from-brand-500 to-brand-700 text-white flex items-center justify-center shadow-[0_6px_16px_rgba(162,58,43,0.25)]">
              <AppIcon name="bot" :size="20" />
            </span>
            <h1 class="font-display text-3xl font-semibold text-ink tracking-tight">AI Sales Insights</h1>
          </div>
          <p class="text-ink-muted text-sm mt-1.5">Intelligent analytics &amp; forecasting across all Nibbles branches</p>
        </div>
        <select v-model="rangeDays" @change="loadData" class="input w-auto">
          <option :value="7">Last 7 days</option>
          <option :value="30">Last 30 days</option>
          <option :value="90">Last 90 days</option>
        </select>
      </div>

      <!-- KPI cards -->
      <div class="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-5">
        <div v-for="k in kpis" :key="k.label" class="card card-hover p-5">
          <div class="flex items-center justify-between mb-3">
            <span class="w-9 h-9 rounded-xl flex items-center justify-center" :class="k.chip"><AppIcon :name="k.icon" :size="18" /></span>
            <span v-if="k.delta !== null" class="inline-flex items-center gap-0.5 text-xs font-medium" :class="k.delta >= 0 ? 'text-emerald-600' : 'text-red-600'">
              <AppIcon :name="k.delta >= 0 ? 'arrow-up' : 'arrow-down'" :size="12" :stroke-width="2.5" />{{ Math.abs(k.delta) }}%
            </span>
          </div>
          <p class="text-2xl font-semibold text-ink tracking-tight tabular-nums">{{ k.value }}</p>
          <p class="text-ink-muted text-sm mt-1">{{ k.label }}</p>
        </div>
      </div>

      <!-- Trend + Donut -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-5 mb-5">
        <div class="card p-6 lg:col-span-2">
          <div class="flex items-center justify-between mb-1">
            <h3 class="font-semibold text-ink flex items-center gap-2"><AppIcon name="trending" :size="18" class="text-brand-500" /> Sales Trend &amp; Forecast</h3>
            <span class="text-xs text-ink-muted">solid = actual · dashed = projected</span>
          </div>
          <p class="text-xs text-ink-muted mb-3">Daily revenue with a 7-day AI projection</p>
          <ChartCanvas v-if="ready" type="line" :data="trendData" :options="trendOptions" height="300px" />
          <div v-else class="h-[300px] flex items-center justify-center text-ink-muted text-sm">Loading…</div>
        </div>
        <div class="card p-6">
          <h3 class="font-semibold text-ink flex items-center gap-2 mb-1"><AppIcon name="croissant" :size="18" class="text-brand-500" /> Product Breakdown</h3>
          <p class="text-xs text-ink-muted mb-3">Revenue share by product</p>
          <ChartCanvas v-if="ready && productData.labels.length" type="doughnut" :data="productData" :options="donutOptions" height="340px" />
          <div v-else class="h-[340px] flex items-center justify-center text-ink-muted text-sm">No sales in range</div>
        </div>
      </div>

      <!-- Category bars + AI forecast summary -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-5 mb-5">
        <div class="card p-6 lg:col-span-2">
          <h3 class="font-semibold text-ink flex items-center gap-2 mb-3"><AppIcon name="chart" :size="18" class="text-brand-500" /> Revenue by Category</h3>
          <ChartCanvas v-if="ready && categoryData.labels.length" type="bar" :data="categoryData" :options="barOptions" height="240px" />
          <div v-else class="h-[240px] flex items-center justify-center text-ink-muted text-sm">No data</div>
        </div>
        <div class="card card-hover p-6 flex flex-col justify-between bg-gradient-to-br from-brand-600 to-brand-800 text-white">
          <div>
            <p class="text-white/70 text-sm font-medium">Projected revenue</p>
            <p class="text-white/60 text-xs">next 7 days</p>
            <p class="text-4xl font-semibold tracking-tight mt-3 tabular-nums">{{ money(forecastTotal) }}</p>
          </div>
          <div class="mt-4 pt-4 border-t border-white/20">
            <p class="text-sm text-white/85 flex items-center gap-1.5">
              <AppIcon :name="forecastTrend >= 0 ? 'arrow-up' : 'arrow-down'" :size="14" :stroke-width="2.5" />
              {{ forecastTrend >= 0 ? 'Upward' : 'Downward' }} trend ({{ forecastTrend >= 0 ? '+' : '' }}{{ forecastTrend }}% vs current avg)
            </p>
          </div>
        </div>
      </div>

      <!-- AI narrative -->
      <div class="card p-6 mb-5">
        <div class="flex items-center justify-between mb-4">
          <div>
            <h3 class="font-semibold text-ink flex items-center gap-2"><AppIcon name="bot" :size="18" class="text-brand-500" /> AI Business Analysis</h3>
            <p class="text-xs text-ink-muted mt-0.5">Demand forecast, insights &amp; recommendations — powered by Groq (Llama 3.3)</p>
          </div>
          <button @click="runAI" :disabled="aiLoading" class="btn-primary">
            <span v-if="aiLoading" class="w-4 h-4 border-2 border-white/40 border-t-white rounded-full animate-spin"></span>
            <AppIcon v-else name="bot" :size="16" />
            {{ aiLoading ? 'Analysing…' : 'Generate analysis' }}
          </button>
        </div>
        <div v-if="aiError" class="p-3 bg-red-50 border border-red-100 rounded-xl text-red-600 text-sm mb-3">{{ aiError }}</div>
        <div v-if="!aiResult && !aiLoading" class="text-center py-10 text-ink-muted">
          <span class="w-12 h-12 rounded-2xl bg-brand-50 text-brand-600 flex items-center justify-center mx-auto mb-3"><AppIcon name="bot" :size="24" /></span>
          <p class="text-sm max-w-md mx-auto">Generate an AI read on demand forecasting, customer behaviour, and what to do this week — based on your live sales data.</p>
        </div>
        <div v-if="aiLoading" class="text-center py-10 text-ink-muted">
          <div class="w-8 h-8 border-2 border-brand-500 border-t-transparent rounded-full animate-spin mx-auto mb-3"></div>
          <p class="text-sm">Groq is analysing {{ completed.length }} orders…</p>
        </div>
        <div v-if="aiResult" class="prose-nibbles text-sm text-ink-soft leading-relaxed whitespace-pre-wrap bg-stone-50 rounded-xl p-5">{{ aiResult }}</div>
        <p v-if="aiResult" class="text-xs text-ink-muted mt-2">Generated {{ aiTimestamp }} · AI-generated, for reference only</p>
      </div>

      <!-- Data reports (tables) -->
      <div class="card">
        <div class="p-5 border-b border-stone-100 flex flex-wrap items-center justify-between gap-3">
          <div>
            <h3 class="font-semibold text-ink">Data Reports</h3>
            <p class="text-xs text-ink-muted mt-0.5">Live records — switch dataset and export to CSV</p>
          </div>
          <button @click="exportCsv" :disabled="!reportRows.length" class="btn-secondary"><AppIcon name="arrow-down" :size="16" /> Export CSV</button>
        </div>
        <div class="px-5 pt-4 flex gap-2 flex-wrap">
          <button v-for="r in reportDefs" :key="r.key" @click="loadReport(r.key)"
            :class="activeReport === r.key ? 'bg-brand-600 text-white' : 'bg-stone-100 text-ink-soft hover:bg-stone-200'"
            class="px-3.5 py-1.5 rounded-full text-xs font-medium transition-colors">{{ r.label }}</button>
        </div>
        <div class="p-5">
          <div class="overflow-x-auto border border-stone-100 rounded-xl">
            <table class="w-full text-sm">
              <thead>
                <tr class="text-left text-ink-muted border-b border-stone-100 bg-stone-50/60">
                  <th v-for="c in reportColumns" :key="c.key" class="px-4 py-2.5 font-medium whitespace-nowrap">{{ c.label }}</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-stone-50">
                <tr v-if="reportLoading"><td :colspan="reportColumns.length" class="px-4 py-8 text-center text-ink-muted">Loading…</td></tr>
                <tr v-else-if="reportRows.length === 0"><td :colspan="reportColumns.length" class="px-4 py-8 text-center text-ink-muted">No records.</td></tr>
                <tr v-for="(row, i) in reportRows" :key="i" class="hover:bg-stone-50/70">
                  <td v-for="c in reportColumns" :key="c.key" class="px-4 py-2.5 whitespace-nowrap" :class="c.numeric ? 'text-ink font-medium tabular-nums' : 'text-ink-soft'">{{ formatCell(row[c.key], c) }}</td>
                </tr>
              </tbody>
            </table>
          </div>
          <p v-if="reportRows.length" class="text-xs text-ink-muted mt-2">{{ reportRows.length }} rows</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../../lib/supabase'
import AppIcon from '../../components/AppIcon.vue'
import ChartCanvas from '../../components/ChartCanvas.vue'

const PALETTE = ['#A23A2B', '#3B82F6', '#F59E0B', '#14B8A6', '#8B5CF6', '#EC4899', '#10B981']
const money = (v) => `R${parseFloat(v || 0).toLocaleString('en-ZA', { minimumFractionDigits: 2 })}`
const moneyShort = (v) => 'R' + Math.round(v).toLocaleString('en-ZA')

const rangeDays = ref(7)
const ready = ref(false)
const tx = ref([])
const lines = ref([])

const completed = computed(() => tx.value.filter(t => t.status === 'completed'))

// ---------- KPIs ----------
const totalRevenue = computed(() => completed.value.reduce((s, t) => s + +t.total_amount, 0))
const avgOrder = computed(() => completed.value.length ? totalRevenue.value / completed.value.length : 0)
const uniqueProducts = computed(() => new Set(lines.value.map(l => l.products?.name).filter(Boolean)).size)
const kpis = computed(() => [
  { label: 'Total Orders', value: completed.value.length, icon: 'receipt', chip: 'bg-sky-50 text-sky-600', delta: null },
  { label: 'Total Revenue', value: money(totalRevenue.value), icon: 'banknote', chip: 'bg-emerald-50 text-emerald-600', delta: revenueDelta.value },
  { label: 'Average Order', value: money(avgOrder.value), icon: 'trending', chip: 'bg-violet-50 text-violet-600', delta: null },
  { label: 'Unique Products', value: uniqueProducts.value, icon: 'croissant', chip: 'bg-amber-50 text-amber-600', delta: null },
])

// ---------- daily series ----------
function dayKey(d) { return new Date(d).toISOString().slice(0, 10) }
const dailySeries = computed(() => {
  const map = {}
  for (let i = rangeDays.value - 1; i >= 0; i--) {
    const d = new Date(); d.setDate(d.getDate() - i)
    map[d.toISOString().slice(0, 10)] = 0
  }
  completed.value.forEach(t => { const k = dayKey(t.created_at); if (k in map) map[k] += +t.total_amount })
  return Object.entries(map).map(([date, revenue]) => ({ date, revenue }))
})
const revenueDelta = computed(() => {
  const s = dailySeries.value
  if (s.length < 4) return null
  const half = Math.floor(s.length / 2)
  const a = s.slice(0, half).reduce((x, d) => x + d.revenue, 0) / half
  const b = s.slice(half).reduce((x, d) => x + d.revenue, 0) / (s.length - half)
  if (!a) return null
  return Math.round(((b - a) / a) * 100)
})

// ---------- forecast (least-squares linear regression) ----------
function linreg(ys) {
  const n = ys.length
  if (n < 2) return { slope: 0, intercept: ys[0] || 0 }
  let sx = 0, sy = 0, sxx = 0, sxy = 0
  ys.forEach((y, x) => { sx += x; sy += y; sxx += x * x; sxy += x * y })
  const denom = n * sxx - sx * sx || 1
  const slope = (n * sxy - sx * sy) / denom
  return { slope, intercept: (sy - slope * sx) / n }
}
const forecast = computed(() => {
  const ys = dailySeries.value.map(d => d.revenue)
  const { slope, intercept } = linreg(ys)
  const out = []
  for (let i = 0; i < 7; i++) {
    const x = ys.length + i
    out.push(Math.max(0, slope * x + intercept))
  }
  return out
})
const forecastTotal = computed(() => forecast.value.reduce((s, v) => s + v, 0))
const forecastTrend = computed(() => {
  const avg = dailySeries.value.reduce((s, d) => s + d.revenue, 0) / (dailySeries.value.length || 1)
  const favg = forecastTotal.value / 7
  if (!avg) return 0
  return Math.round(((favg - avg) / avg) * 100)
})

// ---------- chart data ----------
const fmtLabel = (iso) => { const d = new Date(iso); return `${d.getDate()}/${d.getMonth() + 1}` }
const trendData = computed(() => {
  const actualLabels = dailySeries.value.map(d => fmtLabel(d.date))
  const futureLabels = forecast.value.map((_, i) => {
    const d = new Date(); d.setDate(d.getDate() + i + 1); return fmtLabel(d.toISOString())
  })
  const actual = dailySeries.value.map(d => d.revenue)
  const lastActual = actual[actual.length - 1] ?? 0
  const forecastSeries = [...actual.map(() => null)]
  forecastSeries[forecastSeries.length - 1] = lastActual // join point
  forecast.value.forEach(v => forecastSeries.push(v))
  return {
    labels: [...actualLabels, ...futureLabels],
    datasets: [
      { label: 'Actual revenue', data: [...actual, ...forecast.value.map(() => null)], borderColor: '#A23A2B', backgroundColor: 'rgba(162,58,43,0.08)', borderWidth: 2.5, fill: true, tension: 0.35, pointRadius: 2, pointHoverRadius: 5, pointBackgroundColor: '#A23A2B' },
      { label: 'Projected', data: forecastSeries, borderColor: '#D17263', borderDash: [6, 5], borderWidth: 2, fill: false, tension: 0.35, pointRadius: 0, pointHoverRadius: 4 },
    ],
  }
})
const trendOptions = {
  plugins: { legend: { display: false } },
  scales: {
    y: { beginAtZero: true, grid: { color: 'rgba(120,113,108,0.10)' }, ticks: { callback: (v) => moneyShort(v) } },
    x: { grid: { display: false } },
  },
  interaction: { mode: 'index', intersect: false },
}

const productAgg = computed(() => {
  const m = {}
  lines.value.forEach(l => { const n = l.products?.name || 'Unknown'; m[n] = (m[n] || 0) + +l.line_total })
  const sorted = Object.entries(m).sort((a, b) => b[1] - a[1])
  const top = sorted.slice(0, 6)
  const otherTotal = sorted.slice(6).reduce((s, [, v]) => s + v, 0)
  if (otherTotal > 0) top.push(['Other', otherTotal])
  return top
})
const productData = computed(() => ({
  labels: productAgg.value.map(([n]) => n),
  datasets: [{ data: productAgg.value.map(([, v]) => Math.round(v)), backgroundColor: PALETTE, borderColor: '#fff', borderWidth: 2, hoverOffset: 6 }],
}))
const donutOptions = {
  cutout: '62%',
  plugins: { legend: { position: 'bottom', labels: { boxWidth: 10, boxHeight: 10, usePointStyle: true, padding: 12 } },
    tooltip: { callbacks: { label: (c) => ` ${c.label}: ${money(c.raw)}` } } },
}

const categoryAgg = computed(() => {
  const m = {}
  lines.value.forEach(l => { const c = l.products?.category || 'other'; m[c] = (m[c] || 0) + +l.line_total })
  return Object.entries(m).sort((a, b) => b[1] - a[1])
})
const categoryData = computed(() => ({
  labels: categoryAgg.value.map(([c]) => c.charAt(0).toUpperCase() + c.slice(1)),
  datasets: [{ label: 'Revenue', data: categoryAgg.value.map(([, v]) => Math.round(v)), backgroundColor: PALETTE, borderRadius: 8, maxBarThickness: 48 }],
}))
const barOptions = {
  plugins: { legend: { display: false }, tooltip: { callbacks: { label: (c) => ` ${money(c.raw)}` } } },
  scales: { y: { beginAtZero: true, grid: { color: 'rgba(120,113,108,0.10)' }, ticks: { callback: (v) => moneyShort(v) } }, x: { grid: { display: false } } },
}

// ---------- AI narrative (secure edge function) ----------
const aiResult = ref(''); const aiError = ref(''); const aiLoading = ref(false); const aiTimestamp = ref('')
async function runAI() {
  aiLoading.value = true; aiError.value = ''; aiResult.value = ''
  try {
    const topItems = productAgg.value.map(([n, v]) => `${n}: ${money(v)} revenue`).join('\n')
    const trend = dailySeries.value.map(d => `${d.date}: ${money(d.revenue)}`).join('\n')
    const salesContext = `Period: last ${rangeDays.value} days\nTotal orders: ${completed.value.length}\nTotal revenue: ${money(totalRevenue.value)}\nAverage order: ${money(avgOrder.value)}\n\nTop products by revenue:\n${topItems}\n\nDaily revenue:\n${trend}\n\nLinear-projected next 7 days: ${money(forecastTotal.value)} (${forecastTrend.value}% vs current daily avg)`
    const { data, error } = await supabase.functions.invoke('groq-insights', { body: { salesContext } })
    if (error) throw new Error(error.message || 'Edge function error')
    if (data?.error) throw new Error(data.error)
    aiResult.value = data.result
    aiTimestamp.value = new Date().toLocaleString('en-ZA')
  } catch (err) {
    aiError.value = `AI unavailable: ${err.message}. (Ensure the groq-insights function is deployed and GROQ_API_KEY secret is set.)`
  } finally {
    aiLoading.value = false
  }
}

// ---------- data reports tables ----------
const datetime = (v) => v ? new Date(v).toLocaleString('en-ZA', { dateStyle: 'short', timeStyle: 'short' }) : '—'
const reportDefs = [
  { key: 'transactions', label: 'Transactions', columns: [
      { key: 'receipt_number', label: 'Receipt' }, { key: 'branch', label: 'Branch' },
      { key: 'total_amount', label: 'Amount', numeric: true, format: money }, { key: 'payment_method', label: 'Payment' },
      { key: 'status', label: 'Status' }, { key: 'created_at', label: 'Date', format: datetime } ],
    async load() {
      const { data } = await supabase.from('transactions').select('receipt_number, total_amount, payment_method, status, created_at, branches(name)').order('created_at', { ascending: false }).limit(500)
      return (data || []).map(t => ({ ...t, branch: t.branches?.name?.trim() || '—' }))
    } },
  { key: 'products', label: 'Products', columns: [
      { key: 'name', label: 'Name' }, { key: 'category', label: 'Category' },
      { key: 'unit_price', label: 'Price', numeric: true, format: money }, { key: 'sku', label: 'SKU' } ],
    async load() { const { data } = await supabase.from('products').select('name, category, unit_price, sku').order('name'); return data || [] } },
  { key: 'inventory', label: 'Inventory', columns: [
      { key: 'product', label: 'Product' }, { key: 'branch', label: 'Branch' },
      { key: 'quantity_on_hand', label: 'On hand', numeric: true }, { key: 'reorder_threshold', label: 'Reorder at', numeric: true } ],
    async load() {
      const { data } = await supabase.from('inventory').select('quantity_on_hand, reorder_threshold, products(name), branches(name)').order('quantity_on_hand', { ascending: true }).limit(500)
      return (data || []).map(i => ({ ...i, product: i.products?.name || '—', branch: i.branches?.name?.trim() || '—' }))
    } },
]
const activeReport = ref('transactions')
const reportRows = ref([]); const reportLoading = ref(false); const reportColumns = ref(reportDefs[0].columns)
function formatCell(v, c) { if (c.format) return c.format(v); return v === null || v === undefined || v === '' ? '—' : v }
async function loadReport(key) {
  const def = reportDefs.find(r => r.key === key); if (!def) return
  activeReport.value = key; reportColumns.value = def.columns; reportLoading.value = true
  try { reportRows.value = await def.load() } finally { reportLoading.value = false }
}
function exportCsv() {
  const cols = reportColumns.value
  const esc = (s) => `"${String(s ?? '').replace(/"/g, '""')}"`
  const csv = [cols.map(c => esc(c.label)).join(','), ...reportRows.value.map(r => cols.map(c => esc(formatCell(r[c.key], c))).join(','))].join('\n')
  const url = URL.createObjectURL(new Blob([csv], { type: 'text/csv;charset=utf-8;' }))
  const a = document.createElement('a'); a.href = url; a.download = `nibbles-${activeReport.value}-${new Date().toISOString().slice(0, 10)}.csv`; a.click(); URL.revokeObjectURL(url)
}

// ---------- load ----------
async function loadData() {
  ready.value = false
  const start = new Date(); start.setDate(start.getDate() - rangeDays.value); start.setHours(0, 0, 0, 0)
  const startIso = start.toISOString()
  const [{ data: txData }, { data: lineData }] = await Promise.all([
    supabase.from('transactions').select('id, total_amount, payment_method, status, created_at').gte('created_at', startIso).order('created_at'),
    supabase.from('transaction_lines').select('quantity, line_total, products(name, category), transactions!inner(created_at, status)').gte('transactions.created_at', startIso).eq('transactions.status', 'completed'),
  ])
  tx.value = txData || []
  lines.value = lineData || []
  ready.value = true
}

onMounted(async () => {
  await loadData()
  await loadReport('transactions')
})
</script>
