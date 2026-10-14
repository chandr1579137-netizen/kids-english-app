/* 英语小伙伴网页预览：对照 cursor/kids-ui-flow-7e0f 的 SwiftUI 页面。 */
(function () {
  const DATA = window.PREVIEW_DATA;
  const words = DATA.words;
  const lessons = DATA.lessons;
  const themes = DATA.themes;
  const songs = DATA.songs;
  const wordBy = {};
  words.forEach((w) => { wordBy[w.word.toLowerCase()] = w; });

  const THEME_ICON = {
    fruits: "theme-apple", animals: "theme-cat", vehicles: "theme-car",
    colors: "theme-palette", numbers: "theme-abacus", body: "theme-hand",
    foods: "theme-burger", family: "theme-house", stationery: "theme-stationery",
    toys: "theme-teddy", nature: "theme-tree", home: "theme-house",
    places: "theme-pin", time: "theme-clock", actions: "theme-runner",
    adjectives: "theme-sparkles", functions: "theme-puzzle", others: "theme-dots",
  };
  const THEME_COLOR = {
    fruits: "#ffb5c2", animals: "#4cb04f", vehicles: "#9c59b5", colors: "#2b80ff",
    numbers: "#ffcc33", body: "#ff9966", foods: "#ff8c59", family: "#66b3ff",
    nature: "#59bf80", time: "#8c80e6", stationery: "#73a6ff", toys: "#ffa68c",
    home: "#a68cd9", places: "#66ccbf", actions: "#ffb34d", adjectives: "#bf8cff",
    functions: "#8099b3", others: "#9ea3b3",
  };
  const GAMES = [
    { id: "wordToImage", name: "看词选图", icon: "game-lookword", diff: "简单", color: "rgb(92,156,255)", tint: "rgba(92,156,255,0.35)" },
    { id: "audioToImage", name: "听音选图", icon: "game-listenimage", diff: "简单", color: "rgb(125,212,145)", tint: "rgba(125,212,145,0.35)" },
    { id: "matching", name: "配对消除", icon: "game-match", diff: "中等", color: "rgb(179,135,255)", tint: "rgba(179,135,255,0.35)" },
    { id: "wordToAudio", name: "看词选音", icon: "game-wordaudio", diff: "简单", color: "rgb(255,184,77)", tint: "rgba(255,184,77,0.35)" },
    { id: "imageToWord", name: "看图选词", icon: "game-imageword", diff: "中等", color: "rgb(245,143,176)", tint: "rgba(245,143,176,0.35)" },
    { id: "audioToWord", name: "听音选词", icon: "game-audioword", diff: "中等", color: "rgb(77,209,224)", tint: "rgba(77,209,224,0.35)" },
    { id: "audioToMeaning", name: "听音选义", icon: "game-audiomeaning", diff: "中等", color: "rgb(255,214,79)", tint: "rgba(255,214,79,0.35)" },
    { id: "wordToMeaning", name: "看词选义", icon: "game-wordmeaning", diff: "简单", color: "rgb(255,138,128)", tint: "rgba(255,138,128,0.35)" },
    { id: "dictation", name: "听写训练", icon: "game-dictation", diff: "中等", color: "rgb(61,89,255)", tint: "rgba(61,89,255,0.35)" },
  ];

  const today = new Date().toISOString().slice(0, 10);
  const shot = new URLSearchParams(location.search).get("shot");

  const state = {
    tab: "learn",
    stacks: { learn: [], cards: [], read: [], books: [], profile: [] },
    themeId: null,
    dailyNew: 10,
    learned: new Set(),
    completed: new Set(),
    gameCorrect: 0,
    gameAnswered: 0,
    studyDates: [today],
    limit: 20,
    showCn: true,
    menu: false,
    study: null,
    dir: 1,
    sheet: null,
    songId: null,
    songLine: -1,
    parent: { a: 18, b: 27, answer: "", wrong: false, open: false },
  };

  function loadStore() {
    try {
      const raw = JSON.parse(localStorage.getItem("kids-preview-v1") || "null");
      if (!raw) return;
      state.themeId = raw.themeId || null;
      state.dailyNew = raw.dailyNew || 10;
      state.learned = new Set(raw.learned || []);
      state.completed = new Set(raw.completed || []);
      state.gameCorrect = raw.gameCorrect || 0;
      state.gameAnswered = raw.gameAnswered || 0;
      state.studyDates = raw.studyDates && raw.studyDates.length ? raw.studyDates : [today];
      state.limit = raw.limit ?? 20;
      state.showCn = raw.showCn !== false;
    } catch (e) { /* 第一次打开 */ }
  }
  function saveStore() {
    if (shot) return;
    localStorage.setItem("kids-preview-v1", JSON.stringify({
      themeId: state.themeId,
      dailyNew: state.dailyNew,
      learned: [...state.learned],
      completed: [...state.completed],
      gameCorrect: state.gameCorrect,
      gameAnswered: state.gameAnswered,
      studyDates: state.studyDates,
      limit: state.limit,
      showCn: state.showCn,
    }));
  }
  if (!shot) loadStore();
  if (!state.studyDates.includes(today)) state.studyDates.push(today);

  function esc(s) {
    return String(s ?? "").replace(/[&<>"']/g, (c) => ({
      "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;",
    }[c]));
  }
  function iconURL(name) {
    return "icons/" + name + ".png";
  }
  function img(name, alt) {
    return `<img src="${iconURL(name)}" alt="${esc(alt || "")}">`;
  }
  function svg(path, size) {
    const s = size || 18;
    return `<svg width="${s}" height="${s}" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">${path}</svg>`;
  }
  const I = {
    book: svg('<path d="M5 4.5A2.5 2.5 0 0 1 7.5 2H20v17H7.5A2.5 2.5 0 0 0 5 21.5V4.5z"/><path d="M5 19.2A2.5 2.5 0 0 1 7.5 17H20v5H7.5A2.5 2.5 0 0 1 5 19.5v-.3z"/>'),
    cards: svg('<path d="M7 6h12a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2z"/><path d="M4 8.5 7.2 5.8A2 2 0 0 1 9.7 5.6L17 8" opacity=".55"/>'),
    read: svg('<path d="M4 5.5A2.5 2.5 0 0 1 6.5 3H12v16H6.5A2.5 2.5 0 0 0 4 21.5V5.5z"/><path d="M20 5.5A2.5 2.5 0 0 0 17.5 3H12v16h5.5a2.5 2.5 0 0 1 2.5 2.5V5.5z"/>'),
    books: svg('<path d="M3 6h5a3 3 0 0 1 3 3v11a3 3 0 0 0-3-3H3V6z"/><path d="M21 6h-5a3 3 0 0 0-3 3v11a3 3 0 0 1 3-3h5V6z"/>'),
    person: svg('<path d="M12 12a4 4 0 1 0-4-4 4 4 0 0 0 4 4zm0 2c-4 0-7 2-7 4.5V21h14v-2.5C19 16 16 14 12 14z"/>'),
    chevL: svg('<path d="M15.5 4.5 8 12l7.5 7.5-1.6 1.6L4.8 12l9.1-9.1z"/>', 20),
    chevR: svg('<path d="M8.5 4.5 16 12l-7.5 7.5 1.6 1.6L19.2 12 10.1 2.9z"/>', 16),
    speaker: svg('<path d="M4 9h3.2L12 5.2v13.6L7.2 15H4z"/><path d="M15 8.5a4.5 4.5 0 0 1 0 7" fill="none" stroke="currentColor" stroke-width="2"/><path d="M17.2 6a8 8 0 0 1 0 12" fill="none" stroke="currentColor" stroke-width="2"/>', 22),
    check: svg('<path d="M9.2 16.6 4.6 12l-1.6 1.6 6.2 6.2L21 7.9 19.4 6.3z"/>', 26),
    play: svg('<path d="M8 5v14l12-7z"/>', 20),
    lock: svg('<path d="M7 10V7a5 5 0 0 1 10 0v3h1.5A1.5 1.5 0 0 1 20 11.5v8A1.5 1.5 0 0 1 18.5 21h-13A1.5 1.5 0 0 1 4 19.5v-8A1.5 1.5 0 0 1 5.5 10zm2 0h6V7a3 3 0 0 0-6 0z"/>', 20),
    music: svg('<path d="M9 17.5a2.5 2.5 0 1 1-2-2.45V6l12-2v9.1a2.5 2.5 0 1 1-2-2.45V6.2L9 7.7v9.8z"/>', 22),
    gear: svg('<path d="M12 8.2A3.8 3.8 0 1 0 15.8 12 3.8 3.8 0 0 0 12 8.2z"/><path d="M19.4 13.2a7.7 7.7 0 0 0 .1-2.4l2-1.2-2-3.4-2.2.7a8 8 0 0 0-2-1.2L14.8 3h-5.6l-.5 2.7a8 8 0 0 0-2 1.2l-2.2-.7-2 3.4 2 1.2a7.7 7.7 0 0 0 .1 2.4l-2 1.2 2 3.4 2.2-.7a8 8 0 0 0 2 1.2l.5 2.7h5.6l.5-2.7a8 8 0 0 0 2-1.2l2.2.7 2-3.4z"/>', 22),
    clock: svg('<path d="M12 2a10 10 0 1 0 10 10A10 10 0 0 0 12 2zm1 11h-4V6h2v5h2z"/>', 22),
    cal: svg('<path d="M7 2h2v2h6V2h2v2h3v16H4V4h3zm11 8H6v8h12z"/>', 16),
    flame: svg('<path d="M12 2s6 6 6 11a6 6 0 0 1-12 0c0-2 1.2-4 2.4-5.4C9.2 10 10 12 12 12c0-3 0-6 0-10z"/>', 16),
    chart: svg('<path d="M4 20V10h3v10zm6.5 0V4h3v16zM17 20v-7h3v7z"/>', 20),
    target: svg('<circle cx="12" cy="12" r="8" fill="none" stroke="currentColor" stroke-width="2"/><circle cx="12" cy="12" r="3"/>', 22),
    bookClosed: svg('<path d="M6 3h12a2 2 0 0 1 2 2v14l-8-2-8 2V5a2 2 0 0 1 2-2z"/>', 22),
    checkBig: svg('<path d="M12 2a10 10 0 1 0 10 10A10 10 0 0 0 12 2zm-1.2 14.2-4-4 1.4-1.4 2.6 2.6 5.6-5.6 1.4 1.4z"/>', 120),
  };

  function wordsForBook() {
    if (!state.themeId) return words.slice();
    const theme = themes.find((t) => t.id === state.themeId);
    if (!theme) return [];
    return theme.words.map((w) => wordBy[w.toLowerCase()]).filter(Boolean);
  }
  const THEME_ORDER = [
    "fruits", "animals", "colors", "numbers", "body", "family", "foods", "vehicles",
    "home", "nature", "toys", "stationery", "places", "time", "actions", "adjectives",
    "functions", "others",
  ];
  const themeRank = {};
  THEME_ORDER.forEach((id, tier) => {
    const theme = themes.find((t) => t.id === id);
    if (!theme) return;
    theme.words.forEach((word, index) => {
      const key = word.toLowerCase();
      if (themeRank[key] == null) themeRank[key] = { tier, index };
    });
  });

  function planDays() {
    let pool;
    if (state.themeId) {
      pool = wordsForBook().filter((w) => !state.learned.has(w.word.toLowerCase()));
    } else {
      pool = words
        .filter((w) => !state.learned.has(w.word.toLowerCase()))
        .slice()
        .sort((a, b) => {
          const ra = themeRank[a.word.toLowerCase()] || { tier: 900, index: 0 };
          const rb = themeRank[b.word.toLowerCase()] || { tier: 900, index: 0 };
          if (ra.tier !== rb.tier) return ra.tier - rb.tier;
          if (ra.index !== rb.index) return ra.index - rb.index;
          return (a.level || 1) - (b.level || 1);
        });
    }
    const size = Math.max(1, state.dailyNew);
    const days = [];
    for (let i = 0; i < pool.length; i += size) days.push(pool.slice(i, i + size));
    return days;
  }
  function themeWords(id) {
    const theme = themes.find((t) => t.id === id);
    if (!theme) return [];
    return theme.words.map((w) => wordBy[w.toLowerCase()]).filter(Boolean);
  }
  function themeDone(id) {
    const list = themeWords(id);
    return list.filter((w) => state.learned.has(w.word.toLowerCase())).length;
  }
  function unlocked(lesson) {
    const idx = lessons.findIndex((l) => l.id === lesson.id);
    if (idx <= 0) return true;
    return state.completed.has(lessons[idx - 1].id);
  }
  function streak() {
    const set = new Set(state.studyDates);
    const d = new Date();
    const key = (dt) => dt.toISOString().slice(0, 10);
    if (!set.has(key(d))) d.setDate(d.getDate() - 1);
    if (!set.has(key(d))) return 0;
    let n = 0;
    while (set.has(key(d))) { n += 1; d.setDate(d.getDate() - 1); }
    return n;
  }
  function accuracy() {
    if (!state.gameAnswered) return "—";
    return Math.round(state.gameCorrect / state.gameAnswered * 100) + "%";
  }
  function stack() { return state.stacks[state.tab]; }
  function top() { const s = stack(); return s[s.length - 1] || null; }

  let speakTimer = 0;
  function speak(text, slow) {
    if (!window.speechSynthesis || !text) return;
    window.speechSynthesis.cancel();
    const u = new SpeechSynthesisUtterance(text);
    u.lang = "en-US";
    u.rate = slow ? 0.75 : 1;
    window.speechSynthesis.speak(u);
  }
  function stopSpeak() {
    if (window.speechSynthesis) window.speechSynthesis.cancel();
    clearTimeout(speakTimer);
  }

  function coverEmoji(lesson) {
    let best = null;
    (lesson.content || []).forEach((p) => {
      (p.words || []).forEach((raw) => {
        const key = String(raw).toLowerCase().replace(/[^a-z'-]/g, "");
        const rank = themeRank[key];
        const entry = wordBy[key];
        if (!entry || !entry.emoji || !rank || rank.tier >= 14) return;
        if (!best || rank.tier < best.tier) best = { tier: rank.tier, emoji: entry.emoji };
      });
    });
    return best ? best.emoji : "📖";
  }
  function cover(lesson, cls) {
    const emoji = typeof lesson === "string" ? lesson : coverEmoji(lesson);
    return `<div class="cover ${cls || ""}">${esc(emoji)}</div>`;
  }
  function face(entry) {
    const pic = `<div class="emoji">${esc(entry.emoji || "🌟")}</div>`;
    const ph = entry.phonetic ? `<p class="phonetic">${esc(entry.phonetic)}</p>` : "";
    return `<div class="flash ${state.dir >= 0 ? "slide-next" : "slide-prev"}">
      <div class="pic">${pic}</div>
      <p class="word">${esc(entry.word)}</p>
      ${ph}
      <p class="meaning">${esc(entry.meaningCn)}</p>
    </div>`;
  }

  function statusBar() {
    return `<div class="status"><span>9:41</span><span class="sys">
      ${svg('<path d="M2 16h2v4H2zm4-3h2v7H6zm4-3h2v10h-2zm4-3h2v13h-2z"/>', 16)}
      ${svg('<path d="M12 18a1.5 1.5 0 1 0 1.5 1.5A1.5 1.5 0 0 0 12 18zm-5.2-2.2 1.4 1.4a5.5 5.5 0 0 1 7.6 0l1.4-1.4a7.5 7.5 0 0 0-10.4 0zM4 13l1.4 1.4a9.5 9.5 0 0 1 13.2 0L20 13a11.5 11.5 0 0 0-16 0z"/>', 16)}
      ${svg('<rect x="2" y="7" width="18" height="10" rx="2" fill="none" stroke="currentColor" stroke-width="2"/><rect x="4" y="9" width="12" height="6"/><rect x="21" y="10" width="1.6" height="4" rx=".4"/>', 22)}
    </span></div>`;
  }
  function tabbar() {
    const tabs = [
      ["learn", "背单词", I.book],
      ["cards", "单词卡", I.cards],
      ["read", "读短文", I.read],
      ["books", "绘本", I.books],
      ["profile", "我的", I.person],
    ];
    return `<nav class="tabbar">${tabs.map(([id, title, glyph]) =>
      `<button class="tab press ${state.tab === id ? "on" : ""}" data-act="tab" data-tab="${id}">
        <span class="glyph">${glyph}</span><span>${title}</span>
      </button>`).join("")}</nav>`;
  }

  function homeHTML() {
    const todayWords = planDays()[0] || [];
    const day = Math.floor(state.learned.size / Math.max(1, state.dailyNew)) + 1;
    const books = [
      { id: "", title: "全部单词", sub: words.length + " 词", color: "var(--blue)", icon: "book" },
      { id: "fruits", title: "水果篇", sub: themeWords("fruits").length + " 词", color: "var(--pink)", icon: "strawberry" },
      { id: "animals", title: "动物篇", sub: themeWords("animals").length + " 词", color: "var(--green)", icon: "panda" },
      { id: "vehicles", title: "交通工具", sub: themeWords("vehicles").length + " 词", color: "var(--purple)", icon: "bus" },
    ];
    return `<div class="pane"><div class="scroll"><div class="stack-18">
      <div class="plan">
        <div>
          <div class="kicker">今日计划</div>
          <h2>Day ${day}</h2>
          <div class="sub">新学 ${todayWords.length} 个词</div>
          <div class="meta">已学 ${state.learned.size} / ${words.length}</div>
        </div>
        ${img("rocket", "火箭")}
      </div>
    </div>
    <h3 class="section">选词书</h3>
    <div class="books">${books.map((b) => {
      const on = (state.themeId || "") === b.id;
      return `<button class="book press ${on ? "selected" : ""}" style="background:${b.color}" data-act="book" data-id="${b.id}">
        ${img(b.icon, b.title)}<b>${b.title}</b><small>${b.sub}</small>
      </button>`;
    }).join("")}</div>
    <div style="height:14px"></div>
    <button class="big green press" data-act="start">开始学习 ▶</button>
    <div style="height:14px"></div>
    <button class="big sky press" data-act="games">巩固练习 · 9 种玩法 🎮</button>
    <div style="height:16px"></div>
    </div></div>`;
  }

  function studyHTML() {
    const st = state.study;
    if (!st) return "";
    if (st.finished) {
      return `<div class="study"><div class="celebrate">
        <div class="party">🎉</div>
        <h2>今天学完啦！</h2>
        <p>你认识了 ${st.known.length} 个单词</p>
        <button class="big blue press" data-act="to-games">去巩固 🎮</button>
        <button class="big green press" data-act="close-study">返回首页</button>
      </div></div>`;
    }
    if (!st.queue.length) {
      return `<div class="study"><div class="empty">今天没有新单词啦，换一本词书或明天再来吧</div>
        <button class="big green press" data-act="close-study">返回首页</button></div>`;
    }
    const entry = st.session[st.queue[st.cursor]];
    const idx = st.session.findIndex((w) => w.word === entry.word);
    const pct = st.session.length ? (st.known.length / st.session.length) * 100 : 0;
    return `<div class="study">
      <div class="study-head">
        <div class="row">
          <button class="icon-btn press" data-act="close-study">${I.chevL}</button>
          <h2>背单词 · 第 ${idx + 1} 个</h2>
          <button class="icon-btn blue press" data-act="speak" data-word="${esc(entry.word)}">${I.speaker}</button>
        </div>
        <div class="progress"><div style="width:${pct}%"></div></div>
        <div class="progress-label">学习进度 ${st.known.length}/${st.session.length}</div>
      </div>
      <div class="card-wrap">
        ${face(entry)}
        ${st.success ? `<div class="success-badge" style="color:var(--green)">${I.checkBig}</div>` : ""}
      </div>
      <div class="pills">
        <button class="pill blue press" data-act="speak" data-word="${esc(entry.word)}" data-rate="1">🔊 正常</button>
        <button class="pill green press" data-act="speak" data-word="${esc(entry.word)}" data-rate="0.75">🐢 慢速</button>
      </div>
      <div class="actions">
        <button class="bg-gray press" data-act="prev" ${st.locked ? "disabled" : ""}>← 上一个</button>
        <button class="bg-green press" data-act="know" ${st.locked ? "disabled" : ""}>认识 ✓</button>
        <button class="bg-red press" data-act="dont" ${st.locked ? "disabled" : ""}>不认识 ✕</button>
        <button class="bg-gray press" data-act="next" ${st.locked ? "disabled" : ""}>下一个 →</button>
      </div>
    </div>`;
  }

  function cardsHTML() {
    return `<div class="pane"><div class="scroll">
      <div class="page-title navy">单词卡</div>
      <div class="page-sub">按主题找单词</div>
      <div class="grid-2">${themes.map((t) => {
        const total = themeWords(t.id).length;
        const done = themeDone(t.id);
        const color = THEME_COLOR[t.id] || "#2b80ff";
        const bg = t.id === "colors" ? "" : `background:${color}61`;
        const cls = t.id === "colors" ? "theme-card colors-bg press" : "theme-card press";
        const mark = done === total && total ? `${done}/${total} ✓` : `${done}/${total}`;
        return `<button class="${cls}" style="${bg}" data-act="theme" data-id="${t.id}">
          ${img(THEME_ICON[t.id] || "theme-dots", t.nameCn)}
          <b>${esc(t.nameCn)}</b>
          <span class="count" style="color:${color}">${mark}</span>
        </button>`;
      }).join("")}</div>
    </div></div>`;
  }

  function themeHTML(frame) {
    const list = themeWords(frame.themeId);
    const theme = themes.find((t) => t.id === frame.themeId);
    if (!list.length) {
      return nav(theme ? theme.nameCn : "单词卡") + `<div class="empty">这个主题还没有单词</div>`;
    }
    const entry = list[Math.min(frame.index, list.length - 1)];
    const done = list.filter((w) => state.learned.has(w.word.toLowerCase())).length;
    const known = state.learned.has(entry.word.toLowerCase());
    return `<div class="pane">${nav(theme.nameCn)}
      <div class="scroll" style="display:flex;flex-direction:column">
        <div class="score-line">${done}/${list.length}</div>
        <div class="card-wrap">${face(entry)}
          ${frame.success ? `<div class="success-badge" style="color:var(--green)">${I.checkBig}</div>` : ""}
        </div>
        <div class="pills">
          <button class="pill blue press" data-act="speak" data-word="${esc(entry.word)}">🔊 正常</button>
          <button class="pill green press" data-act="speak" data-word="${esc(entry.word)}" data-rate="0.75">🐢 慢速</button>
        </div>
        <div class="actions">
          <button class="bg-gray press" data-act="theme-step" data-d="-1">← 上一个</button>
          <button class="bg-green press" data-act="theme-know">${known ? "已认识 ✓" : "认识 ✓"}</button>
          <button class="bg-blue press" data-act="theme-step" data-d="1">下一个 →</button>
        </div>
      </div></div>`;
  }

  function nav(title, tool) {
    return `<div class="nav"><button class="back press" data-act="back">${I.chevL}</button><h1>${esc(title)}</h1>${tool || "<span></span>"}</div>`;
  }

  function readHTML() {
    const list = lessons.filter((l) => l.level === state.level);
    return `<div class="pane">
      <div class="page-title blue">读短文</div>
      <div class="page-sub">${lessons.length} 篇分级小故事</div>
      <div class="levels">${[1, 2, 3, 4, 5, 6, 7].map((lv) =>
        `<button class="lv press ${state.level === lv ? "on" : ""}" data-act="level" data-lv="${lv}">L${lv}</button>`).join("")}</div>
      <div class="scroll">${list.map((l) => {
        const open = unlocked(l);
        const done = state.completed.has(l.id);
        const badge = done
          ? `<span class="badge done">${I.check}</span>`
          : open
            ? `<span class="badge play">${I.play}</span>`
            : `<span class="badge lock">${I.lock}</span>`;
        return `<button class="lesson press" data-act="lesson" data-id="${l.id}" ${open ? "" : "disabled"}>
          ${cover(l, "sq")}
          <span class="titles"><b>${esc(l.title)}</b><span>${esc(l.titleCn)}</span></span>
          ${badge}
        </button>`;
      }).join("")}</div></div>`;
  }

  function lessonHTML(frame) {
    const lesson = lessons.find((l) => l.id === frame.lessonId);
    if (!lesson) return nav("课文");
    const paras = lesson.content.map((p) => {
      const bits = (p.words.length ? p.words : p.text.split(/\s+/)).map((w, i) =>
        `<span class="w ${frame.hi === i && frame.playId === p.id ? "on" : ""}" data-act="lookup" data-word="${esc(w.replace(/[.,!?]/g, ""))}">${esc(w)}</span>`).join(" ");
      const tr = state.showCn ? `<div class="tr">${esc(p.translation)}</div>` : "";
      return `<div class="para"><div class="words">${bits}</div>${tr}
        <div class="para-actions">
          <button class="chip" data-act="read-para" data-id="${p.id}">${frame.playId === p.id ? "暂停" : "🔊 朗读"}</button>
          <button class="chip" data-act="mic">🎤 跟读</button>
        </div></div>`;
    }).join("");
    const quiz = lesson.quizCount
      ? `<button class="quiz-go press" data-act="quiz">✏️ 开始练习 (${lesson.quizCount} 道题)</button>` : "";
    const sheet = state.sheet ? `<div class="sheet"><h3>${esc(state.sheet.word)}</h3>
      <p class="phonetic">${esc(state.sheet.phonetic)}</p>
      <p class="meaning" style="font-size:28px">${esc(state.sheet.meaningCn)}</p>
      <button class="chip" data-act="close-sheet">关闭</button></div>` : "";
    const toast = state.toast ? `<div class="sheet"><b>${esc(state.toast)}</b>
      <button class="chip" data-act="close-sheet" style="margin-top:8px">知道了</button></div>` : "";
    return `<div class="pane">${nav(lesson.titleCn, `<button class="tool" data-act="lang">${state.showCn ? "中" : "EN"}</button>`)}
      <div class="scroll reader">${cover(lesson, "wide")}
        <h2>${esc(lesson.title)}</h2><div class="cn">${esc(lesson.titleCn)}</div>
        ${paras}${quiz}</div>${sheet}${toast}</div>`;
  }

  function booksHTML() {
    return `<div class="pane"><div class="scroll">
      <div class="page-title navy">绘本</div>
      <div class="page-sub">${lessons.length} 本图画故事</div>
      <div class="grid-2">${lessons.map((l) =>
        `<button class="shelf-card press" data-act="open-book" data-id="${l.id}">
          ${cover(l)}
          <div class="en">${esc(l.title)}</div>
          <div class="cn">${esc(l.titleCn)}</div>
        </button>`).join("")}</div>
    </div></div>`;
  }

  function bookHTML(frame) {
    const lesson = lessons.find((l) => l.id === frame.lessonId);
    if (!lesson) return "";
    const pages = lesson.content.length + 1;
    let body;
    if (frame.page === 0) {
      body = `${cover(lesson, "hero")}
        <div class="en-title">${esc(lesson.title)}</div>
        <h2>${esc(lesson.titleCn)}</h2>
        <div class="hint">向左滑，开始听故事</div>`;
    } else {
      const p = lesson.content[frame.page - 1];
      body = `<div class="story">${esc(p.text)}</div>
        <div class="cn-line">${esc(p.translation)}</div>
        <button class="listen press" data-act="listen">${I.speaker} 听一听</button>`;
    }
    return `<div class="pane">${nav(lesson.titleCn)}
      <div class="scroll" style="display:flex;align-items:stretch;padding-top:8px">
        <div class="book-page ${frame.turn ? "turn" : ""}" data-act="swipe-zone">${body}</div>
      </div>
      <div class="pager">
        <button class="turn-btn press" data-act="page" data-d="-1" ${frame.page === 0 ? "disabled" : ""}>${I.chevL} 上一页</button>
        <b>${frame.page + 1} / ${pages}</b>
        <button class="turn-btn press" data-act="page" data-d="1" ${frame.page + 1 >= pages ? "disabled" : ""}>下一页 ${I.chevR}</button>
      </div></div>`;
  }

  function profileHTML() {
    const limitLabel = state.limit === 0 ? "每日限时 不限" : `每日限时 ${state.limit} 分钟`;
    const pop = state.menu ? `<div class="menu-pop">
      ${[0, 10, 20, 30].map((n) => `<button data-act="limit" data-n="${n}">${n === 0 ? "不限" : n + " 分钟"}</button>`).join("")}
    </div>` : "";
    return `<div class="pane"><div class="scroll">
      <div class="hero">
        <div class="avatar"><div class="skin"></div><div class="hair"></div><div class="face"></div>
          <div class="eyes"><i></i><i></i></div><div class="mouth"></div><div class="spark">✦</div></div>
        <div>
          <h2>小宝贝</h2>
          <div class="line">${I.cal} 已学习 ${state.studyDates.length} 天</div>
          <div class="line">${I.flame} 连续打卡 ${streak()} 天</div>
        </div>
      </div>
      <div class="report">
        <div class="hd">${I.chart} 学习报告</div>
        <div class="stats">
          <div class="stat" style="color:var(--blue)">${I.bookClosed}<b>${state.learned.size}</b><small>已学单词</small></div>
          <div class="div"></div>
          <div class="stat" style="color:var(--green)">${I.read}<b>${state.completed.size}</b><small>已读短文</small></div>
          <div class="div"></div>
          <div class="stat" style="color:var(--orange)">${I.target}<b>${accuracy()}</b><small>游戏正确率</small></div>
        </div>
      </div>
      <button class="menu press" data-act="songs">${I.music}<b>英文儿歌</b><span class="chev">${I.chevR}</span></button>
      <button class="menu press" data-act="parent">${I.lock}<b>家长模式</b><span class="chev">${I.lock}</span></button>
      <button class="menu press" data-act="limit-menu">${I.clock}<b>${limitLabel}</b><span class="chev">${I.lock}</span></button>
      <button class="menu press" data-act="settings">${I.gear}<b>设置</b><span class="chev">${I.chevR}</span></button>
      ${pop}
    </div></div>`;
  }

  function songsHTML() {
    return `<div class="pane">${nav("英文儿歌")}<div class="scroll" style="padding-top:8px">${songs.map((s) => {
      const open = state.songId === s.id;
      const lines = open ? `<div class="lines">${s.lines.map((ln, i) =>
        `<div class="line ${state.songLine === i ? "on" : ""}"><b>${esc(ln.en)}</b><div><small>${esc(ln.cn)}</small></div></div>`).join("")}</div>` : "";
      return `<div class="song"><button class="top" data-act="song" data-id="${s.id}">
        <span style="font-size:28px">🎵</span>
        <span style="flex:1"><h3>${esc(s.title)}</h3><small>${esc(s.titleCn)}</small></span>
        <span style="color:var(--orange);font-size:32px">${open && state.songLine >= 0 ? "⏸" : "▶"}</span>
      </button>${lines}</div>`;
    }).join("")}</div></div>`;
  }

  function parentHTML() {
    const p = state.parent;
    if (p.open) {
      return `<div class="pane">${nav("家长中心")}<div class="list">
        <h3>📊 学习报告</h3>
        <div class="row"><span>已完成课程</span><b>${state.completed.size} / ${lessons.length}</b></div>
        <div class="row"><span>已学单词</span><b>${state.learned.size}</b></div>
        <div class="row"><span>游戏正确率</span><b>${accuracy()}</b></div>
        <h3>⏱️ 每日限时</h3>
        <div class="row"><span>每天最多学</span><b>${state.limit === 0 ? "不限" : state.limit + " 分钟"}</b></div>
        <h3>ℹ️ 关于</h3>
        <div class="row"><span>内容来源：magic-english-buddy（CC BY-NC-SA 4.0），仅限家庭内部学习使用</span></div>
      </div></div>`;
    }
    return `<div class="pane">${nav("家长中心")}<div class="parent">
      <div class="lock">🔒</div>
      <h2>家长验证</h2>
      <p>请回答下面的数学题进入家长区
（防止小朋友误入）</p>
      <div class="math">${p.a} + ${p.b} = ?</div>
      <input id="parent-answer" inputmode="numeric" placeholder="答案" value="${esc(p.answer)}">
      ${p.wrong ? `<div class="toast">不对哦，再算算</div>` : ""}
      <button class="go press" data-act="parent-go">进入</button>
    </div></div>`;
  }

  function settingsHTML() {
    return `<div class="pane">${nav("设置")}<div class="list">
      <h3>每天新学</h3>
      <div class="row"><span>${state.dailyNew} 个</span>
        <span class="stepper">
          <button data-act="daily" data-d="-5">−</button>
          <button data-act="daily" data-d="5">+</button>
        </span></div>
      <h3>课文</h3>
      <div class="row"><span>默认显示中文翻译</span>
        <button class="chip" data-act="toggle-cn">${state.showCn ? "开" : "关"}</button></div>
      <h3>关于</h3>
      <div class="row"><span>内容来源：magic-english-buddy（CC BY-NC-SA 4.0）
仅限家庭内部学习使用</span></div>
    </div></div>`;
  }

  function gamePool() {
    const learned = words.filter((w) => state.learned.has(w.word.toLowerCase()));
    const base = learned.length ? learned : (planDays()[0] || words.slice(0, 10));
    return base;
  }
  function shuffle(list) {
    const arr = list.slice();
    for (let i = arr.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [arr[i], arr[j]] = [arr[j], arr[i]];
    }
    return arr;
  }
  function freshGame(mode) {
    let pool = gamePool().slice();
    if (!shot) pool = shuffle(pool);
    const count = mode === "matching" ? Math.min(4, pool.length) : Math.min(10, pool.length);
    const g = {
      mode, questions: pool.slice(0, count), index: 0, score: 0,
      options: [], correct: 0, picked: {}, answered: false, finished: false,
      shake: 0, input: "", cards: [], selected: [], matched: {}, busy: false,
    };
    prepareRound(g);
    return g;
  }
  function choiceRest(target) {
    const preferred = [];
    const seen = new Set([target.word]);
    planDays().slice(0, 8).forEach((day) => day.forEach((w) => {
      if (!seen.has(w.word)) { seen.add(w.word); preferred.push(w); }
    }));
    words.forEach((w) => {
      if (!seen.has(w.word)) { seen.add(w.word); preferred.push(w); }
    });
    return preferred;
  }
  function prepareRound(g) {
    if (g.mode === "matching") { setupMatch(g); return; }
    deal(g);
  }
  function setupMatch(g) {
    const pairs = g.questions.slice(0, Math.min(4, g.questions.length));
    let cards = [];
    pairs.forEach((w, i) => {
      cards.push({ id: i * 2, word: w.word, emoji: w.emoji || "🌟", isImage: false });
      cards.push({ id: i * 2 + 1, word: w.word, emoji: w.emoji || "🌟", isImage: true });
    });
    if (shot) {
      const order = [0, 3, 5, 2, 7, 1, 4, 6];
      const byId = {};
      cards.forEach((c) => { byId[c.id] = c; });
      cards = order.map((id) => byId[id]).filter(Boolean);
    } else {
      cards = shuffle(cards);
    }
    g.cards = cards;
    g.selected = [];
    g.matched = {};
    g.busy = false;
  }
  function deal(g) {
    if (g.mode === "matching") return;
    const target = g.questions[g.index];
    if (!target) { g.finished = true; return; }
    const rest = choiceRest(target);
    let distract;
    if (shot) distract = rest.slice(0, 3);
    else distract = shuffle(rest).slice(0, 3);
    let options = [target, ...distract];
    if (shot) options = [distract[0], target, distract[1], distract[2]].filter(Boolean);
    else options = shuffle(options);
    g.options = options;
    g.correct = options.findIndex((w) => w && w.word === target.word);
    g.picked = {};
    g.answered = false;
    g.input = "";
  }

  function optionCells(g, kind) {
    return g.options.map((opt, i) => {
      const mark = g.picked[i];
      const cls = mark === "ok" ? "ok" : mark === "bad" ? "bad" : (g.answered && mark !== "ok" ? "dim" : "");
      if (kind === "image") {
        return `<button class="opt press ${cls}" data-act="pick" data-i="${i}">${esc(opt.emoji || "🌟")}</button>`;
      }
      const tone = g.mode === "audioToWord" ? "tone-purple" : g.mode === "audioToMeaning" ? "tone-gold" : g.mode === "wordToMeaning" ? "tone-teal" : "";
      if (kind === "word") {
        return `<button class="choice press ${tone} ${cls}" data-act="pick" data-i="${i}">${esc(opt.word)}</button>`;
      }
      if (kind === "meaning") {
        return `<button class="choice press ${tone} ${cls}" data-act="pick" data-i="${i}">${esc(opt.meaningCn || opt.word)}</button>`;
      }
      return `<button class="audio-row press ${cls}" data-act="pick" data-i="${i}">
        <span class="mini-speaker">${I.speaker}</span><b>发音 ${i + 1}</b></button>`;
    }).join("");
  }

  function gamesHTML(frame) {
    if (!frame.game) {
      const pool = gamePool();
      const body = pool.length ? `<div class="games-title">选个玩法吧！🎮</div>
        <div class="games-sub">9种游戏，越玩越熟</div>
        <div class="grid-3">${GAMES.map((g) =>
          `<button class="game-tile press" style="background:${g.tint}" data-act="mode" data-mode="${g.id}">
            <div class="bubble">${img(g.icon, g.name)}</div>
            <b>${g.name}</b><em style="background:${g.color}">${g.diff}</em>
          </button>`).join("")}</div>`
        : `<div class="empty">先去背单词吧 📚</div>`;
      return `<div class="pane">${nav("巩固练习")}<div class="scroll">${body}</div></div>`;
    }
    const g = frame.game;
    const meta = GAMES.find((x) => x.id === g.mode) || { name: "游戏" };
    if (g.finished) {
      const total = g.mode === "matching" ? g.cards.filter((c) => !c.isImage).length : g.questions.length;
      return `<div class="pane">${nav(meta.name)}
        <button class="switch-game press" data-act="exit-game">换游戏</button>
        <div class="celebrate"><div class="party">🎉</div><h2>得了 ${g.score} 分！</h2>
        <p>${g.score} / ${total}</p>
        <button class="big green press" data-act="replay">再来一局</button></div></div>`;
    }
    if (g.mode === "matching") {
      const cards = g.cards.map((c) => {
        const on = g.selected.includes(c.id) ? "on" : "";
        const bad = g.picked[c.id] === "bad" ? "bad" : "";
        const gone = g.matched[c.id] ? "gone" : "";
        const face = c.isImage ? `<span class="big-emoji">${esc(c.emoji)}</span>` : `<b>${esc(c.word)}</b>`;
        return `<button class="match press ${on} ${bad} ${gone}" data-act="match" data-id="${c.id}">${face}</button>`;
      }).join("");
      return `<div class="pane">${nav(meta.name)}
        <button class="switch-game press" data-act="exit-game">换游戏</button>
        <div class="scroll" style="padding:0 16px 12px">
          <div class="q-meta">找到单词和图片的一对 · 得分 ${g.score}</div>
          <div class="match-grid ${g.shake ? "shake" : ""}">${cards}</div>
        </div></div>`;
    }
    const q = g.questions[g.index];
    const head = `<div class="q-meta">第 ${g.index + 1} / ${g.questions.length} 题  ·  得分 ${g.score}</div>`;
    let body = "";
    if (g.mode === "wordToImage") {
      body = `${head}<div class="prompt"><div class="bigword">${esc(q.word)}</div>
        <button class="speaker press" data-act="speak" data-word="${esc(q.word)}">${I.speaker}</button></div>
        <div class="opt-grid ${g.shake ? "shake" : ""}">${optionCells(g, "image")}</div>`;
    } else if (g.mode === "audioToImage") {
      body = `${head}<div class="listen-prompt">听一听，选出对应的图片 👂</div>
        <button class="speaker big press" data-act="speak" data-word="${esc(q.word)}">${I.speaker}</button>
        <div class="opt-grid ${g.shake ? "shake" : ""}">${optionCells(g, "image")}</div>`;
    } else if (g.mode === "imageToWord") {
      body = `${head}<div class="listen-prompt">这张图是哪个单词？🖼️</div>
        <div class="hero-emoji">${esc(q.emoji || "🌟")}</div>
        <div class="choice-list ${g.shake ? "shake" : ""}">${optionCells(g, "word")}</div>`;
    } else if (g.mode === "audioToWord") {
      body = `${head}<div class="listen-prompt">听一听，是哪个单词？</div>
        <button class="speaker big press" data-act="speak" data-word="${esc(q.word)}">${I.speaker}</button>
        <div class="choice-list ${g.shake ? "shake" : ""}">${optionCells(g, "word")}</div>`;
    } else if (g.mode === "wordToAudio") {
      body = `${head}<div class="prompt"><div class="bigword">${esc(q.word)}</div></div>
        <div class="listen-prompt">点喇叭听一听，选出正确的发音 🔊</div>
        <div class="choice-list ${g.shake ? "shake" : ""}">${optionCells(g, "audio")}</div>`;
    } else if (g.mode === "audioToMeaning") {
      body = `${head}<div class="listen-prompt">听一听，是什么意思？</div>
        <button class="speaker big press" data-act="speak" data-word="${esc(q.word)}">${I.speaker}</button>
        <div class="choice-list ${g.shake ? "shake" : ""}">${optionCells(g, "meaning")}</div>`;
    } else if (g.mode === "wordToMeaning") {
      body = `${head}<div class="prompt"><div class="bigword">${esc(q.word)}</div>
        <button class="speaker press" data-act="speak" data-word="${esc(q.word)}">${I.speaker}</button></div>
        <div class="listen-prompt">是什么意思？</div>
        <div class="choice-list ${g.shake ? "shake" : ""}">${optionCells(g, "meaning")}</div>`;
    } else {
      body = `${head}<div class="listen-prompt">听一听，写出单词</div>
        <button class="speaker big press" data-act="speak" data-word="${esc(q.word)}">${I.speaker}</button>
        <p class="hint">点喇叭可以再听</p>
        <input id="dict-answer" class="${g.shake ? "shake" : ""}" placeholder="输入英文单词" value="${esc(g.input)}" autocomplete="off" autocapitalize="none">
        ${g.mark === "ok" ? `<div class="mark ok">对啦！</div>` : ""}
        ${g.mark === "bad" ? `<div class="mark bad">正确答案是：${esc(q.word)}</div>` : ""}
        ${g.mark ? "" : `<button class="big green press" data-act="dict-check">检查</button>`}`;
    }
    return `<div class="pane">${nav(meta.name)}
      <button class="switch-game press" data-act="exit-game">换游戏</button>
      <div class="scroll" style="padding:0 16px 16px">${body}</div></div>`;
  }

  function quizHTML(frame) {
    const lesson = lessons.find((l) => l.id === frame.lessonId);
    const quiz = (lesson && lesson.quiz) || [];
    if (!quiz.length) return `<div class="pane">${nav("练习时间")}<div class="empty">这一课还没有练习</div></div>`;
    if (frame.done || frame.index >= quiz.length) {
      const score = Math.round((frame.correct / quiz.length) * 100);
      const passed = score >= 60;
      return `<div class="pane">${nav("练习时间")}<div class="celebrate">
        <div class="party">${passed ? "🎉" : "💪"}</div>
        <h2>${score} 分</h2>
        <p>${passed ? "太棒了！下一课已解锁" : "差一点点，再学一次吧！"}</p>
        <button class="big green press" data-act="quiz-done">${passed ? "继续闯关" : "知道了"}</button>
      </div></div>`;
    }
    const item = quiz[frame.index];
    const built = frame.built || [];
    let extra = "";
    if (item.type === "sentence_order" || item.type === "word_builder") {
      const pool = frame.left || [];
      extra = `<div class="built">${built.map((w) => `<span>${esc(w)}</span>`).join("") || "点下面的词"}</div>
        <div class="chip-row">${pool.map((w, i) => `<button class="chip" data-act="quiz-build" data-i="${i}">${esc(w)}</button>`).join("")}</div>`;
    } else {
      extra = `<div class="choice-list">${(item.options || []).map((opt) => {
        const mark = frame.picked == null ? "" : (opt.value === item.correctAnswer ? "ok" : (frame.picked === opt.value ? "bad" : "dim"));
        const icon = opt.image ? `<span class="opt-emoji">${esc(opt.image)}</span>` : "";
        return `<button class="choice press ${mark}" data-act="quiz-pick" data-value="${esc(opt.value)}">${icon}<span>${esc(opt.text || opt.value)}</span></button>`;
      }).join("")}</div>`;
    }
    const note = frame.mark === "ok" ? `<div class="mark ok">答对啦！</div>` : (frame.mark === "bad" ? `<div class="mark bad">再想想，下次加油！</div>` : "");
    return `<div class="pane">${nav("练习时间")}
      <div class="scroll" style="padding:8px 16px 20px">
        <div class="q-meta">第 ${frame.index + 1} / ${quiz.length} 题</div>
        <h2 class="quiz-q">${esc(item.question)}</h2>
        ${extra}${note}
      </div></div>`;
  }

  function screenHTML() {
    if (state.study) return studyHTML();
    const frame = top();
    if (frame) {
      if (frame.id === "quiz") return quizHTML(frame);
      if (frame.id === "games") return gamesHTML(frame);
      if (frame.id === "theme") return themeHTML(frame);
      if (frame.id === "lesson") return lessonHTML(frame);
      if (frame.id === "book") return bookHTML(frame);
      if (frame.id === "songs") return songsHTML();
      if (frame.id === "parent") return parentHTML();
      if (frame.id === "settings") return settingsHTML();
    }
    if (state.tab === "learn") return homeHTML();
    if (state.tab === "cards") return cardsHTML();
    if (state.tab === "read") return readHTML();
    if (state.tab === "books") return booksHTML();
    return profileHTML();
  }

  const device = document.getElementById("device");
  function render() {
    const hideTabs = !!state.study;
    device.innerHTML = statusBar() + `<div class="stage">${screenHTML()}</div>` + (hideTabs ? "" : tabbar());
    device.dataset.ready = "1";
    const input = document.getElementById("parent-answer");
    if (input) input.focus();
  }

  function startStudy(autoSpeak) {
    const todayWords = planDays()[0] || [];
    state.study = {
      session: todayWords,
      queue: todayWords.map((_, i) => i),
      cursor: 0,
      known: [],
      finished: false,
      success: false,
      locked: false,
    };
    state.dir = 1;
    render();
    if (autoSpeak && todayWords[0] && !shot) {
      speakTimer = setTimeout(() => speak(todayWords[0].word, false), 450);
    }
  }

  function currentEntry() {
    const st = state.study;
    if (!st || st.cursor >= st.queue.length) return null;
    return st.session[st.queue[st.cursor]];
  }

  device.addEventListener("click", (ev) => {
    const el = ev.target.closest("[data-act]");
    if (!el) return;
    const act = el.dataset.act;
    if (act === "tab") {
      stopSpeak();
      state.tab = el.dataset.tab;
      state.menu = false;
      state.study = null;
      render();
      return;
    }
    if (act === "back") {
      stopSpeak();
      state.sheet = null;
      state.toast = null;
      stack().pop();
      render();
      return;
    }
    if (act === "book") {
      state.themeId = el.dataset.id || null;
      saveStore();
      render();
      return;
    }
    if (act === "start") { startStudy(true); return; }
    if (act === "close-study") { stopSpeak(); state.study = null; render(); return; }
    if (act === "speak") {
      speak(el.dataset.word, el.dataset.rate === "0.75");
      return;
    }
    if (act === "know") return markKnown();
    if (act === "dont") return markUnknown();
    if (act === "next") return go(1);
    if (act === "prev") return go(-1);
    if (act === "to-games") {
      state.study = null;
      state.tab = "learn";
      state.stacks.learn = [{ id: "games", game: null }];
      render();
      return;
    }
    if (act === "games") {
      state.stacks.learn.push({ id: "games", game: null });
      render();
      return;
    }
    if (act === "mode") {
      const frame = top();
      frame.game = freshGame(el.dataset.mode);
      render();
      if (!shot) speak(frame.game.questions[0].word, false);
      return;
    }
    if (act === "exit-game") { top().game = null; stopSpeak(); render(); return; }
    if (act === "replay") {
      const frame = top();
      frame.game = freshGame(frame.game.mode);
      render();
      return;
    }
    if (act === "pick") return pickOption(Number(el.dataset.i));
    if (act === "match") return matchCard(Number(el.dataset.id));
    if (act === "dict-check") return dictCheck();
    if (act === "quiz-pick") return quizPick(el.dataset.value);
    if (act === "quiz-build") return quizBuild(Number(el.dataset.i));
    if (act === "quiz-done") return quizDone();
    if (act === "theme") {
      state.dir = 1;
      state.stacks.cards.push({ id: "theme", themeId: el.dataset.id, index: 0, success: false });
      render();
      return;
    }
    if (act === "theme-step") return themeStep(Number(el.dataset.d));
    if (act === "theme-know") return themeKnow();
    if (act === "level") { state.level = Number(el.dataset.lv); render(); return; }
    if (act === "lesson") {
      if (el.disabled) return;
      state.stacks.read.push({ id: "lesson", lessonId: el.dataset.id, playId: null, hi: -1 });
      render();
      return;
    }
    if (act === "lang") { state.showCn = !state.showCn; saveStore(); render(); return; }
    if (act === "read-para") return readPara(el.dataset.id);
    if (act === "lookup") return lookup(el.dataset.word);
    if (act === "close-sheet") { state.sheet = null; state.toast = null; render(); return; }
    if (act === "mic") { state.toast = "网页预览不能录音，真机上可以跟读"; state.sheet = null; render(); return; }
    if (act === "quiz") return openQuiz();
    if (act === "open-book") {
      state.stacks.books.push({ id: "book", lessonId: el.dataset.id, page: 0, turn: false });
      render();
      return;
    }
    if (act === "page") return turnPage(Number(el.dataset.d));
    if (act === "listen") return listenPage(false);
    if (act === "songs") { state.stacks.profile.push({ id: "songs" }); render(); return; }
    if (act === "song") return toggleSong(el.dataset.id);
    if (act === "parent") {
      state.parent = { a: 12 + Math.floor(Math.random() * 30), b: 11 + Math.floor(Math.random() * 30), answer: "", wrong: false, open: false };
      state.stacks.profile.push({ id: "parent" });
      render();
      return;
    }
    if (act === "parent-go") return parentGo();
    if (act === "settings") { state.stacks.profile.push({ id: "settings" }); render(); return; }
    if (act === "limit-menu") { state.menu = !state.menu; render(); return; }
    if (act === "limit") { state.limit = Number(el.dataset.n); state.menu = false; saveStore(); render(); return; }
    if (act === "daily") {
      state.dailyNew = Math.min(20, Math.max(5, state.dailyNew + Number(el.dataset.d)));
      saveStore();
      render();
      return;
    }
    if (act === "toggle-cn") { state.showCn = !state.showCn; saveStore(); render(); return; }
  });

  device.addEventListener("input", (ev) => {
    if (ev.target.id === "parent-answer") state.parent.answer = ev.target.value;
    if (ev.target.id === "dict-answer") {
      const g = top() && top().game;
      if (g) g.input = ev.target.value;
    }
  });

  let dragX = 0;
  device.addEventListener("pointerdown", (ev) => {
    if (!ev.target.closest("[data-act='swipe-zone']")) return;
    dragX = ev.clientX;
  });
  device.addEventListener("pointerup", (ev) => {
    if (!dragX) return;
    const dx = ev.clientX - dragX;
    dragX = 0;
    const frame = top();
    if (!frame || frame.id !== "book") return;
    if (dx < -50) turnPage(1);
    else if (dx > 50) turnPage(-1);
  });

  function markKnown() {
    const st = state.study;
    const entry = currentEntry();
    if (!st || st.locked || !entry) return;
    st.locked = true;
    state.dir = 1;
    state.learned.add(entry.word.toLowerCase());
    if (!st.known.includes(entry.word)) st.known.push(entry.word);
    st.success = true;
    saveStore();
    render();
    setTimeout(() => {
      st.success = false;
      st.queue.splice(st.cursor, 1);
      if (!st.queue.length) {
        st.finished = true;
        stopSpeak();
      } else if (st.cursor >= st.queue.length) st.cursor = 0;
      st.locked = false;
      render();
      const next = currentEntry();
      if (next && !st.finished && !shot) setTimeout(() => speak(next.word, false), 420);
    }, 550);
  }
  function markUnknown() {
    const st = state.study;
    const entry = currentEntry();
    if (!st || st.locked || !entry) return;
    speak(entry.word, true);
    if (st.queue.length < 2) return;
    st.locked = true;
    const token = entry.word;
    setTimeout(() => {
      const now = currentEntry();
      if (!now || now.word !== token) { st.locked = false; return; }
      state.dir = 1;
      const item = st.queue.splice(st.cursor, 1)[0];
      st.queue.push(item);
      if (st.cursor >= st.queue.length) st.cursor = 0;
      st.locked = false;
      render();
      const next = currentEntry();
      if (next && !shot) setTimeout(() => speak(next.word, false), 420);
    }, 700);
  }
  function go(delta) {
    const st = state.study;
    if (!st || st.locked || st.queue.length < 2) {
      const entry = currentEntry();
      if (entry) speak(entry.word, false);
      return;
    }
    state.dir = delta;
    if (delta > 0) {
      const item = st.queue.splice(st.cursor, 1)[0];
      st.queue.push(item);
      if (st.cursor >= st.queue.length) st.cursor = 0;
    } else {
      st.cursor = (st.cursor - 1 + st.queue.length) % st.queue.length;
    }
    render();
    const entry = currentEntry();
    if (entry && !shot) setTimeout(() => speak(entry.word, false), 420);
  }

  function themeStep(delta) {
    const frame = top();
    const list = themeWords(frame.themeId);
    if (!list.length) return;
    state.dir = delta;
    frame.success = false;
    frame.index = (frame.index + delta + list.length) % list.length;
    render();
    if (!shot) setTimeout(() => speak(list[frame.index].word, false), 400);
  }
  function themeKnow() {
    const frame = top();
    const list = themeWords(frame.themeId);
    const entry = list[frame.index];
    state.learned.add(entry.word.toLowerCase());
    saveStore();
    frame.success = true;
    render();
    setTimeout(() => {
      frame.success = false;
      if (list.length > 1) themeStep(1);
      else render();
    }, 450);
  }

  function readPara(id) {
    const frame = top();
    const lesson = lessons.find((l) => l.id === frame.lessonId);
    const para = lesson.content.find((p) => p.id === id);
    if (frame.playId === id) { stopSpeak(); frame.playId = null; frame.hi = -1; render(); return; }
    frame.playId = id;
    frame.hi = -1;
    render();
    speak(para.text, false);
    const wordsIn = para.words.length ? para.words : para.text.split(/\s+/);
    let i = 0;
    const tick = () => {
      if (frame.playId !== id) return;
      frame.hi = i;
      render();
      i += 1;
      if (i < wordsIn.length) speakTimer = setTimeout(tick, 380);
      else speakTimer = setTimeout(() => { frame.playId = null; frame.hi = -1; render(); }, 400);
    };
    speakTimer = setTimeout(tick, 380);
  }
  function lookup(raw) {
    const key = String(raw || "").toLowerCase().replace(/[^a-z'-]/g, "");
    const hit = wordBy[key];
    state.toast = null;
    if (hit) state.sheet = hit;
    else { state.sheet = null; state.toast = `「${raw}」暂时没有收录`; }
    render();
  }
  function turnPage(delta) {
    const frame = top();
    const lesson = lessons.find((l) => l.id === frame.lessonId);
    const next = frame.page + delta;
    if (next < 0 || next > lesson.content.length) return;
    frame.page = next;
    frame.turn = true;
    render();
    if (next > 0 && !shot) setTimeout(() => listenPage(true), 420);
  }
  function listenPage(auto) {
    const frame = top();
    const lesson = lessons.find((l) => l.id === frame.lessonId);
    if (frame.page < 1) return;
    const para = lesson.content[frame.page - 1];
    speak(para.text, false);
    if (!auto) return;
    const ms = Math.min(8000, Math.max(1200, para.text.split(/\s+/).length * 420));
    speakTimer = setTimeout(() => {
      if (top() === frame && frame.page > 0) turnPage(1);
    }, ms);
  }
  function toggleSong(id) {
    if (state.songId === id && state.songLine >= 0) {
      stopSpeak();
      state.songLine = -1;
      render();
      return;
    }
    const song = songs.find((s) => s.id === id);
    state.songId = id;
    let i = 0;
    const step = () => {
      if (state.songId !== id) return;
      if (i >= song.lines.length) { state.songLine = -1; render(); return; }
      state.songLine = i;
      render();
      speak(song.lines[i].en, false);
      i += 1;
      speakTimer = setTimeout(step, 1600);
    };
    step();
  }
  function parentGo() {
    const p = state.parent;
    const field = document.getElementById("parent-answer");
    if (field) p.answer = field.value;
    if (Number(p.answer) === p.a + p.b) { p.open = true; p.wrong = false; }
    else { p.wrong = true; p.answer = ""; }
    render();
  }
  function note(ok) {
    state.gameAnswered += 1;
    if (ok) state.gameCorrect += 1;
    saveStore();
  }
  function pickOption(i) {
    const g = top().game;
    if (!g || g.answered) return;
    const opt = g.options[i];
    if (!opt) return;
    if (g.mode === "wordToAudio" && !shot) speak(opt.word, false);
    if (i === g.correct) {
      g.picked[i] = "ok";
      g.answered = true;
      g.score += 1;
      note(true);
      render();
      setTimeout(() => {
        g.index += 1;
        if (g.index >= g.questions.length) g.finished = true;
        else deal(g);
        render();
        if (!g.finished && !shot && g.mode !== "wordToAudio" && g.mode !== "imageToWord" && g.mode !== "wordToMeaning") {
          speak(g.questions[g.index].word, false);
        }
      }, 700);
    } else {
      g.picked[i] = "bad";
      g.shake += 1;
      note(false);
      render();
    }
  }
  function matchCard(id) {
    const g = top().game;
    if (!g || g.busy || g.matched[id] || g.selected.includes(id)) return;
    const card = g.cards.find((c) => c.id === id);
    if (!card) return;
    if (!shot) speak(card.word, false);
    if (g.selected.length === 1) {
      const first = g.cards.find((c) => c.id === g.selected[0]);
      g.selected.push(id);
      if (first && first.word === card.word && first.isImage !== card.isImage) {
        g.busy = true;
        g.score += 1;
        note(true);
        const ids = [first.id, id];
        render();
        setTimeout(() => {
          ids.forEach((n) => { g.matched[n] = true; });
          g.selected = [];
          g.busy = false;
          if (Object.keys(g.matched).length >= g.cards.length) g.finished = true;
          render();
        }, 450);
      } else {
        g.busy = true;
        g.picked[first.id] = "bad";
        g.picked[id] = "bad";
        g.shake += 1;
        note(false);
        render();
        setTimeout(() => {
          delete g.picked[first.id];
          delete g.picked[id];
          g.selected = [];
          g.busy = false;
          render();
        }, 700);
      }
    } else {
      g.selected = [id];
      render();
    }
  }
  function dictCheck() {
    const g = top().game;
    if (!g || g.answered) return;
    const field = document.getElementById("dict-answer");
    if (field) g.input = field.value;
    const typed = String(g.input || "").trim().toLowerCase();
    const word = g.questions[g.index].word.toLowerCase();
    const ok = typed === word;
    g.mark = ok ? "ok" : "bad";
    g.answered = true;
    if (ok) g.score += 1;
    else g.shake += 1;
    note(ok);
    render();
    setTimeout(() => {
      g.index += 1;
      g.mark = null;
      g.answered = false;
      if (g.index >= g.questions.length) g.finished = true;
      else deal(g);
      render();
      if (!g.finished && !shot) speak(g.questions[g.index].word, false);
    }, ok ? 800 : 1600);
  }
  function openQuiz() {
    const frame = top();
    if (!frame || frame.id !== "lesson") return;
    const lesson = lessons.find((l) => l.id === frame.lessonId);
    const quiz = { id: "quiz", lessonId: frame.lessonId, index: 0, correct: 0, picked: null, built: [], left: null, mark: null, done: false };
    primeQuiz(quiz, lesson);
    state.stacks.read.push(quiz);
    render();
  }
  function primeQuiz(frame, lesson) {
    const item = lesson && lesson.quiz && lesson.quiz[frame.index];
    frame.picked = null;
    frame.mark = null;
    frame.built = [];
    if (!item) { frame.left = []; return; }
    if (item.type === "word_builder") frame.left = (item.shuffledWords || []).slice();
    else if (item.type === "sentence_order") frame.left = (item.shuffledWords || item.correctOrder || []).slice();
    else frame.left = [];
  }
  function quizPick(value) {
    const frame = top();
    if (!frame || frame.id !== "quiz" || frame.picked) return;
    const lesson = lessons.find((l) => l.id === frame.lessonId);
    const item = lesson.quiz[frame.index];
    frame.picked = value;
    const ok = value === item.correctAnswer;
    frame.mark = ok ? "ok" : "bad";
    if (ok) frame.correct += 1;
    render();
    setTimeout(() => advanceQuiz(frame, lesson), 800);
  }
  function quizBuild(i) {
    const frame = top();
    if (!frame || frame.id !== "quiz" || frame.mark) return;
    const lesson = lessons.find((l) => l.id === frame.lessonId);
    const item = lesson.quiz[frame.index];
    const word = frame.left[i];
    if (word == null) return;
    frame.left.splice(i, 1);
    frame.built.push(word);
    if (frame.left.length) { render(); return; }
    let ok = false;
    if (item.type === "word_builder") ok = frame.built.join("") === String(item.correctAnswer || "");
    else ok = frame.built.join(" ") === (item.correctOrder || []).join(" ");
    frame.mark = ok ? "ok" : "bad";
    if (ok) frame.correct += 1;
    render();
    setTimeout(() => advanceQuiz(frame, lesson), 800);
  }
  function advanceQuiz(frame, lesson) {
    frame.index += 1;
    if (frame.index >= lesson.quiz.length) {
      frame.done = true;
      const score = Math.round((frame.correct / lesson.quiz.length) * 100);
      if (score >= 60) state.completed.add(lesson.id);
      saveStore();
    } else primeQuiz(frame, lesson);
    render();
  }
  function quizDone() {
    state.stacks.read.pop();
    render();
  }

  state.level = 1;
  function applyShot() {
    if (shot === "learn") startStudy(false);
    else if (shot === "celebrate") {
      const todayWords = planDays()[0] || words.slice(0, 10);
      state.study = { session: todayWords, queue: [], cursor: 0, known: todayWords.map((w) => w.word), finished: true, success: false, locked: false };
    } else if (shot === "games") {
      state.stacks.learn = [{ id: "games", game: null }];
    } else if (shot === "game" || (shot && shot.indexOf("game-") === 0)) {
      const mode = shot === "game" ? "wordToImage" : shot.slice(5);
      const count = mode === "matching" ? 4 : 4;
      const frame = { id: "games", game: freshGame(mode) };
      frame.game.questions = (planDays()[0] || words).slice(0, count);
      frame.game.index = 0;
      frame.game.score = 0;
      frame.game.finished = false;
      prepareRound(frame.game);
      state.stacks.learn = [frame];
    } else if (shot === "cards") state.tab = "cards";
    else if (shot === "theme") {
      state.tab = "cards";
      state.stacks.cards = [{ id: "theme", themeId: "fruits", index: 0, success: false }];
    } else if (shot === "read") {
      state.tab = "read";
      state.level = 1;
      if (lessons[0]) state.completed.add(lessons[0].id);
    } else if (shot === "lesson") {
      state.tab = "read";
      state.stacks.read = [{ id: "lesson", lessonId: lessons[0].id, playId: null, hi: -1 }];
    } else if (shot === "quiz") {
      state.tab = "read";
      const lesson = lessons[0];
      const quiz = { id: "quiz", lessonId: lesson.id, index: 0, correct: 0, picked: null, built: [], left: null, mark: null, done: false };
      primeQuiz(quiz, lesson);
      state.stacks.read = [quiz];
    } else if (shot === "books") state.tab = "books";
    else if (shot === "bookpage") {
      state.tab = "books";
      state.stacks.books = [{ id: "book", lessonId: lessons[0].id, page: 1, turn: false }];
    } else if (shot === "profile") state.tab = "profile";
    else if (shot === "parent") {
      state.tab = "profile";
      state.parent = { a: 18, b: 27, answer: "", wrong: false, open: false };
      state.stacks.profile = [{ id: "parent" }];
    }
  }
  applyShot();
  render();
})();
