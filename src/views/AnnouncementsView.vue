<template>
  <div class="h-full overflow-auto bg-transparent">
    <div class="p-8 max-w-3xl mx-auto">
      <div class="flex items-center justify-between mb-6">
        <div>
          <h1 class="font-display text-3xl font-semibold text-ink tracking-tight">Announcements</h1>
          <p class="text-ink-muted text-sm mt-1">Team noticeboard — company &amp; branch updates</p>
        </div>
        <button v-if="canPost" @click="showPost = !showPost" class="btn-primary">
          <AppIcon name="plus" :size="16" :stroke-width="2.25" /> New post
        </button>
      </div>

      <!-- Composer (admin/manager) -->
      <div v-if="canPost && showPost" class="card p-5 mb-5">
        <form @submit.prevent="post" class="space-y-3">
          <input v-model="form.title" type="text" required placeholder="Title" class="input" />
          <textarea v-model="form.body" required rows="3" placeholder="Write an announcement for the team…" class="input resize-none"></textarea>
          <div class="flex flex-wrap items-center gap-3">
            <select v-model="form.audience" class="input w-auto">
              <option value="all">Everyone (all branches)</option>
              <option v-if="auth.branchId" value="branch">My branch only</option>
            </select>
            <label class="flex items-center gap-2 text-sm text-ink-soft">
              <input v-model="form.is_pinned" type="checkbox" class="w-4 h-4 accent-brand-600 rounded" /> Pin to top
            </label>
            <div class="flex-1"></div>
            <button type="button" @click="showPost = false" class="btn-secondary">Cancel</button>
            <button type="submit" :disabled="busy" class="btn-primary">{{ busy ? 'Posting…' : 'Post' }}</button>
          </div>
        </form>
      </div>

      <!-- Feed -->
      <div v-if="loading" class="text-ink-muted text-sm py-10 text-center">Loading…</div>
      <div v-else-if="items.length === 0" class="card p-10 text-center text-ink-muted text-sm">No announcements yet.</div>
      <div v-else class="space-y-4">
        <div v-for="a in items" :key="a.id" class="card card-hover p-5">
          <div class="flex items-start justify-between gap-3">
            <div class="flex items-center gap-2 flex-wrap">
              <span v-if="a.is_pinned" class="badge-warning"><AppIcon name="alert" :size="12" /> Pinned</span>
              <h3 class="font-semibold text-ink">{{ a.title }}</h3>
            </div>
            <button v-if="canDelete(a)" @click="remove(a)" class="text-stone-400 hover:text-red-500 transition-colors flex-shrink-0" title="Delete">
              <AppIcon name="x" :size="16" />
            </button>
          </div>
          <p class="text-sm text-ink-soft mt-2 whitespace-pre-wrap leading-relaxed">{{ a.body }}</p>
          <div class="flex items-center gap-2 mt-3 text-xs text-ink-muted">
            <span class="w-6 h-6 rounded-full bg-brand-600/90 text-white text-[10px] font-semibold flex items-center justify-center">{{ initials(a.author_name) }}</span>
            <span class="font-medium text-ink-soft">{{ a.author_name || 'Management' }}</span>
            <span>·</span>
            <span>{{ timeAgo(a.created_at) }}</span>
            <span :class="a.audience === 'branch' ? 'badge bg-sky-50 text-sky-700' : 'badge-neutral'" class="ml-1">
              {{ a.audience === 'branch' ? 'Branch' : 'All branches' }}
            </span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useAuthStore } from '../stores/auth'
import { supabase } from '../lib/supabase'
import AppIcon from '../components/AppIcon.vue'
import { useToast } from '../composables/useToast'

const auth = useAuthStore()
const toast = useToast()
const items = ref([])
const loading = ref(true)
const busy = ref(false)
const showPost = ref(false)
const form = ref({ title: '', body: '', audience: 'all', is_pinned: false })

const canPost = computed(() => ['admin', 'manager'].includes(auth.role))
const canDelete = (a) => auth.role === 'admin' || a.author_id === auth.user?.id

const initials = (name) => (name || 'NB').split(' ').map(w => w[0]).slice(0, 2).join('').toUpperCase()
function timeAgo(ts) {
  const m = Math.round((Date.now() - new Date(ts).getTime()) / 60000)
  if (m < 1) return 'just now'
  if (m < 60) return `${m}m ago`
  const h = Math.round(m / 60)
  if (h < 24) return `${h}h ago`
  return `${Math.round(h / 24)}d ago`
}

async function load() {
  loading.value = true
  const { data } = await supabase.from('announcements')
    .select('*')
    .order('is_pinned', { ascending: false })
    .order('created_at', { ascending: false })
  items.value = data || []
  loading.value = false
}

async function post() {
  busy.value = true
  try {
    const { error } = await supabase.from('announcements').insert({
      title: form.value.title,
      body: form.value.body,
      author_id: auth.user.id,
      author_name: auth.fullName,
      audience: form.value.audience,
      branch_id: form.value.audience === 'branch' ? auth.branchId : null,
      is_pinned: form.value.is_pinned,
    })
    if (error) throw error
    form.value = { title: '', body: '', audience: 'all', is_pinned: false }
    showPost.value = false
    await load()
    toast.success('Announcement posted')
  } catch (err) { toast.error(err.message) } finally { busy.value = false }
}

async function remove(a) {
  if (!confirm('Delete this announcement?')) return
  const { error } = await supabase.from('announcements').delete().eq('id', a.id)
  if (error) { toast.error(error.message); return }
  await load()
  toast.success('Announcement deleted')
}

onMounted(load)
</script>
