<template>
  <Teleport to="body">
    <div class="fixed top-4 right-4 z-[100] flex flex-col gap-2 w-[min(92vw,360px)] pointer-events-none">
      <TransitionGroup name="toast">
        <div
          v-for="t in toasts"
          :key="t.id"
          class="pointer-events-auto flex items-start gap-3 p-3.5 rounded-2xl shadow-soft border bg-white/90 backdrop-blur-xl"
          :class="styles(t.type).border"
        >
          <span class="w-7 h-7 rounded-lg flex items-center justify-center flex-shrink-0" :class="styles(t.type).chip">
            <AppIcon :name="styles(t.type).icon" :size="16" />
          </span>
          <p class="flex-1 text-sm text-ink leading-snug pt-0.5">{{ t.message }}</p>
          <button @click="remove(t.id)" class="text-stone-400 hover:text-ink transition-colors flex-shrink-0">
            <AppIcon name="x" :size="15" />
          </button>
        </div>
      </TransitionGroup>
    </div>
  </Teleport>
</template>

<script setup>
import { useToast } from '../composables/useToast'
import AppIcon from './AppIcon.vue'

const { toasts, remove } = useToast()

function styles(type) {
  if (type === 'success') return { icon: 'check-circle', chip: 'bg-emerald-50 text-emerald-600', border: 'border-emerald-100' }
  if (type === 'error') return { icon: 'alert', chip: 'bg-red-50 text-red-600', border: 'border-red-100' }
  return { icon: 'dot', chip: 'bg-brand-50 text-brand-600', border: 'border-stone-200/70' }
}
</script>

<style scoped>
.toast-enter-active, .toast-leave-active { transition: all 0.28s cubic-bezier(0.22, 1, 0.36, 1); }
.toast-enter-from { opacity: 0; transform: translateX(20px) scale(0.96); }
.toast-leave-to { opacity: 0; transform: translateX(20px) scale(0.96); }
.toast-move { transition: transform 0.28s cubic-bezier(0.22, 1, 0.36, 1); }
</style>
