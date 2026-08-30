/* Inersiyali silliq skroll.
 *
 * Brauzerning sichqoncha g'ildiragi odatda sahifani zinapoyasimon, keskin
 * siljitadi. Bu yerda g'ildirak hodisasini o'zimiz qabul qilib, "maqsad"
 * nuqtasini yangilaymiz, joriy holat esa har kadrda maqsad tomon bir oz
 * yaqinlashadi (lerp). Natijada ko'p aylantirilsa ham sahifa og'ir va
 * silliq siljiydi, so'ng asta to'xtaydi.
 *
 * Ataylab tegilmaydigan holatlar:
 *   - sensorli ekranlar: ularda tizimning o'z inersiyasi bor, aralashish
 *     faqat buzadi;
 *   - "harakatni kamaytirish" yoqilgan foydalanuvchilar;
 *   - modal oyna ochiq payt (body scroll bloklangan);
 *   - Ctrl+g'ildirak (masshtab).
 */
(function () {
  var mm = window.matchMedia;
  if (!mm) return;
  if (mm('(prefers-reduced-motion: reduce)').matches) return;
  if (!mm('(pointer: fine)').matches) return;          // sensorli qurilma emas
  if (!('requestAnimationFrame' in window)) return;

  var EASE = 0.082;   // kichikroq = og'irroq va uzoqroq siljiydi
  var STEP = 1.0;     // g'ildirak qadamining kuchi
  var STOP = 0.4;     // shu masofadan keyin to'xtatamiz (px)

  var target = window.scrollY;
  var current = target;
  var running = false;

  function limit() {
    return Math.max(0, document.documentElement.scrollHeight - window.innerHeight);
  }

  function clamp(v, a, b) { return v < a ? a : (v > b ? b : v); }

  function frame() {
    var diff = target - current;
    if (Math.abs(diff) < STOP) {
      current = target;
      window.scrollTo(0, Math.round(current));
      running = false;
      return;
    }
    current += diff * EASE;
    window.scrollTo(0, Math.round(current));
    requestAnimationFrame(frame);
  }

  function start() {
    if (running) return;
    running = true;
    current = window.scrollY;
    requestAnimationFrame(frame);
  }

  /* Ichida o'z skrolli bor element ustida bo'lsak, sahifani emas, o'sha
     elementni siljitish kerak — aralashmaymiz. */
  function insideScrollable(node) {
    while (node && node !== document.body && node !== document.documentElement) {
      if (node.scrollHeight > node.clientHeight + 2) {
        var ov = getComputedStyle(node).overflowY;
        if (ov === 'auto' || ov === 'scroll') return true;
      }
      node = node.parentElement;
    }
    return false;
  }

  window.addEventListener('wheel', function (e) {
    if (e.ctrlKey) return;                                  // masshtab
    if (document.body.style.overflow === 'hidden') return;  // modal ochiq
    if (e.deltaMode !== 0 && e.deltaMode !== 1) return;
    if (insideScrollable(e.target)) return;

    var d = e.deltaY;
    if (e.deltaMode === 1) d *= 18;                         // qator birligida kelsa

    e.preventDefault();
    target = clamp(target + d * STEP, 0, limit());
    start();
  }, { passive: false });

  /* Klaviatura, anchor havolalar yoki skriptdan kelgan siljishni
     kuzatib boramiz — aks holda keyingi g'ildirakda sahifa sakrab ketadi. */
  window.addEventListener('scroll', function () {
    if (!running) {
      current = window.scrollY;
      target = current;
    }
  }, { passive: true });

  window.addEventListener('resize', function () {
    target = clamp(target, 0, limit());
  }, { passive: true });

  /* Sahifa ichidagi havolalar ham shu inersiya bilan borsin. */
  document.addEventListener('click', function (e) {
    var a = e.target.closest && e.target.closest('a[href^="#"]');
    if (!a) return;
    var id = a.getAttribute('href').slice(1);
    if (!id) return;
    var el = document.getElementById(id);
    if (!el) return;
    e.preventDefault();
    var top = el.getBoundingClientRect().top + window.scrollY;
    target = clamp(top, 0, limit());
    start();
    if (history.replaceState) history.replaceState(null, '', '#' + id);
  });
})();
