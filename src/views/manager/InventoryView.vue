<template>
  <div class="h-full overflow-auto bg-transparent">
    <div class="p-8">
      <div class="flex items-center justify-between mb-6">
        <div>
          <h1 class="font-display text-3xl font-semibold text-ink tracking-tight">Inventory Management</h1>
          <p class="text-ink-muted text-sm mt-1">Stock levels for {{ branchName || 'your branch' }}</p>
        </div>
        <div class="flex gap-2">
          <button @click="refreshInventory" :disabled="loading" class="btn-secondary">
            <span v-if="loading" class="w-4 h-4 border-2 border-stone-300 border-t-brand-500 rounded-full animate-spin"></span>
            <AppIcon v-else name="refresh" :size="16" /> Refresh
          </button>
          <button @click="showScanner = true" class="btn-secondary">
            <AppIcon name="search" :size="16" /> Scan
          </button>
          <button @click="openAdd" class="btn-primary">
            <AppIcon name="plus" :size="16" :stroke-width="2.25" /> Add Item
          </button>
        </div>
      </div>

      <div v-if="scanMessage" class="mb-4 flex items-center gap-2 p-3 rounded-xl text-sm" :class="scanMessage.ok ? 'bg-emerald-50 text-emerald-700 border border-emerald-100' : 'bg-amber-50 text-amber-700 border border-amber-100'">
        <AppIcon :name="scanMessage.ok ? 'check-circle' : 'alert'" :size="16" /> {{ scanMessage.text }}
      </div>

      <!-- Stats -->
      <div class="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <div class="card p-5"><p class="text-sm text-ink-muted mb-1">In Stock</p><p class="text-2xl font-semibold text-emerald-600 tabular-nums">{{ inStockCount }}</p></div>
        <div class="card p-5"><p class="text-sm text-ink-muted mb-1">Low Stock</p><p class="text-2xl font-semibold text-amber-600 tabular-nums">{{ lowStockCount }}</p></div>
        <div class="card p-5"><p class="text-sm text-ink-muted mb-1">Out of Stock</p><p class="text-2xl font-semibold text-red-600 tabular-nums">{{ outOfStockCount }}</p></div>
        <div class="card p-5"><p class="text-sm text-ink-muted mb-1">Total Products</p><p class="text-2xl font-semibold text-ink tabular-nums">{{ inventory.length }}</p></div>
      </div>

      <!-- Filters -->
      <div class="card p-4 mb-6 flex gap-3">
        <input v-model="search" type="text" placeholder="Search products…" class="input flex-1" />
        <select v-model="filterStatus" class="input w-auto">
          <option value="">All Status</option>
          <option value="in_stock">In Stock</option>
          <option value="low_stock">Low Stock</option>
          <option value="out_of_stock">Out of Stock</option>
        </select>
      </div>

      <!-- Inventory table -->
      <div class="card overflow-hidden">
        <table class="w-full text-sm">
          <thead class="bg-stone-50/60 border-b border-stone-100">
            <tr class="text-left text-ink-muted">
              <th class="px-6 py-3 font-medium">Product</th>
              <th class="px-6 py-3 font-medium">Current Stock</th>
              <th class="px-6 py-3 font-medium">Reorder Level</th>
              <th class="px-6 py-3 font-medium">Status</th>
              <th class="px-6 py-3 font-medium">Last Updated</th>
              <th class="px-6 py-3 font-medium text-right">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-stone-50">
            <tr v-if="loading"><td colspan="6" class="px-6 py-10 text-center text-ink-muted">Loading…</td></tr>
            <tr v-else-if="filteredInventory.length === 0"><td colspan="6" class="px-6 py-10 text-center text-ink-muted">No inventory records found</td></tr>
            <tr v-for="item in filteredInventory" :key="item.product_id" class="hover:bg-stone-50/70">
              <td class="px-6 py-4 font-medium text-ink">{{ item.product_name }}</td>
              <td class="px-6 py-4">
                <span :class="item.quantity_on_hand <= 0 ? 'text-red-600 font-semibold' : 'text-ink-soft'" class="tabular-nums">{{ item.quantity_on_hand }} units</span>
              </td>
              <td class="px-6 py-4 text-ink-muted tabular-nums">{{ item.reorder_level }} units</td>
              <td class="px-6 py-4">
                <span :class="statusClass(item.status)" class="badge">
                  <AppIcon :name="item.status === 'in_stock' ? 'check' : item.status === 'low_stock' ? 'alert' : 'x'" :size="12" :stroke-width="2.25" />
                  {{ item.status === 'in_stock' ? 'In Stock' : item.status === 'low_stock' ? 'Low Stock' : 'Out of Stock' }}
                </span>
              </td>
              <td class="px-6 py-4 text-ink-muted text-xs">{{ formatDate(item.last_updated) }}</td>
              <td class="px-6 py-4">
                <div class="flex items-center justify-end gap-3">
                  <button @click="openRestock(item)" class="inline-flex items-center gap-1.5 text-brand-600 hover:text-brand-700 font-semibold text-xs"><AppIcon name="package" :size="14" /> Restock</button>
                  <button @click="openEdit(item)" class="inline-flex items-center gap-1.5 text-ink-soft hover:text-ink font-semibold text-xs"><AppIcon name="settings" :size="14" /> Edit</button>
                  <button @click="openDelete(item)" class="inline-flex items-center gap-1.5 text-red-600 hover:text-red-700 font-semibold text-xs"><AppIcon name="x" :size="14" /> Delete</button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Add item modal -->
    <div v-if="showAdd" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 px-4">
      <div class="card p-6 w-full max-w-sm">
        <h2 class="font-display text-xl font-semibold text-ink mb-4">Add Inventory Item</h2>
        <div v-if="availableProducts.length === 0" class="text-sm text-ink-muted mb-4">All products are already tracked for this branch.</div>
        <form v-else @submit.prevent="confirmAdd" class="space-y-4">
          <div>
            <label class="label">Product</label>
            <select v-model="addForm.product_id" required class="input">
              <option value="">Select a product</option>
              <option v-for="p in availableProducts" :key="p.id" :value="p.id">{{ p.name }}</option>
            </select>
          </div>
          <div class="grid grid-cols-2 gap-3">
            <div><label class="label">Opening stock</label><input v-model.number="addForm.quantity_on_hand" type="number" min="0" required class="input" /></div>
            <div><label class="label">Reorder level</label><input v-model.number="addForm.reorder_level" type="number" min="0" required class="input" /></div>
          </div>
          <div v-if="formError" class="p-3 bg-red-50 border border-red-100 rounded-xl text-red-600 text-sm">{{ formError }}</div>
          <div class="flex gap-3 pt-1">
            <button type="button" @click="showAdd = false" class="btn-secondary flex-1">Cancel</button>
            <button type="submit" :disabled="saving" class="btn-primary flex-1">{{ saving ? 'Adding…' : 'Add Item' }}</button>
          </div>
        </form>
        <button v-if="availableProducts.length === 0" @click="showAdd = false" class="btn-secondary w-full mt-2">Close</button>
      </div>
    </div>

    <!-- Edit modal -->
    <div v-if="showEdit" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 px-4">
      <div class="card p-6 w-full max-w-sm">
        <h2 class="font-display text-xl font-semibold text-ink mb-1">Edit: {{ editItem?.product_name }}</h2>
        <p class="text-xs text-ink-muted mb-4">Set the on-hand count and reorder threshold.</p>
        <form @submit.prevent="confirmEdit" class="space-y-4">
          <div class="grid grid-cols-2 gap-3">
            <div><label class="label">Quantity on hand</label><input v-model.number="editForm.quantity_on_hand" type="number" min="0" required class="input" /></div>
            <div><label class="label">Reorder level</label><input v-model.number="editForm.reorder_level" type="number" min="0" required class="input" /></div>
          </div>
          <div v-if="formError" class="p-3 bg-red-50 border border-red-100 rounded-xl text-red-600 text-sm">{{ formError }}</div>
          <div class="flex gap-3 pt-1">
            <button type="button" @click="showEdit = false" class="btn-secondary flex-1">Cancel</button>
            <button type="submit" :disabled="saving" class="btn-primary flex-1">{{ saving ? 'Saving…' : 'Save' }}</button>
          </div>
        </form>
      </div>
    </div>

    <!-- Restock modal -->
    <div v-if="showRestock" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 px-4">
      <div class="card p-6 w-full max-w-sm">
        <h2 class="font-display text-xl font-semibold text-ink mb-4">Restock: {{ restockItem?.product_name }}</h2>
        <p class="text-sm text-ink-muted mb-4">Current stock: <span class="font-semibold text-brand-600">{{ restockItem?.quantity_on_hand }} units</span></p>
        <label class="label">Quantity to add</label>
        <input v-model.number="restockQuantity" type="number" min="1" class="input" />
        <div class="mt-3 p-3 bg-stone-50 rounded-xl text-xs text-ink-soft">New stock: <span class="font-semibold">{{ (restockItem?.quantity_on_hand || 0) + (restockQuantity || 0) }} units</span></div>
        <div v-if="formError" class="mt-3 p-3 bg-red-50 border border-red-100 rounded-xl text-red-600 text-sm">{{ formError }}</div>
        <div class="flex gap-3 mt-4">
          <button @click="showRestock = false" class="btn-secondary flex-1">Cancel</button>
          <button @click="confirmRestock" :disabled="saving" class="btn-primary flex-1">{{ saving ? 'Restocking…' : 'Confirm' }}</button>
        </div>
      </div>
    </div>

    <!-- Delete confirm -->
    <div v-if="showDelete" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 px-4">
      <div class="card p-6 w-full max-w-sm">
        <h2 class="font-display text-xl font-semibold text-ink mb-2">Remove item?</h2>
        <p class="text-ink-soft text-sm mb-6">Remove <span class="font-semibold">{{ deleteItem?.product_name }}</span> from this branch's inventory? This does not delete the product itself.</p>
        <div v-if="formError" class="mb-3 p-3 bg-red-50 border border-red-100 rounded-xl text-red-600 text-sm">{{ formError }}</div>
        <div class="flex gap-3">
          <button @click="showDelete = false" class="btn-secondary flex-1">Cancel</button>
          <button @click="confirmDelete" :disabled="saving" class="btn flex-1 bg-red-600 text-white hover:bg-red-700 px-4 py-2.5">{{ saving ? 'Removing…' : 'Remove' }}</button>
        </div>
      </div>
    </div>

    <!-- Barcode scanner -->
    <BarcodeScanner v-if="showScanner" @scanned="onScanned" @close="showScanner = false" />
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useAuthStore } from '../../stores/auth'
import { supabase } from '../../lib/supabase'
import AppIcon from '../../components/AppIcon.vue'
import BarcodeScanner from '../../components/BarcodeScanner.vue'
import { useToast } from '../../composables/useToast'

