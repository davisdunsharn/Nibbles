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

    const supabaseUrl = Deno.env.get("SUPABASE_URL")
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")
    if (!supabaseUrl || !supabaseServiceKey) throw new Error("Missing Supabase environment variables")
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Verify the caller is a signed-in admin (not just any authenticated user).
    const token = authHeader.replace("Bearer ", "")
    const { data: { user: caller } } = await supabase.auth.getUser(token)
    if (!caller) return json({ error: "Invalid session" }, 401)
    const { data: callerProfile } = await supabase.from("user_profiles").select("role").eq("id", caller.id).single()
    if (callerProfile?.role !== "admin") return json({ error: "Admin access required" }, 403)

    const { email, password, first_name, last_name, role, branch_id } = await req.json()

    const { data: authData, error: authError } = await supabase.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
    })
    if (authError) throw new Error(`Auth error: ${authError.message}`)

    const { error: profileError } = await supabase.from("user_profiles").insert({
      id: authData.user.id,
      first_name,
      last_name,
      role,
      branch_id: branch_id || null,
      is_active: true,
      created_by: caller.id,
    })

    if (profileError) {
      await supabase.auth.admin.deleteUser(authData.user.id)
      throw new Error(`Profile error: ${profileError.message}`)
    }

    return json({ success: true, user: authData.user }, 201)
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
