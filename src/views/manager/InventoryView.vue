<template>
  <div class="h-full overflow-auto bg-gray-50">
    <div class="p-6">
      <div class="mb-6">
        <h1 class="text-3xl font-bold text-nibbles-dark mb-2">Inventory Management</h1>
        <p class="text-gray-600">Real-time stock levels across branches</p>
      </div>

      <!-- Stats -->
      <div class="grid grid-cols-4 gap-4 mb-6">
        <div class="bg-white rounded-xl p-4 border-l-4 border-green-500">
          <p class="text-sm text-gray-600 mb-1">In Stock</p>
          <p class="text-2xl font-bold text-green-600">{{ inStockCount }}</p>
        </div>
        <div class="bg-white rounded-xl p-4 border-l-4 border-yellow-500">
          <p class="text-sm text-gray-600 mb-1">Low Stock</p>
          <p class="text-2xl font-bold text-yellow-600">{{ lowStockCount }}</p>
        </div>
        <div class="bg-white rounded-xl p-4 border-l-4 border-red-500">
          <p class="text-sm text-gray-600 mb-1">Out of Stock</p>
          <p class="text-2xl font-bold text-red-600">{{ outOfStockCount }}</p>
        </div>
        <div class="bg-white rounded-xl p-4 border-l-4 border-blue-500">
          <p class="text-sm text-gray-600 mb-1">Total Products</p>
          <p class="text-2xl font-bold text-blue-600">{{ inventory.length }}</p>
        </div>
      </div>

      <!-- Filters -->
      <div class="bg-white rounded-xl p-4 mb-6 flex gap-3">
        <input v-model="search" type="text" placeholder="Search products..." 
          class="flex-1 px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-nibbles-red" />
        <select v-model="filterStatus" class="px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-nibbles-red">
          <option value="">All Status</option>
          <option value="in_stock">In Stock</option>
          <option value="low_stock">Low Stock</option>
          <option value="out_of_stock">Out of Stock</option>
        </select>
        <button @click="refreshInventory" class="px-4 py-2 bg-nibbles-red text-white rounded-lg text-sm font-semibold hover:bg-nibbles-red-dark transition-colors">
          🔄 Refresh
        </button>
      </div>

      <!-- Inventory table -->
      <div class="bg-white rounded-xl overflow-hidden shadow">
        <table class="w-full text-sm">
          <thead class="bg-gray-50 border-b border-gray-200">
            <tr>
              <th class="px-6 py-3 text-left font-semibold text-gray-700">Product</th>
              <th class="px-6 py-3 text-left font-semibold text-gray-700">Current Stock</th>
              <th class="px-6 py-3 text-left font-semibold text-gray-700">Reorder Level</th>
              <th class="px-6 py-3 text-left font-semibold text-gray-700">Status</th>
              <th class="px-6 py-3 text-left font-semibold text-gray-700">Last Updated</th>
              <th class="px-6 py-3 text-left font-semibold text-gray-700">Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="filteredInventory.length === 0" class="border-b border-gray-200 hover:bg-gray-50">
              <td colspan="6" class="px-6 py-8 text-center text-gray-500">No inventory records found</td>
            </tr>
            <tr v-for="item in filteredInventory" :key="item.product_id" class="border-b border-gray-200 hover:bg-gray-50">
              <td class="px-6 py-4">
                <div>
                  <p class="font-semibold text-gray-800">{{ item.product_name }}</p>
                  <p class="text-xs text-gray-500">{{ item.product_id }}</p>
                </div>
              </td>
              <td class="px-6 py-4">
                <p :class="item.quantity_on_hand <= 0 ? 'text-red-600 font-bold' : 'text-gray-800'">
                  {{ item.quantity_on_hand }} units
                </p>
              </td>
              <td class="px-6 py-4 text-gray-600">{{ item.reorder_level }} units</td>
              <td class="px-6 py-4">
                <span :class="statusClass(item.status)" class="px-3 py-1 rounded-full text-xs font-semibold">
                  {{ item.status === 'in_stock' ? '✓ In Stock' : item.status === 'low_stock' ? '⚠ Low Stock' : '✕ Out of Stock' }}
                </span>
              </td>
              <td class="px-6 py-4 text-gray-600 text-xs">{{ formatDate(item.last_updated) }}</td>
              <td class="px-6 py-4">
                <button @click="openRestockModal(item)" class="text-blue-600 hover:text-blue-800 font-semibold text-xs">
                  📦 Restock
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Restock modal -->
      <div v-if="showRestock" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 px-4">
        <div class="bg-white rounded-2xl p-6 w-full max-w-sm">
          <h2 class="text-lg font-bold text-nibbles-dark mb-4">Restock: {{ restockItem?.product_name }}</h2>
          
          <div class="mb-4">
            <p class="text-sm text-gray-600 mb-1">Current Stock: <span class="font-bold text-nibbles-red">{{ restockItem?.quantity_on_hand }} units</span></p>
          </div>

          <div class="mb-4">
            <label class="block text-sm font-medium text-gray-700 mb-2">Quantity to Add</label>
            <input v-model.number="restockQuantity" type="number" min="1" 
              class="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-nibbles-red" />
          </div>

          <div class="mb-4 p-3 bg-gray-50 rounded-lg">
            <p class="text-xs text-gray-600"><span class="font-semibold">New Stock:</span> {{ (restockItem?.quantity_on_hand || 0) + (restockQuantity || 0) }} units</p>
          </div>

          <div v-if="restockError" class="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg">
            <p class="text-xs text-red-600">{{ restockError }}</p>
          </div>

          <div class="flex gap-3">
            <button @click="showRestock = false" class="flex-1 px-4 py-2 border border-gray-200 rounded-lg text-sm text-gray-600 hover:bg-gray-50">
              Cancel
            </button>
            <button @click="confirmRestock" :disabled="restocking" 
              class="flex-1 bg-nibbles-red text-white px-4 py-2 rounded-lg text-sm font-semibold hover:bg-nibbles-red-dark disabled:opacity-50 transition-colors">
              {{ restocking ? 'Restocking...' : 'Confirm' }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useAuthStore } from '../../stores/auth'
