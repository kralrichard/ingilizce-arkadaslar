/* 22 Arkadaş — İngilizce konuşma uygulaması */
const S = {
  index: null,      // arkadaş listesi
  friend: null,     // açık olan arkadaşın tüm verisi
  scene: null,      // açık diyalog
  turn: 0,
  showTr: true,
  prog: JSON.parse(localStorage.getItem('arkadaslar-v1') || '{}'),
};

const $ = s => document.querySelector(s);
const el = (t, c, h) => { const n = document.createElement(t); if (c) n.className = c; if (h != null) n.innerHTML = h; return n; };
const esc = s => s.replace(/[&<>]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;' }[c]));
const save = () => localStorage.setItem('arkadaslar-v1', JSON.stringify(S.prog));
const doneCount = id => Object.keys(S.prog[id] || {}).length;

function go(name) {
  document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
  $('#screen-' + name).classList.add('active');
  window.scrollTo(0, 0);
}

/* ---------------- sesli okuma ---------------- */
let voices = [];
const loadVoices = () => { voices = speechSynthesis.getVoices(); };
loadVoices();
speechSynthesis.onvoiceschanged = loadVoices;

function speak(text, lang) {
  if (!window.speechSynthesis) return;
  speechSynthesis.cancel();
  const u = new SpeechSynthesisUtterance(text);
  u.lang = lang || 'en-GB';
  const v = voices.find(x => x.lang.replace('_', '-') === u.lang)
         || voices.find(x => x.lang.startsWith('en'));
  if (v) u.voice = v;
  u.rate = 0.92;
  speechSynthesis.speak(u);
}

/* ---------------- arkadaş listesi ---------------- */
async function boot() {
  const r = await fetch('data/index.json');
  S.index = await r.json();
  $('#listSub').textContent =
    S.index.friends.length + ' arkadaş · ' + S.index.total.toLocaleString('tr-TR') + ' cümle';
  renderFriends('all');

  document.querySelectorAll('#filters .chip').forEach(b => b.onclick = () => {
    document.querySelectorAll('#filters .chip').forEach(x => x.classList.remove('active'));
    b.classList.add('active');
    renderFriends(b.dataset.lvl);
  });
  $('#btnBackChat').onclick = () => { speechSynthesis.cancel(); openFriend(S.friend.id); };
  $('#btnTr').onclick = () => {
    S.showTr = !S.showTr;
    $('#screen-chat').classList.toggle('hide-tr', !S.showTr);
    $('#btnTr').style.opacity = S.showTr ? 1 : .45;
  };
  document.querySelectorAll('.tab').forEach(t => t.onclick = () => {
    document.querySelectorAll('.tab').forEach(x => x.classList.remove('active'));
    document.querySelectorAll('.tabpane').forEach(x => x.classList.remove('active'));
    t.classList.add('active');
    $('#tab-' + t.dataset.tab).classList.add('active');
  });
}

function renderFriends(lvl) {
  const g = $('#friendGrid');
  g.innerHTML = '';
  S.index.friends
    .filter(f => lvl === 'all' || f.level === lvl)
    .forEach(f => {
      const d = doneCount(f.id);
      const c = el('button', 'fcard');
      c.innerHTML =
        `<div class="row">
           <div class="av" style="background:${f.color}22;border:1px solid ${f.color}55">${f.emoji}</div>
           <div><b>${esc(f.name)}</b><div class="meta">${f.age} · ${esc(f.cityTr)}</div></div>
           <span class="lvl" style="margin-left:auto">${f.level}</span>
         </div>
         <div class="meta">${esc(f.jobTr)} · ${esc(f.team)}</div>
         <div class="bio">${esc(f.bio)}</div>
         <div class="bar"><i style="width:${d / 25 * 100}%"></i></div>
         <div class="meta">${d}/25 diyalog</div>`;
      c.onclick = () => openFriend(f.id);
      g.appendChild(c);
    });
}

/* ---------------- arkadaş ekranı ---------------- */
async function openFriend(id) {
  if (!S.friend || S.friend.id !== id) {
    const r = await fetch('data/chars/' + id + '.json');
    S.friend = await r.json();
  }
  const f = S.friend;
  $('#friendHead').innerHTML =
    `<div class="av" style="background:${f.color}22;border:1px solid ${f.color}55">${f.emoji}</div>
     <div><b>${esc(f.full)}</b><span>${f.age} yaşında · ${esc(f.cityTr)} · ${esc(f.jobTr)} · ${f.level}</span></div>`;

  // diyaloglar kategoriye göre
  const list = $('#sceneList');
  list.innerHTML = '';
  let cat = '';
  f.dialogues.forEach((d, i) => {
    if (d.cat !== cat) { cat = d.cat; list.appendChild(el('div', 'cat', esc(cat))); }
    const done = (S.prog[f.id] || {})[d.id];
    const b = el('button', 'scene');
    b.innerHTML =
      `<span class="em">${d.emoji}</span>
       <span class="t"><b>${esc(d.title)}</b><span>${d.turns.length} tur · 40 cümle</span></span>
       <span class="done">${done ? '✓' : ''}</span>`;
    b.onclick = () => startChat(i);
    list.appendChild(b);
  });

  // onu tanı
  const q = $('#qaList');
  q.innerHTML = '';
  f.qa.forEach(x => {
    const n = el('div', 'qitem');
    n.innerHTML =
      `<div class="q">${esc(x.q.en)}<div class="qtr">${esc(x.q.tr)}</div></div>
       <div class="a">${esc(x.a.en)}<div class="atr">${esc(x.a.tr)}</div></div>`;
    n.querySelector('.q').onclick = () => speak(x.q.en, f.voice);
    n.querySelector('.a').onclick = () => speak(x.a.en, f.voice);
    q.appendChild(n);
  });

  go('friend');
}

/* ---------------- sohbet ---------------- */
function startChat(sceneIdx) {
  const f = S.friend;
  S.scene = f.dialogues[sceneIdx];
  S.turn = 0;
  $('#chatHead').innerHTML =
    `<div class="av" style="background:${f.color}22;border:1px solid ${f.color}55">${f.emoji}</div>
     <div><b>${esc(f.name)} · ${esc(S.scene.title)}</b><span>${esc(f.cityTr)} · ${f.level}</span></div>`;
  $('#chatLog').innerHTML = '';
  $('#chatLog').appendChild(el('div', 'intro', esc(S.scene.intro)));
  $('#screen-chat').classList.toggle('hide-tr', !S.showTr);
  go('chat');
  nextTurn();
}

function bubble(side, en, tr, who) {
  const log = $('#chatLog');
  const m = el('div', 'msg ' + side);
  if (who) m.appendChild(el('div', 'who', esc(who)));
  const b = el('div', 'b', esc(en));
  b.onclick = () => speak(en, S.friend.voice);
  m.appendChild(b);
  m.appendChild(el('div', 'tr', esc(tr)));
  log.appendChild(m);
  log.scrollTop = log.scrollHeight;
  return m;
}

function nextTurn() {
  const f = S.friend, sc = S.scene;
  if (S.turn >= sc.turns.length) return finish();

  const t = sc.turns[S.turn];
  bubble('them', t.f.en, t.f.tr, f.name);
  speak(t.f.en, f.voice);

  const box = $('#choices');
  box.innerHTML = '';
  box.appendChild(el('div', 'progress', `Tur ${S.turn + 1} / ${sc.turns.length}`));
  t.o.forEach(o => {
    const b = el('button', 'opt', `${esc(o.en)}<small>${esc(o.tr)}</small>`);
    b.onclick = () => {
      bubble('me', o.en, o.tr, 'Sen');
      S.turn++;
      box.innerHTML = '<div class="progress">…</div>';
      setTimeout(nextTurn, 450);
    };
    box.appendChild(b);
  });
}

function finish() {
  const f = S.friend, sc = S.scene;
  (S.prog[f.id] = S.prog[f.id] || {})[sc.id] = 1;
  save();

  const log = $('#chatLog');
  log.appendChild(el('div', 'intro',
    `✓ <b>${esc(sc.title)}</b> tamamlandı · ${doneCount(f.id)}/25 diyalog`));
  log.scrollTop = log.scrollHeight;

  const idx = f.dialogues.findIndex(d => d.id === sc.id);
  const box = $('#choices');
  box.innerHTML = '';
  if (idx + 1 < f.dialogues.length) {
    const n = el('button', 'btn', `Sıradaki: ${f.dialogues[idx + 1].emoji} ${esc(f.dialogues[idx + 1].title)}`);
    n.onclick = () => startChat(idx + 1);
    box.appendChild(n);
  }
  const again = el('button', 'btn ghost', 'Bu diyaloğu tekrar et');
  again.onclick = () => startChat(idx);
  box.appendChild(again);
  const back = el('button', 'btn ghost', `${esc(f.name)} sayfasına dön`);
  back.onclick = () => openFriend(f.id);
  box.appendChild(back);
}

boot();
