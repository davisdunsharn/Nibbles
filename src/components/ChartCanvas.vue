<template>
  <div class="relative" :style="{ height: height }">
    <canvas ref="canvasEl"></canvas>
  </div>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount, watch } from 'vue'
import {
  Chart,
  LineController, BarController, DoughnutController,
  LineElement, PointElement, BarElement, ArcElement,
  CategoryScale, LinearScale, Filler, Tooltip, Legend,
} from 'chart.js'

Chart.register(
  LineController, BarController, DoughnutController,
  LineElement, PointElement, BarElement, ArcElement,
  CategoryScale, LinearScale, Filler, Tooltip, Legend,
)

// Apple-ish global defaults
Chart.defaults.font.family = "'Inter', system-ui, sans-serif"
Chart.defaults.font.size = 12
Chart.defaults.color = '#78716c'
Chart.defaults.plugins.tooltip.backgroundColor = 'rgba(28,25,23,0.92)'
Chart.defaults.plugins.tooltip.padding = 10
Chart.defaults.plugins.tooltip.cornerRadius = 10
Chart.defaults.plugins.tooltip.titleFont = { weight: '600' }
Chart.defaults.plugins.tooltip.displayColors = true
Chart.defaults.plugins.tooltip.boxPadding = 4

const props = defineProps({
  type: { type: String, required: true },
  data: { type: Object, required: true },
  options: { type: Object, default: () => ({}) },
  height: { type: String, default: '280px' },
})

const canvasEl = ref(null)
let chart = null

function build() {
  if (!canvasEl.value) return
  chart = new Chart(canvasEl.value, {
    type: props.type,
    data: props.data,
    options: {
      responsive: true,
      maintainAspectRatio: false,
      animation: { duration: 600, easing: 'easeOutQuart' },
      ...props.options,
    },
  })
}

onMounted(build)
onBeforeUnmount(() => { if (chart) chart.destroy() })

watch(() => [props.data, props.options], () => {
  if (!chart) return
  chart.data = props.data
  chart.options = { responsive: true, maintainAspectRatio: false, ...props.options }
  chart.update()
}, { deep: true })
</script>
