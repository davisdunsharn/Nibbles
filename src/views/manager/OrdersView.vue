<template>
  <div class="h-full overflow-auto bg-transparent">
    <div class="p-8">
      <div class="flex items-center justify-between mb-6">
        <div>
          <h1 class="font-display text-3xl font-semibold text-ink tracking-tight">Purchase Orders</h1>
          <p class="text-ink-muted text-sm mt-1">Restock orders for {{ branchName || 'your branch' }}</p>
        </div>
        <button @click="openCreate" class="btn-primary">
          <AppIcon name="plus" :size="16" :stroke-width="2.25" /> New Order
        </button>
      </div>

      <!-- Filters -->
      <div class="card p-4 mb-6 flex gap-3">
        <input v-model="search" type="text" placeholder="Search supplier or notes…" class="input flex-1" />
        <select v-model="filterStatus" class="input w-auto">
          <option value="">All statuses</option>
          <option v-for="s in STATUSES" :key="s" :value="s">{{ label(s) }}</option>
        </select>
      </div>

      <!-- Orders table -->
      <div class="card overflow-hidden">
        <table class="w-full text-sm">
          <thead class="bg-stone-50/60 border-b border-stone-100">
            <tr class="text-left text-ink-muted">
              <th class="px-6 py-3 font-medium">Order</th>
              <th class="px-6 py-3 font-medium">Supplier</th>
              <th class="px-6 py-3 font-medium">Items</th>
              <th class="px-6 py-3 font-medium">Total</th>
              <th class="px-6 py-3 font-medium">Expected</th>
              <th class="px-6 py-3 font-medium">Status</th>
              <th class="px-6 py-3 font-medium text-right">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-stone-50">
            <tr v-if="loading"><td colspan="7" class="px-6 py-10 text-center text-ink-muted">Loading…</td></tr>
            <tr v-else-if="filteredOrders.length === 0"><td colspan="7" class="px-6 py-10 text-center text-ink-muted">No purchase orders yet.</td></tr>
            <tr v-for="o in filteredOrders" :key="o.id" class="hover:bg-stone-50/70">
              <td class="px-6 py-4 font-mono text-xs text-ink-muted">#{{ o.id.slice(0, 8) }}</td>
              <td class="px-6 py-4 text-ink">{{ o.suppliers?.name || '—' }}</td>
              <td class="px-6 py-4 text-ink-soft tabular-nums">{{ o.purchase_order_lines?.length || 0 }}</td>
              <td class="px-6 py-4 font-semibold text-ink tabular-nums">{{ money(o.total_value) }}</td>
              <td class="px-6 py-4 text-ink-muted">{{ o.expected_delivery ? date(o.expected_delivery) : '—' }}</td>
              <td class="px-6 py-4"><span :class="statusBadge(o.status)" class="capitalize">{{ label(o.status) }}</span></td>
              <td class="px-6 py-4">
                <div class="flex items-center justify-end gap-3">
                  <button @click="openView(o)" class="text-ink-soft hover:text-ink font-semibold text-xs">View</button>
                  <button v-if="nextStatus(o.status)" @click="advance(o)" class="text-brand-600 hover:text-brand-700 font-semibold text-xs">{{ nextStatusLabel(o.status) }}</button>
                  <button v-if="canReceive(o.status)" @click="receive(o)" class="text-emerald-600 hover:text-emerald-700 font-semibold text-xs">Receive</button>
                  <button v-if="!isFinal(o.status)" @click="cancel(o)" class="text-red-600 hover:text-red-700 font-semibold text-xs">Cancel</button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Create modal -->
    <div v-if="showCreate" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 px-4 py-8 overflow-y-auto">
      <div class="card p-6 w-full max-w-2xl">
        <h2 class="font-display text-xl font-semibold text-ink mb-4">New Purchase Order</h2>
        <form @submit.prevent="confirmCreate" class="space-y-4">
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label class="label">Supplier</label>
              <select v-model="form.supplier_id" required class="input">
                <option value="">Select supplier</option>
                <option v-for="s in suppliers" :key="s.id" :value="s.id">{{ s.name }}</option>
              </select>
            </div>
            <div>
              <label class="label">Expected delivery</label>
              <input v-model="form.expected_delivery" type="date" class="input" />
            </div>
          </div>

          <div>
            <label class="label">Order items</label>
            <div class="space-y-2">
              <div v-for="(line, i) in form.lines" :key="i" class="flex gap-2 items-start">
                <select v-model="line.product_id" required class="input flex-1">
                  <option value="">Product</option>
                  <option v-for="p in products" :key="p.id" :value="p.id">{{ p.name }}</option>
                </select>
                <input v-model.number="line.quantity_ordered" type="number" min="1" required placeholder="Qty" class="input w-24" />
                <input v-model.number="line.unit_cost" type="number" min="0" step="0.01" required placeholder="Unit R" class="input w-28" />
                <span class="w-24 pt-2.5 text-sm text-ink-soft tabular-nums text-right">{{ money(lineTotal(line)) }}</span>
                <button type="button" @click="removeLine(i)" class="pt-2.5 text-stone-400 hover:text-red-500" :disabled="form.lines.length === 1">
                  <AppIcon name="x" :size="16" />
                </button>
              </div>
            </div>
            <button type="button" @click="addLine" class="mt-2 inline-flex items-center gap-1.5 text-brand-600 hover:text-brand-700 text-sm font-medium">
              <AppIcon name="plus" :size="14" :stroke-width="2.25" /> Add item
            </button>
          </div>

          <div>
            <label class="label">Notes <span class="text-stone-400 font-normal">(optional)</span></label>
            <input v-model="form.notes" type="text" placeholder="e.g. weekly flour restock" class="input" />
          </div>

          <div class="flex items-center justify-between border-t border-stone-100 pt-4">
            <p class="text-sm text-ink-muted">Total: <span class="font-semibold text-ink text-base tabular-nums">{{ money(orderTotal) }}</span></p>
            <div class="flex gap-3">
              <button type="button" @click="showCreate = false" class="btn-secondary">Cancel</button>
              <button type="submit" :disabled="saving" class="btn-primary">{{ saving ? 'Creating…' : 'Create Order' }}</button>
            </div>
          </div>
          <div v-if="formError" class="p-3 bg-red-50 border border-red-100 rounded-xl text-red-600 text-sm">{{ formError }}</div>
        </form>
      </div>
    </div>

    <!-- View modal -->
    <div v-if="showView" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 px-4 py-8 overflow-y-auto">
      <div class="card p-6 w-full max-w-lg">
        <div class="flex items-start justify-between mb-4">
          <div>
            <h2 class="font-display text-xl font-semibold text-ink">Order #{{ viewOrder?.id.slice(0, 8) }}</h2>
            <p class="text-sm text-ink-muted mt-0.5">{{ viewOrder?.suppliers?.name }} · <span :class="statusBadge(viewOrder?.status)" class="capitalize">{{ label(viewOrder?.status) }}</span></p>
          </div>
          <button @click="showView = false" class="text-stone-400 hover:text-ink"><AppIcon name="x" :size="20" /></button>
        </div>
        <div class="space-y-2 mb-4">
          <div v-for="l in viewOrder?.purchase_order_lines || []" :key="l.id" class="flex justify-between text-sm p-3 bg-stone-50 rounded-xl">
            <span class="text-ink">{{ productName(l.product_id) }} <span class="text-ink-muted">× {{ l.quantity_ordered }}</span></span>
            <span class="font-medium text-ink tabular-nums">{{ money(l.line_total) }}</span>
          </div>
          <div v-if="!viewOrder?.purchase_order_lines?.length" class="text-sm text-ink-muted">No line items recorded.</div>
        </div>
        <div class="flex justify-between border-t border-stone-100 pt-3 text-sm">
          <span class="text-ink-muted">Expected: {{ viewOrder?.expected_delivery ? date(viewOrder.expected_delivery) : '—' }}</span>
          <span class="font-semibold text-ink">Total {{ money(viewOrder?.total_value) }}</span>
        </div>
        <p v-if="viewOrder?.notes" class="text-xs text-ink-muted mt-3">{{ viewOrder.notes }}</p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useAuthStore } from '../../stores/auth'
