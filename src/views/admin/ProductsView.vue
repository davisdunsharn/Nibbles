<template>
  <div class="p-6">
    <div class="flex items-center justify-between mb-6">
      <div>
        <h1 class="text-2xl font-bold text-nibbles-dark">Products</h1>
        <p class="text-gray-500 text-sm mt-1">Global product catalogue</p>
      </div>
      <button @click="showModal = true" class="bg-nibbles-red text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-nibbles-red-dark transition-colors">
        + Add Product
      </button>
    </div>
    <div class="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
      <div class="p-4 border-b border-gray-100 flex gap-3">
        <input v-model="search" type="text" placeholder="Search products..." class="flex-1 px-4 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-nibbles-red" />
        <select v-model="filterCat" class="px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-nibbles-red">
          <option value="">All categories</option>
          <option v-for="c in ['bread','roll','pastry','cake','beverage','other']" :key="c" :value="c" class="capitalize">{{ c }}</option>
        </select>
      </div>
      <table class="w-full text-sm">
        <thead>
          <tr class="text-left text-gray-400 border-b border-gray-100 bg-gray-50">
            <th class="px-4 py-3 font-medium cursor-pointer" @click="toggleSort('name')">Name {{ sortIcon('name') }}</th>
            <th class="px-4 py-3 font-medium">Category</th>
            <th class="px-4 py-3 font-medium cursor-pointer" @click="toggleSort('unit_price')">Price {{ sortIcon('unit_price') }}</th>
            <th class="px-4 py-3 font-medium">SKU</th>
            <th class="px-4 py-3 font-medium">Status</th>
            <th class="px-4 py-3 font-medium">Actions</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-50">
          <tr v-if="loading"><td colspan="6" class="px-4 py-8 text-center text-gray-400">Loading...</td></tr>
          <tr v-else-if="filtered.length === 0"><td colspan="6" class="px-4 py-8 text-center text-gray-400">No products found.</td></tr>
          <tr v-for="p in filtered" :key="p.id" class="hover:bg-gray-50">
            <td class="px-4 py-3 font-medium text-gray-800">{{ p.name }}</td>
            <td class="px-4 py-3 capitalize text-gray-500">{{ p.category }}</td>
            <td class="px-4 py-3 font-semibold text-nibbles-dark">R{{ parseFloat(p.unit_price).toFixed(2) }}</td>
            <td class="px-4 py-3 font-mono text-xs text-gray-400">{{ p.sku || '—' }}</td>
            <td class="px-4 py-3">
              <span :class="p.is_active ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'" class="px-2 py-0.5 rounded text-xs font-medium">
                {{ p.is_active ? 'Active' : 'Inactive' }}
              </span>
            </td>
            <td class="px-4 py-3">
              <button @click="toggleProduct(p)" class="text-xs text-gray-400 hover:text-nibbles-red transition-colors">
                {{ p.is_active ? 'Deactivate' : 'Activate' }}
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <div v-if="showModal" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 px-4">
      <div class="bg-white rounded-2xl p-6 w-full max-w-md">
        <h2 class="text-lg font-bold text-nibbles-dark mb-4">Add Product</h2>
        <form @submit.prevent="createProduct" class="space-y-4">
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
          <div v-if="formError" class="p-3 bg-red-50 border border-red-200 rounded-lg text-red-600 text-sm">{{ formError }}</div>
          <div class="flex gap-3 pt-2">
            <button type="button" @click="closeModal" class="flex-1 px-4 py-2 border border-gray-200 rounded-lg text-sm text-gray-600 hover:bg-gray-50">Cancel</button>
            <button type="submit" :disabled="saving" class="flex-1 bg-nibbles-red text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-nibbles-red-dark disabled:opacity-60">
              {{ saving ? 'Saving...' : 'Add Product' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../../lib/supabase'

const products = ref([])
const loading = ref(true)
const search = ref('')
const filterCat = ref('')
const showModal = ref(false)
const saving = ref(false)
const formError = ref('')
const sortCol = ref('name')
const sortDir = ref('asc')
const form = ref({ name: '', category: '', unit_price: '', sku: '', description: '' })

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
function sortIcon(col) { return sortCol.value === col ? (sortDir.value === 'asc' ? '↑' : '↓') : '↕' }

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

async function toggleProduct(p) {
  await supabase.from('products').update({ is_active: !p.is_active }).eq('id', p.id)
  p.is_active = !p.is_active
}

function closeModal() {
  showModal.value = false; formError.value = ''
  form.value = { name: '', category: '', unit_price: '', sku: '', description: '' }
}

onMounted(load)
</script>
