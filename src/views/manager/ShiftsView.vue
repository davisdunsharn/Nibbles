<template>
  <div class="h-full overflow-auto bg-transparent">
    <div class="p-8">
      <div class="flex flex-wrap items-center justify-between gap-4 mb-6">
        <div>
          <h1 class="font-display text-3xl font-semibold text-ink tracking-tight">Weekly Shift Schedule</h1>
          <p class="text-ink-muted text-sm mt-1">{{ branchName || 'Your branch' }} · staff rota &amp; clock-in</p>
        </div>
        <div class="flex items-center gap-2">
          <button @click="generateStandardWeek" :disabled="busy" class="btn-secondary">
            <AppIcon name="calendar" :size="16" /> Generate standard week
          </button>
          <button @click="openCreate()" class="btn-primary">
            <AppIcon name="plus" :size="16" :stroke-width="2.25" /> Add shift
          </button>
        </div>
      </div>

      <!-- Week navigation -->
      <div class="flex items-center justify-between mb-4">
        <button @click="weekOffset--" class="btn-ghost"><AppIcon name="chevron-up" :size="16" class="-rotate-90" /> Prev</button>
        <div class="text-sm font-medium text-ink-soft">
          Week of {{ fmtRange }}
          <button v-if="weekOffset !== 0" @click="weekOffset = 0" class="ml-2 text-brand-600 hover:text-brand-700 text-xs font-semibold">Today</button>
        </div>
        <button @click="weekOffset++" class="btn-ghost">Next <AppIcon name="chevron-down" :size="16" class="-rotate-90" /></button>
      </div>

      <!-- Schedule grid -->
      <div class="card overflow-x-auto">
        <table class="w-full text-sm min-w-[640px]">
          <thead>
            <tr class="border-b border-stone-100 bg-stone-50/60">
              <th class="px-4 py-3 text-left font-medium text-ink-muted w-32">Day</th>
              <th v-for="m in staff" :key="m.id" class="px-4 py-3 text-left font-medium text-ink-muted">
                {{ m.first_name }} {{ m.last_name }}
                <span class="block text-[11px] font-normal capitalize text-stone-400">{{ m.role }}</span>
              </th>
              <th v-if="staff.length === 0" class="px-4 py-3 text-left font-medium text-ink-muted">Staff</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-stone-50">
            <tr v-for="d in weekDays" :key="d.date" :class="d.isToday ? 'bg-brand-50/40' : ''">
              <td class="px-4 py-3 align-top">
                <p class="font-medium text-ink">{{ d.label }}</p>
                <p class="text-xs text-ink-muted">{{ d.dom }}</p>
                <span v-if="d.isToday" class="badge-warning mt-1">Today</span>
              </td>
              <td v-for="m in staff" :key="m.id + d.date" class="px-4 py-3 align-top">
                <button
                  @click="cellClick(m, d)"
                  class="w-full text-left rounded-lg px-2.5 py-2 transition-colors"
                  :class="shiftFor(m.id, d.date) ? 'bg-stone-50 hover:bg-stone-100' : 'hover:bg-stone-50'"
                >
                  <template v-if="shiftFor(m.id, d.date)">
                    <span class="text-sm font-medium text-ink tabular-nums">{{ hhmm(shiftFor(m.id, d.date).planned_start) }}–{{ hhmm(shiftFor(m.id, d.date).planned_end) }}</span>
                    <span :class="statusBadge(shiftFor(m.id, d.date).status)" class="mt-1 block w-fit capitalize">{{ label(shiftFor(m.id, d.date).status) }}</span>
                  </template>
                  <span v-else class="text-xs font-medium text-stone-400">OFF</span>
                </button>
              </td>
              <td v-if="staff.length === 0" class="px-4 py-3 text-ink-muted text-sm">No staff for this branch.</td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Today: clock in / out -->
      <div class="card mt-5 p-6">
        <h3 class="font-semibold text-ink mb-4 flex items-center gap-2"><AppIcon name="clock" :size="18" class="text-brand-500" /> Today's clock-in</h3>
        <div v-if="todaysShifts.length === 0" class="text-ink-muted text-sm">No shifts scheduled for today.</div>
        <div v-else class="space-y-2">
          <div v-for="s in todaysShifts" :key="s.id" class="flex flex-wrap items-center justify-between gap-3 p-3 bg-stone-50 rounded-xl">
            <div class="flex items-center gap-3">
              <span class="w-9 h-9 rounded-full bg-brand-600/90 text-white text-xs font-semibold flex items-center justify-center">{{ initials(s) }}</span>
              <div>
                <p class="text-sm font-medium text-ink">{{ staffName(s) }}</p>
                <p class="text-xs text-ink-muted tabular-nums">
                  {{ hhmm(s.planned_start) }}–{{ hhmm(s.planned_end) }}
                  <span v-if="s.actual_clock_in"> · in {{ time(s.actual_clock_in) }}</span>
                  <span v-if="s.actual_clock_out"> · out {{ time(s.actual_clock_out) }}</span>
                </p>
              </div>
            </div>
            <div class="flex items-center gap-2">
              <span :class="statusBadge(s.status)" class="capitalize">{{ label(s.status) }}</span>
              <button v-if="s.status === 'scheduled'" @click="clockIn(s)" class="btn-primary py-1.5 px-3 text-xs">Clock in</button>
              <button v-else-if="s.status === 'in_progress'" @click="clockOut(s)" class="btn bg-emerald-600 text-white hover:bg-emerald-700 py-1.5 px-3 text-xs">Clock out</button>
              <button v-if="s.status === 'scheduled'" @click="markAbsent(s)" class="btn-ghost py-1.5 px-2 text-xs">Absent</button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Create / Edit modal -->
    <div v-if="showForm" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 px-4">
      <div class="card p-6 w-full max-w-sm">
        <div class="flex items-start justify-between mb-4">
          <h2 class="font-display text-xl font-semibold text-ink">{{ editId ? 'Edit Shift' : 'Add Shift' }}</h2>
          <button v-if="editId" @click="confirmDelete" class="text-red-600 hover:text-red-700 text-xs font-semibold">Delete</button>
        </div>
        <form @submit.prevent="confirmSave" class="space-y-4">
          <div>
            <label class="label">Staff member</label>
            <select v-model="form.staff_id" required class="input">
              <option value="">Select staff</option>
              <option v-for="u in staff" :key="u.id" :value="u.id">{{ u.first_name }} {{ u.last_name }} ({{ u.role }})</option>
            </select>
          </div>
          <div><label class="label">Date</label><input v-model="form.shift_date" type="date" required class="input" /></div>
          <div class="grid grid-cols-2 gap-3">
            <div><label class="label">Start</label><input v-model="form.planned_start" type="time" required class="input" /></div>
            <div><label class="label">End</label><input v-model="form.planned_end" type="time" required class="input" /></div>
          </div>
          <div v-if="editId">
            <label class="label">Status</label>
            <select v-model="form.status" class="input"><option v-for="s in STATUSES" :key="s" :value="s">{{ label(s) }}</option></select>
          </div>
          <div v-if="formError" class="p-3 bg-red-50 border border-red-100 rounded-xl text-red-600 text-sm">{{ formError }}</div>
          <div class="flex gap-3 pt-1">
            <button type="button" @click="showForm = false" class="btn-secondary flex-1">Cancel</button>
            <button type="submit" :disabled="busy" class="btn-primary flex-1">{{ busy ? 'Saving…' : (editId ? 'Save' : 'Add') }}</button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted } from 'vue'