import { supabase } from '../../lib/supabase'

const auth = useAuthStore()
const inventory = ref([])
const loading = ref(true)
const search = ref('')
const filterStatus = ref('')
const showRestock = ref(false)
const restockItem = ref(null)
const restockQuantity = ref(0)
const restocking = ref(false)
const restockError = ref('')

const filteredInventory = computed(() => {
  return inventory.value.filter(item => {
    const matchSearch = !search.value || item.product_name.toLowerCase().includes(search.value.toLowerCase())
    const matchStatus = !filterStatus.value || item.status === filterStatus.value
    return matchSearch && matchStatus
  })
})

const inStockCount = computed(() => inventory.value.filter(i => i.status === 'in_stock').length)
const lowStockCount = computed(() => inventory.value.filter(i => i.status === 'low_stock').length)
const outOfStockCount = computed(() => inventory.value.filter(i => i.status === 'out_of_stock').length)

function statusClass(status) {
  return {
    'in_stock': 'bg-green-100 text-green-800',
    'low_stock': 'bg-yellow-100 text-yellow-800',
    'out_of_stock': 'bg-red-100 text-red-800'
  }[status] || 'bg-gray-100 text-gray-800'
}

function formatDate(date) {
  return new Date(date).toLocaleString('en-ZA', { 
    dateStyle: 'short',
    timeStyle: 'short'
  })
}

async function refreshInventory() {
  loading.value = true
  try {
    const { data, error } = await supabase.rpc('get_branch_inventory', { 
      p_branch_id: auth.branchId 
    })
    
    if (error) throw error
    inventory.value = data || []
  } catch (err) {
    console.error('Error loading inventory:', err.message)
  } finally {
    loading.value = false
  }
}

function openRestockModal(item) {
  restockItem.value = item
  restockQuantity.value = 0
  restockError.value = ''
  showRestock.value = true
}

async function confirmRestock() {
  if (!restockQuantity.value || restockQuantity.value <= 0) {
    restockError.value = 'Please enter a valid quantity'
    return
  }

  restocking.value = true
  restockError.value = ''
  
  try {
    const { data, error } = await supabase.rpc('restock_inventory', {
      p_product_id: restockItem.value.product_id,
      p_branch_id: auth.branchId,
      p_quantity: restockQuantity.value
    })
    
    if (error) throw error
    
    showRestock.value = false
    await refreshInventory()
  } catch (err) {
    restockError.value = err.message
  } finally {
    restocking.value = false
  }
}

onMounted(refreshInventory)
</script>
