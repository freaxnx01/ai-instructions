# Dockerfile — multi-stage Alpine, non-root

Reference scaffold. Adjust the `dotnet publish` source path to match the project's host project name.

```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:10.0-alpine AS build
WORKDIR /src
COPY . .
RUN dotnet publish src/Host -c Release -o /app/publish --no-self-contained

FROM mcr.microsoft.com/dotnet/aspnet:10.0-alpine AS runtime
WORKDIR /app
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
COPY --from=build /app/publish .
USER appuser
ENTRYPOINT ["dotnet", "Host.dll"]
```

Pair with `docker-compose.yml` (production-like) + `docker-compose.override.yml` (local dev: ports, volumes, hot-reload). Secrets via env vars or Docker secrets — never baked in.