const toast = useToast()
const auth = useAuthStore()
const inventory = ref([])
const products = ref([])
const branchName = ref('')
const loading = ref(true)
const search = ref('')
const filterStatus = ref('')
const saving = ref(false)
const formError = ref('')
const showScanner = ref(false)
const scanMessage = ref(null)

const showAdd = ref(false)
const showEdit = ref(false)
const showRestock = ref(false)
const showDelete = ref(false)
const editItem = ref(null)
const restockItem = ref(null)
const deleteItem = ref(null)
const restockQuantity = ref(0)
const addForm = ref({ product_id: '', quantity_on_hand: 0, reorder_level: 10 })
const editForm = ref({ quantity_on_hand: 0, reorder_level: 0 })

const filteredInventory = computed(() =>
  inventory.value.filter(item => {
    const matchSearch = !search.value || item.product_name.toLowerCase().includes(search.value.toLowerCase())
    const matchStatus = !filterStatus.value || item.status === filterStatus.value
    return matchSearch && matchStatus
  })
)
const inStockCount = computed(() => inventory.value.filter(i => i.status === 'in_stock').length)
const lowStockCount = computed(() => inventory.value.filter(i => i.status === 'low_stock').length)
const outOfStockCount = computed(() => inventory.value.filter(i => i.status === 'out_of_stock').length)