import { supabase } from '../../lib/supabase'
import AppIcon from '../../components/AppIcon.vue'
import { useToast } from '../../composables/useToast'

const toast = useToast()
const auth = useAuthStore()
const STATUSES = ['pending', 'sent', 'confirmed', 'partially_received', 'received', 'cancelled']

const orders = ref([])
const suppliers = ref([])
const products = ref([])
const branchName = ref('')
const loading = ref(true)
const saving = ref(false)
const search = ref('')
const filterStatus = ref('')
const formError = ref('')

const showCreate = ref(false)
const showView = ref(false)
const viewOrder = ref(null)
const form = ref({ supplier_id: '', expected_delivery: '', notes: '', lines: [{ product_id: '', quantity_ordered: 1, unit_cost: 0 }] })

const money = (v) => `R${parseFloat(v || 0).toLocaleString('en-ZA', { minimumFractionDigits: 2 })}`
const date = (v) => new Date(v).toLocaleDateString('en-ZA')
const label = (s) => (s || '').replace(/_/g, ' ')
const productName = (id) => products.value.find(p => p.id === id)?.name || '—'
const lineTotal = (l) => (l.quantity_ordered || 0) * (l.unit_cost || 0)
const orderTotal = computed(() => form.value.lines.reduce((s, l) => s + lineTotal(l), 0))

