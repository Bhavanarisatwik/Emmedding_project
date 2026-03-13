const { useState, useRef, useEffect, useCallback } = React;

// ── Inline SVG Icons ─────────────────────────────────────────────────────
const Ico = ({ paths, size = 18, fill = false, ...p }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill={fill ? 'currentColor' : 'none'}
    stroke={fill ? 'none' : 'currentColor'} strokeWidth="2"
    strokeLinecap="round" strokeLinejoin="round" {...p}>
    {paths.map((d, i) => <path key={i} d={d} />)}
  </svg>
);

const I = {
  Send:       () => <Ico paths={["M22 2L11 13","M22 2L15 22 11 13 2 9l20-7z"]} />,
  Clip:       () => <Ico paths={["M21.44 11.05l-9.19 9.19a6 6 0 01-8.49-8.49l9.19-9.19a4 4 0 015.66 5.66l-9.2 9.19a2 2 0 01-2.83-2.83l8.49-8.48"]} />,
  X:          () => <Ico paths={["M18 6L6 18","M6 6l12 12"]} />,
  Upload:     () => <Ico paths={["M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4","M17 8l-5-5-5 5","M12 3v12"]} />,
  ChevDown:   () => <Ico paths={["M6 9l6 6 6-6"]} />,
  ChevRight:  () => <Ico paths={["M9 18l6-6-6-6"]} />,
  LogOut:     () => <Ico paths={["M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4","M16 17l5-5-5-5","M21 12H9"]} />,
  File:       () => <Ico paths={["M13 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V9z","M13 2v7h7"]} />,
  Image:      () => <Ico paths={["M21 19a2 2 0 01-2 2H5a2 2 0 01-2-2V5a2 2 0 012-2h14a2 2 0 012 2z","M8.5 10a1.5 1.5 0 100-3 1.5 1.5 0 000 3z","M21 15l-5-5L5 21"]} />,
  Video:      () => <Ico paths={["M23 7l-7 5 7 5V7z","M1 5h14a2 2 0 012 2v10a2 2 0 01-2 2H1a2 2 0 01-2-2z"]} />,
  Menu:       () => <Ico paths={["M3 12h18","M3 6h18","M3 18h18"]} />,
  Plus:       () => <Ico paths={["M12 5v14","M5 12h14"]} />,
  Check:      () => <Ico paths={["M20 6L9 17l-5-5"]} />,
  Alert:      () => <Ico paths={["M12 22c5.523 0 10-4.477 10-10S17.523 2 12 2 2 6.477 2 12s4.477 10 10 10z","M12 8v4","M12 16h.01"]} />,
  Stars:      () => <Ico paths={["M12 3l1.8 5.4L19 10l-5.2 1.8L12 17l-1.8-5.4L5 10l5.2-1.8L12 3z","M5 3l.9 2.7L8.5 7l-2.6.9L5 10.6 4.1 7.9 1.5 7l2.6-.9L5 3z","M19 17l.9 2.7 2.6.9-2.6.9-.9 2.7-.9-2.7-2.6-.9 2.6-.9.9-2.7z"]} />,
  Pdf:        () => <Ico paths={["M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z","M14 2v6h6","M16 13H8","M16 17H8","M10 9H8"]} />,
  Doc:        () => <Ico paths={["M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z","M14 2v6h6","M12 18v-6","M9 15l3 3 3-3"]} />,
  Tag:        () => <Ico paths={["M20.59 13.41l-7.17 7.17a2 2 0 01-2.83 0L2 12V2h10l8.59 8.59a2 2 0 010 2.82z","M7 7h.01"]} />,
};

