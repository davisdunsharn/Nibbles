import { createApp } from 'vue'
import { createPinia } from 'pinia'
import router from './router'
import { useAuthStore } from './stores/auth'
import './style.css'
import App from './App.vue'

const app = createApp(App)
const pinia = createPinia()
app.use(pinia)
app.use(router)

const auth = useAuthStore()
// Always mount, even if startup auth fails — the app falls back to /login
// rather than showing a blank screen on a fresh device.
auth.init().finally(() => { app.mount('#app') })