const filteredOrders = computed(() =>
  orders.value.filter(o => {
    const hay = `${o.suppliers?.name || ''} ${o.notes || ''}`.toLowerCase()
    const matchSearch = !search.value || hay.includes(search.value.toLowerCase())
    const matchStatus = !filterStatus.value || o.status === filterStatus.value
    return matchSearch && matchStatus
  })
)

function statusBadge(s) {
  if (s === 'received') return 'badge-success'
  if (s === 'cancelled') return 'badge-neutral'
  if (s === 'pending') return 'badge-warning'
  if (s === 'partially_received') return 'badge bg-amber-50 text-amber-700'
  return 'badge bg-sky-50 text-sky-700'
}
const FLOW = { pending: 'sent', sent: 'confirmed' }
const isFinal = (s) => s === 'received' || s === 'cancelled'
const nextStatus = (s) => FLOW[s] || null
const nextStatusLabel = (s) => ({ pending: 'Send', sent: 'Confirm' }[s] || '')
const canReceive = (s) => ['pending', 'sent', 'confirmed', 'partially_received'].includes(s)

function addLine() { form.value.lines.push({ product_id: '', quantity_ordered: 1, unit_cost: 0 }) }
function removeLine(i) { if (form.value.lines.length > 1) form.value.lines.splice(i, 1) }

function openCreate() {
  formError.value = ''
  form.value = { supplier_id: '', expected_delivery: '', notes: '', lines: [{ product_id: '', quantity_ordered: 1, unit_cost: 0 }] }
  showCreate.value = true
}
function openView(o) { viewOrder.value = o; showView.value = true }

async function load() {
  loading.value = true
  try {
    const { data } = await supabase
      .from('purchase_orders')
      .select('id, status, expected_delivery, notes, total_value, created_at, suppliers(name), purchase_order_lines(id, product_id, quantity_ordered, unit_cost, line_total)')
      .eq('branch_id', auth.branchId)
      .order('created_at', { ascending: false })
    orders.value = data || []
  } catch (err) {
    console.error('Error loading orders:', err)
  } finally {
    loading.value = false
  }
}

async function confirmCreate() {
  saving.value = true; formError.value = ''
  try {
    const { data: po, error } = await supabase.from('purchase_orders').insert({
      branch_id: auth.branchId,
      supplier_id: form.value.supplier_id,
      raised_by: auth.user.id,
      status: 'pending',
      is_auto_generated: false,
      expected_delivery: form.value.expected_delivery || null,
      notes: form.value.notes || null,
      total_value: orderTotal.value,
    }).select().single()
    if (error) throw error

    const lines = form.value.lines
      .filter(l => l.product_id)
      .map(l => ({
        purchase_order_id: po.id,
        product_id: l.product_id,
        quantity_ordered: l.quantity_ordered,
        quantity_received: 0,
        unit_cost: l.unit_cost,
        line_total: lineTotal(l),
      }))
    if (lines.length) {
      const { error: lineErr } = await supabase.from('purchase_order_lines').insert(lines)
      if (lineErr) throw lineErr
    }
    showCreate.value = false
    await load()
    toast.success('Purchase order created')
  } catch (err) { formError.value = err.message; toast.error(err.message) } finally { saving.value = false }
}

async function setStatus(o, status) {
  const { error } = await supabase.from('purchase_orders').update({ status, updated_at: new Date().toISOString() }).eq('id', o.id)
  if (error) { console.error(error); return false }
  return true
}
async function advance(o) { if (await setStatus(o, nextStatus(o.status))) { await load(); toast.success(`Order marked ${label(nextStatus(o.status))}`) } }
async function cancel(o) { if (confirm('Cancel this order?') && await setStatus(o, 'cancelled')) { await load(); toast.success('Order cancelled') } }

async function receive(o) {
  // mark received and restock inventory for each ordered line
  try {
    for (const l of o.purchase_order_lines || []) {
      await supabase.rpc('restock_inventory', { p_product_id: l.product_id, p_branch_id: auth.branchId, p_quantity: l.quantity_ordered })
      await supabase.from('purchase_order_lines').update({ quantity_received: l.quantity_ordered, received_at: new Date().toISOString() }).eq('id', l.id)
    }
    await setStatus(o, 'received')
    await load()
    toast.success('Order received — inventory restocked')
  } catch (err) { console.error('Receive error:', err); toast.error('Could not fully receive order') }
}

onMounted(async () => {
  if (auth.branchId) {
    const { data } = await supabase.from('branches').select('name').eq('id', auth.branchId).single()
    if (data) branchName.value = data.name.trim()
  }
  const [{ data: sup }, { data: prod }] = await Promise.all([
    supabase.from('suppliers').select('id, name').eq('is_active', true).order('name'),
    supabase.from('products').select('id, name').eq('is_active', true).order('name'),
  ])
  suppliers.value = sup || []
  products.value = prod || []
  await load()
})
</script>
