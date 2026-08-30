// supabase/functions/send-push/index.ts
//
// Flutter ilova tomonidan chaqiriladi (notification_repository.dart)
// — har safar yangi e'lon/tadbir joylanganda yoki murojaat holati
// o'zgarganda. Firebase Cloud Functions o'rniga shu yerda ishlashining
// sababi: loyiha hozircha Firebase Spark (bepul) planda, Cloud
// Functions esa Blaze (pullik) plan talab qiladi. FCM push
// yuborishning o'zi PULLIK EMAS — faqat Cloud Functions'ning ishga
// tushishi (compute) pullik. Supabase Edge Functions bepul planida
// push yuborish uchun bemalol yetarli.
//
// Xavfsizlik: bu funksiya `FIREBASE_SERVICE_ACCOUNT` maxfiy o'zgaruvchisi
// (Supabase secret, hech qachon client kodga qo'shilmaydi) orqali
// Firebase Admin sifatida FCM'ga ulanadi. Client faqat o'z tokenlarini
// va xabar matnini yuboradi — service account kaliti hech qachon
// qurilmaga tushmaydi.

import { cert, getApps, initializeApp } from "npm:firebase-admin@12/app";
import { getMessaging } from "npm:firebase-admin@12/messaging";

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

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (!serviceAccountJson) {
    return new Response(
      JSON.stringify({
        error: "FIREBASE_SERVICE_ACCOUNT sozlanmagan (Supabase secret)",
      }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  try {
    const { tokens, title, body, data } = await req.json();

    if (!Array.isArray(tokens) || tokens.length === 0) {
      return new Response(JSON.stringify({ error: "tokens bo'sh" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
    if (typeof title !== "string" || typeof body !== "string") {
      return new Response(
        JSON.stringify({ error: "title/body noto'g'ri" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // FCM bitta so'rovda 500 tokengacha qabul qiladi — kichik mahalla
    // hajmida bu chegaraga yetish deyarli mumkin emas, lekin
    // xavfsizlik uchun bo'laklarga bo'lamiz.
    const chunks: string[][] = [];
    for (let i = 0; i < tokens.length; i += 500) {
      chunks.push(tokens.slice(i, i + 500));
    }

    const messaging = getMessaging();
    let successCount = 0;
    let failureCount = 0;

    for (const chunk of chunks) {
      const response = await messaging.sendEachForMulticast({
        tokens: chunk,
        notification: { title, body },
        data: data
          ? Object.fromEntries(
            Object.entries(data).map(([k, v]) => [k, String(v)]),
          )
          : undefined,
        android: { priority: "high" },
        apns: { headers: { "apns-priority": "10" } },
      });
      successCount += response.successCount;
      failureCount += response.failureCount;
    }

    return new Response(
      JSON.stringify({ successCount, failureCount }),
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