import { useAuthStore } from '../../stores/auth'
import { supabase } from '../../lib/supabase'
import AppIcon from '../../components/AppIcon.vue'
import { useToast } from '../../composables/useToast'

const toast = useToast()
const auth = useAuthStore()
const STATUSES = ['scheduled', 'in_progress', 'completed', 'absent', 'late']

// Standard role templates (the "standard" — OFF days are everything not listed).
const TEMPLATES = {
  manager: { days: [1, 2, 3, 4, 5], start: '08:00', end: '16:00' },          // Mon–Fri
  cashier: { days: [1, 2, 5, 6, 0], start: '06:30', end: '15:00' },          // Mon,Tue,Fri,Sat,Sun
}

const shifts = ref([])
const staff = ref([])
const branchName = ref('')
const busy = ref(false)
const formError = ref('')
const weekOffset = ref(0)

const showForm = ref(false)
const editId = ref(null)
const form = ref({ staff_id: '', shift_date: '', planned_start: '', planned_end: '', status: 'scheduled' })

const label = (s) => (s || '').replace(/_/g, ' ')
const hhmm = (t) => (t ? t.slice(0, 5) : '')
const time = (t) => new Date(t).toLocaleTimeString('en-ZA', { hour: '2-digit', minute: '2-digit' })
const todayStr = () => new Date().toISOString().slice(0, 10)

function mondayOf(offset) {
  const d = new Date()
  d.setHours(0, 0, 0, 0)
  const diff = (d.getDay() + 6) % 7 // 0 = Monday
  d.setDate(d.getDate() - diff + offset * 7)
  return d
}
const weekStart = computed(() => mondayOf(weekOffset.value))
const weekDays = computed(() => {
  const out = []
  const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
  for (let i = 0; i < 7; i++) {
    const d = new Date(weekStart.value); d.setDate(d.getDate() + i)
    const ds = d.toISOString().slice(0, 10)
    out.push({ date: ds, label: names[i], dom: d.toLocaleDateString('en-ZA', { day: '2-digit', month: 'short' }), isToday: ds === todayStr() })
  }
  return out
})
const fmtRange = computed(() => {
  const a = weekDays.value[0], b = weekDays.value[6]
  return `${a.dom} – ${b.dom}`
})

const shiftMap = computed(() => {
  const m = {}
  shifts.value.forEach(s => { m[`${s.staff_id}|${s.shift_date}`] = s })
  return m
})
const shiftFor = (staffId, date) => shiftMap.value[`${staffId}|${date}`]
const todaysShifts = computed(() => shifts.value.filter(s => s.shift_date === todayStr()))

