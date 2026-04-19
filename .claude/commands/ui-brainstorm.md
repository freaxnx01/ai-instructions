Design a new UI screen or component using ASCII wireframes (Phase 1 of 4). Stack-neutral — use the active stack overlay (`.ai/stacks/<stack>.md`) for component-library vocabulary.

Context: $ARGUMENTS

## Steps

1. Ask clarifying questions before designing:
   - What is the primary user goal on this screen?
   - Which user roles interact with it?
   - What data is displayed or captured?
   - Are there any existing components in the project's shared/common folder that could be reused?
   - Any known constraints (auth, offline, performance, a11y)?
2. Wait for answers before continuing
3. Draw a clear ASCII wireframe showing:
   - Overall layout (top bar / nav / main content area, or the stack's equivalent)
   - Key regions (tables, forms, dialogs)
   - Primary actions (buttons, FABs, links)
   - Empty / loading / error state placeholders
   - Use box-drawing characters for clarity
4. Wait for approval — do NOT proceed to Mermaid diagrams or code
5. End with: "Does this wireframe match your intent? Approve to continue to Phase 2 (/ui-flow)."
6. On approval, save the wireframe to `docs/design/<feature-name>/wireframe.md`

## Rules
- No Mermaid diagrams in this phase
- No code in this phase
- One wireframe iteration at a time
- If the user asks for code, remind them we are still in Phase 1
