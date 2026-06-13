<template>
  <div class="p-6">
    <div class="flex items-center justify-between mb-6">
      <div>
        <h1 class="text-2xl font-bold text-nibbles-dark">Inventory</h1>
        <p class="text-gray-500 text-sm mt-1">Stock levels at your branch</p>
      </div>
    </div>
    <div class="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
      <div class="p-4 border-b border-gray-100">
        <input v-model="search" type="text" placeholder="Search products..." class="w-full max-w-xs px-4 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-nibbles-red" />
      </div>
      <table class="w-full text-sm">
        <thead>
          <tr class="text-left text-gray-400 border-b border-gray-100 bg-gray-50">
            <th class="px-4 py-3 font-medium">Product</th>
            <th class="px-4 py-3 font-medium">Category</th>
            <th class="px-4 py-3 font-medium">On Hand</th>
            <th class="px-4 py-3 font-medium">Reorder At</th>
            <th class="px-4 py-3 font-medium">Status</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-50">
          <tr v-if="loading"><td colspan="5" class="px-4 py-8 text-center text-gray-400">Loading...</td></tr>
          <tr v-else-if="filtered.length === 0"><td colspan="5" class="px-4 py-8 text-center text-gray-400">No products found.</td></tr>
          <tr v-for="item in filtered" :key="item.id" class="hover:bg-gray-50">
            <td class="px-4 py-3 font-medium text-gray-800">{{ item.products?.name }}</td>
            <td class="px-4 py-3 text-gray-500 capitalize">{{ item.products?.category }}</td>
            <td class="px-4 py-3 font-semibold text-nibbles-dark">{{ item.quantity_on_hand }}</td>
            <td class="px-4 py-3 text-gray-500">{{ item.reorder_threshold }}</td>
            <td class="px-4 py-3">
              <span :class="stockStatus(item).class" class="px-2 py-0.5 rounded text-xs font-medium">{{ stockStatus(item).label }}</span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../../lib/supabase'
import { useAuthStore } from '../../stores/auth'

const auth = useAuthStore()
const inventory = ref([])
const loading = ref(true)
const search = ref('')

const filtered = computed(() => {
  if (!search.value) return inventory.value
  return inventory.value.filter(i => i.products?.name?.toLowerCase().includes(search.value.toLowerCase()))
})

function stockStatus(item) {
  if (item.quantity_on_hand === 0) return { label: 'Out of stock', class: 'bg-red-100 text-red-700' }
  if (item.quantity_on_hand <= item.reorder_threshold) return { label: 'Low stock', class: 'bg-yellow-100 text-yellow-700' }
  return { label: 'In stock', class: 'bg-green-100 text-green-700' }
}

onMounted(async () => {
  loading.value = true
  const { data } = await supabase.from('inventory').select('*, products(name, category)').eq('branch_id', auth.branchId).order('quantity_on_hand', { ascending: true })
  if (data) inventory.value = data
  loading.value = false
})
</script>