const staffName = (s) => {
  const u = staff.value.find(x => x.id === s.staff_id)
  return u ? `${u.first_name} ${u.last_name}` : '—'
}
const initials = (s) => {
  const u = staff.value.find(x => x.id === s.staff_id)
  return u ? `${u.first_name[0]}${u.last_name[0]}`.toUpperCase() : '—'
}
function statusBadge(s) {
  return {
    scheduled: 'badge bg-sky-50 text-sky-700',
    in_progress: 'badge bg-violet-50 text-violet-700',
    completed: 'badge-success',
    absent: 'badge-danger',
    late: 'badge-warning',
  }[s] || 'badge-neutral'
}

function openCreate(prefill = {}) {
  formError.value = ''
  editId.value = null
  form.value = {
    staff_id: prefill.staff_id || '',
    shift_date: prefill.shift_date || todayStr(),
    planned_start: '08:00',
    planned_end: '16:00',
    status: 'scheduled',
  }
  showForm.value = true
}
function openEdit(s) {
  formError.value = ''
  editId.value = s.id
  form.value = { staff_id: s.staff_id, shift_date: s.shift_date, planned_start: hhmm(s.planned_start), planned_end: hhmm(s.planned_end), status: s.status }
  showForm.value = true
}
function cellClick(member, day) {
  const s = shiftFor(member.id, day.date)
  if (s) openEdit(s)
  else openCreate({ staff_id: member.id, shift_date: day.date })
}

async function loadStaff() {
  const { data } = await supabase.from('user_profiles').select('id, first_name, last_name, role').eq('branch_id', auth.branchId).order('role')
  staff.value = data || []
}
async function load() {
  const start = weekDays.value[0].date, end = weekDays.value[6].date
  const { data } = await supabase
    .from('shifts')
    .select('id, staff_id, shift_date, planned_start, planned_end, actual_clock_in, actual_clock_out, status')
    .eq('branch_id', auth.branchId)
    .gte('shift_date', start)
    .lte('shift_date', end)
  shifts.value = data || []
}
watch(weekOffset, load)

async function confirmSave() {
  busy.value = true; formError.value = ''
  try {
    const payload = { staff_id: form.value.staff_id, shift_date: form.value.shift_date, planned_start: form.value.planned_start, planned_end: form.value.planned_end, status: form.value.status }
    if (editId.value) {
      const { error } = await supabase.from('shifts').update(payload).eq('id', editId.value)
      if (error) throw error
    } else {
      const { error } = await supabase.from('shifts').insert({ ...payload, branch_id: auth.branchId, created_by: auth.user.id })
      if (error) throw error
    }
    showForm.value = false
    await load()
    toast.success(editId.value ? 'Shift updated' : 'Shift scheduled')
  } catch (err) { formError.value = err.message; toast.error(err.message) } finally { busy.value = false }
}
async function confirmDelete() {
  if (!editId.value) return
  busy.value = true
  try {
    const { error } = await supabase.from('shifts').delete().eq('id', editId.value)
    if (error) throw error
    showForm.value = false
    await load()
    toast.success('Shift deleted')
  } catch (err) { formError.value = err.message; toast.error(err.message) } finally { busy.value = false }
}

async function patch(s, fields, msg) {
  const { error } = await supabase.from('shifts').update(fields).eq('id', s.id)
  if (error) { console.error(error); toast.error(error.message); return }
  await load()
  if (msg) toast.success(msg)
}
const clockIn = (s) => patch(s, { actual_clock_in: new Date().toISOString(), status: 'in_progress' }, `${staffName(s)} clocked in`)
const clockOut = (s) => patch(s, { actual_clock_out: new Date().toISOString(), status: 'completed' }, `${staffName(s)} clocked out`)
const markAbsent = (s) => patch(s, { status: 'absent' }, `${staffName(s)} marked absent`)

async function generateStandardWeek() {
  busy.value = true
  try {
    const rows = []
    for (const m of staff.value) {
      const tpl = TEMPLATES[m.role]
      if (!tpl) continue
      for (const day of weekDays.value) {
        const dowSun = new Date(day.date).getDay() // 0=Sun..6=Sat
        if (!tpl.days.includes(dowSun)) continue
        rows.push({
          staff_id: m.id, branch_id: auth.branchId, shift_date: day.date,
          planned_start: tpl.start, planned_end: tpl.end, status: 'scheduled',
          notes: 'std-week', created_by: auth.user.id,
        })
      }
    }
    if (rows.length) {
      const { error } = await supabase.from('shifts').upsert(rows, { onConflict: 'staff_id,shift_date,planned_start', ignoreDuplicates: true })
      if (error) throw error
    }
    await load()
    toast.success('Standard week generated')
  } catch (err) { console.error('Generate week error:', err); toast.error(err.message) } finally { busy.value = false }
}

onMounted(async () => {
  if (auth.branchId) {
    const { data } = await supabase.from('branches').select('name').eq('id', auth.branchId).single()
    if (data) branchName.value = data.name.trim()
  }
  await loadStaff()
  await load()
})
</script>
