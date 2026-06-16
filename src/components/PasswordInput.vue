<template>
  <div class="relative">
    <input
      :type="visible ? 'text' : 'password'"
      :value="modelValue"
      @input="$emit('update:modelValue', $event.target.value)"
      v-bind="$attrs"
      class="input pr-11"
    />
    <button
      type="button"
      tabindex="-1"
      :aria-label="visible ? 'Hide password' : 'Show password (hold)'"
      class="absolute right-2.5 top-1/2 -translate-y-1/2 text-stone-400 hover:text-ink transition-colors"
      @mousedown.prevent="show"
      @mouseup="hide"
      @mouseleave="hide"
      @touchstart.prevent="show"
      @touchend="hide"
      @touchcancel="hide"
    >
      <AppIcon :name="visible ? 'eye-off' : 'eye'" :size="18" />
    </button>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import AppIcon from './AppIcon.vue'

defineOptions({ inheritAttrs: false })
defineProps({ modelValue: { type: String, default: '' } })
defineEmits(['update:modelValue'])

const visible = ref(false)
const show = () => { visible.value = true }
const hide = () => { visible.value = false }
</script>
