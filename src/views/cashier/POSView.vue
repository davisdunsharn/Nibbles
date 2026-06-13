<template>
  <div class="flex h-full">
    <!-- Left: Product grid -->
    <div class="flex-1 flex flex-col overflow-hidden">
      <!-- Search + category tabs -->
      <div class="bg-white border-b border-gray-200 p-4 space-y-3">
        <input v-model="search" type="text" placeholder="Search products..."
          class="w-full px-4 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-nibbles-red" />
        <div class="flex gap-2 overflow-x-auto pb-1">
          <button v-for="cat in categories" :key="cat"
            @click="activeCategory = cat"
            :class="activeCategory === cat ? 'bg-nibbles-red text-white' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'"
            class="px-4 py-1.5 rounded-full text-xs font-medium capitalize whitespace-nowrap transition-colors">
            {{ cat === 'all' ? 'All' : cat }}
          </button>
        </div>
      </div>

      <!-- Product grid -->
      <div class="flex-1 overflow-y-auto p-4">
        <div v-if="loading" class="text-center text-gray-400 py-12">Loading products...</div>
        <div v-else-if="filteredProducts.length === 0" class="text-center text-gray-400 py-12">No products found.</div>
        <div v-else class="grid grid-cols-2 md:grid-cols-3 xl:grid-cols-4 gap-3">
          <button v-for="product in filteredProducts" :key="product.id"
            @click="addToCart(product)"
            class="bg-white border border-gray-200 rounded-xl p-4 text-left hover:border-nibbles-red hover:shadow-md transition-all group">
            <div class="w-10 h-10 bg-nibbles-cream rounded-lg flex items-center justify-center mb-3 group-hover:bg-red-50">
              <span class="text-xl">{{ categoryIcon(product.category) }}</span>
            </div>
            <p class="text-sm font-semibold text-gray-800 leading-tight mb-1">{{ product.name }}</p>
            <p class="text-nibbles-red font-bold text-sm">R{{ parseFloat(product.unit_price).toFixed(2) }}</p>
          </button>
        </div>
      </div>
    </div>

    <!-- Right: Cart -->
    <div class="w-80 bg-white border-l border-gray-200 flex flex-col">
      <div class="p-4 border-b border-gray-200">
        <div class="flex items-center justify-between">
          <h3 class="font-semibold text-nibbles-dark">Current Order</h3>
          <button v-if="cart.length" @click="clearCart" class="text-xs text-gray-400 hover:text-red-500 transition-colors">Clear</button>
        </div>
        <!-- Customer lookup -->
        <div class="mt-3 relative">
          <input v-model="phoneSearch" @input="searchCustomer" type="text" placeholder="Customer phone (optional)"
            class="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-nibbles-red" />
          <div v-if="customerResult" class="mt-2 p-2 bg-green-50 border border-green-200 rounded-lg">
            <p class="text-xs font-medium text-green-800">{{ customerResult.first_name }} {{ customerResult.last_name }}</p>
            <p class="text-xs text-green-600">{{ customerResult.loyalty_points }} points</p>
          </div>
        </div>
      </div>

      <!-- Cart items -->
      <div class="flex-1 overflow-y-auto p-4 space-y-2">
        <div v-if="cart.length === 0" class="text-center text-gray-400 text-sm py-8">
          Tap a product to add it to the order
        </div>
        <div v-for="(item, i) in cart" :key="i" class="flex items-center gap-3 bg-gray-50 rounded-lg p-3">
          <div class="flex-1 min-w-0">
            <p class="text-sm font-medium text-gray-800 truncate">{{ item.name }}</p>
            <p class="text-xs text-nibbles-red font-semibold">R{{ (item.unit_price * item.quantity).toFixed(2) }}</p>
          </div>
          <div class="flex items-center gap-1">
            <button @click="changeQty(i, -1)" class="w-6 h-6 rounded bg-gray-200 hover:bg-gray-300 text-gray-600 text-sm font-bold flex items-center justify-center">−</button>
            <span class="text-sm font-medium w-6 text-center">{{ item.quantity }}</span>
            <button @click="changeQty(i, 1)" class="w-6 h-6 rounded bg-gray-200 hover:bg-gray-300 text-gray-600 text-sm font-bold flex items-center justify-center">+</button>
          </div>
          <button @click="removeItem(i)" class="text-gray-300 hover:text-red-500 text-sm transition-colors">✕</button>
        </div>
      </div>

      <!-- Totals + payment -->
      <div class="p-4 border-t border-gray-200 space-y-3">
        <div class="space-y-1 text-sm">
          <div class="flex justify-between text-gray-500"><span>Subtotal</span><span>R{{ subtotal.toFixed(2) }}</span></div>
          <div class="flex justify-between font-bold text-nibbles-dark text-base"><span>Total</span><span>R{{ subtotal.toFixed(2) }}</span></div>
        </div>
        <button @click="showPayment = true" :disabled="cart.length === 0"
          class="w-full bg-nibbles-red text-white py-3 rounded-xl font-semibold hover:bg-nibbles-red-dark disabled:opacity-40 disabled:cursor-not-allowed transition-colors">
          Charge R{{ subtotal.toFixed(2) }}
        </button>
      </div>
    </div>

    <!-- Payment modal -->
    <div v-if="showPayment" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 px-4">
      <div class="bg-white rounded-2xl p-6 w-full max-w-sm">
        <h2 class="text-lg font-bold text-nibbles-dark mb-1">Payment</h2>
        <p class="text-2xl font-bold text-nibbles-red mb-4">R{{ subtotal.toFixed(2) }}</p>

        <div class="flex gap-2 mb-4">
          <button v-for="method in ['cash','card','split']" :key="method"
            @click="paymentMethod = method"
            :class="paymentMethod === method ? 'bg-nibbles-red text-white' : 'bg-gray-100 text-gray-600'"
            class="flex-1 py-2 rounded-lg text-sm font-medium capitalize transition-colors">
            {{ method }}
          </button>
        </div>

        <div v-if="paymentMethod === 'cash'" class="mb-4">
          <label class="block text-sm font-medium text-gray-700 mb-1">Cash tendered</label>
          <input v-model.number="cashTendered" type="number" step="0.01" :min="subtotal"
            class="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-nibbles-red" />
          <p v-if="cashTendered >= subtotal" class="text-sm text-green-600 mt-2 font-medium">
            Change: R{{ (cashTendered - subtotal).toFixed(2) }}
          </p>
        </div>

        <div v-if="paymentMethod === 'card'" class="mb-4">
          <label class="block text-sm font-medium text-gray-700 mb-1">Card reference</label>
          <input v-model="cardReference" type="text" placeholder="e.g. YC-2024-001"
            class="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-nibbles-red" />
        </div>

        <div v-if="payError" class="mb-3 p-3 bg-red-50 rounded-lg text-red-600 text-sm">{{ payError }}</div>

        <div class="flex gap-3">
          <button @click="showPayment = false" class="flex-1 px-4 py-2 border border-gray-200 rounded-lg text-sm text-gray-600 hover:bg-gray-50">Cancel</button>
          <button @click="processPayment" :disabled="paying || (paymentMethod === 'cash' && cashTendered < subtotal)"
            class="flex-1 bg-nibbles-red text-white px-4 py-2 rounded-lg text-sm font-semibold hover:bg-nibbles-red-dark disabled:opacity-50 transition-colors">
            {{ paying ? 'Processing...' : 'Confirm' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Receipt modal -->
    <div v-if="showReceipt" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 px-4">
      <div class="bg-white rounded-2xl p-6 w-full max-w-sm text-center">
        <div class="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
          <span class="text-3xl">✓</span>
        </div>
        <h2 class="text-lg font-bold text-nibbles-dark mb-1">Payment Complete</h2>
        <p class="font-mono text-sm text-gray-500 mb-1">{{ lastReceipt }}</p>
        <p class="text-2xl font-bold text-nibbles-red mb-4">R{{ lastTotal }}</p>
        <div v-if="lastChange > 0" class="mb-4 p-3 bg-gray-50 rounded-lg">
          <p class="text-sm text-gray-600">Change due: <span class="font-bold text-nibbles-dark">R{{ lastChange.toFixed(2) }}</span></p>
        </div>
        <button @click="newOrder" class="w-full bg-nibbles-red text-white py-3 rounded-xl font-semibold hover:bg-nibbles-red-dark transition-colors">
          New Order
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useAuthStore } from '../../stores/auth'
import { supabase } from '../../lib/supabase'
import { useDebounceFn } from '@vueuse/core'

const auth = useAuthStore()
const products = ref([])
const cart = ref([])
const loading = ref(true)
const search = ref('')
const activeCategory = ref('all')
const showPayment = ref(false)
const showReceipt = ref(false)
const paymentMethod = ref('cash')
const cashTendered = ref(0)
const cardReference = ref('')
const paying = ref(false)
const payError = ref('')
const phoneSearch = ref('')
const customerResult = ref(null)
const lastReceipt = ref('')
const lastTotal = ref('')
const lastChange = ref(0)

const categories = computed(() => ['all', ...new Set(products.value.map(p => p.category))])

const filteredProducts = computed(() => {
  return products.value.filter(p => {
    const matchCat = activeCategory.value === 'all' || p.category === activeCategory.value
    const matchSearch = !search.value || p.name.toLowerCase().includes(search.value.toLowerCase())
    return matchCat && matchSearch && p.is_active
  })
})

const subtotal = computed(() => cart.value.reduce((s, i) => s + i.unit_price * i.quantity, 0))

function categoryIcon(cat) {
  return { bread: '🍞', roll: '🥐', pastry: '🥐', cake: '🎂', beverage: '☕', other: '🛍️' }[cat] || '🛍️'
}

function addToCart(product) {
  const existing = cart.value.find(i => i.id === product.id)
  if (existing) { existing.quantity++ } else { cart.value.push({ ...product, quantity: 1 }) }
}

function changeQty(index, delta) {
  cart.value[index].quantity += delta
  if (cart.value[index].quantity <= 0) cart.value.splice(index, 1)
}

function removeItem(index) { cart.value.splice(index, 1) }
function clearCart() { cart.value = []; customerResult.value = null; phoneSearch.value = '' }

const searchCustomer = useDebounceFn(async () => {
  if (!phoneSearch.value || phoneSearch.value.length < 4) { customerResult.value = null; return }
  const { data } = await supabase.from('customers').select('*').ilike('phone', `%${phoneSearch.value}%`).limit(1).single()
  customerResult.value = data || null
}, 300)

async function generateReceiptNumber() {
  const now = new Date()
  const date = now.toLocaleDateString('en-ZA', { day: '2-digit', month: '2-digit', year: '2-digit' }).replace(/\//g, '')
  const { data: branch } = await supabase.from('branches').select('name').eq('id', auth.branchId).single()
  const code = branch ? branch.name.substring(0, 2).toUpperCase() : 'NB'
  const count = Math.floor(Math.random() * 9000) + 1000
  return `NB-${code}-${date}-${count}`
}

async function processPayment() {
  paying.value = true
  payError.value = ''
  try {
    const receiptNumber = await generateReceiptNumber()
    const total = subtotal.value
    const change = paymentMethod.value === 'cash' ? cashTendered.value - total : 0

    const { data: tx, error: txError } = await supabase.from('transactions').insert({
      branch_id: auth.branchId,
      cashier_id: auth.user.id,
      customer_id: customerResult.value?.id || null,
      receipt_number: receiptNumber,
      subtotal: total,
      discount_amount: 0,
      total_amount: total,
      payment_method: paymentMethod.value,
      cash_tendered: paymentMethod.value === 'cash' ? cashTendered.value : null,
      change_given: change > 0 ? change : null,
      card_reference: paymentMethod.value === 'card' ? cardReference.value : null,
      status: 'completed'
    }).select().single()

    if (txError) throw txError

    const lines = cart.value.map(item => ({
      transaction_id: tx.id,
      product_id: item.id,
      quantity: item.quantity,
      unit_price_at_sale: item.unit_price,
      line_total: item.unit_price * item.quantity,
      discount_applied: 0
    }))

    const { error: linesError } = await supabase.from('transaction_lines').insert(lines)
    if (linesError) throw linesError

    lastReceipt.value = receiptNumber
    lastTotal.value = total.toFixed(2)
    lastChange.value = change
    showPayment.value = false
    showReceipt.value = true
  } catch (err) {
    payError.value = err.message
  } finally {
    paying.value = false
  }
}

function newOrder() {
  showReceipt.value = false
  clearCart()
  paymentMethod.value = 'cash'
  cashTendered.value = 0
  cardReference.value = ''
}

onMounted(async () => {
  loading.value = true
  const { data } = await supabase.from('products').select('*').eq('is_active', true).order('name')
  if (data) products.value = data
  loading.value = false
})
</script>
