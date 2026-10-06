# claude-cache-cost

Claude Code 상태 줄에 프롬프트 캐시 남은 시간과 세션 비용을 표시하는 모드.

```
캐시 58분 남음 | $15.50 | ctx 38%
```

## 설치 (macOS / Linux)

```bash
curl -fsSL https://raw.githubusercontent.com/yeopjoonhyun/claude-cache-cost/main/install.sh | bash
```

`~/.claude/mods/cache-cost`에 모드를 쓰고 `~/.claude/settings.json`의
`env.CLAUDE_CODE_PLUGIN_DIRS`에 등록합니다. 설치 후 새 세션부터 적용됩니다.
`python3`가 필요합니다.

## 설정

5분 캐시를 쓰는 계정이면 `~/.claude/mods/cache-cost/hooks/register.ts`의
`CACHE_TTL_MS`를 `5 * 60_000`으로 바꾸세요.
