---
name: github-actions
globs: [".github/workflows/**", ".github/actions/**"]
---

## GitHub Actions Conventions

### Reusable workflows

Public reusable workflows are the primary deliverable. Define inputs and outputs explicitly:

```yaml
on:
  workflow_call:
    inputs:
      runner-labels:
        description: JSON array of runner labels
        type: string
        default: '["ubuntu-latest"]'
      timeout-minutes:
        type: number
        default: 30
    secrets:
      TOKEN:
        required: true
```

- **One reusable workflow per public entry point.** Don't multiplex unrelated triggers in one file.
- **Pin every action by full SHA**, not by tag. Renovate/Dependabot promotes the SHA.

  ```yaml
  - uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11  # v4.1.1
  ```

- **Concurrency control** on every long-running workflow: cancel in-progress runs of the same ref.

  ```yaml
  concurrency:
    group: ${{ github.workflow }}-${{ github.ref }}
    cancel-in-progress: true
  ```

- **Permissions: least-privilege.** Top of the workflow:

  ```yaml
  permissions:
    contents: read
  ```

  Then escalate per-job only where needed (`pull-requests: write`, `issues: write`, `id-token: write`).
- **`timeout-minutes:` on every job.** Defaults of 6 hours are not safe defaults.
- **Output extraction in scripts, not inline bash.** Inline bash in YAML is unlinted, untested, hard to read. One-liners excepted.

### Composite actions

Use composite actions for steps reused across multiple workflows in the same repo. Keep them in `.github/actions/<name>/action.yml`. A composite action without tests does not exist.

### Self-hosted runners

- **Never attach self-hosted runners to public repos.** Pwn-request attack surface. Public repos must use `ubuntu-latest` (or other GitHub-hosted) permanently.
- Self-hosted labels conventional: `[self-hosted, <site>, <purpose>]` (e.g. `[self-hosted, homelab, claude]`).
- The runner toolchain contract is defined in `docs/RUNNER-REQUIREMENTS.md` and provisioned by an Ansible role in the homelab repo — not by the workflow repo itself.
