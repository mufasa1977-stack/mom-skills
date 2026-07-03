# mom-brain  (self-updating AI package for Mom's Claude Code)

One source of truth for Mom's assistant: the operating **brain** (CLAUDE.md), a bundle of general
**skills**, and a memory scaffold. All portable, no secrets, no personal paths, no session-trapping hooks.

## First-time install on her PC
`git clone https://github.com/mufasa1977-stack/mom-skills ~/mom-brain`
`powershell -ExecutionPolicy Bypass -File ~/mom-brain/install.ps1`   (then restart Claude Code)

## Update anytime (as the brain/skills get better)
`powershell -ExecutionPolicy Bypass -File ~/mom-brain/update.ps1`   (git pull + reinstall; backs up first)
Or just tell her Claude: **"update yourself"** — its brain knows how.
