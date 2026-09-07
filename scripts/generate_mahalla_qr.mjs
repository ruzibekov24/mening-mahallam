#!/usr/bin/env node
// Berilgan qo'shilish kodi (masalan "12345678") uchun `landing/mahallalar.json`
// formatiga mos QR SVG ma'lumotini (`n` viewBox o'lchami, `d` path) chop etadi.
//
// Ishlatish:
//   node scripts/generate_mahalla_qr.mjs 12345678
//
// Natijani `landing/mahallalar.json`dagi tegishli mahalla yozuvining
// "n" va "d" maydonlariga qo'lda joylashtiring.
//
// Eslatma: bu skript `qrcode` npm paketiga bog'liq — `scripts/`
// papkasida `npm install` qilingan bo'lishi kerak (`scripts/node_modules`
// git'ga qo'shilmaydi, shuning uchun birinchi ishlatishdan oldin
// `cd scripts && npm install` bajaring).

import QRCode from 'qrcode';

const code = process.argv[2];
if (!code) {
  console.error('Foydalanish: node generate_mahalla_qr.mjs <kod, masalan 12345678>');
  process.exit(1);
}

const qr = QRCode.create(code, { errorCorrectionLevel: 'M' });
const { size, data } = qr.modules;

// Mavjud mahallalar.json namunalari bilan bir xil: har tomondan 4
// modul chegara (quiet zone) qo'shiladi.
const margin = 4;
const n = size + margin * 2;

const isDark = (x, y) => data[y * size + x] === 1;

// Har bir qatordagi qorong'u modul "yugurishlarini" (runs) bitta
// to'rtburchakka birlashtirib, `Mx yhWv1h-Wz` shaklidagi SVG path
// buyrug'iga aylantiradi — landing/mahallalar.json'dagi mavjud
// formatning aynan o'zi.
const commands = [];
for (let y = 0; y < size; y++) {
  let runStart = -1;
  for (let x = 0; x <= size; x++) {
    const dark = x < size && isDark(x, y);
    if (dark && runStart === -1) {
      runStart = x;
    } else if (!dark && runStart !== -1) {
      const width = x - runStart;
      const px = runStart + margin;
      const py = y + margin;
      commands.push(`M${px} ${py}h${width}v1h-${width}z`);
      runStart = -1;
    }
  }
}

console.log(JSON.stringify({ n, d: commands.join('') }, null, 2));
