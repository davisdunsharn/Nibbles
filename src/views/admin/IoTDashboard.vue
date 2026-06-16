<template>
  <div class="p-8">
    <div class="mb-7 flex flex-wrap items-end justify-between gap-4">
      <div>
        <div class="flex items-center gap-2.5">
          <h1 class="font-display text-3xl font-semibold text-ink tracking-tight">Production &amp; Operations Hub</h1>
          <span v-if="simulating" class="inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full bg-emerald-50 text-emerald-700 text-xs font-semibold">
            <span class="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse"></span> LIVE
          </span>
        </div>
        <p class="text-ink-muted text-sm mt-1">Live RFID scan activity, deliveries and alerts across all branches</p>
      </div>
      <div class="flex items-center gap-2">
        <button @click="toggleSim" class="btn" :class="simulating ? 'bg-red-50 text-red-600 border border-red-200 hover:bg-red-100 px-4 py-2.5' : 'btn-secondary'">
          <AppIcon :name="simulating ? 'x' : 'radio'" :size="16" /> {{ simulating ? 'Stop simulation' : 'Simulate live' }}
        </button>
        <button @click="loadAll" :disabled="loading" class="btn-secondary">
          <span v-if="loading" class="w-4 h-4 border-2 border-stone-300 border-t-brand-500 rounded-full animate-spin"></span>
          <AppIcon v-else name="refresh" :size="16" /> Refresh
        </button>
      </div>
    </div>

    <!-- Key Metrics -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-5">
      <div v-for="m in metrics" :key="m.label" class="card card-hover p-5">
        <div class="flex items-center justify-between mb-3">
          <span class="w-10 h-10 rounded-xl flex items-center justify-center" :class="m.chip">
            <AppIcon :name="m.icon" :size="20" />
          </span>
        </div>
        <p class="text-2xl font-semibold text-ink tracking-tight tabular-nums">{{ m.value }}</p>
        <p class="text-ink-muted text-sm mt-1">{{ m.label }}</p>
        <p v-if="m.sub" class="text-xs text-ink-muted mt-0.5">{{ m.sub }}</p>
      </div>
    </div>

    <!-- Main Grid -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-5">
      <!-- Recent IoT Activity -->
      <div class="lg:col-span-2 card">
        <div class="p-5 border-b border-stone-100 flex items-center justify-between">
          <h3 class="font-semibold text-ink flex items-center gap-2">
            <span class="w-2 h-2 bg-emerald-500 rounded-full animate-pulse"></span>
            Recent IoT Scan Activity
          </h3>
          <span class="text-xs text-ink-muted">last 48 hours</span>
        </div>
        <div class="divide-y divide-stone-50">
          <div v-for="e in recentEvents" :key="e.id" class="flex items-center gap-4 px-5 py-3">
            <span class="w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0" :class="eventStyle(e).chip">
              <AppIcon :name="eventStyle(e).icon" :size="18" />
            </span>
            <div class="flex-1 min-w-0">
              <p class="text-sm font-medium text-ink truncate">
                {{ e.products?.name || e.sku_scanned || 'Unknown item' }}
                <span v-if="e.is_anomaly" class="badge-danger ml-1">anomaly</span>
              </p>
              <p class="text-xs text-ink-muted truncate">{{ e.branches?.name?.trim() }} · {{ e.device_id }}</p>
            </div>
            <div class="text-right flex-shrink-0">
              <p class="text-sm font-semibold" :class="eventStyle(e).text">{{ eventStyle(e).sign }}{{ e.quantity }}</p>
              <p class="text-xs text-ink-muted capitalize">{{ e.event_type.replace('_',' ') }} · {{ timeAgo(e.created_at) }}</p>
            </div>
          </div>
          <div v-if="!loading && recentEvents.length === 0" class="px-5 py-10 text-center text-ink-muted text-sm">
            No scan activity recorded yet
          </div>
          <div v-if="loading" class="px-5 py-10 text-center text-ink-muted text-sm">Loading…</div>
        </div>
      </div>

      <!-- Branch Device Activity -->
      <div class="card">
        <div class="p-5 border-b border-stone-100">
          <h3 class="font-semibold text-ink">Branch Device Activity</h3>
        </div>
        <div class="p-5 space-y-3">
          <div v-for="b in deviceActivity" :key="b.id" class="p-3 border border-stone-200 rounded-xl">
            <div class="flex items-center justify-between mb-2">
              <p class="text-sm font-medium text-ink">{{ b.name.trim() }}</p>
              <span :class="b.online ? 'badge-success' : 'badge-neutral'">
                <AppIcon name="dot" :size="10" :stroke-width="0" class="fill-current" />
                {{ b.online ? 'Reporting' : 'Idle' }}
              </span>
            </div>
            <div class="flex items-center gap-4 text-xs text-ink-muted">
              <span class="inline-flex items-center gap-1"><AppIcon name="radio" :size="14" class="text-brand-400" /> {{ b.events }} scans / 24h</span>
              <span v-if="b.lastSeen">· last {{ timeAgo(b.lastSeen) }}</span>
            </div>
          </div>
          <div v-if="!loading && deviceActivity.length === 0" class="text-ink-muted text-sm">No branches found</div>
        </div>
      </div>
    </div>

    <!-- Deliveries & Alerts -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-5 mt-5">
      <!-- Scheduled Deliveries -->
      <div class="card">
        <div class="p-5 border-b border-stone-100">
          <h3 class="font-semibold text-ink">Scheduled Deliveries</h3>
        </div>
        <div class="p-5 space-y-3">
          <div v-for="d in deliveries" :key="d.id" class="flex items-center gap-3 p-3 rounded-xl border" :class="deliveryDone(d) ? 'border-emerald-100 bg-emerald-50/50' : 'border-stone-200'">
            <span class="w-9 h-9 rounded-lg bg-white border border-stone-100 flex items-center justify-center flex-shrink-0" :class="deliveryDone(d) ? 'text-emerald-500' : 'text-brand-500'">
              <AppIcon name="truck" :size="18" />
            </span>
            <div class="flex-1 min-w-0">
              <p class="text-sm font-medium text-ink truncate">{{ d.branches?.name?.trim() }}</p>
              <p class="text-xs text-ink-muted truncate">{{ d.suppliers?.name }} · {{ formatDate(d.expected_delivery) }}</p>
            </div>
            <span :class="deliveryBadge(d.status)" class="capitalize flex-shrink-0">{{ d.status.replace('_',' ') }}</span>
          </div>
          <div v-if="!loading && deliveries.length === 0" class="p-6 text-center text-ink-muted text-sm">
            No deliveries scheduled
          </div>
        </div>
      </div>

      <!-- System Alerts -->
      <div class="card">
        <div class="p-5 border-b border-stone-100">
          <h3 class="font-semibold text-ink">System Alerts &amp; Notifications</h3>
        </div>
        <div class="p-5 space-y-3">
          <div v-if="!loading && alerts.length === 0" class="flex items-center justify-center gap-2 p-6 text-ink-muted text-sm">
            <AppIcon name="check-circle" :size="16" class="text-emerald-500" /> All systems operating normally
          </div>
          <div v-for="a in alerts" :key="a.id" class="flex items-start gap-3 p-3 rounded-xl border" :class="alertStyle(a.type).box">
            <AppIcon :name="alertStyle(a.type).icon" :size="18" class="flex-shrink-0 mt-0.5" :class="alertStyle(a.type).text" />
            <div class="flex-1 min-w-0">
              <p class="text-sm font-medium text-ink">{{ a.title }}</p>
              <p class="text-xs text-ink-muted mt-0.5">{{ a.body }}</p>
              <p class="text-xs text-ink-muted mt-1">{{ timeAgo(a.created_at) }}</p>
            </div>
            <span v-if="!a.is_read" class="w-2 h-2 rounded-full bg-brand-500 mt-1.5 flex-shrink-0"></span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onBeforeUnmount } from 'vue'
