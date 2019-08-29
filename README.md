# Analog - Multi-Platform Standard Logging

Analog provides an interface to the standard logging APIs of various systems.

You can easily output to multiple logs, and create or wrap your own loggers.

## Current System Support

Linux:
    - [x] syslog
    - [ ] systemd journal
    - [x] GELF

Windows:
    - [ ] Windows Event Log
    - [ ] Remote syslog
    - [?] GELF (untested)

macOS:
    - [ ] Apple unified logger (10.12+ (Sierra))
    - [ ] Local syslog? (does Apple still support it?)
    - [ ] Remote syslog
    - [?] GELF (untested)

BSD:
    - [?] syslog (untested)
    - [?] GELF (untested)

## Example Usage

```d
import log = analog;
import analog : Log;

log.loggers ~= new log.Syslogger("myappname"); // Default level is Info.
log.loggers ~= new log.Gelflogger("myappname", "localhost", 12201, Log.Warning);

// Optional in case of problems with a main logger - see "Exception Policy" below.
log.backupLogger = new log.Filelogger("myapp.log");

log.info("Loggers are ready.");

// Set the logging level for all loggers:
log.setLevel(Log.Error);

// Or just one type:
log.setLevel!(log.Syslogger)(Log.Info);

log.error("Only GELF will log this. Syslog won't see it.");
```

If you know you only want one logger, you can just deal with it directly.

```d
import analog : syslog;
auto log = new Syslogger("myapp");
log.info("My message");
```

## Exception Policy

Instantiating a logger may throw an exception.

The goal (and eventual requirement) is that logging functions will not throw
(Gelflogger is currently non-conforming).

A backup logger can be specified (and a basic FileLogger is present for this
purpose). If a primary logger fails, it should send the message to the backup
logger. If the backup logger is not set or if it fails, messages are silently
ignored. The FileLogger will output to STDERR on failure.

## Custom Loggers

Though the provided loggers all inherit the Logger class, common functions are
provided as mixins rather than through inheritance, so you could even create a
Logger as a struct, though you won't be able to add it to the loggers array:

```d
struct ConsoleLogger {
    import analog.mixins;
    mixin(GenProperty!Log("level"));
    mixin(GenLogWriterMethods());

    this() { _level = Log.Info; }

    // Just provide the write templated method and you're good.
    nothrow void write(Log level)(string msg, string extra = "") {
        try {
            import std.stdio : writeln;
            if (extra.length)
                writeln(msg, "; extra data: ", extra);
            else writeln(msg);
        } catch (Exception) {
            import analog = log;
            backupLogger.error("Failed to log to the console: " ~ msg, extra);
        }
    }
}
```
