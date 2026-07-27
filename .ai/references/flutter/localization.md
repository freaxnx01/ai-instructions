# Flutter — localization & regional formatting

Base rules for language support and regional formatting live in
[`.ai/references/base/localization.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/base/localization.md).
This file covers the Flutter wiring.

Add `flutter_localizations` (SDK) and `intl` to `pubspec.yaml`. Generate ARB-driven
message classes via `flutter gen-l10n` — `l10n.yaml` configured for `lib/l10n/app_en.arb`
and `app_de.arb`.

## `MaterialApp` configuration

```dart
MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: const [
    Locale('en'),
    Locale('de', 'CH'),
    Locale('de', 'DE'),
    Locale('de', 'AT'),
  ],
  localeResolutionCallback: (deviceLocale, supported) {
    if (deviceLocale?.languageCode == 'de') {
      return supported.firstWhere(
        (l) => l.languageCode == 'de'
            && l.countryCode == deviceLocale!.countryCode,
        orElse: () => const Locale('de', 'CH'), // fallback for unrecognized de-*
      );
    }
    return const Locale('en');
  },
  locale: _userOverride, // null = follow OS
  // ...
);
```

The `orElse` branch is what implements the base rule that an unrecognized `de-*` region
falls back to `de-CH`. `locale: null` means "follow the OS".