import { supabase } from '../../lib/supabase'
import AppIcon from '../../components/AppIcon.vue'

const loading = ref(true)
const branches = ref([])
const events = ref([])
const deliveries = ref([])
const alerts = ref([])
const products = ref([])
const simulating = ref(false)
let simTimer = null

const OPEN_STATUSES = ['pending', 'sent', 'confirmed', 'partially_received']

function isToday(ts) {
  const d = new Date(ts)
  const now = new Date()
  return d.getFullYear() === now.getFullYear() && d.getMonth() === now.getMonth() && d.getDate() === now.getDate()
}
function within24h(ts) {
  return Date.now() - new Date(ts).getTime() <= 24 * 60 * 60 * 1000
}

const activeBranches = computed(() => branches.value.filter(b => b.is_active).length)
const stockInToday = computed(() =>
  events.value.filter(e => e.event_type === 'stock_in' && isToday(e.created_at)).reduce((s, e) => s + (e.quantity || 0), 0)
)
const scans24h = computed(() => events.value.filter(e => within24h(e.created_at)).length)
const openDeliveries = computed(() => deliveries.value.filter(d => OPEN_STATUSES.includes(d.status)).length)

const recentEvents = computed(() => events.value.slice(0, 8))

const deviceActivity = computed(() =>
  branches.value
    .filter(b => b.is_active)
    .map(b => {
      const branchEvents = events.value.filter(e => e.branch_id === b.id && within24h(e.created_at))
      const lastSeen = branchEvents.length ? branchEvents[0].created_at : null
      return { id: b.id, name: b.name, events: branchEvents.length, lastSeen, online: branchEvents.length > 0 }
    })
)

