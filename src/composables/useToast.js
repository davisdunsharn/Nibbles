import { reactive } from 'vue'

const state = reactive({ toasts: [] })
let counter = 0

function push(type, message, opts = {}) {
  const id = ++counter
  state.toasts.push({ id, type, message })
  const duration = opts.duration ?? (type === 'error' ? 5000 : 3200)
  setTimeout(() => remove(id), duration)
  return id
}

function remove(id) {
  const i = state.toasts.findIndex((t) => t.id === id)
  if (i > -1) state.toasts.splice(i, 1)
}

export function useToast() {
  return {
    toasts: state.toasts,
    success: (m, o) => push('success', m, o),
    error: (m, o) => push('error', m, o),
    info: (m, o) => push('info', m, o),
    remove,
  }
}
