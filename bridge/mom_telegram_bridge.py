"""
mom_telegram_bridge.py — text your Claude Code assistant from your phone.

You (or a family member) text a Telegram bot from your phone -> this bridge runs ONE
headless Claude Code turn on this laptop (full skills + memory), with permissions
AUTO-APPROVED (no "allow?" prompts), and texts the result back. Conversation context
persists across messages via --resume <session_id>, so it's one continuous chat. Photos
you send are downloaded and read too.

SAFETY: runs claude with --dangerously-skip-permissions so you never have to press allow
from your phone. Any PreToolUse safety hooks STILL FIRE in this mode -> destructive commands
remain blocked. Auto-approve only removes the prompt, not the safety backstop. The bridge is
LOCKED to your own chat id — nobody else can drive it (unknown senders are logged, not obeyed;
the very first person to text 'claim' binds themselves, then it's locked to them).

Config (plain text files next to this script):
  bot_token.txt   the token BotFather gave you when you created the bot   (required)
  chat_id.txt     your Telegram chat id                                    (auto-filled on first 'claim')

Run:        python mom_telegram_bridge.py
Self-test:  python mom_telegram_bridge.py --selftest
Commands in chat:  /new (reset conversation) · /ping (health) · /whoami · /stop
"""
import json, os, shutil, socket, subprocess, sys, time
from datetime import datetime
from pathlib import Path
import requests

HERE = Path(__file__).resolve().parent
# The Claude Code project the phone drives. Defaults to this script's folder; override with
# a workspace.txt file (one line: an absolute path) if you keep the bridge separate from the
# workspace you actually want Claude to work in.
def _resolve_workspace():
    wf = HERE / "workspace.txt"
    if wf.exists():
        p = wf.read_text(encoding="utf-8").strip()
        if p and Path(p).is_dir():
            return Path(p)
    return HERE
WORKSPACE = _resolve_workspace()

TOKEN = (HERE / "bot_token.txt").read_text(encoding="utf-8").strip()
CHAT_FILE = HERE / "chat_id.txt"
CHAT_ID = CHAT_FILE.read_text(encoding="utf-8").strip() if CHAT_FILE.exists() else ""

STATE = HERE / "_bridge_state.json"
LOG = HERE / "_bridge.log"
PIDFILE = HERE / "_bridge.pid"
MEDIA_DIR = HERE / "_bridge_media"
MEDIA_DIR.mkdir(parents=True, exist_ok=True)
LOCK_PORT = 48733   # singleton lock (its own port so another bridge on the same network won't collide)
CLAUDE = shutil.which("claude") or shutil.which("claude.cmd") or "claude"
TURN_TIMEOUT = 1800   # 30 min per turn
API = f"https://api.telegram.org/bot{TOKEN}"

def chat_ids():
    ids = set()
    if CHAT_FILE.exists():
        for ln in CHAT_FILE.read_text(encoding="utf-8").splitlines():
            if ln.strip():
                ids.add(ln.strip())
    return ids

def log(m):
    line = f"[{datetime.now():%Y-%m-%d %H:%M:%S}] {m}"
    print(line, flush=True)
    try: LOG.open("a", encoding="utf-8").write(line + "\n")
    except Exception: pass

def load_state():
    if STATE.exists():
        try: return json.loads(STATE.read_text())
        except Exception: pass
    return {"offset": 0, "session_id": None}

def save_state(s): STATE.write_text(json.dumps(s, indent=2))

def bind_chat(cid: str):
    """Persist a newly-claimed chat id so the bridge stays locked to it across restarts."""
    existing = chat_ids()
    if cid not in existing:
        with CHAT_FILE.open("a", encoding="utf-8") as f:
            f.write(cid + "\n")

def send(text: str, to=None):
    """Send plain-text reply to every authorized chat (or a specific one), chunked to Telegram's limit."""
    targets = [to] if to else list(chat_ids())
    for cid in targets:
        for i in range(0, len(text) or 1, 3800):
            chunk = text[i:i+3800] or " "
            try:
                requests.post(f"{API}/sendMessage", data={"chat_id": cid, "text": chunk}, timeout=30)
            except Exception as e:
                log(f"send fail ({cid}): {e}")

def get_updates(offset):
    try:
        r = requests.get(f"{API}/getUpdates", params={"offset": offset, "timeout": 30}, timeout=60)
        return r.json().get("result", []) if r.status_code == 200 else None
    except Exception as e:
        log(f"getUpdates fail: {e}"); return None

def download_file(file_id: str, update_id: int, suffix: str):
    try:
        gf = requests.get(f"{API}/getFile", params={"file_id": file_id}, timeout=30).json()
        file_path = gf["result"]["file_path"]
        data = requests.get(f"https://api.telegram.org/file/bot{TOKEN}/{file_path}", timeout=90).content
        out = MEDIA_DIR / f"tg_{datetime.now():%Y%m%d_%H%M%S}_{update_id}{suffix}"
        out.write_bytes(data)
        log(f"downloaded image -> {out} ({len(data)} bytes)")
        return str(out)
    except Exception as e:
        log(f"image download FAILED: {e}"); return None

