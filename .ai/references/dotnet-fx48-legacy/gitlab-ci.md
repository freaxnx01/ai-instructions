# GitLab CI — Cake on a Windows runner (net48)

net48 + `msbuild.exe` requires a **Windows** runner with Visual Studio Build
Tools. CI just invokes the Cake bootstrap. (Azure DevOps Pipelines is the
equivalent alternative — a `windows-latest` pool running the same `build.ps1`.)

```yaml
stages:
  - build

variables:
  CONFIGURATION: "Release"

build:
  stage: build
  tags:
    - windows            # runner tag pointing at a Windows + VS Build Tools host
  script:
    - powershell -ExecutionPolicy Bypass -File ./build.ps1 -Target Test -Configuration $CONFIGURATION
  artifacts:
    name: "$CI_PROJECT_NAME-$CI_COMMIT_SHORT_SHA"
    paths:
      - artifacts/
    expire_in: 2 weeks
  only:
    - main
    - merge_requests
```

Keep the build logic in Cake, not in CI YAML — the same `build.ps1 -Target …`
runs identically on a developer machine and on the runner.
