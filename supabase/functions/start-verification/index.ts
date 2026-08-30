// supabase/functions/start-verification/index.ts
//
// Ilova telefon raqamini yuborganda chaqiriladi. Yangi tasdiqlash
// yozuvi (token) yaratadi va uni qaytaradi. Ilova shu token bilan
// Telegram deep link hosil qiladi va keyin holatni shu token orqali
// so'raydi.

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
    const { phone } = await req.json();

    if (!phone || typeof phone !== "string" || !/^\+998\d{9}$/.test(phone)) {
      return new Response(
        JSON.stringify({ error: "Telefon raqam formati noto'g'ri" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

    // Shu raqam uchun eski, hali tasdiqlanmagan tokenlarni bekor qilamiz
    // (foydalanuvchi bir necha marta urinsa, eskilari chalkashmasin).
    await supabase
      .from("phone_verifications")
      .update({ status: "expired" })
      .eq("phone", phone)
      .eq("status", "pending");

    const { data, error } = await supabase
      .from("phone_verifications")
      .insert({ phone })
      .select("token")
      .single();

    if (error || !data) {
      console.error(error);
      return new Response(
        JSON.stringify({ error: "Tasdiqlash boshlanmadi, qayta urinib ko'ring" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    return new Response(
      JSON.stringify({ token: data.token }),
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
