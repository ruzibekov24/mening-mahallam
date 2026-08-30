// Mening Mahallam — APK yuklab olish Worker'i.
//
// R2 bucket'ining o'zi ochiq qilinmagan; fayllar faqat shu Worker
// orqali beriladi. Shu sabab havola barqaror bo'ladi va biz to'g'ri
// sarlavhalarni (fayl turi, nomi, keshlash, qismli yuklash) hamda
// yuklab olishlar sonini o'zimiz nazorat qilamiz.

const ALLOWED = new Set([
  // Universal — barcha protsessorlar uchun kod ichida. Xavfsiz
  // zaxira: telefon turini aniqlab bo'lmasa shu beriladi.
  'mening-mahallam.apk',
  // Protsessorga mos, ikki barobar yengil variantlar. Sayt telefonni
  // aniqlab, shulardan birini taklif qiladi.
  'mening-mahallam-arm64.apk',
  'mening-mahallam-arm32.apk',
  'mening-mahallam-eski.apk',
  // Sinov uchun: saytda havola berilmaydi, faqat qo'lda ochiladi.
  'mening-mahallam-v105-test.apk',
]);

// Yuklab olishlar hisobiga QO'SHILMAYDIGAN fayllar. Sinov build'ini
// o'zimiz bir necha marta yuklab olamiz — bu aholi statistikasini
// buzmasligi kerak.
const NOT_COUNTED = new Set([
  'mening-mahallam-v105-test.apk',
]);

const SITE_URL = 'https://mening-mahallam.pages.dev/';

const CORS = {
  'access-control-allow-origin': '*',
  'access-control-allow-methods': 'GET, HEAD, OPTIONS',
};

/// Yuklab olishlar hisoblagichi. Durable Object bitta oqimda
/// ishlagani uchun "o'qib-yozish" poygasi bo'lmaydi — KV'da bir
/// vaqtda kelgan ikki yuklash bir-birining hisobini o'chirib
/// yuborardi.
export class Counter {
  constructor(state) {
    this.state = state;
  }

  async fetch(request) {
    const { pathname } = new URL(request.url);
    if (pathname === '/bump') {
      const n = ((await this.state.storage.get('n')) || 0) + 1;
      await this.state.storage.put('n', n);
      return Response.json({ n });
    }
    return Response.json({ n: (await this.state.storage.get('n')) || 0 });
  }
}

function counterStub(env) {
  return env.COUNTER.get(env.COUNTER.idFromName('downloads'));
}

export default {
  async fetch(request, env, ctx) {
    const { pathname } = new URL(request.url);
    const key = decodeURIComponent(pathname.replace(/^\/+/, ''));

    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: CORS });
    }

    // Sayt hisoblagichni shu manzildan o'qiydi.
    if (key === 'count') {
      const res = await counterStub(env).fetch('https://c/');
      const { n } = await res.json();
      return Response.json(
        { downloads: n },
        { headers: { ...CORS, 'cache-control': 'public, max-age=60' } },
      );
    }

    if (!key) {
      return Response.redirect(SITE_URL, 302);
    }

    // Faqat ro'yxatdagi fayllar beriladi — bucket'dagi boshqa
    // narsalar tasodifan ochilib qolmasligi uchun.
    if (!ALLOWED.has(key)) {
      return new Response('Topilmadi', { status: 404, headers: CORS });
    }

    // Range faqat brauzer haqiqatan so'raganda ishlatiladi. Aks holda
    // oddiy so'rovga ham 206 qaytib, ba'zi yuklovchilarni chalg'itadi.
    const hasRange = request.headers.has('range');
    const object = await env.DOWNLOADS.get(key, {
      ...(hasRange ? { range: request.headers } : {}),
      onlyIf: request.headers,
    });

    if (object === null) {
      return new Response('Topilmadi', { status: 404, headers: CORS });
    }

    // Hisoblagich: faqat to'liq GET so'rovlari sanaladi. HEAD
    // (brauzer tekshiruvi) va Range (uzilgan yuklashni davom
    // ettirish) sanalmaydi — aks holda bitta yuklash bir necha marta
    // hisoblanib ketardi.
    if (
      request.method === 'GET' &&
      !hasRange &&
      object.body &&
      !NOT_COUNTED.has(key)
    ) {
      ctx.waitUntil(counterStub(env).fetch('https://c/bump'));
    }

    const headers = new Headers(CORS);
    object.writeHttpMetadata(headers);
    headers.set('etag', object.httpEtag);
    headers.set('content-type', 'application/vnd.android.package-archive');
    headers.set('content-disposition', `attachment; filename="${key}"`);
    headers.set('cache-control', 'public, max-age=3600');
    headers.set('accept-ranges', 'bytes');

    // Shartli so'rov mos kelmasa, R2 tanasiz obyekt qaytaradi.
    if (!object.body) {
      return new Response(null, { status: 304, headers });
    }

    if (hasRange && object.range) {
      const { offset = 0, length = object.size - offset } = object.range;
      headers.set(
        'content-range',
        `bytes ${offset}-${offset + length - 1}/${object.size}`,
      );
      return new Response(object.body, { status: 206, headers });
    }

    headers.set('content-length', String(object.size));
    return new Response(object.body, { status: 200, headers });
  },
};
