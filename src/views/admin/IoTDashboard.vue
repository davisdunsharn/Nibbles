<template>
  <div class="p-6">
    <div class="mb-8">
      <h1 class="text-3xl font-bold text-nibbles-dark tracking-tight">Production & Operations Hub</h1>
      <p class="text-gray-500 text-sm mt-2">Real-time monitoring of bakery operations across all branches</p>
    </div>

    <!-- Key Metrics -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
      <div class="bg-gradient-to-br from-blue-50 to-blue-100 rounded-xl p-4 border border-blue-200">
        <div class="flex items-center justify-between mb-3">
          <p class="text-sm font-medium text-blue-700">Active Branches</p>
          <span class="text-2xl">🏪</span>
        </div>
        <p class="text-3xl font-bold text-blue-900">{{ activeBranches }}</p>
      </div>

      <div class="bg-gradient-to-br from-green-50 to-green-100 rounded-xl p-4 border border-green-200">
        <div class="flex items-center justify-between mb-3">
          <p class="text-sm font-medium text-green-700">Today's Production</p>
          <span class="text-2xl">📦</span>
        </div>
        <p class="text-3xl font-bold text-green-900">{{ todaysProduction }}</p>
        <p class="text-xs text-green-600 mt-1">Units produced</p>
      </div>

      <div class="bg-gradient-to-br from-orange-50 to-orange-100 rounded-xl p-4 border border-orange-200">
        <div class="flex items-center justify-between mb-3">
          <p class="text-sm font-medium text-orange-700">Equipment Status</p>
          <span class="text-2xl">⚙️</span>
        </div>
        <p class="text-3xl font-bold text-orange-900">{{ equipmentStatus }}</p>
        <p class="text-xs text-orange-600 mt-1">Operating normally</p>
      </div>

      <div class="bg-gradient-to-br from-purple-50 to-purple-100 rounded-xl p-4 border border-purple-200">
        <div class="flex items-center justify-between mb-3">
          <p class="text-sm font-medium text-purple-700">Scheduled Deliveries</p>
          <span class="text-2xl">🚚</span>
        </div>
        <p class="text-3xl font-bold text-purple-900">{{ scheduledDeliveries }}</p>
        <p class="text-xs text-purple-600 mt-1">This week</p>
      </div>
    </div>

    <!-- Main Grid -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <!-- Production Status -->
      <div class="lg:col-span-2 bg-white rounded-xl shadow-sm border border-gray-100">
        <div class="p-5 border-b border-gray-100">
          <h3 class="font-semibold text-nibbles-dark flex items-center gap-2">
            <span class="w-2 h-2 bg-green-500 rounded-full animate-pulse"></span>
            Today's Production Status
          </h3>
        </div>
        <div class="p-5 space-y-4">
          <div v-for="item in productionStatus" :key="item.id" class="flex items-center gap-4 p-3 bg-gray-50 rounded-lg">
            <div class="text-2xl">{{ item.icon }}</div>
            <div class="flex-1">
              <p class="text-sm font-medium text-nibbles-dark">{{ item.name }}</p>
              <p class="text-xs text-gray-500">{{ item.branch }}</p>
            </div>
            <div class="text-right">
              <p class="text-lg font-bold text-nibbles-red">{{ item.units }}</p>
              <p class="text-xs text-gray-500">{{ item.time }}</p>
            </div>
          </div>
          <div v-if="productionStatus.length === 0" class="p-8 text-center text-gray-400 text-sm">
            No production data available
          </div>
        </div>
      </div>

      <!-- Branch Operations -->
      <div class="bg-white rounded-xl shadow-sm border border-gray-100">
        <div class="p-5 border-b border-gray-100">
          <h3 class="font-semibold text-nibbles-dark">Branch Operations</h3>
        </div>
        <div class="p-5 space-y-3">
          <div v-for="branch in branchOpsData" :key="branch.id" class="p-3 border border-gray-100 rounded-lg">
            <div class="flex items-center justify-between mb-2">
              <p class="text-sm font-medium text-nibbles-dark">{{ branch.name }}</p>
              <span :class="branch.status === 'operating' ? 'text-green-600' : 'text-yellow-600'" class="text-xs font-medium">
                {{ branch.status === 'operating' ? '● Operating' : '● Offline' }}
              </span>
            </div>
            <div class="text-xs text-gray-500 space-y-1">
              <p>🌡️ Temp: {{ branch.temp }}°C</p>
              <p>💧 Humidity: {{ branch.humidity }}%</p>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Deliveries & Alerts -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mt-6">
      <!-- Scheduled Deliveries -->
      <div class="bg-white rounded-xl shadow-sm border border-gray-100">
        <div class="p-5 border-b border-gray-100">
          <h3 class="font-semibold text-nibbles-dark">Scheduled Deliveries</h3>
        </div>
        <div class="p-5 space-y-3">
          <div v-for="delivery in deliveries" :key="delivery.id" class="flex items-center gap-3 p-3 border-l-4" :class="delivery.status === 'pending' ? 'border-yellow-400 bg-yellow-50' : 'border-green-400 bg-green-50'">
            <span class="text-xl">🚚</span>
            <div class="flex-1">
              <p class="text-sm font-medium text-nibbles-dark">{{ delivery.location }}</p>
              <p class="text-xs text-gray-600">{{ delivery.time }}</p>
            </div>
            <span :class="delivery.status === 'pending' ? 'bg-yellow-100 text-yellow-700' : 'bg-green-100 text-green-700'" class="text-xs font-medium px-2 py-1 rounded">
              {{ delivery.status === 'pending' ? 'Pending' : 'Completed' }}
            </span>
          </div>
          <div v-if="deliveries.length === 0" class="p-6 text-center text-gray-400 text-sm">
            No deliveries scheduled
          </div>
        </div>
      </div>

      <!-- System Alerts -->
      <div class="bg-white rounded-xl shadow-sm border border-gray-100">
        <div class="p-5 border-b border-gray-100">
          <h3 class="font-semibold text-nibbles-dark">System Alerts & Notifications</h3>
        </div>
        <div class="p-5 space-y-3">
          <div v-if="alerts.length === 0" class="p-6 text-center text-gray-400 text-sm">
            ✓ All systems operating normally
          </div>
          <div v-for="alert in alerts" :key="alert.id" class="flex items-start gap-3 p-3 rounded-lg" :class="alert.level === 'error' ? 'bg-red-50 border border-red-200' : 'bg-yellow-50 border border-yellow-200'">
            <span class="text-lg flex-shrink-0">{{ alert.level === 'error' ? '🔴' : '⚠️' }}</span>
            <div class="flex-1">
              <p class="text-sm font-medium text-gray-900">{{ alert.message }}</p>
              <p class="text-xs text-gray-600 mt-1">{{ alert.time }}</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { supabase } from '../../lib/supabase'
