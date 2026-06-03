# Tech Stack — .NET Framework 4.8 (Legacy) service

| Layer | Technology |
|---|---|
| Target framework | `net48` (full .NET Framework); projects in a single solution may mix **SDK-style** (`Sdk="Microsoft.NET.Sdk"` + `PackageReference`) and **classic** (`<TargetFrameworkVersion>v4.8</TargetFrameworkVersion>` + `packages.config`) styles |
| Language | C# (the latest lang version the installed SDK/compiler allows on net48); **no** implicit usings, **no** nullable reference types by default |
| REST framework | [Nancy](https://github.com/NancyFx/Nancy) 2.x on **OWIN/Katana** — self-hosted via `Microsoft.Owin.Host.HttpListener` and/or hosted in **IIS**. (Alternative legacy flavour: ASP.NET Web API 2 on OWIN.) |
| Views (optional) | Nancy SuperSimpleViewEngine (`.sshtml`) |
| Hosting | Console / **Windows Service** (`System.ServiceProcess`) for self-host; IIS for the web host |
| DI | Nancy **TinyIoC** (built in); register in a custom `Bootstrapper` |
| JSON | [Newtonsoft.Json](https://www.newtonsoft.com/json) 13.x |
| Logging | [NLog](https://nlog-project.org/) 5.x, configured via `NLog.config` |
| Config | `app.config` / `web.config` + `System.Configuration`; binding redirects via `AutoGenerateBindingRedirects` |
| Tests | [xUnit](https://xunit.net/) **desktop runner** (`xunit.runner.console` / `xunit.runner.visualstudio`), [Moq](https://github.com/moq/moq4), [Shouldly](https://github.com/shouldly/shouldly), [Nancy.Testing](https://github.com/NancyFx/Nancy), [RestSharp](https://restsharp.dev/) |
| Build | [Cake](https://cakebuild.net/) (`build.ps1` bootstrap → `build.cake`) driving full-framework **`msbuild.exe`** (not `dotnet build`); 7-Zip for packaging |
| Versioning | Centralized in a repo-root `Directory.Build.props` — one `<Version>` for **all** assemblies |
| CI | GitLab CI running `powershell build.ps1` on a **Windows** runner (alternative: Azure DevOps Pipelines) |
| API exploration | [Bruno](https://www.usebruno.com/) collection under `api-client/` |
