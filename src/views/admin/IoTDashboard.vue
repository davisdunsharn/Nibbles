<template>
  <div class="p-6">
    <div class="mb-6">
      <h1 class="text-2xl font-bold text-nibbles-dark">IoT Dashboard</h1>
      <p class="text-gray-500 text-sm mt-1">Live barcode/RFID scanner events across all branches</p>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <!-- Live feed -->
      <div class="lg:col-span-2 bg-white rounded-xl shadow-sm border border-gray-100">
        <div class="p-4 border-b border-gray-100 flex items-center justify-between">
          <h3 class="font-semibold text-nibbles-dark">Live Scan Feed</h3>
          <div class="flex items-center gap-2">
            <span class="w-2 h-2 bg-green-500 rounded-full animate-pulse"></span>
            <span class="text-xs text-gray-500">Live</span>
          </div>
        </div>
        <div class="divide-y divide-gray-50 max-h-96 overflow-y-auto">
          <div v-if="events.length === 0" class="p-8 text-center text-gray-400 text-sm">
            No scan events yet. Use the simulator to generate some.
          </div>
          <div v-for="event in events" :key="event.id" class="px-4 py-3 flex items-center gap-4 hover:bg-gray-50">
            <div :class="eventColor(event.event_type)" class="w-8 h-8 rounded-lg flex items-center justify-center text-sm flex-shrink-0">
              {{ eventIcon(event.event_type) }}
            </div>
            <div class="flex-1 min-w-0">
              <div class="flex items-center gap-2">
                <p class="text-sm font-medium text-gray-800 truncate">{{ event.products?.name || event.sku_scanned || 'Unknown SKU' }}</p>
                <span v-if="event.is_anomaly" class="text-xs bg-red-100 text-red-600 px-1.5 py-0.5 rounded font-medium">⚠ Anomaly</span>
              </div>
              <p class="text-xs text-gray-400">{{ event.branches?.name }} · {{ event.event_type.replace('_', ' ') }} · Qty: {{ event.quantity }}</p>
            </div>
            <span class="text-xs text-gray-400 flex-shrink-0">{{ formatTime(event.created_at) }}</span>
          </div>
        </div>
      </div>

      <!-- Simulator -->
      <div class="bg-white rounded-xl shadow-sm border border-gray-100">
        <div class="p-4 border-b border-gray-100">
          <h3 class="font-semibold text-nibbles-dark">IoT Simulator</h3>
          <p class="text-xs text-gray-400 mt-1">Simulates a barcode/RFID scanner</p>
        </div>
        <div class="p-4 space-y-4">
          <div>
            <label class="block text-xs font-medium text-gray-600 mb-1">Branch</label>
            <select v-model="sim.branch_id" class="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-nibbles-red">
              <option value="">Select branch</option>
              <option v-for="b in branchList" :key="b.id" :value="b.id">{{ b.name }}</option>
            </select>
          </div>
          <div>
            <label class="block text-xs font-medium text-gray-600 mb-1">Product SKU</label>
            <select v-model="sim.product_id" class="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-nibbles-red">
              <option value="">Select product</option>
              <option v-for="p in productList" :key="p.id" :value="p.id">{{ p.name }} {{ p.sku ? '(' + p.sku + ')' : '' }}</option>
            </select>
          </div>
          <div>
            <label class="block text-xs font-medium text-gray-600 mb-1">Event type</label>
            <select v-model="sim.event_type" class="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-nibbles-red">
              <option value="stock_in">Stock In (delivery)</option>
              <option value="stock_out">Stock Out (sold/used)</option>
              <option value="stock_check">Stock Check</option>
            </select>
          </div>
          <div>
            <label class="block text-xs font-medium text-gray-600 mb-1">Quantity</label>
            <input v-model.number="sim.quantity" type="number" min="1" max="500"
              class="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-nibbles-red" />
          </div>
          <button @click="fireSimEvent" :disabled="!sim.branch_id || !sim.product_id || simLoading"
            class="w-full bg-nibbles-red text-white py-2 rounded-lg text-sm font-medium hover:bg-nibbles-red-dark disabled:opacity-50 transition-colors">
            {{ simLoading ? 'Sending...' : '📡 Fire Scan Event' }}
          </button>
          <p v-if="simSuccess" class="text-xs text-green-600 text-center">✓ Event sent successfully</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { supabase } from '../../lib/supabase'

const events = ref([])
const branchList = ref([])
const productList = ref([])
const simLoading = ref(false)
const simSuccess = ref(false)
const sim = ref({ branch_id: '', product_id: '', event_type: 'stock_in', quantity: 1 })

let subscription = null

function eventColor(type) {
  return { stock_in: 'bg-green-100', stock_out: 'bg-red-100', stock_check: 'bg-blue-100', unknown: 'bg-gray-100' }[type] || 'bg-gray-100'
}
function eventIcon(type) {
  return { stock_in: '📥', stock_out: '📤', stock_check: '🔍', unknown: '❓' }[type] || '❓'
}
function formatTime(d) { return new Date(d).toLocaleTimeString('en-ZA', { hour: '2-digit', minute: '2-digit', second: '2-digit' }) }

async function fireSimEvent() {
  simLoading.value = true
  simSuccess.value = false
  const { error } = await supabase.from('iot_events').insert({
    branch_id: sim.value.branch_id,
    product_id: sim.value.product_id,
    event_type: sim.value.event_type,
    quantity: sim.value.quantity,
    device_id: 'simulator-001',
    processed: false
  })
  simLoading.value = false
  if (!error) { simSuccess.value = true; setTimeout(() => simSuccess.value = false, 3000) }
}

onMounted(async () => {
  const { data: recent } = await supabase.from('iot_events').select('*, products(name), branches(name)').order('created_at', { ascending: false }).limit(30)
  if (recent) events.value = recent

  const { data: b } = await supabase.from('branches').select('id, name').eq('is_active', true)
  if (b) branchList.value = b

  const { data: p } = await supabase.from('products').select('id, name, sku').eq('is_active', true)
  if (p) productList.value = p

  subscription = supabase.channel('iot-events').on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'iot_events' }, async (payload) => {
    const { data } = await supabase.from('iot_events').select('*, products(name), branches(name)').eq('id', payload.new.id).single()
    if (data) events.value = [data, ...events.value].slice(0, 50)
  }).subscribe()
})

onUnmounted(() => { if (subscription) supabase.removeChannel(subscription) })
</script>