const availableProducts = computed(() => {
  const tracked = new Set(inventory.value.map(i => i.product_id))
  return products.value.filter(p => !tracked.has(p.id))
})

function statusClass(status) {
  return {
    in_stock: 'bg-emerald-50 text-emerald-700',
    low_stock: 'bg-amber-50 text-amber-700',
    out_of_stock: 'bg-red-50 text-red-700',
  }[status] || 'bg-stone-100 text-stone-600'
}
function formatDate(d) {
  return d ? new Date(d).toLocaleString('en-ZA', { dateStyle: 'short', timeStyle: 'short' }) : '—'
}

async function refreshInventory() {
  loading.value = true
  try {
    const { data, error } = await supabase.rpc('get_branch_inventory', { p_branch_id: auth.branchId })
    if (error) throw error
    inventory.value = data || []
  } catch (err) {
    console.error('Error loading inventory:', err.message)
  } finally {
    loading.value = false
  }
}

async function loadProducts() {
  const { data } = await supabase.from('products').select('id, name, sku').eq('is_active', true).order('name')
  if (data) products.value = data
}

// ---- Barcode scan → find product, then restock or add ----
function onScanned(code) {
  showScanner.value = false
  const q = String(code).trim().toLowerCase()
  const product = products.value.find(p =>
    (p.sku && p.sku.toLowerCase() === q) || p.name.toLowerCase() === q || p.id === code
  )
  if (!product) {
    scanMessage.value = { ok: false, text: `No product matches "${code}". Add it under Products first.` }
    return
  }
  const tracked = inventory.value.find(i => i.product_id === product.id)
  if (tracked) {
    scanMessage.value = { ok: true, text: `${product.name} found — restocking.` }
    openRestock(tracked)
  } else {
    scanMessage.value = { ok: true, text: `${product.name} found — add it to this branch.` }
    openAdd()
    addForm.value.product_id = product.id
  }
}

