# Localization (i18n) & Regional Formatting

User-facing apps must support **`de` and `en`**. CI tooling and developer-only utilities are exempt.

## Language

- Default language resolved from the OS / browser locale at first launch
- User can override at runtime via an in-app language switcher
- The user's choice is persisted (cookie, preferences store, or user profile — stack-specific)

## Regional formatting (decoupled from language)

Regional formatting (date, time, number, currency separators) is selected from the OS region — **not** dictated by the language.

- Auto-detect any `de-*` OS region (`de-CH`, `de-DE`, `de-AT`, …) and use the matching culture
- If the language is `de` but the OS region is missing or unrecognized: fall back to **`de-CH`**
- For `en`: use the OS-provided region (typically `en-US` / `en-GB`) — do not force a default

## Rules

- All date / number / currency rendering goes through the platform's localization API — never hand-format with raw `string.Format` / `toString()` / template literals.
- Do not couple regional formatting to the UI language. A user can read German text with US formatting, or English text with Swiss formatting; both must work.
- Stack overlays specify the concrete API (`CultureInfo` + `RequestLocalization` for .NET, `flutter_localizations` + `intl` for Flutter, etc.).
