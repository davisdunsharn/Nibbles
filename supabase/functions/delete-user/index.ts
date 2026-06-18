import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders })

  try {
    const authHeader = req.headers.get("Authorization")
    if (!authHeader) return json({ error: "Missing authorization header" }, 401)

    const url = Deno.env.get("SUPABASE_URL")
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")
    if (!url || !serviceKey) throw new Error("Missing Supabase environment variables")
    const admin = createClient(url, serviceKey)

    // Verify the caller is a signed-in admin.
    const token = authHeader.replace("Bearer ", "")
    const { data: { user: caller } } = await admin.auth.getUser(token)
    if (!caller) return json({ error: "Invalid session" }, 401)
    const { data: callerProfile } = await admin.from("user_profiles").select("role").eq("id", caller.id).single()
    if (callerProfile?.role !== "admin") return json({ error: "Admin access required" }, 403)

    const { id } = await req.json()
    if (!id) return json({ error: "Missing user id" }, 400)
    if (id === caller.id) return json({ error: "You cannot delete your own account" }, 400)

    // Try a full delete first. This cascades to user_profiles, but is blocked
    // by NOT NULL references (transactions.cashier_id, shifts.staff_id, etc.).
    const { error: delErr } = await admin.auth.admin.deleteUser(id)

    if (delErr) {
      // The user has linked records (sales, shifts, orders). Deleting them would
      // destroy business/audit history, so deactivate instead — they can no longer
      // log in, but their records stay intact.
      const { error: upErr } = await admin.from("user_profiles").update({ is_active: false }).eq("id", id)
      if (upErr) throw new Error(upErr.message)
      // Best-effort: revoke their sessions so they're logged out immediately.
      try { await admin.auth.admin.signOut(id, "global") } catch (_) { /* ignore */ }
      return json({
        success: true,
        deactivated: true,
        message: "This user has linked records (sales, shifts or orders), so they were deactivated to preserve history rather than permanently deleted.",
      }, 200)
    }

    return json({ success: true, deleted: true }, 200)
  } catch (error) {
    return json({ error: error.message }, 400)
  }
})

function json(body: unknown, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  })
}
