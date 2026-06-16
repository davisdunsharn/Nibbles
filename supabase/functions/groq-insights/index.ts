import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

// Server-side Groq call. Keeps GROQ_API_KEY out of the browser bundle.
// Deploy:  supabase functions deploy groq-insights
// Secret:  supabase secrets set GROQ_API_KEY=gsk_...
serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders })

  try {
    // Require an authenticated caller (the app sends the user's JWT automatically).
    if (!req.headers.get("Authorization")) {
      return new Response(JSON.stringify({ error: "Missing authorization header" }), {
        status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" },
      })
    }

    const apiKey = Deno.env.get("GROQ_API_KEY")
    if (!apiKey) throw new Error("GROQ_API_KEY secret is not set")

    const { salesContext } = await req.json()

    const prompt = `You are a business analyst for Nibbles Bakery, a multi-branch bakery in Durban, South Africa.

Based on the following sales data from our system:
${salesContext || "(no sales data provided)"}

Please provide:
1. DEMAND FORECAST: Which products are likely to need restocking soon and by how much
2. BUSINESS INSIGHTS: What the sales patterns tell us about customer behaviour
3. RECOMMENDATIONS: 2-3 specific actions the owner should take this week
4. RISK FLAGS: Any products that seem to be underperforming

Keep it practical and specific to a bakery business. Be concise but detailed.`

    const resp = await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      headers: { "Content-Type": "application/json", "Authorization": `Bearer ${apiKey}` },
      body: JSON.stringify({
        model: "llama-3.3-70b-versatile",
        messages: [{ role: "user", content: prompt }],
        max_tokens: 800,
        temperature: 0.7,
      }),
    })
    const data = await resp.json()
    if (data.error) throw new Error(data.error.message)

    return new Response(JSON.stringify({ result: data.choices[0].message.content }), {
      status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" },
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
    })
  }
})
