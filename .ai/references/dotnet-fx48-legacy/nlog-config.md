# NLog.config baseline (net48)

Copy `NLog.config` to the host project; set **Copy to Output Directory =
PreserveNewest**. Use `ILogger`-style usage via `LogManager.GetCurrentClassLogger()`.

```xml
<?xml version="1.0" encoding="utf-8"?>
<nlog xmlns="http://www.nlog-project.org/schemas/NLog.xsd"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      throwConfigExceptions="true">
  <targets>
    <!-- Console for self-host / dev. -->
    <target name="console" xsi:type="ColoredConsole"
            layout="${longdate}|${level:uppercase=true}|${logger}|${message} ${exception:format=ToString}" />
    <!-- Rolling file for Windows Service / IIS. -->
    <target name="file" xsi:type="File"
            fileName="${basedir}/logs/app.log"
            archiveAboveSize="10485760" maxArchiveFiles="10"
            layout="${longdate}|${level:uppercase=true}|${logger}|${message} ${exception:format=ToString}" />
  </targets>
  <rules>
    <logger name="*" minlevel="Info" writeTo="console,file" />
  </rules>
</nlog>
```

```csharp
private static readonly NLog.Logger Log = NLog.LogManager.GetCurrentClassLogger();
// ...
Log.Info("Started widget {WidgetId}", id);
```

Named placeholders like `{WidgetId}` render positionally by default — wire `${event-properties}` or a JSON layout to capture them as structured properties, and add an OTLP/JSON target if the service ships logs to a collector. Never log secrets or full request bodies.