// ---- Create ----
function openAdd() {
  formError.value = ''
  addForm.value = { product_id: '', quantity_on_hand: 0, reorder_level: 10 }
  showAdd.value = true
}
async function confirmAdd() {
  saving.value = true; formError.value = ''
  try {
    const { error } = await supabase.from('inventory').insert({
      branch_id: auth.branchId,
      product_id: addForm.value.product_id,
      quantity_on_hand: addForm.value.quantity_on_hand,
      reorder_threshold: addForm.value.reorder_level,
    })
    if (error) throw error
    showAdd.value = false
    await refreshInventory()
    toast.success('Item added to inventory')
  } catch (err) { formError.value = err.message; toast.error(err.message) } finally { saving.value = false }
}

// ---- Update ----
function openEdit(item) {
  formError.value = ''
  editItem.value = item
  editForm.value = { quantity_on_hand: item.quantity_on_hand, reorder_level: item.reorder_level }
  showEdit.value = true
}
async function confirmEdit() {
  saving.value = true; formError.value = ''
  try {
    const { error } = await supabase.from('inventory')
      .update({ quantity_on_hand: editForm.value.quantity_on_hand, reorder_threshold: editForm.value.reorder_level, updated_at: new Date().toISOString() })
      .eq('branch_id', auth.branchId).eq('product_id', editItem.value.product_id)
    if (error) throw error
    showEdit.value = false
    await refreshInventory()
    toast.success('Inventory updated')
  } catch (err) { formError.value = err.message; toast.error(err.message) } finally { saving.value = false }
}

// ---- Restock (logs history via RPC) ----
function openRestock(item) {
  formError.value = ''
  restockItem.value = item
  restockQuantity.value = 0
  showRestock.value = true
}
async function confirmRestock() {
  if (!restockQuantity.value || restockQuantity.value <= 0) { formError.value = 'Enter a valid quantity'; return }
  saving.value = true; formError.value = ''
  try {
    const { error } = await supabase.rpc('restock_inventory', {
      p_product_id: restockItem.value.product_id,
      p_branch_id: auth.branchId,
      p_quantity: restockQuantity.value,
    })
    if (error) throw error
    showRestock.value = false
    await refreshInventory()
    toast.success(`Restocked +${restockQuantity.value} units`)
  } catch (err) { formError.value = err.message; toast.error(err.message) } finally { saving.value = false }
}

// ---- Delete ----
function openDelete(item) {
  formError.value = ''
  deleteItem.value = item
  showDelete.value = true
}
async function confirmDelete() {
  saving.value = true; formError.value = ''
  try {
    const { error } = await supabase.from('inventory').delete()
      .eq('branch_id', auth.branchId).eq('product_id', deleteItem.value.product_id)
    if (error) throw error
    showDelete.value = false
    await refreshInventory()
    toast.success('Item removed')
  } catch (err) { formError.value = err.message; toast.error(err.message) } finally { saving.value = false }
}

onMounted(async () => {
  if (auth.branchId) {
    const { data } = await supabase.from('branches').select('name').eq('id', auth.branchId).single()
    if (data) branchName.value = data.name.trim()
  }
  await Promise.all([refreshInventory(), loadProducts()])
})
</script>
