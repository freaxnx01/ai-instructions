# GitHub Actions — .NET baseline pipeline shape

Pipeline stages: `build` → `test` → `security-scan` → `docker-build` → `push`. Layer-specific overlays add E2E (Playwright for Blazor) and perf smoke (k6 for WebAPI) jobs on top.

```yaml
jobs:
  build-and-test:
    - dotnet restore
    - dotnet build --no-restore -c Release
    - dotnet test --no-build --collect:"XPlat Code Coverage"
    - dotnet list package --vulnerable --fail-on-severity high

  docker:
    needs: build-and-test
    - docker build
    - docker push (on main only)
```
