<template>
  <div class="p-6">
    <div class="flex items-center justify-between mb-6">
      <div>
        <h1 class="text-2xl font-bold text-nibbles-dark">Suppliers</h1>
        <p class="text-gray-500 text-sm mt-1">Manage product suppliers</p>
      </div>
      <button @click="showModal = true" class="bg-nibbles-red text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-nibbles-red-dark transition-colors">+ Add Supplier</button>
    </div>
    <div class="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
      <table class="w-full text-sm">
        <thead>
          <tr class="text-left text-gray-400 border-b border-gray-100 bg-gray-50">
            <th class="px-4 py-3 font-medium">Name</th>
            <th class="px-4 py-3 font-medium">Contact</th>
            <th class="px-4 py-3 font-medium">Phone</th>
            <th class="px-4 py-3 font-medium">Email</th>
            <th class="px-4 py-3 font-medium">Payment Terms</th>
            <th class="px-4 py-3 font-medium">Status</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-50">
          <tr v-if="loading"><td colspan="6" class="px-4 py-8 text-center text-gray-400">Loading...</td></tr>
          <tr v-for="s in suppliers" :key="s.id" class="hover:bg-gray-50">
            <td class="px-4 py-3 font-medium text-gray-800">{{ s.name }}</td>
            <td class="px-4 py-3 text-gray-600">{{ s.contact_person || '—' }}</td>
            <td class="px-4 py-3 text-gray-600">{{ s.phone || '—' }}</td>
            <td class="px-4 py-3 text-gray-600">{{ s.email || '—' }}</td>
            <td class="px-4 py-3 text-gray-600">{{ s.payment_terms || '—' }}</td>
            <td class="px-4 py-3">
              <span :class="s.is_active ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'" class="px-2 py-0.5 rounded text-xs font-medium">
                {{ s.is_active ? 'Active' : 'Inactive' }}
              </span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <div v-if="showModal" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 px-4">
      <div class="bg-white rounded-2xl p-6 w-full max-w-md">
        <h2 class="text-lg font-bold text-nibbles-dark mb-4">Add Supplier</h2>
        <form @submit.prevent="createSupplier" class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Company name</label>
            <input v-model="form.name" type="text" required class="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-nibbles-red" />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Contact person</label>
            <input v-model="form.contact_person" type="text" class="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-nibbles-red" />
          </div>
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Phone</label>
              <input v-model="form.phone" type="text" class="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-nibbles-red" />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Email</label>
              <input v-model="form.email" type="email" class="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-nibbles-red" />
            </div>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Payment terms</label>
            <input v-model="form.payment_terms" type="text" placeholder="e.g. 30 days EOM, COD" class="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-nibbles-red" />
          </div>
          <div v-if="formError" class="p-3 bg-red-50 rounded-lg text-red-600 text-sm">{{ formError }}</div>
          <div class="flex gap-3 pt-2">
            <button type="button" @click="closeModal" class="flex-1 px-4 py-2 border border-gray-200 rounded-lg text-sm text-gray-600">Cancel</button>
            <button type="submit" :disabled="saving" class="flex-1 bg-nibbles-red text-white px-4 py-2 rounded-lg text-sm font-medium disabled:opacity-60">
              {{ saving ? 'Saving...' : 'Add Supplier' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '../../lib/supabase'
import { useToast } from '../../composables/useToast'
const toast = useToast()
const suppliers = ref([]); const loading = ref(true); const showModal = ref(false)
const saving = ref(false); const formError = ref('')
const form = ref({ name: '', contact_person: '', phone: '', email: '', payment_terms: '' })
async function load() { loading.value = true; const { data } = await supabase.from('suppliers').select('*').order('name'); if (data) suppliers.value = data; loading.value = false }
async function createSupplier() { saving.value = true; formError.value = ''; const { error } = await supabase.from('suppliers').insert({ ...form.value }); if (error) { formError.value = error.message; toast.error(error.message) } else { closeModal(); await load(); toast.success('Supplier added') }; saving.value = false }
function closeModal() { showModal.value = false; formError.value = ''; form.value = { name: '', contact_person: '', phone: '', email: '', payment_terms: '' } }
onMounted(load)
</script>
