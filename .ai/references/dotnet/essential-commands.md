# Essential commands (.NET baseline)

Routine work goes through `just` — see
[`justfile-recipes.md`](https://github.com/freaxnx01/ai-instructions/blob/main/.ai/references/dotnet/justfile-recipes.md)
for the canonical recipe names. These are the underlying commands, for when you need to
run one directly or are writing a recipe body.

```bash
# Restore / build (warnings as errors) / run
dotnet restore
dotnet build -c Release
dotnet run --project src/Host

# Run full stack locally
docker-compose -f docker-compose.yml -f docker-compose.override.yml up --build

# Tests
dotnet test                                         # all
dotnet test tests/<Module>.UnitTests                # unit only
dotnet test tests/<Module>.IntegrationTests         # integration (needs Docker)
dotnet test --collect:"XPlat Code Coverage" --results-directory ./coverage

# Security / package checks
dotnet list package --vulnerable --fail-on-severity high
dotnet list package --outdated
```
