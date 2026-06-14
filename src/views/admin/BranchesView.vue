<template>
  <div class="p-6">
    <div class="flex items-center justify-between mb-6">
      <div>
        <h1 class="text-2xl font-bold text-nibbles-dark">Branches</h1>
        <p class="text-gray-500 text-sm mt-1">Manage Nibbles bakery locations</p>
      </div>
      <button @click="showModal = true" class="bg-nibbles-red text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-nibbles-red-dark transition-colors">
        + Add Branch
      </button>
    </div>
    <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
      <div v-for="branch in branches" :key="branch.id" class="bg-white rounded-xl p-5 shadow-sm border border-gray-100">
        <div class="flex items-start justify-between mb-3">
          <div class="w-10 h-10 bg-nibbles-cream rounded-lg flex items-center justify-center">
            <span class="text-xl">🏪</span>
          </div>
          <span :class="branch.is_active ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'" class="text-xs font-medium px-2 py-0.5 rounded">
            {{ branch.is_active ? 'Active' : 'Inactive' }}
          </span>
        </div>
        <h3 class="font-semibold text-nibbles-dark">{{ branch.name }}</h3>
        <p class="text-sm text-gray-500 mt-1">{{ branch.suburb }}</p>
        <p class="text-xs text-gray-400 mt-1">{{ branch.address }}</p>
        <p v-if="branch.phone" class="text-xs text-gray-400 mt-1">{{ branch.phone }}</p>
        <div class="mt-4 pt-4 border-t border-gray-100 flex gap-2">
          <button @click="editBranch(branch)" class="flex-1 text-xs text-nibbles-red hover:bg-red-50 py-1.5 rounded transition-colors font-medium">
            Edit
          </button>
          <button @click="toggleBranch(branch)" class="flex-1 text-xs text-gray-500 hover:bg-gray-50 py-1.5 rounded transition-colors">
            {{ branch.is_active ? 'Deactivate' : 'Activate' }}
          </button>
        </div>
      </div>
    </div>

    <div v-if="showModal" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 px-4">
      <div class="bg-white rounded-2xl p-6 w-full max-w-md">
        <h2 class="text-lg font-bold text-nibbles-dark mb-4">{{ editingId ? 'Edit Branch' : 'Add Branch' }}</h2>
        <form @submit.prevent="saveBranch" class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Branch name</label>
            <input v-model="form.name" type="text" required placeholder="e.g. Gateway Umhlanga" class="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-nibbles-red" />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Suburb</label>
            <input v-model="form.suburb" type="text" required placeholder="e.g. Umhlanga" class="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-nibbles-red" />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Street address</label>
            <input v-model="form.address" type="text" required placeholder="e.g. Shop 12, Gateway Theatre of Shopping" class="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-nibbles-red" />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Phone</label>
            <input v-model="form.phone" type="text" placeholder="031 555 0000" class="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-nibbles-red" />
          </div>
          <div v-if="formError" class="p-3 bg-red-50 border border-red-200 rounded-lg text-red-600 text-sm">{{ formError }}</div>
          <div class="flex gap-3 pt-2">
            <button type="button" @click="closeModal" class="flex-1 px-4 py-2 border border-gray-200 rounded-lg text-sm text-gray-600 hover:bg-gray-50">Cancel</button>
            <button type="submit" :disabled="saving" class="flex-1 bg-nibbles-red text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-nibbles-red-dark disabled:opacity-60">
              {{ saving ? 'Saving...' : (editingId ? 'Update Branch' : 'Add Branch') }}
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

const branches = ref([])
const showModal = ref(false)
const saving = ref(false)
const formError = ref('')
const editingId = ref(null)
const form = ref({ name: '', suburb: '', address: '', phone: '' })

async function load() {
  const { data } = await supabase.from('branches').select('*').order('name')
  if (data) branches.value = data
}

async function saveBranch() {
  saving.value = true; formError.value = ''
  if (editingId.value) {
    const { error } = await supabase.from('branches').update({ ...form.value }).eq('id', editingId.value)
    if (error) { formError.value = error.message } else { closeModal(); await load() }
  } else {
    const { error } = await supabase.from('branches').insert({ ...form.value })
    if (error) { formError.value = error.message } else { closeModal(); await load() }
  }
  saving.value = false
}

function editBranch(branch) {
  editingId.value = branch.id
  form.value = { name: branch.name, suburb: branch.suburb, address: branch.address, phone: branch.phone }
  showModal.value = true
}

async function toggleBranch(branch) {
  await supabase.from('branches').update({ is_active: !branch.is_active }).eq('id', branch.id)
  branch.is_active = !branch.is_active
}

function closeModal() {
  showModal.value = false; formError.value = ''; editingId.value = null
  form.value = { name: '', suburb: '', address: '', phone: '' }
}

onMounted(load)
</script>
