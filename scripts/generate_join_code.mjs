#!/usr/bin/env node
// Yangi mahalla uchun tasodifiy qo'shilish kodi yaratadi va uni
// Firestore konsolida qo'lda kiritish uchun tayyor ko'rinishda chop
// etadi. Mahalla hujjatlari singari (`firestore.rules`dagi izohga
// qarang), qo'shilish kodlari ham hozircha qo'lda/skript orqali
// provisioned qilinadi — admin panelda alohida ekran yo'q.
//
// Format: 1 harf (mahalla nomining bosh harfi, katta) + 7 tasodifiy
// raqam, masalan "Y2345678" ("Y234-5678" qilib ko'rsatiladi).
//
// Ishlatish:
//   node scripts/generate_join_code.mjs <mahallaId> [harf]
//   masalan: node scripts/generate_join_code.mjs yettiguzar
//            node scripts/generate_join_code.mjs yettiguzar Y
//
// [harf] berilmasa, mahallaId'ning birinchi harfi ishlatiladi —
// agar bir nechta mahalla nomi bir xil harfdan boshlansa, kolliziyani
// oldini olish uchun uni qo'lda ko'rsating.

import { randomInt } from 'node:crypto';

const mahallaId = process.argv[2];
if (!mahallaId) {
  console.error('Foydalanish: node generate_join_code.mjs <mahallaId> [harf]');
  process.exit(1);
}

const letter = (process.argv[3] ?? mahallaId[0]).toUpperCase();
if (!/^[A-Z]$/.test(letter)) {
  console.error('Harf lotin alifbosidan bitta belgi bo\'lishi kerak (masalan "Y").');
  process.exit(1);
}

// `randomInt` kriptografik jihatdan xavfsiz (Node crypto) — Math.random()
// dan farqli o'laroq, taxmin qilib bo'lmaydigan qiymat beradi.
const digits = String(randomInt(0, 10_000_000)).padStart(7, '0');
const code = `${letter}${digits}`;
const formatted = `${code.slice(0, 4)}-${code.slice(4)}`;

console.log(`Kod (foydalanuvchiga ko'rsatish uchun): ${formatted}`);
console.log('');
console.log('Firestore konsolida yaratish kerak bo\'lgan hujjat:');
console.log(`  Kolleksiya: joinCodes`);
console.log(`  Hujjat ID:  ${code}`);
console.log(`  Maydon:     mahallaId (string) = "${mahallaId}"`);
console.log('');
console.log('QR SVG uchun:');
console.log(`  node scripts/generate_mahalla_qr.mjs ${code}`);
