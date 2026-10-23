# claude-actions

One place that runs [claude-code-action](https://github.com/marketplace/actions/claude-code-action-official) on every repo of this account.

- `sync.yml` runs hourly. It puts `stub.yml` at `.github/workflows/claude.yml` in every non-fork, non-archived repo and copies the token secrets in. New repos are covered within the hour; run it by hand for an instant sync.
- The stub calls `reusable.yml`, so changing the prompt or behaviour here changes every repo at once.
- Each PR gets one review when it opens (or leaves draft, or reopens). If that run never happened (GitHub skips it while the PR conflicts with its base) or failed, the next push to the PR runs it.
- Comment `@claude review` on a PR to review it again, for example after fixing what the review found. Comment `@claude ...` on a PR or issue to ask for anything else.
- Every run uses the Pro account first and retries with the Team account only when the Pro run fails.

## Secrets (in this repo only)

| Secret | What |
|---|---|
| `CLAUDE_CODE_OAUTH_TOKEN` | `claude setup-token` while signed in to the Pro account |
| `CLAUDE_CODE_OAUTH_TOKEN_TEAM` | `claude setup-token` while signed in to the Team account |
| `SYNC_TOKEN` | Fine-grained PAT, all repositories: Contents, Secrets and Workflows read/write |

Set them with `powershell -ExecutionPolicy Bypass -File set-secrets.ps1` (it runs `claude setup-token` for you and checks each paste looks right).
The Claude tokens last a year. To rotate one, run the script again and skip the other steps, then run **Sync**. Run **Check tokens** to see whether both work.

## Opt a repo out

Give it the topic `no-claude`, then delete its `.github/workflows/claude.yml`.
