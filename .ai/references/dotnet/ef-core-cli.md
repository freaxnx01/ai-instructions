# EF Core CLI — migration commands

Run from repo root. Substitute `<Module>` and `<MigrationName>` as appropriate.

```bash
# Add migration
dotnet ef migrations add <MigrationName> \
  --project src/Modules/<Module>/Infrastructure \
  --startup-project src/Host

# Apply
dotnet ef database update \
  --project src/Modules/<Module>/Infrastructure \
  --startup-project src/Host

# Generate SQL script (for production review)
dotnet ef migrations script \
  --project src/Modules/<Module>/Infrastructure \
  --startup-project src/Host \
  --output migrations.sql
```

Migrations are **never** applied automatically on `app.Run()` — they run as a separate init container or pre-deploy step (12-Factor V).