// ── Markdown renderer ─────────────────────────────────────────────────────
function escHtml(s) {
  return s.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

// Event delegation for copy buttons (DOMPurify strips onclick, so we use bubbling)
document.addEventListener('click', function(e) {
  const btn = e.target.closest('.nkb-copy-btn');
  if (!btn) return;
  const code = btn.closest('.nkb-code-block')?.querySelector('code')?.innerText || '';
  navigator.clipboard.writeText(code).then(() => {
    btn.textContent = 'Copied!';
    btn.classList.add('copied');
    setTimeout(() => { btn.textContent = 'Copy'; btn.classList.remove('copied'); }, 2000);
  }).catch(() => { btn.textContent = 'Error'; setTimeout(() => btn.textContent = 'Copy', 2000); });
});

let _markedReady = false;
function renderMarkdown(text) {
  try {
    if (!window.marked) return escHtml(text);
    if (!_markedReady) {
      const r = new window.marked.Renderer();

      r.code = function(code, lang) {
        const langLabel = lang ? escHtml(lang) : 'text';
        const escaped = escHtml(typeof code === 'string' ? code : String(code));
        return `<div class="nkb-code-block">
  <div class="nkb-code-header">
    <span class="nkb-code-lang">${langLabel}</span>
    <button class="nkb-copy-btn">Copy</button>
  </div>
  <pre><code>${escaped}</code></pre>
</div>`;
      };

      r.link = function(href, title, t) {
        return `<a href="${escHtml(href)}" target="_blank" rel="noopener noreferrer">${t}</a>`;
      };

      r.blockquote = function(quote) {
        return `<blockquote class="nkb-blockquote">${quote}</blockquote>`;
      };

      r.table = function(header, body) {
        return `<div class="nkb-table-wrap"><table><thead>${header}</thead><tbody>${body}</tbody></table></div>`;
      };

      window.marked.use({ renderer: r, breaks: true, gfm: true });
      _markedReady = true;
    }
    const html = window.marked.parse(text);
    return window.DOMPurify
      ? window.DOMPurify.sanitize(html, {
          ADD_ATTR: ['target', 'rel', 'onclick', 'class'],
          FORCE_BODY: false,
        })
      : html;
  } catch { return escHtml(text); }
}

// ── Toast ─────────────────────────────────────────────────────────────────
function Toast({ toast, onDismiss }) {
  useEffect(() => {
    const t = setTimeout(() => onDismiss(toast.id), 4500);
    return () => clearTimeout(t);
  }, [toast.id]);

  const cfg = {
    success: { border: 'border-emerald-500/30 bg-emerald-950/90', icon: <I.Check />, color: 'text-emerald-400' },
    error:   { border: 'border-red-500/30 bg-red-950/90',     icon: <I.Alert />, color: 'text-red-400' },
    info:    { border: 'border-indigo-500/30 bg-indigo-950/90', icon: <I.Stars />, color: 'text-indigo-400' },
  }[toast.type] || {};

  return (
    <div className={`toast-enter flex items-start gap-3 px-4 py-3 rounded-2xl border backdrop-blur-xl text-sm max-w-sm shadow-2xl ${cfg.border}`}>
      <span className={`mt-0.5 shrink-0 ${cfg.color}`}>{cfg.icon}</span>
      <span className="text-[#e4e4e7] flex-1 leading-snug">{toast.message}</span>
      <button onClick={() => onDismiss(toast.id)} className="text-[#52525b] hover:text-[#fafafa] shrink-0 transition-colors">
        <I.X />
      </button>
    </div>
  );
}

// ── Source Modal ──────────────────────────────────────────────────────────
function SourceModal({ source, onClose }) {
  const m = source.metadata || {};
  const imgSrc = source.url || m.data_url;
  const score = Math.round((source.score || 0) * 100);
  const typeBadge = {
    image: 'bg-orange-500/20 text-orange-400 border-orange-500/20',
    video: 'bg-purple-500/20 text-purple-400 border-purple-500/20',
    text:  'bg-indigo-500/20 text-indigo-400 border-indigo-500/20',
  }[m.type] || 'bg-zinc-800 text-zinc-400';

  useEffect(() => {
    const h = e => { if (e.key === 'Escape') onClose(); };
    document.addEventListener('keydown', h);
    document.body.style.overflow = 'hidden';
    return () => { document.removeEventListener('keydown', h); document.body.style.overflow = ''; };
  }, []);

  const fileExt = (m.filename || '').split('.').pop().toLowerCase();
  const fileIcon = m.type === 'image' ? <I.Image /> : m.type === 'video' ? <I.Video /> :
    fileExt === 'pdf' ? <I.Pdf /> : <I.File />;

  return (
    <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center" onClick={onClose}>
      <div className="absolute inset-0 bg-black/75 backdrop-blur-sm" />
      <div
        className="modal-enter relative w-full sm:max-w-lg bg-[#111113] border border-[#2a2a32] rounded-t-3xl sm:rounded-2xl overflow-hidden shadow-2xl"
        style={{ boxShadow: '0 25px 60px rgba(0,0,0,0.7), 0 0 0 1px rgba(99,102,241,0.08)' }}
        onClick={e => e.stopPropagation()}
      >
        {/* Drag handle (mobile) */}
        <div className="flex justify-center pt-3 pb-1 sm:hidden">
          <div className="w-10 h-1 rounded-full bg-[#27272a]" />
        </div>

        {/* Header */}
        <div className="flex items-center gap-3 px-5 py-4 border-b border-[#1c1c1f]">
          <div className={`p-2 rounded-lg ${m.type === 'image' ? 'bg-orange-500/10 text-orange-400' : m.type === 'video' ? 'bg-purple-500/10 text-purple-400' : 'bg-indigo-500/10 text-indigo-400'}`}>
            {fileIcon}
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-sm font-semibold text-[#fafafa] truncate">{m.filename || source.id}</p>
            <div className="flex items-center gap-2 mt-0.5 flex-wrap">
              <span className={`text-xs px-2 py-0.5 rounded-full border font-medium ${typeBadge}`}>
                {m.type || 'document'}
              </span>
              <span className="text-xs text-[#52525b]">Relevance: <span className="text-[#818cf8]">{score}%</span></span>
              {m.user_tag && (
                <span className="flex items-center gap-1 text-xs text-[#818cf8]">
                  <I.Tag size={11} /> {m.user_tag}
                </span>
              )}
            </div>
          </div>
          <button onClick={onClose} className="text-[#52525b] hover:text-[#fafafa] transition-colors p-2 rounded-xl hover:bg-[#27272a]">
            <I.X />
          </button>
        </div>

        {/* Body */}
        <div className="max-h-[55vh] overflow-y-auto">
          {imgSrc ? (
            <div className="flex flex-col items-center p-5 gap-3">
              <img
                src={imgSrc} alt={m.filename}
                className="max-w-full rounded-xl border border-[#27272a] shadow-xl"
                style={{ maxHeight: '350px', objectFit: 'contain' }}
              />
            </div>
          ) : m.content_preview ? (
            <div className="p-5">
              <p className="text-sm text-[#a1a1aa] leading-relaxed whitespace-pre-wrap">{m.content_preview}</p>
            </div>
          ) : (
            <div className="p-5 flex flex-col items-center gap-3 py-10">
              <span className="text-[#27272a] text-4xl">{m.type === 'video' ? '🎬' : '📄'}</span>
              <p className="text-sm text-[#52525b]">No preview available</p>
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="px-5 py-3 border-t border-[#1c1c1f] flex items-center justify-between">
          <span className="text-xs text-[#52525b]">
            {m.source ? `via ${m.source.toUpperCase()}` : 'Knowledge base'}
          </span>
          {m.source === 'pdf' && source.url && (
            <a href={source.url} target="_blank" rel="noopener"
              className="text-xs text-indigo-400 hover:text-indigo-300 transition-colors flex items-center gap-1">
              Open PDF ↗
            </a>
          )}
        </div>
      </div>
    </div>
  );
}

// ── Source Chip ───────────────────────────────────────────────────────────
function SourceChip({ source, onClick }) {
  const m = source.metadata || {};
  const imgSrc = source.url || m.data_url;
  const score = Math.round((source.score || 0) * 100);
  const isImg = m.type === 'image';
  const isVid = m.type === 'video';

  return (
    <button
      onClick={onClick}
      className="source-chip shrink-0 flex items-center gap-2 pl-2 pr-3 py-1.5 bg-[#18181b] hover:bg-[#222228] border border-[#27272a] hover:border-[#3f3f46] rounded-xl text-xs transition-all group"
      style={{ backdropFilter: 'blur(8px)' }}
    >
      {isImg && imgSrc ? (
        <img src={imgSrc} alt="" className="w-6 h-6 object-cover rounded-lg shrink-0" />
      ) : (
        <span className={`shrink-0 ${isVid ? 'text-purple-400' : isImg ? 'text-orange-400' : 'text-indigo-400/70'}`}>
          {isImg ? <I.Image size={14}/> : isVid ? <I.Video size={14}/> : <I.File size={14}/>}
        </span>
      )}
      <span className="max-w-[120px] truncate text-[#71717a] group-hover:text-[#a1a1aa] transition-colors">
        {m.filename || source.id}
      </span>
      <span className="text-[#3f3f46] shrink-0 group-hover:text-[#52525b] transition-colors">{score}%</span>
    </button>
  );
}

// ── Message Bubble ────────────────────────────────────────────────────────
function MessageBubble({ message, onSourceClick }) {
  const isUser = message.role === 'user';
  const sources = message.sources || [];

  if (isUser) {
    return (
      <div className="msg-enter flex justify-end">
        <div className="max-w-[75%] px-4 py-3 rounded-2xl rounded-tr-sm text-[15px] leading-relaxed"
          style={{
            background: 'linear-gradient(135deg, rgba(99,102,241,0.22) 0%, rgba(99,102,241,0.13) 100%)',
            border: '1px solid rgba(99,102,241,0.28)',
            color: '#f0f0f5',
            whiteSpace: 'pre-wrap',
            wordBreak: 'break-word',
          }}>
          {message.content}
        </div>
      </div>
    );
  }

  return (
    <div className="msg-enter flex gap-3 items-start">
      {/* Avatar */}
      <div className="shrink-0 mt-1 w-8 h-8 rounded-xl flex items-center justify-center logo-glow"
        style={{ background: 'rgba(99,102,241,0.12)', border: '1px solid rgba(99,102,241,0.25)', color: '#818cf8', minWidth: 32 }}>
        <I.Stars size={14} />
      </div>

      {/* Content */}
      <div className="flex-1 min-w-0 flex flex-col gap-3">
        <div className="prose-custom" dangerouslySetInnerHTML={{ __html: renderMarkdown(message.content) }} />

        {sources.length > 0 && (
          <div className="flex flex-col gap-2 pt-1">
            <span className="text-xs font-medium uppercase tracking-wider" style={{ color: '#3f3f46' }}>Sources</span>
            <div className="flex gap-2 overflow-x-auto pb-1 sources-row flex-wrap">
              {sources.slice(0, 6).map((s, i) => (
                <SourceChip key={s.id || i} source={s} onClick={() => onSourceClick(s)} />
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

// ── Thinking Indicator ────────────────────────────────────────────────────
function ThinkingIndicator() {
  return (
    <div className="msg-enter flex items-start gap-3">
      <div className="shrink-0 mt-1 w-8 h-8 rounded-xl flex items-center justify-center logo-glow"
        style={{ background: 'rgba(99,102,241,0.12)', border: '1px solid rgba(99,102,241,0.25)', color: '#818cf8', minWidth: 32 }}>
        <I.Stars size={14} />
      </div>
      <div className="flex items-center gap-1.5 py-3 px-1">
        {[0, 150, 300].map(d => (
          <span key={d} className="thinking-dot w-2 h-2 rounded-full bg-indigo-400/50" style={{ animationDelay: `${d}ms` }} />
        ))}
      </div>
    </div>
  );
}

// ── Welcome Screen ────────────────────────────────────────────────────────
function WelcomeScreen({ onSuggest }) {
  const cards = [
    { emoji: '📄', label: 'Summarize my documents' },
    { emoji: '🖼️', label: 'Show my uploaded photos' },
    { emoji: '🔍', label: 'Find notes about...' },
    { emoji: '📊', label: 'What did I upload today?' },
  ];
  return (
    <div className="flex flex-col items-center justify-center flex-1 px-6 py-16 text-center select-none">
      <div className="w-16 h-16 rounded-2xl flex items-center justify-center mb-6 logo-glow"
        style={{ background: 'rgba(99,102,241,0.12)', border: '1px solid rgba(99,102,241,0.25)', color: '#818cf8' }}>
        <I.Stars size={26} />
      </div>
      <h1 className="text-3xl font-bold text-[#fafafa] mb-2 tracking-tight">NeuralKB</h1>
      <p className="text-[#52525b] text-sm mb-10 max-w-xs leading-relaxed">
        Your personal AI knowledge base. Ask anything about the documents, images and files you've uploaded.
      </p>
      <div className="grid grid-cols-2 gap-3 w-full max-w-md">
        {cards.map((c, i) => (
          <button key={i} onClick={() => onSuggest(c.label)}
            className="flex items-center gap-3 p-4 rounded-2xl text-left transition-all group"
            style={{ background: '#111113', border: '1px solid #1c1c1f' }}
            onMouseEnter={e => e.currentTarget.style.borderColor = '#3f3f46'}
            onMouseLeave={e => e.currentTarget.style.borderColor = '#1c1c1f'}
          >
            <span className="text-xl">{c.emoji}</span>
            <span className="text-sm text-[#52525b] group-hover:text-[#a1a1aa] transition-colors leading-snug">{c.label}</span>
          </button>
        ))}
      </div>
    </div>
  );
}

// ── Upload Drop Zone ──────────────────────────────────────────────────────
function DropZone({ onFile }) {
  const [drag, setDrag] = useState(false);
  const ref = useRef();
  return (
    <div
      className={`rounded-xl border-2 border-dashed p-4 flex flex-col items-center gap-1.5 cursor-pointer transition-all duration-200 ${
        drag ? 'border-indigo-500 bg-indigo-600/8 scale-[1.02]' : 'border-[#27272a] hover:border-indigo-500/40'
      }`}
      onClick={() => ref.current.click()}
      onDragOver={e => { e.preventDefault(); setDrag(true); }}
      onDragLeave={() => setDrag(false)}
      onDrop={e => { e.preventDefault(); setDrag(false); const f = e.dataTransfer.files[0]; if (f) onFile(f); }}
    >
      <input ref={ref} type="file" className="hidden"
        accept="image/*,video/*,.pdf,.docx,.txt,.md,.csv"
        onChange={e => { if (e.target.files[0]) onFile(e.target.files[0]); e.target.value = ''; }}
      />
      <span className="text-indigo-500/50 mt-1"><I.Upload size={20}/></span>
      <p className="text-xs text-[#52525b] text-center">Drop or click to browse</p>
      <p className="text-xs text-[#3f3f46]">Images · Videos · PDF · DOCX · TXT</p>
    </div>
  );
}

// ── Sidebar ───────────────────────────────────────────────────────────────
function Sidebar({ model, setModel, pendingFile, setPendingFile, tag, setTag,
  onUpload, uploadQueue, uploadOpen, setUploadOpen, onNewChat, onClose }) {

  return (
    <aside className="flex flex-col h-full bg-[#0d0d10] border-r border-[#1a1a1f]" style={{ width: 272 }}>
      {/* Logo */}
      <div className="flex items-center gap-3 px-4 py-4 border-b border-[#1a1a1f]">
        <div className="w-8 h-8 rounded-xl flex items-center justify-center logo-glow shrink-0"
          style={{ background: 'rgba(99,102,241,0.12)', border: '1px solid rgba(99,102,241,0.25)', color: '#818cf8' }}>
          <I.Stars size={14} />
        </div>
        <span className="font-bold text-[#fafafa] tracking-tight text-sm">NeuralKB</span>
        <button onClick={onClose} className="ml-auto text-[#3f3f46] hover:text-[#fafafa] transition-colors lg:hidden p-1">
          <I.X size={16}/>
        </button>
      </div>

      <div className="flex flex-col gap-1 p-3">
        {/* New chat */}
        <button onClick={onNewChat}
          className="flex items-center gap-2.5 px-3 py-2.5 rounded-xl text-sm transition-all"
          style={{ color: '#71717a', border: '1px solid #1c1c1f' }}
          onMouseEnter={e => { e.currentTarget.style.background = '#18181b'; e.currentTarget.style.color = '#e4e4e7'; }}
          onMouseLeave={e => { e.currentTarget.style.background = ''; e.currentTarget.style.color = '#71717a'; }}>
          <I.Plus size={15}/> New chat
        </button>
      </div>

      {/* Model picker */}
      <div className="px-3 pb-2">
        <label className="text-xs text-[#3f3f46] px-1 mb-1.5 block font-medium uppercase tracking-widest">Model</label>
        <div className="relative">
          <select value={model} onChange={e => setModel(e.target.value)}
            className="w-full appearance-none bg-[#111113] border border-[#1c1c1f] text-[#71717a] text-sm rounded-xl px-3 py-2.5 pr-8 focus:outline-none focus:border-indigo-500/40 cursor-pointer transition-colors hover:border-[#27272a]">
            <option value="kimi-k2.5">⚡ Kimi K2.5 — Fastest</option>
            <option value="glm-5">⚖️ GLM-5 — Balanced</option>
          </select>
          <span className="absolute right-3 top-1/2 -translate-y-1/2 text-[#3f3f46] pointer-events-none">
            <I.ChevDown size={14}/>
          </span>
        </div>
      </div>

      {/* Upload section */}
      <div className="px-3 pb-2">
        <button onClick={() => setUploadOpen(o => !o)}
          className="flex items-center gap-2 w-full px-1 py-2 text-xs text-[#3f3f46] hover:text-[#71717a] transition-colors uppercase tracking-widest font-medium">
          <I.Upload size={13}/>
          <span>Upload Files</span>
          <span className={`ml-auto transition-transform duration-200 ${uploadOpen ? 'rotate-90' : ''}`}>
            <I.ChevRight size={13}/>
          </span>
        </button>

        {uploadOpen && (
          <div className="flex flex-col gap-2 animate-fade-down mt-1">
            {pendingFile ? (
              <div className="flex flex-col gap-2">
                <div className="flex items-center gap-2 px-3 py-2 rounded-xl text-xs text-[#71717a]"
                  style={{ background: '#111113', border: '1px solid #1c1c1f' }}>
                  <I.File size={13}/>
                  <span className="truncate flex-1 text-[#a1a1aa]">{pendingFile.name}</span>
                  <button onClick={() => setPendingFile(null)} className="text-[#3f3f46] hover:text-red-400 transition-colors">
                    <I.X size={12}/>
                  </button>
                </div>
                <input type="text" value={tag} onChange={e => setTag(e.target.value)}
                  placeholder='Add a tag (e.g. "Devi photo")'
                  className="w-full bg-[#111113] border border-[#1c1c1f] focus:border-indigo-500/40 text-sm text-[#e4e4e7] placeholder-[#3f3f46] rounded-xl px-3 py-2 focus:outline-none transition-colors"
                  onKeyDown={e => { if (e.key === 'Enter') { onUpload(pendingFile, tag); setPendingFile(null); setTag(''); }}}
                />
                <button
                  onClick={() => { onUpload(pendingFile, tag); setPendingFile(null); setTag(''); }}
                  className="w-full flex items-center justify-center gap-2 py-2.5 rounded-xl text-sm font-medium text-white transition-all active:scale-95"
                  style={{ background: 'linear-gradient(135deg, #6366f1 0%, #818cf8 100%)', boxShadow: '0 0 20px rgba(99,102,241,0.3)' }}>
                  <I.Upload size={14}/> Upload & Index
                </button>
              </div>
            ) : (
              <DropZone onFile={f => setPendingFile(f)} />
            )}

            {/* Upload queue */}
            {uploadQueue.length > 0 && (
              <div className="flex flex-col gap-1.5 mt-1">
                {uploadQueue.map(q => (
                  <div key={q.id} className="rounded-xl overflow-hidden" style={{ background: '#111113', border: '1px solid #1c1c1f' }}>
                    <div className="flex items-center gap-2 px-3 py-2 text-xs">
                      <I.File size={12} className="shrink-0" style={{ color: '#3f3f46' }} />
                      <span className="truncate flex-1 text-[#71717a]">{q.filename}</span>
                      <span className={q.status === 'done' ? 'text-emerald-400' : q.status === 'error' ? 'text-red-400' : 'text-indigo-400'}>
                        {q.status === 'done' ? '✓' : q.status === 'error' ? '✗' : `${q.progress}%`}
                      </span>
                    </div>
                    {q.status === 'uploading' && (
                      <div className="h-0.5 bg-[#1c1c1f]">
                        <div className="h-full bg-indigo-500 transition-all duration-300 rounded-full" style={{ width: `${q.progress}%` }} />
                      </div>
                    )}
                  </div>
                ))}
              </div>
            )}
          </div>
        )}
      </div>

      {/* Chat history */}
      <div className="flex-1 overflow-y-auto px-3 py-2">
        <p className="text-xs text-[#3f3f46] px-1 mb-2 uppercase tracking-widest font-medium">History</p>
        <div className="flex flex-col gap-0.5">
          {['Current session'].map((h, i) => (
            <div key={i} className="px-3 py-2 rounded-xl text-xs text-[#3f3f46] truncate"
              style={{ background: '#111113', border: '1px solid #1a1a1f' }}>
              {h}
            </div>
          ))}
        </div>
      </div>

      {/* Logout */}
      <div className="px-3 py-3 border-t border-[#1a1a1f]">
        <a href="/logout"
          className="flex items-center gap-2.5 px-3 py-2.5 rounded-xl text-sm text-[#3f3f46] hover:text-red-400 transition-all w-full group"
          onMouseEnter={e => e.currentTarget.style.background = 'rgba(239,68,68,0.06)'}
          onMouseLeave={e => e.currentTarget.style.background = ''}>
          <I.LogOut size={15}/> Sign out
        </a>
      </div>
    </aside>
  );
}

// ── Input Bar ─────────────────────────────────────────────────────────────
function InputBar({ input, setInput, onSend, thinking, onFilePick }) {
  const taRef = useRef();

  useEffect(() => {
    const ta = taRef.current;
    if (!ta) return;
    ta.style.height = 'auto';
    ta.style.height = Math.min(ta.scrollHeight, 160) + 'px';
  }, [input]);

  return (
    <div className="px-4 pb-5 pt-2">
      <div className="flex items-end gap-3 rounded-2xl px-4 py-3 transition-all"
        style={{ background: '#111113', border: '1px solid #1c1c1f', boxShadow: '0 4px 24px rgba(0,0,0,0.4)' }}
        onFocus={() => {}} // border focus handled via CSS
      >
        <button onClick={onFilePick} title="Upload file"
          className="text-[#3f3f46] hover:text-indigo-400 transition-colors pb-0.5 shrink-0">
          <I.Clip size={18}/>
        </button>
        <textarea
          ref={taRef}
          value={input}
          onChange={e => setInput(e.target.value)}
          onKeyDown={e => { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); onSend(); } }}
          placeholder="Ask anything about your knowledge base…"
          rows={1}
          disabled={thinking}
          className="flex-1 bg-transparent resize-none text-sm text-[#e4e4e7] placeholder-[#3f3f46] focus:outline-none leading-relaxed"
          style={{ maxHeight: 160 }}
        />
        <button
          onClick={onSend}
          disabled={!input.trim() || thinking}
          className="shrink-0 w-9 h-9 rounded-xl flex items-center justify-center transition-all active:scale-95"
          style={input.trim() && !thinking ? {
            background: 'linear-gradient(135deg, #6366f1 0%, #818cf8 100%)',
            boxShadow: '0 0 20px rgba(99,102,241,0.4)',
            color: 'white',
          } : {
            background: '#18181b',
            color: '#3f3f46',
            cursor: 'not-allowed',
          }}>
          {thinking
            ? <span className="w-4 h-4 border-2 border-white/20 border-t-white/80 rounded-full animate-spin" />
            : <I.Send size={14}/>}
        </button>
      </div>
      <p className="text-center text-xs mt-2" style={{ color: '#2a2a32' }}>
        NeuralKB may make mistakes — always verify important information
      </p>
    </div>
  );
}

// ── App Root ──────────────────────────────────────────────────────────────
function App() {
  const [messages, setMessages] = useState([]);
  const [thinking, setThinking] = useState(false);
  const [input, setInput] = useState('');
  const [model, setModel] = useState('kimi-k2.5');
  const [sidebarOpen, setSidebarOpen] = useState(window.innerWidth >= 1024);
  const [activeSource, setActiveSource] = useState(null);
  const [toasts, setToasts] = useState([]);
  const [pendingFile, setPendingFile] = useState(null);
  const [tag, setTag] = useState('');
  const [uploadQueue, setUploadQueue] = useState([]);
  const [uploadOpen, setUploadOpen] = useState(true);
  const bottomRef = useRef();

  const addToast = useCallback((type, msg) => {
    setToasts(prev => [...prev, { id: Date.now() + Math.random(), type, message: msg }]);
  }, []);
  const dismissToast = useCallback(id => setToasts(prev => prev.filter(t => t.id !== id)), []);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, thinking]);

  const sendMessage = async (text) => {
    const content = (text || input).trim();
    if (!content || thinking) return;
    setMessages(prev => [...prev, { id: Date.now(), role: 'user', content }]);
    setInput('');
    setThinking(true);
    try {
      const res = await fetch('/api/chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ message: content, model }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || `Error ${res.status}`);
      setMessages(prev => [...prev, { id: Date.now() + 1, role: 'assistant', content: data.answer, sources: data.sources || [] }]);
    } catch (e) {
      addToast('error', e.message);
    } finally {
      setThinking(false);
    }
  };

  const uploadFile = async (file, fileTag) => {
    const qid = Date.now() + Math.random();
    setUploadQueue(prev => [...prev, { id: qid, filename: file.name, progress: 0, status: 'uploading' }]);
    const fd = new FormData();
    fd.append('file', file);
    fd.append('tag', fileTag || '');
    try {
      await new Promise((resolve, reject) => {
        const xhr = new XMLHttpRequest();
        xhr.open('POST', '/api/upload');
        xhr.upload.onprogress = e => {
          if (e.lengthComputable) {
            const pct = Math.round(e.loaded / e.total * 100);
            setUploadQueue(prev => prev.map(q => q.id === qid ? { ...q, progress: pct } : q));
          }
        };
        xhr.onload = () => {
          try { const d = JSON.parse(xhr.responseText); d.error ? reject(new Error(d.error)) : resolve(d); }
          catch { reject(new Error('Invalid server response')); }
        };
        xhr.onerror = () => reject(new Error('Network error'));
        xhr.send(fd);
      });
      setUploadQueue(prev => prev.map(q => q.id === qid ? { ...q, progress: 100, status: 'done' } : q));
      addToast('success', `✓ "${file.name}" indexed successfully`);
      setTimeout(() => setUploadQueue(prev => prev.filter(q => q.id !== qid)), 5000);
    } catch (e) {
      setUploadQueue(prev => prev.map(q => q.id === qid ? { ...q, status: 'error' } : q));
      addToast('error', `Upload failed: ${e.message}`);
    }
  };

  return (
    <div className="flex h-screen overflow-hidden" style={{ background: '#09090b' }}>
      {/* Mobile backdrop */}
      {sidebarOpen && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-20 lg:hidden"
          onClick={() => setSidebarOpen(false)} />
      )}

      {/* Sidebar */}
      <div className={`fixed lg:relative z-30 h-full sidebar-transition ${sidebarOpen ? 'translate-x-0' : '-translate-x-full'} lg:translate-x-0`}>
        <Sidebar
          model={model} setModel={setModel}
          pendingFile={pendingFile} setPendingFile={setPendingFile}
          tag={tag} setTag={setTag}
          onUpload={uploadFile}
          uploadQueue={uploadQueue}
          uploadOpen={uploadOpen} setUploadOpen={setUploadOpen}
          onNewChat={() => setMessages([])}
          onClose={() => setSidebarOpen(false)}
        />
      </div>

      {/* Main content */}
      <main className="flex flex-col flex-1 min-w-0 overflow-hidden">
        {/* Header */}
        <header className="shrink-0 flex items-center gap-3 px-5 py-3.5 border-b border-[#1a1a1f]">
          <button onClick={() => setSidebarOpen(o => !o)}
            className="text-[#3f3f46] hover:text-[#a1a1aa] transition-colors p-1.5 rounded-xl hover:bg-[#18181b] lg:hidden">
            <I.Menu />
          </button>
          <span className="text-sm font-medium text-[#3f3f46]">
            {messages.length > 0 ? 'Conversation' : 'New conversation'}
          </span>
          <div className="ml-auto flex items-center gap-2">
            <span className="text-xs text-[#2a2a32] hidden sm:block">
              {model === 'kimi-k2.5' ? '⚡ Kimi K2.5' : '⚖️ GLM-5'}
            </span>
          </div>
        </header>

        {/* Messages */}
        <div className="flex-1 overflow-y-auto px-6 py-6 flex flex-col">
          {messages.length === 0 ? (
            <WelcomeScreen onSuggest={text => { setInput(text); setTimeout(() => sendMessage(text), 50); }} />
          ) : (
            <div className="flex flex-col gap-7 w-full">
              {messages.map(m => (
                <MessageBubble key={m.id} message={m} onSourceClick={setActiveSource} />
              ))}
              {thinking && <ThinkingIndicator />}
              <div ref={bottomRef} />
            </div>
          )}
        </div>

        {/* Input */}
        <div className="shrink-0 w-full">
          <InputBar
            input={input} setInput={setInput}
            onSend={() => sendMessage()}
            thinking={thinking}
            onFilePick={() => { setUploadOpen(true); setSidebarOpen(true); }}
          />
        </div>
      </main>

      {/* Modals & Overlays */}
      {activeSource && <SourceModal source={activeSource} onClose={() => setActiveSource(null)} />}
      <div className="fixed top-4 right-4 z-50 flex flex-col gap-2 max-w-sm">
        {toasts.map(t => <Toast key={t.id} toast={t} onDismiss={dismissToast} />)}
      </div>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
