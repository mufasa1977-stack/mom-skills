---
name: website-deploy-hostgator
description: >-
  Edit and PUBLISH a website hosted on cPanel shared hosting (HostGator, Bluehost, SiteGround,
  A2, InMotion — anything with cPanel + FTPS) directly from this machine, instead of walking the
  user through File Manager clicks. Triggers on: "update my website", "change the text on my
  site", "put this on my homepage", "the site still shows the old page", "add a section to my
  transportation page", or any request to change a live site the user owns. Replaces the
  screenshot-and-name-the-next-click loop with a real edit-preview-deploy-verify cycle.
---

# website-deploy-hostgator

## The failure this exists to kill

A helper with no deploy path falls back to "take a screenshot and I'll tell you where to click."
That loop is slow, it guesses at what is on screen, and it strands finished work on the wrong
machine — the classic symptom being a site that still shows the OLD page days after the new one
was "uploaded" (it landed as `index (4).html` because the upload would not overwrite).

With this skill you do the whole thing: pull the live file, edit it locally, preview it, upload it,
and prove it went live by reading the site back.

## One-time setup (the owner does this once)

Credentials never live in the repo and are never typed by the assistant.

1. The owner creates an FTP account in cPanel (**Files → FTP Accounts**) — or uses the main one —
   and notes the **host**, **username**, **password**, and the site's document root
   (commonly `/public_html`, on HostGator often `/home2/<acct>/public_html`).
2. The owner saves them in a local file, outside any git repo — `~/.site_deploy.json`:

```json
{
  "host": "ftp.example.com",
  "user": "deploy@example.com",
  "password": "THE-OWNER-TYPES-THIS",
  "remote_root": "/public_html",
  "site_url": "https://example.com"
}
```

3. Add `.site_deploy.json` to `.gitignore`. Never commit it, never print it, never paste it into a
   chat. Read it only to hand values to `curl`.

## The cycle — run all four phases, in order

```bash
# 0. load config (never echo it)
CFG=~/.site_deploy.json
HOST=$(jq -r .host $CFG); USER=$(jq -r .user $CFG); PASS=$(jq -r .password $CFG)
ROOT=$(jq -r .remote_root $CFG); URL=$(jq -r .site_url $CFG)

# 1. PULL the current live file (never edit blind)
curl -s --ftp-ssl -u "$USER:$PASS" "ftp://$HOST$ROOT/index.html" -o index.html

# 2. BACK UP the remote copy before you overwrite it
curl -s --ftp-ssl -u "$USER:$PASS" -T index.html "ftp://$HOST$ROOT/index-backup-$(date +%Y%m%d-%H%M).html"

#    ...now edit index.html locally and preview it: python3 -m http.server 8000

# 3. DEPLOY
curl -s --ftp-ssl -u "$USER:$PASS" -T index.html "ftp://$HOST$ROOT/index.html"

# 4. VERIFY FROM THE OUTSIDE — this is the only proof
curl -sI "$URL" | grep -i "last-modified"
curl -s "$URL" | grep -ci "the exact new text you added"    # must be >= 1
```

PowerShell equivalent for step 3/4 when `curl`/`jq` are unavailable:

```powershell
$c = Get-Content ~/.site_deploy.json | ConvertFrom-Json
$cred = New-Object System.Net.NetworkCredential($c.user, $c.password)
$wc = New-Object System.Net.WebClient; $wc.Credentials = $cred
$wc.UploadFile("ftp://$($c.host)$($c.remote_root)/index.html", "STOR", "index.html")
(Invoke-WebRequest $c.site_url).Headers['Last-Modified']
```

## Laws

1. **VERIFY FROM THE PUBLIC URL, never from your own notes.** A note saying the site is updated is
   not evidence. `curl` the live URL and grep for the new text. A stale note claiming "still shows
   coming soon" has caused a helper to re-walk an owner through a fix that was already finished —
   which reads to them as the assistant having gotten stupid.
2. **Back up the remote file before every overwrite.** Shared hosting has no undo.
3. **Never upload alongside — always overwrite the real filename.** A file that lands as
   `index (4).html` or `index-new.html` means the live site did not change. If the upload will not
   overwrite, rename the old one first (`index-old.html`), then upload to the true name.
4. **Never print, log, or commit the credentials.** Read them from the config at run time only. The
   password is the owner's to type, once, into that file.
5. **One page at a time, and say what changed.** After deploying, tell the owner in one sentence what
   is now live and give them the URL to look at.

## If there is no FTP access yet

Do not fall back to "send me a screenshot and I'll name the clicks" as the permanent plan. Do the
task that way once if it is urgent, then set up the config above so it never has to happen again.
