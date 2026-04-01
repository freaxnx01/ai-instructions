Generate user-friendly release notes in RELEASENOTES.md from git history.

Context: $ARGUMENTS

## Steps

1. Read current version from `Directory.Build.props`
2. List git tags: `git tag --sort=-v:refname`
3. Read existing `RELEASENOTES.md` — identify which versions already have entries
4. For each missing version, get commits: `git log <prev-tag>..<tag> --oneline --no-merges`
5. Write user-friendly summaries in English:
   - Audience: end users, not developers
   - Group by: New Features / Improvements / Bug Fixes (skip empty groups)
   - Combine related commits into clear bullet points (3-8 per version)
   - Skip chore, ci, refactor, test, docs commits unless user-visible
6. Insert new entries after the header, before existing entries (latest first)
7. Never modify existing entries
8. Read back the file to verify, report what was added

## Rules
- Never modify or regenerate existing entries
- No commit hashes, PR numbers, or module prefixes in output
- If no missing versions, say so and stop
- Do not commit — user reviews and commits separately