def run_claude(prompt: str, session_id):
    cmd = [CLAUDE, "-p", prompt, "--output-format", "json", "--dangerously-skip-permissions"]
    if session_id:
        cmd += ["--resume", session_id]
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, cwd=str(WORKSPACE),
                           timeout=TURN_TIMEOUT, encoding="utf-8", errors="replace")
    except subprocess.TimeoutExpired:
        return ("(that took over 30 min — it may still have done the work; send /new if it seems stuck)", session_id, False)
    if p.returncode != 0:
        return (f"(claude exited {p.returncode})\n{(p.stderr or p.stdout or '')[-1500:]}", session_id, False)
    try:
        data = json.loads(p.stdout)
        return (data.get("result") or "(no text result)", data.get("session_id") or session_id, not data.get("is_error", False))
    except Exception:
        return (p.stdout[-3500:] if p.stdout else "(empty output)", session_id, True)

def handle(text: str, state) -> bool:
    low = text.strip().lower()
    if low == "/stop":
        send("🛑 Bridge shutting down. Restart it with start_bridge.bat on the laptop."); return False
    if low == "/ping":
        send("🟢 alive. session=" + (state["session_id"] or "new")); return True
    if low == "/whoami":
        send(f"locked to={sorted(chat_ids())}\nworkspace={WORKSPACE}\nclaude={CLAUDE}"); return True
    if low == "/new":
        state["session_id"] = None; save_state(state)
        send("🧠 New conversation started (context cleared)."); return True
    send("🧠 on it…")
    t0 = time.time()
    result, sid, ok = run_claude(text, state["session_id"])
    state["session_id"] = sid; save_state(state)
    mark = "✅" if ok else "⚠️"
    send(f"{mark} ({time.time()-t0:.0f}s)\n\n{result}")
    return True

def selftest():
    log("SELFTEST: token loaded, claude=" + str(CLAUDE) + f", workspace={WORKSPACE}")
    assert TOKEN, "missing bot_token.txt"
    log("SELFTEST: running a headless claude turn (skip-permissions)…")
    res, sid, ok = run_claude("Reply with exactly the single word: PONG", None)
    log(f"SELFTEST claude -> ok={ok} session={sid} result={res[:120]!r}")
    if chat_ids():
        send(f"🧪 Self-test: claude headless {'OK' if ok else 'FAILED'} → {res[:80]}")
    return ok

def acquire_singleton():
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        s.bind(("127.0.0.1", LOCK_PORT)); s.listen(1)
    except OSError:
        log(f"singleton lock busy (port {LOCK_PORT}) — another bridge is alive, exiting quietly")
        sys.exit(0)
    try: PIDFILE.write_text(str(os.getpid()))
    except Exception: pass
    return s

def main():
    if "--selftest" in sys.argv:
        sys.exit(0 if selftest() else 1)
    _lock = acquire_singleton()   # noqa: F841
    state = load_state()
    locked = chat_ids()
    log("=" * 56); log("MOM TELEGRAM BRIDGE online"); log(f"  workspace={WORKSPACE}  locked_to={sorted(locked)}"); log("=" * 56)
    if locked:
        send("🤖 Your Claude assistant is ONLINE. Text me anything and I'll work on it on the laptop and text you back.\n"
             "Commands: /new (fresh start) /ping /whoami /stop")
    else:
        log("No chat_id yet — waiting for the owner to text the bot the word: claim")
    running = True
    while running:
        updates = get_updates(state["offset"] + 1)
        if updates is None:
            time.sleep(10); continue
        for upd in updates:
            state["offset"] = max(state["offset"], upd["update_id"]); save_state(state)
            msg = upd.get("message") or upd.get("edited_message") or {}
            sender_id = str(msg.get("from", {}).get("id", ""))
            text = (msg.get("text") or "").strip()
            authorized = chat_ids()
            if sender_id not in authorized:
                frm = msg.get("from", {})
                log(f"UNKNOWN SENDER id={sender_id} name={frm.get('first_name')} user={frm.get('username')} text={text[:60]!r}")
                # First person to text 'claim' (or, if nobody is bound yet, ANY first texter) locks the bridge to themselves.
                if text.lower() == "claim" or not authorized:
                    bind_chat(sender_id)
                    send("✅ You're connected. This assistant is now locked to your phone. "
                         "Text me anything to work on the laptop. Commands: /new /ping /whoami", to=sender_id)
                    log(f"BOUND: {sender_id}")
                continue
            caption = (msg.get("caption") or "").strip()
            image_path = None
            if "photo" in msg:
                image_path = download_file(msg["photo"][-1]["file_id"], upd["update_id"], ".jpg")
            elif str(msg.get("document", {}).get("mime_type", "")).startswith("image/"):
                doc = msg["document"]
                suffix = Path(doc.get("file_name", "img")).suffix or ".img"
                image_path = download_file(doc["file_id"], upd["update_id"], suffix)
            prompt = text or caption
            if image_path:
                note = f"[The user sent an image from their phone — use the Read tool on this file to view it: {image_path}]"
                prompt = (prompt + "\n\n" + note) if prompt else note
            if not prompt:
                continue
            log(f"MSG: {prompt[:100]!r}")
            try:
                running = handle(prompt, state)
            except Exception as e:
                log(f"handle error: {e}"); send(f"⚠️ error: {str(e)[:300]}")
    log("bridge stopped.")

if __name__ == "__main__":
    main()