const metrics = computed(() => [
  { label: 'Active Branches', value: activeBranches.value, icon: 'store', chip: 'bg-sky-50 text-sky-600' },
  { label: 'Stock-In Today', value: stockInToday.value.toLocaleString(), sub: 'Units scanned in', icon: 'package', chip: 'bg-emerald-50 text-emerald-600' },
  { label: 'IoT Scans (24h)', value: scans24h.value, sub: 'Across all devices', icon: 'radio', chip: 'bg-amber-50 text-amber-600' },
  { label: 'Open Deliveries', value: openDeliveries.value, sub: 'Awaiting receipt', icon: 'truck', chip: 'bg-violet-50 text-violet-600' },
])

function eventStyle(e) {
  if (e.is_anomaly || e.event_type === 'unknown')
    return { icon: 'alert', chip: 'bg-red-50 text-red-600', text: 'text-red-600', sign: '' }
  if (e.event_type === 'stock_in')
    return { icon: 'arrow-down', chip: 'bg-emerald-50 text-emerald-600', text: 'text-emerald-600', sign: '+' }
  if (e.event_type === 'stock_out')
    return { icon: 'arrow-up', chip: 'bg-amber-50 text-amber-600', text: 'text-amber-600', sign: '−' }
  return { icon: 'check', chip: 'bg-stone-100 text-stone-500', text: 'text-ink-soft', sign: '' }
}

function deliveryDone(d) { return d.status === 'received' }
function deliveryBadge(status) {
  if (status === 'received') return 'badge-success'
  if (status === 'cancelled') return 'badge-neutral'
  if (status === 'pending') return 'badge-warning'
  return 'badge bg-sky-50 text-sky-700'
}

function alertStyle(type) {
  if (type === 'iot_anomaly') return { icon: 'alert', box: 'bg-red-50 border-red-100', text: 'text-red-500' }
  if (type === 'low_stock') return { icon: 'alert', box: 'bg-amber-50 border-amber-100', text: 'text-amber-500' }
  if (type === 'order_received') return { icon: 'check-circle', box: 'bg-emerald-50 border-emerald-100', text: 'text-emerald-500' }
  return { icon: 'dot', box: 'bg-stone-50 border-stone-100', text: 'text-stone-400' }
}

