<template>
  <div class="p-8">
    <div class="flex items-center justify-between mb-6">
      <div>
        <h1 class="font-display text-3xl font-semibold text-ink tracking-tight">Products</h1>
        <p class="text-ink-muted text-sm mt-1">Global product catalogue</p>
      </div>
      <button @click="showModal = true" class="btn-primary">
        <AppIcon name="plus" :size="16" :stroke-width="2.25" /> Add Product
      </button>
    </div>
    <div class="card overflow-hidden">
      <div class="p-4 border-b border-stone-100 flex gap-3">
        <input v-model="search" type="text" placeholder="Search products..." class="input flex-1" />
        <select v-model="filterCat" class="input w-auto">
          <option value="">All categories</option>
          <option v-for="c in ['bread','roll','pastry','cake','beverage','other']" :key="c" :value="c" class="capitalize">{{ c }}</option>
        </select>
      </div>
      <table class="w-full text-sm">
        <thead>
          <tr class="text-left text-ink-muted border-b border-stone-100 bg-stone-50/60">
            <th class="px-4 py-3 font-medium cursor-pointer select-none" @click="toggleSort('name')">
              <span class="inline-flex items-center gap-1">Name <AppIcon :name="sortIcon('name')" :size="13" class="text-stone-400" /></span>
            </th>
            <th class="px-4 py-3 font-medium">Category</th>
            <th class="px-4 py-3 font-medium cursor-pointer select-none" @click="toggleSort('unit_price')">
              <span class="inline-flex items-center gap-1">Price <AppIcon :name="sortIcon('unit_price')" :size="13" class="text-stone-400" /></span>
            </th>
            <th class="px-4 py-3 font-medium">SKU</th>
            <th class="px-4 py-3 font-medium">Status</th>
            <th class="px-4 py-3 font-medium">Actions</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-stone-50">
          <tr v-if="loading"><td colspan="6" class="px-4 py-8 text-center text-ink-muted">Loading…</td></tr>
          <tr v-else-if="filtered.length === 0"><td colspan="6" class="px-4 py-8 text-center text-ink-muted">No products found.</td></tr>
          <tr v-for="p in filtered" :key="p.id" class="hover:bg-stone-50/70">
            <td class="px-4 py-3 font-medium text-ink">{{ p.name }}</td>
            <td class="px-4 py-3 capitalize text-ink-soft">{{ p.category }}</td>
            <td class="px-4 py-3 font-semibold text-ink tabular-nums">R{{ parseFloat(p.unit_price).toFixed(2) }}</td>
            <td class="px-4 py-3 font-mono text-xs text-ink-muted">{{ p.sku || '—' }}</td>
            <td class="px-4 py-3">
              <span :class="p.is_active ? 'badge-success' : 'badge-neutral'">
                {{ p.is_active ? 'Active' : 'Inactive' }}
              </span>
            </td>
            <td class="px-4 py-3">
              <div class="flex gap-3">
                <button @click="editProduct(p)" class="text-xs text-brand-600 hover:text-brand-700 font-semibold">Edit</button>
                <button @click="deleteProduct(p)" class="text-xs text-red-600 hover:text-red-700 font-semibold">Delete</button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <div v-if="showModal" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 px-4">
      <div class="bg-white rounded-2xl p-6 w-full max-w-md">
        <h2 class="text-lg font-bold text-nibbles-dark mb-4">{{ editingId ? 'Edit Product' : 'Add Product' }}</h2>
        <form @submit.prevent="saveProduct" class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Product name</label>
            <input v-model="form.name" type="text" required placeholder="e.g. White Bread Loaf 700g" class="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-nibbles-red" />
          </div>
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Category</label>
              <select v-model="form.category" required class="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-nibbles-red">
                <option value="">Select</option>
                <option v-for="c in ['bread','roll','pastry','cake','beverage','other']" :key="c" :value="c" class="capitalize">{{ c }}</option>
              </select>
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Price (R)</label>
              <input v-model.number="form.unit_price" type="number" step="0.01" min="0.01" required placeholder="0.00" class="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-nibbles-red" />
            </div>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">SKU / Barcode <span class="text-gray-400 font-normal">(optional)</span></label>
            <input v-model="form.sku" type="text" placeholder="e.g. NB-BRD-001" class="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-nibbles-red" />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Description <span class="text-gray-400 font-normal">(optional)</span></label>
            <textarea v-model="form.description" rows="2" placeholder="Short product description" class="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-nibbles-red resize-none"></textarea>
          </div>
          <div>
            <label class="flex items-center">
              <input v-model="form.is_active" type="checkbox" class="w-4 h-4 text-nibbles-red rounded focus:ring-nibbles-red" />
              <span class="ml-2 text-sm text-gray-700">Active</span>
            </label>
          </div>
          <div v-if="formError" class="p-3 bg-red-50 border border-red-200 rounded-lg text-red-600 text-sm">{{ formError }}</div>
          <div class="flex gap-3 pt-2">
            <button type="button" @click="closeModal" class="flex-1 px-4 py-2 border border-gray-200 rounded-lg text-sm text-gray-600 hover:bg-gray-50">Cancel</button>
            <button type="submit" :disabled="saving" class="flex-1 bg-nibbles-red text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-nibbles-red-dark disabled:opacity-60">
              {{ saving ? 'Saving...' : editingId ? 'Update' : 'Add' }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- Delete confirmation modal -->
    <div v-if="showDeleteConfirm" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 px-4">
      <div class="bg-white rounded-2xl p-6 w-full max-w-sm">
        <h2 class="text-lg font-bold text-nibbles-dark mb-2">Delete Product?</h2>
        <p class="text-gray-600 mb-6">Are you sure you want to delete <span class="font-semibold">{{ deleteItem?.name }}</span>? This cannot be undone.</p>
        <div class="flex gap-3">
          <button @click="showDeleteConfirm = false" class="flex-1 px-4 py-2 border border-gray-200 rounded-lg text-sm text-gray-600 hover:bg-gray-50">
            Cancel
          </button>
          <button @click="confirmDelete" :disabled="deleting" class="flex-1 bg-red-600 text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-red-700 disabled:opacity-60">
            {{ deleting ? 'Deleting...' : 'Delete' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../../lib/supabase'
import { useToast } from '../../composables/useToast'
import AppIcon from '../../components/AppIcon.vue'

const toast = useToast()
const products = ref([])
const loading = ref(true)
const search = ref('')
const filterCat = ref('')
const showModal = ref(false)
const showDeleteConfirm = ref(false)
const saving = ref(false)
const deleting = ref(false)
const formError = ref('')
const sortCol = ref('name')
const sortDir = ref('asc')
const editingId = ref(null)
const deleteItem = ref(null)
const form = ref({ name: '', category: '', unit_price: '', sku: '', description: '', is_active: true })

const filtered = computed(() => {
  let list = products.value.filter(p => {
    const matchSearch = !search.value || p.name.toLowerCase().includes(search.value.toLowerCase())
    const matchCat = !filterCat.value || p.category === filterCat.value
    return matchSearch && matchCat
  })
  list = [...list].sort((a, b) => {
    const av = a[sortCol.value]; const bv = b[sortCol.value]
    if (av < bv) return sortDir.value === 'asc' ? -1 : 1
    if (av > bv) return sortDir.value === 'asc' ? 1 : -1
    return 0
  })
  return list
})

function toggleSort(col) {
  if (sortCol.value === col) sortDir.value = sortDir.value === 'asc' ? 'desc' : 'asc'
  else { sortCol.value = col; sortDir.value = 'asc' }
}
function sortIcon(col) { return sortCol.value === col ? (sortDir.value === 'asc' ? 'chevron-up' : 'chevron-down') : 'arrow-up-down' }

async function load() {
  loading.value = true
  const { data } = await supabase.from('products').select('*').order('name')
  if (data) products.value = data
  loading.value = false
}

async function createProduct() {
  saving.value = true; formError.value = ''
  const { error } = await supabase.from('products').insert({ ...form.value, sku: form.value.sku || null })
  if (error) { formError.value = error.message } else { closeModal(); await load() }
  saving.value = false
}

async function saveProduct() {
  saving.value = true; formError.value = ''
  try {
    if (editingId.value) {
      const { error } = await supabase.from('products').update({
        name: form.value.name,
        category: form.value.category,
        unit_price: form.value.unit_price,
        sku: form.value.sku || null,
        description: form.value.description || null,
        is_active: form.value.is_active
      }).eq('id', editingId.value)
      if (error) throw error
    } else {
      const { error } = await supabase.from('products').insert({
        name: form.value.name,
        category: form.value.category,
        unit_price: form.value.unit_price,
        sku: form.value.sku || null,
        description: form.value.description || null,
        is_active: form.value.is_active
      })
      if (error) throw error
    }
    closeModal()
    await load()
    toast.success(editingId.value ? 'Product updated' : 'Product added')
  } catch (err) {
    formError.value = err.message
    toast.error(err.message)
  } finally {
    saving.value = false
  }
}

function editProduct(p) {
  editingId.value = p.id
  form.value = {
    name: p.name,
    category: p.category,
    unit_price: p.unit_price,
    sku: p.sku || '',
    description: p.description || '',
    is_active: p.is_active
  }
  showModal.value = true
}

function deleteProduct(p) {
  deleteItem.value = p
  showDeleteConfirm.value = true
}

async function confirmDelete() {
  if (!deleteItem.value) return
  deleting.value = true
  try {
    const { error } = await supabase.from('products').delete().eq('id', deleteItem.value.id)
    if (error) throw error
    showDeleteConfirm.value = false
    deleteItem.value = null
    await load()
    toast.success('Product deleted')
  } catch (err) {
    toast.error(err.message)
  } finally {
    deleting.value = false
  }
}

async function toggleProduct(p) {
  await supabase.from('products').update({ is_active: !p.is_active }).eq('id', p.id)
  p.is_active = !p.is_active
}

function closeModal() {
  showModal.value = false
  editingId.value = null
  formError.value = ''
  form.value = { name: '', category: '', unit_price: '', sku: '', description: '', is_active: true }
}

onMounted(load)
</script>
