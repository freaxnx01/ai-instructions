Build the approved UI component step by step (Phase 3 of 4). The wireframe and flow diagrams must be approved before starting. Stack-neutral — follow the active stack overlay (`.ai/stacks/<stack>.md`) for component-library specifics, file naming, and code-behind conventions.

Context: $ARGUMENTS

## Steps

1. **Shell only** — Create the component file(s) with:
   - Layout structure matching the approved wireframe, using the stack's preferred layout/container components
   - Placeholder comments where dynamic content will go
   - Service/dependency declarations (no implementation yet)
   - No business logic, no API calls, no real data
   - Present the shell. Wait for confirmation before Step 2.
2. **Wire up data & logic** —
   - Implement service calls
   - Bind data to the UI (stack's native binding mechanism)
   - Handle **loading** states (skeleton / spinner / progress indicator)
   - Handle **empty** states (clear message or empty-state widget)
   - Handle **API error** states (toast / snackbar / banner)
   - Present the result. Wait for confirmation before Step 3.
3. **Interactions & events** —
   - Implement action handlers and parent/child event wiring
   - Add a confirmation dialog for destructive actions
   - Add form validation using the stack's validation mechanism
   - Present the result. Wait for confirmation before Step 4.
4. **Polish** —
   - Apply consistent spacing using the stack's spacing utilities
   - Verify responsive behaviour at the expected breakpoints
   - Add tooltips on icon-only buttons
   - Verify icon set consistency (one family, one weight)

## Rules
- One step at a time — never skip ahead
- Keep view/markup files free of business logic — only binding and UI events
- Reuse from the project's shared/common folder — check before creating anything new
- No raw HTML / primitive widgets where a first-party component library component exists (per the stack overlay)
- Remind the user to run component-level tests after Step 3 (bUnit / widget test / RTL — per stack)
