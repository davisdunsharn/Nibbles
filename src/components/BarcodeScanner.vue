<template>
  <div class="fixed inset-0 bg-black/60 z-50 flex items-center justify-center px-4">
    <div class="card p-5 w-full max-w-md">
      <div class="flex items-start justify-between mb-3">
        <div>
          <h2 class="font-display text-xl font-semibold text-ink flex items-center gap-2">
            <AppIcon name="search" :size="18" class="text-brand-500" /> Scan barcode
          </h2>
          <p class="text-xs text-ink-muted mt-0.5">Point the camera at a product barcode</p>
        </div>
        <button @click="$emit('close')" class="text-stone-400 hover:text-ink transition-colors"><AppIcon name="x" :size="20" /></button>
      </div>

      <div v-if="cameras.length > 1" class="mb-3">
        <label class="label">Camera</label>
        <select v-model="selectedCamera" @change="restart" class="input">
          <option v-for="c in cameras" :key="c.id" :value="c.id">{{ c.label || 'Camera' }}</option>
        </select>
      </div>

      <div :id="readerId" class="rounded-xl overflow-hidden bg-stone-900 aspect-[4/3] flex items-center justify-center">
        <p v-if="status === 'starting'" class="text-stone-400 text-sm">Starting camera…</p>
      </div>

      <div v-if="error" class="mt-3 flex items-start gap-2 p-3 bg-red-50 border border-red-100 rounded-xl">
        <AppIcon name="alert" :size="16" class="text-red-500 mt-0.5 flex-shrink-0" />
        <p class="text-red-600 text-sm">{{ error }}</p>
      </div>
      <div v-else-if="lastCode" class="mt-3 flex items-center gap-2 p-3 bg-emerald-50 border border-emerald-100 rounded-xl">
        <AppIcon name="check-circle" :size="16" class="text-emerald-500" />
        <p class="text-emerald-700 text-sm">Scanned <span class="font-mono font-medium">{{ lastCode }}</span></p>
      </div>

      <p class="text-xs text-ink-muted mt-3 leading-relaxed">
        On a Mac, pick your iPhone under <span class="font-medium text-ink-soft">Camera</span> (Continuity Camera), or open this page on your phone for the back camera.
        You can also enter a code manually below.
      </p>
      <form @submit.prevent="manualSubmit" class="mt-3 flex gap-2">
        <input v-model="manual" type="text" placeholder="Enter barcode / SKU" class="input flex-1" />
        <button type="submit" class="btn-secondary">Use</button>
      </form>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount, nextTick } from 'vue'
import { Html5Qrcode } from 'html5-qrcode'
import AppIcon from './AppIcon.vue'

const emit = defineEmits(['scanned', 'close'])

const readerId = `bc-reader-${Math.random().toString(36).slice(2, 8)}`
const cameras = ref([])
const selectedCamera = ref(null)
const status = ref('starting')
const error = ref('')
const lastCode = ref('')
const manual = ref('')
let scanner = null

function pickDefault(list) {
  const pref = list.find(c => /back|rear|environment|iphone|continuity/i.test(c.label || ''))
  return (pref || list[list.length - 1] || list[0])?.id
}

async function start(cameraId) {
  error.value = ''
  status.value = 'starting'
  try {
    if (!scanner) scanner = new Html5Qrcode(readerId, { verbose: false })
    await scanner.start(
      cameraId,
      { fps: 10, qrbox: { width: 260, height: 170 }, aspectRatio: 1.333 },
      (decodedText) => {
        if (lastCode.value === decodedText) return
        lastCode.value = decodedText
        emit('scanned', decodedText)
      },
      () => {}, // ignore per-frame decode errors
    )
    status.value = 'scanning'
  } catch (err) {
    status.value = 'error'
    error.value = /permission|NotAllowed/i.test(err?.message || err)
      ? 'Camera permission denied. Allow camera access in your browser settings.'
      : `Could not start camera: ${err?.message || err}`
  }
}

async function stop() {
  try { if (scanner && scanner.isScanning) await scanner.stop() } catch { /* noop */ }
}
async function restart() {
  await stop()
  await start(selectedCamera.value)
}
function manualSubmit() {
  if (manual.value.trim()) emit('scanned', manual.value.trim())
}

onMounted(async () => {
  await nextTick()
  try {
    const list = await Html5Qrcode.getCameras()
    if (!list || list.length === 0) { error.value = 'No camera found on this device.'; status.value = 'error'; return }
    cameras.value = list
    selectedCamera.value = pickDefault(list)
    await start(selectedCamera.value)
  } catch (err) {
    status.value = 'error'
    error.value = `Camera unavailable: ${err?.message || err}. You can still enter a code manually.`
  }
})
onBeforeUnmount(stop)
</script>
