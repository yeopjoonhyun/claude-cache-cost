#!/usr/bin/env bash
# cache-cost 모드 설치 (macOS / Linux)
# 1) ~/.claude/mods/cache-cost 에 모드 파일 3개를 쓰고
# 2) ~/.claude/settings.json 의 env.CLAUDE_CODE_PLUGIN_DIRS 에 그 폴더를 등록한다.
set -euo pipefail

DIR="$HOME/.claude/mods/cache-cost"
SETTINGS="$HOME/.claude/settings.json"

mkdir -p "$DIR/.claude-plugin" "$DIR/hooks"

cat > "$DIR/.claude-plugin/plugin.json" <<'EOF'
{ "name": "cache-cost", "version": "0.1.0", "description": "Status line: prompt cache time left and this session's cost" }
EOF

cat > "$DIR/hooks/hooks.json" <<'EOF'
{ "modules": ["./register.ts"] }
EOF

cat > "$DIR/hooks/register.ts" <<'EOF'
import type { EngineInterface, Register } from 'claude-code'

// The prompt cache lives this long after the last model response (1h tier).
// Set to 5 * 60_000 if your account uses the 5 minute tier.
const CACHE_TTL_MS = 60 * 60_000
const REFRESH_MS = 15_000

let lastResponseAt: number | undefined

async function draw($: EngineInterface) {
  const [now, usage] = await Promise.all([$.clock.now(), $.session.usage()])
  const parts: string[] = []

  if (lastResponseAt === undefined) {
    parts.push('캐시 없음')
  } else {
    const leftMin = Math.ceil((lastResponseAt + CACHE_TTL_MS - now) / 60_000)
    parts.push(leftMin > 0 ? `캐시 ${leftMin}분 남음` : '캐시 만료')
  }

  if (usage.cost) parts.push(`$${usage.cost.usd.toFixed(2)}`)
  if (usage.context.percent !== undefined) parts.push(`ctx ${usage.context.percent}%`)

  $.ui.status(parts.join(' | '))
}

export const register: Register = (on) => {
  on('session.start', async ($, e, next) => {
    $.clock.every(REFRESH_MS, () => void draw($))
    void draw($)
    return next(e)
  })

  on('turn.complete', async ($, e, next) => {
    const result = await next(e)
    // A main-loop turn that made a real request refreshed the cache.
    if (e.agentId === undefined && e.usage !== undefined) {
      lastResponseAt = await $.clock.now()
    }
    void draw($)
    return result
  })
}
EOF

python3 - "$SETTINGS" "$DIR" <<'EOF'
import json, os, sys

path, mod = sys.argv[1], sys.argv[2]
data = {}
if os.path.exists(path):
    with open(path, encoding="utf-8") as f:
        data = json.load(f)

env = data.setdefault("env", {})
current = [p for p in env.get("CLAUDE_CODE_PLUGIN_DIRS", "").split(os.pathsep) if p]
if mod not in current:
    current.append(mod)
env["CLAUDE_CODE_PLUGIN_DIRS"] = os.pathsep.join(current)

with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
    f.write("\n")
EOF

echo "설치 완료: $DIR"
echo "새 Claude Code 세션을 열면 상태 줄에 캐시/비용이 표시됩니다."
