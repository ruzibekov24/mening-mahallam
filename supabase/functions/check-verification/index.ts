// supabase/functions/check-verification/index.ts
//
// Ilova bu manzilni har 2 soniyada so'rab, foydalanuvchi Telegram'da
// /start bosganmi-yo'qmi tekshiradi.

import { createClient } from "npm:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const url = new URL(req.url);
    const token = url.searchParams.get("token");

    if (!token) {
      return new Response(
        JSON.stringify({ error: "token kerak" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

    const { data, error } = await supabase
      .from("phone_verifications")
      .select("status, expires_at")
      .eq("token", token)
      .maybeSingle();

    if (error || !data) {
      return new Response(
        JSON.stringify({ status: "not_found" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const isExpired = new Date(data.expires_at) < new Date() && data.status === "pending";

    return new Response(
      JSON.stringify({ status: isExpired ? "expired" : data.status }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (e) {
    console.error(e);
    return new Response(
      JSON.stringify({ error: "Kutilmagan xatolik" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