function formatDate(d) {
  if (!d) return '—'
  return new Date(d).toLocaleDateString('en-ZA', { weekday: 'short', day: '2-digit', month: 'short' })
}
function timeAgo(ts) {
  const diff = Date.now() - new Date(ts).getTime()
  const mins = Math.round(diff / 60000)
  if (mins < 1) return 'just now'
  if (mins < 60) return `${mins}m ago`
  const hrs = Math.round(mins / 60)
  if (hrs < 24) return `${hrs}h ago`
  return `${Math.round(hrs / 24)}d ago`
}

async function loadAll() {
  loading.value = true
  try {
    const [branchRes, eventRes, poRes, notifRes] = await Promise.all([
      supabase.from('branches').select('id, name, is_active'),
      supabase
        .from('iot_events')
        .select('id, branch_id, event_type, quantity, sku_scanned, device_id, is_anomaly, anomaly_reason, created_at, products(name), branches(name)')
        .gte('created_at', new Date(Date.now() - 48 * 60 * 60 * 1000).toISOString())
        .order('created_at', { ascending: false })
        .limit(200),
      supabase
        .from('purchase_orders')
        .select('id, status, expected_delivery, total_value, created_at, suppliers(name), branches(name)')
        .order('expected_delivery', { ascending: true }),
      supabase
        .from('notifications')
        .select('id, type, title, body, is_read, created_at')
        .order('created_at', { ascending: false })
        .limit(8),
    ])
    if (branchRes.data) branches.value = branchRes.data
    if (eventRes.data) events.value = eventRes.data
    if (poRes.data) deliveries.value = poRes.data
    if (notifRes.data) alerts.value = notifRes.data
  } catch (err) {
    console.error('Error loading IoT dashboard:', err)
  } finally {
    loading.value = false
  }
}

// ---------- Live simulation ----------
// Generates real iot_events (RFID scans) so the dashboard updates in real time.
const rand = (arr) => arr[Math.floor(Math.random() * arr.length)]
async function emitScanBatch() {
  if (!branches.value.length || !products.value.length) return
  const n = 1 + Math.floor(Math.random() * 2)
  const rows = []
  for (let i = 0; i < n; i++) {
    const b = rand(branches.value.filter(x => x.is_active))
    const p = rand(products.value)
    const type = Math.random() < 0.55 ? 'stock_out' : (Math.random() < 0.6 ? 'stock_in' : 'stock_check')
    const anomaly = Math.random() < 0.08
    rows.push({
      branch_id: b.id,
      product_id: anomaly ? null : p.id,
      sku_scanned: anomaly ? `UNKNOWN-${Math.floor(Math.random() * 9000 + 1000)}` : (p.sku || 'NB-SKU'),
      event_type: anomaly ? 'unknown' : type,
      quantity: type === 'stock_in' ? 20 + Math.floor(Math.random() * 200) : 1 + Math.floor(Math.random() * 12),
      device_id: `RFID-${(b.name || 'NB').trim().slice(0, 2).toUpperCase()}-${1 + Math.floor(Math.random() * 2)}`,
      is_anomaly: anomaly,
      anomaly_reason: anomaly ? 'Unregistered SKU scanned by device' : null,
      processed: !anomaly,
    })
  }
  const { error } = await supabase.from('iot_events').insert(rows)
  if (error) { console.error('Sim insert error:', error); return }
  await loadAll()
}
async function toggleSim() {
  simulating.value = !simulating.value
  if (simulating.value) {
    if (!products.value.length) {
      const { data } = await supabase.from('products').select('id, sku').eq('is_active', true)
      products.value = data || []
    }
    await emitScanBatch()
    simTimer = setInterval(emitScanBatch, 4000)
  } else {
    clearInterval(simTimer); simTimer = null
  }
}
onBeforeUnmount(() => { if (simTimer) clearInterval(simTimer) })

onMounted(loadAll)
</script>
