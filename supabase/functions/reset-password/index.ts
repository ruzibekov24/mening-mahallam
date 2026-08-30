// supabase/functions/reset-password/index.ts
//
// "Parolni unutdim" oqimining oxirgi qadami. Telefon raqam Telegram
// bot orqali allaqachon tasdiqlangan (phone_verifications.status ==
// "verified") — bu funksiya shu tasdiqni token orqali tekshiradi va
// Firebase Admin SDK (FIREBASE_SERVICE_ACCOUNT secret, send-push
// funksiyasi bilan bir xil) orqali foydalanuvchining parolini
// yangilaydi. Client SDK bunga qodir emas — boshqa foydalanuvchining
// parolini eskisini bilmasdan yangilash uchun Admin huquqi kerak.
//
// Token bir martalik: muvaffaqiyatli almashtirilgandan keyin
// "expired" deb belgilanadi, qayta ishlatib bo'lmaydi.

import { cert, getApps, initializeApp } from "npm:firebase-admin@12/app";
import { getAuth } from "npm:firebase-admin@12/auth";
import { createClient } from "npm:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const serviceAccountJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");

if (serviceAccountJson && getApps().length === 0) {
  initializeApp({
    credential: cert(JSON.parse(serviceAccountJson)),
  });
}

// Client tomondagi `_phoneToPseudoEmail` bilan AYNAN bir xil formula
// (lib/features/auth/data/auth_repository.dart) — faqat raqamlar +
// "@mahallam.uz".
function phoneToPseudoEmail(rawPhone: string): string {
  const digitsOnly = rawPhone.replace(/[^0-9]/g, "");
  return `${digitsOnly}@mahallam.uz`;
}

function jsonResponse(body: unknown, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (!serviceAccountJson) {
    return jsonResponse(
      { error: "FIREBASE_SERVICE_ACCOUNT sozlanmagan (Supabase secret)" },
      500,
    );
  }

  try {
    const { token, newPassword } = await req.json();

    if (typeof token !== "string" || !token) {
      return jsonResponse({ error: "token kerak" }, 400);
    }
    if (typeof newPassword !== "string" || newPassword.length < 6) {
      return jsonResponse(
        { error: "Parol kamida 6 ta belgidan iborat bo'lishi kerak" },
        400,
      );
    }

    const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

    const { data, error } = await supabase
      .from("phone_verifications")
      .select("phone, status")
      .eq("token", token)
      .maybeSingle();

    if (error || !data) {
      return jsonResponse({ error: "Token topilmadi" }, 400);
    }
    if (data.status !== "verified") {
      return jsonResponse(
        { error: "Telefon raqam hali tasdiqlanmagan" },
        400,
      );
    }

    const pseudoEmail = phoneToPseudoEmail(data.phone as string);

    let uid: string;
    try {
      const userRecord = await getAuth().getUserByEmail(pseudoEmail);
      uid = userRecord.uid;
    } catch (_e) {
      return jsonResponse(
        { error: "Bu raqamga mos foydalanuvchi topilmadi" },
        404,
      );
    }

    await getAuth().updateUser(uid, { password: newPassword });

    // Token qayta ishlatilmasin.
    await supabase
      .from("phone_verifications")
      .update({ status: "expired" })
      .eq("token", token);

    return jsonResponse({ success: true }, 200);
  } catch (e) {
    console.error(e);
    return jsonResponse({ error: "Kutilmagan xatolik" }, 500);
  }
});
