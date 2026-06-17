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
    if (!authHeader) {
      return json({ error: "Missing authorization header" }, 401)
    }

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

    // Deleting the auth user cascades to user_profiles (FK ON DELETE CASCADE).
    const { error } = await admin.auth.admin.deleteUser(id)
    if (error) throw new Error(error.message)

    return json({ success: true }, 200)
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
