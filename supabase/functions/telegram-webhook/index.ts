// supabase/functions/telegram-webhook/index.ts
//
// Telegram bot har bir xabarni shu manzilga yuboradi (webhook orqali
// sozlanadi).
//
// XAVFSIZLIK — MUHIM.
//
// Oldingi versiyada bot "/start <token>" kelishi bilan raqamni
// TASDIQLANGAN deb belgilardi. Bu telefon egaligini umuman
// isbotlamasdi: havolani OCHGAN HAR QANDAY Telegram hisobi —
// butunlay boshqa raqamdagi hisob ham — tasdiqni o'tkazib yuborardi.
//
// Amaliy oqibati og'ir edi:
//   * qo'shnisining raqami bilan ro'yxatdan o'tish mumkin edi;
//   * "parolni unutdim" oqimi ham xuddi shu tokenga ishonadi, ya'ni
//     istalgan raqam egasining hisobini egallab olish mumkin edi.
//
// Endi tasdiq faqat foydalanuvchi Telegram'ning O'Z "kontaktni
// yuborish" tugmasi orqali raqamini ulashgandagina beriladi va
// quyidagi ikki shart TEKSHIRILADI:
//
//   1. contact.user_id === message.from.id
//      Telegram kontakt kartochkasini boshqa odamnikini ham yuborishga
//      ruxsat beradi. Faqat `user_id` yuboruvchining o'ziga teng
//      bo'lgandagina raqam haqiqatan shu hisobga tegishli bo'ladi.
//
//   2. Ulashilgan raqam token yaratilganda kiritilgan raqam bilan
//      bir xil bo'lishi shart.
//
// Ikkalasidan biri bajarilmasa — tasdiq berilmaydi.

import { createClient } from "npm:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const BOT_TOKEN = Deno.env.get("TELEGRAM_BOT_TOKEN")!;