import { useAuthStore } from '../../stores/auth'

const auth = useAuthStore()
const branchOpsData = ref([
  { id: 1, name: 'Gateway Umhlanga', status: 'operating', temp: 24, humidity: 65 },
  { id: 2, name: 'Sandton City', status: 'operating', temp: 23, humidity: 68 },
  { id: 3, name: 'Menlyn Park', status: 'operating', temp: 25, humidity: 62 }
])

const productionStatus = ref([
  { id: 1, name: 'Sourdough Bread', icon: '🍞', units: '240 loaves', branch: 'Gateway', time: 'Today 07:30' },
  { id: 2, name: 'Croissants', icon: '🥐', units: '360 units', branch: 'Sandton', time: 'Today 08:15' },
  { id: 3, name: 'Donuts', icon: '🍩', units: '520 units', branch: 'Menlyn', time: 'Today 09:00' }
])

const deliveries = ref([
  { id: 1, location: 'Gateway Umhlanga', time: 'Today 15:00', status: 'pending' },
  { id: 2, location: 'Sandton City', time: 'Today 16:30', status: 'pending' },
  { id: 3, location: 'Menlyn Park', time: 'Tomorrow 08:00', status: 'pending' }
])

const alerts = ref([])

const activeBranches = computed(() => branchOpsData.value.length)
const todaysProduction = computed(() => {
  return productionStatus.value.reduce((sum, item) => {
    const match = item.units.match(/(\d+)/)
    return sum + (match ? parseInt(match[1]) : 0)
  }, 0)
})
const equipmentStatus = computed(() => branchOpsData.value.filter(b => b.status === 'operating').length + '/' + branchOpsData.value.length)
const scheduledDeliveries = computed(() => deliveries.value.filter(d => d.status === 'pending').length)

onMounted(() => {
  // Simulate occasional updates
  setInterval(() => {
    if (Math.random() > 0.7) {
      branchOpsData.value[0].temp = 23 + Math.random() * 3
      branchOpsData.value[0].humidity = 60 + Math.random() * 15
    }
  }, 5000)
})
</script>
