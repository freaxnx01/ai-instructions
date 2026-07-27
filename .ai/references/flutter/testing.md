# Flutter — testing

Base TDD rules live in `base-instructions.md`. This file covers the Flutter-specific detail.


## Layout

```text
test/
  <feature>_test.dart          ← widget tests for screens + flows
  <module>_unit_test.dart      ← pure-Dart unit tests for repositories, parsers, models
```

Test files mirror the production tree where useful. Keep them flat and discoverable.

## Conventions

- `flutter_test` only by default. **Do not add `mockito`, `mocktail`, `build_runner`, or codegen-based mocking without asking** — write hand-rolled fakes that extend or implement the production class.
- Inject fakes through the optional constructor params of the widget under test.
- For `shared_preferences`-backed code, call `SharedPreferences.setMockInitialValues({})` in `setUp`.
- For `flutter_secure_storage` use a fake subclass overriding `instanceUrl` / `apiToken` / `isConfigured` — there is no first-party in-memory backend.
- Use `pumpAndSettle` after async work; for tight async loops a small explicit duration (`pumpAndSettle(const Duration(milliseconds: 100))`) is fine.
- Always `addTearDown(...)` for `StreamController` / disposable test fakes.
- Test naming: describe the behaviour in plain English (`'records the new task in local history after Done'`). The base instruction's `MethodName_StateUnderTest_ExpectedBehavior` pattern is fine for pure-Dart unit tests; widget tests read better as sentences.

## Sample widget test skeleton

```dart
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('redirects share to setup screen when not configured', (tester) async {
    final shareSource = _FakeShareIntentSource();
    addTearDown(shareSource.dispose);

    await tester.pumpWidget(MaterialApp(
      home: HomePage(
        storage: _UnconfiguredSecureStorage(),
        shareSource: shareSource,
        enableShareListener: true,
      ),
    ));
    await tester.pumpAndSettle();

    shareSource.fireTextShare('https://example.com/page');
    await tester.pumpAndSettle();

    expect(find.byType(ProjectPickerScreen), findsNothing);
  });
}
```

## Required after every change

- `flutter analyze` passes with zero issues
- `flutter test` passes the **full** suite — not just the new test
- Never modify a test to make it green. Never hardcode return values, mock results, or stub logic to satisfy a test. Never silently swallow exceptions.