async function callTelegram(method: string, payload: unknown) {
  await fetch(`https://api.telegram.org/bot${BOT_TOKEN}/${method}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
}

function sendMessage(chatId: number, text: string, replyMarkup?: unknown) {
  return callTelegram("sendMessage", {
    chat_id: chatId,
    text,
    ...(replyMarkup ? { reply_markup: replyMarkup } : {}),
  });
}

/// Faqat raqamlarni qoldiradi: "+998 90 123-45-67" -> "998901234567".
function digitsOnly(value: string): string {
  return value.replace(/\D/g, "");
}

/// Ikki raqam bir xilmi.
///
/// Telegram raqamni goh "+998...", goh "998..." ko'rinishida beradi,
/// ba'zi operatorlarda esa mamlakat kodisiz kelishi mumkin. Shuning
/// uchun taqqoslash oxirgi 9 raqam bo'yicha amalga oshadi — bu
/// O'zbekiston raqamlari uchun yagona (operator kodi + 7 raqam).
function samePhone(a: string, b: string): boolean {
  const da = digitsOnly(a);
  const db = digitsOnly(b);
  if (da.length < 9 || db.length < 9) return false;
  return da.slice(-9) === db.slice(-9);
}

const askContactKeyboard = {
  keyboard: [[{ text: "📱 Raqamimni yuborish", request_contact: true }]],
  resize_keyboard: true,
  one_time_keyboard: true,
};

Deno.serve(async (req) => {
  try {
    const update = await req.json();
    const message = update?.message;
    const chatId: number | undefined = message?.chat?.id;

    if (!chatId) return new Response("ok", { status: 200 });

    const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

    // ----------------------------------------------------------------
    // 1-bosqich: "/start <token>" — tokenni tekshiramiz va raqamni
    // SO'RAYMIZ (hali tasdiqlamaymiz).
    // ----------------------------------------------------------------
    const text: string | undefined = message?.text;
    if (text) {
      const match = text.match(/^\/start\s+([0-9a-fA-F-]{36})$/);

      if (!match) {
        await sendMessage(
          chatId,
          'Salom! Bu bot "Mening Mahallam" ilovasida telefon raqamingizni ' +
            'tasdiqlash uchun ishlatiladi. Ilovada "Telegram orqali ' +
            'tasdiqlash" tugmasini bosing.',
        );
        return new Response("ok", { status: 200 });
      }

      const token = match[1];

      const { data: verification, error: fetchError } = await supabase
        .from("phone_verifications")
        .select("token, status, expires_at")
        .eq("token", token)
        .maybeSingle();

      if (fetchError || !verification) {
        await sendMessage(
          chatId,
          "Havola noto'g'ri yoki eskirgan. Ilovaga qaytib qayta urinib ko'ring.",
        );
        return new Response("ok", { status: 200 });
      }

      if (new Date(verification.expires_at) < new Date()) {
        await sendMessage(
          chatId,
          "Havola muddati tugagan. Ilovaga qaytib qayta urinib ko'ring.",
        );
        return new Response("ok", { status: 200 });
      }

      if (verification.status === "verified") {
        await sendMessage(chatId, "✅ Bu raqam allaqachon tasdiqlangan. Ilovaga qayting.");
        return new Response("ok", { status: 200 });
      }

      // Shu suhbatning qaysi tokenga tegishli ekanini eslab qolamiz —
      // keyingi qadamda kelgan kontaktni aynan shu token bilan
      // solishtiramiz. Eslatib qo'yamiz: `status` HALI "pending".
      const { error: bindError } = await supabase
        .from("phone_verifications")
        .update({ chat_id: chatId })
        .eq("token", token);

      if (bindError) {
        console.error(bindError);
        await sendMessage(chatId, "Xatolik yuz berdi. Qayta urinib ko'ring.");
        return new Response("ok", { status: 200 });
      }

      await sendMessage(
        chatId,
        "Raqamingizni tasdiqlash uchun pastdagi tugmani bosing.\n\n" +
          "Faqat SHU Telegram hisobiga biriktirilgan raqam qabul qilinadi — " +
          "ilovada kiritgan raqamingiz bilan bir xil bo'lishi kerak.",
        askContactKeyboard,
      );
      return new Response("ok", { status: 200 });
    }

    // ----------------------------------------------------------------
    // 2-bosqich: foydalanuvchi kontaktini ulashdi — ASOSIY TEKSHIRUV.
    // ----------------------------------------------------------------
    const contact = message?.contact;
    if (!contact) return new Response("ok", { status: 200 });

    const fromId: number | undefined = message?.from?.id;

    // Boshqa odamning kontakt kartochkasi yuborilgan bo'lsa —
    // `user_id` yuboruvchiga teng bo'lmaydi (yoki umuman bo'lmaydi).
    if (!contact.user_id || !fromId || contact.user_id !== fromId) {
      await sendMessage(
        chatId,
        "❌ Faqat O'ZINGIZNING raqamingizni yuborishingiz mumkin.\n\n" +
          'Pastdagi "📱 Raqamimni yuborish" tugmasidan foydalaning.',
        askContactKeyboard,
      );
      return new Response("ok", { status: 200 });
    }

    // Shu suhbatga biriktirilgan, hali tasdiqlanmagan so'rovni topamiz.
    const { data: verification } = await supabase
      .from("phone_verifications")
      .select("token, phone, status, expires_at")
      .eq("chat_id", chatId)
      .eq("status", "pending")
      // Eng yangi so'rov — eng kech tugaydigani. `created_at`
      // o'rniga `expires_at` ishlatiladi, chunki bu ustun
      // yuqorida ham o'qilyapti, ya'ni mavjudligi aniq.
      .order("expires_at", { ascending: false })
      .limit(1)
      .maybeSingle();

    if (!verification) {
      await sendMessage(
        chatId,
        "Avval ilovadagi \"Telegram orqali tasdiqlash\" tugmasini bosing.",
        { remove_keyboard: true },
      );
      return new Response("ok", { status: 200 });
    }

    if (new Date(verification.expires_at) < new Date()) {
      await sendMessage(
        chatId,
        "Havola muddati tugagan. Ilovaga qaytib qayta urinib ko'ring.",
        { remove_keyboard: true },
      );
      return new Response("ok", { status: 200 });
    }

    // ENG MUHIM TEKSHIRUV: ulashilgan raqam ilovada kiritilgan raqam
    // bilan bir xilmi.
    if (!samePhone(contact.phone_number ?? "", verification.phone)) {
      await sendMessage(
        chatId,
        "❌ Telegram hisobingizdagi raqam ilovada kiritgan raqamdan " +
          "farq qiladi.\n\nIlovaga qayting va aynan shu Telegram " +
          "hisobiga biriktirilgan raqamni kiriting.",
        { remove_keyboard: true },
      );
      return new Response("ok", { status: 200 });
    }

    const { error: updateError } = await supabase
      .from("phone_verifications")
      // ESLATMA: bu yerda ataylab FAQAT mavjudligi aniq bo'lgan
      // ustunlar yangilanadi. Yo'q ustunga yozilsa so'rov xato
      // qaytaradi va tasdiqlash butunlay ishlamay qoladi. Telegram
      // hisobi identifikatori allaqachon `chat_id`da saqlangan
      // (1-bosqichda yozilgan).
      .update({
        status: "verified",
        verified_at: new Date().toISOString(),
      })
      .eq("token", verification.token)
      // Poyga holatida ikki marta tasdiqlanmasligi uchun.
      .eq("status", "pending");

    if (updateError) {
      console.error(updateError);
      await sendMessage(chatId, "Xatolik yuz berdi. Qayta urinib ko'ring.");
      return new Response("ok", { status: 200 });
    }

    await sendMessage(
      chatId,
      "✅ Raqamingiz tasdiqlandi!\n\nIlovaga qaytishingiz mumkin — bu " +
        "oynani yopsangiz ham bo'ladi, ilova avtomatik davom etadi.",
      { remove_keyboard: true },
    );

    return new Response("ok", { status: 200 });
  } catch (e) {
    console.error(e);
    // Telegram xato holatida ham 200 qaytarishni talab qiladi,
    // aks holda webhook'ni qayta-qayta urinib, spam qiladi.
    return new Response("ok", { status: 200 });
  }
});
