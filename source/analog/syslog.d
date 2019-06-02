module analog.syslog;

version(Posix):

import core.sys.posix.syslog;
import analog.log : Logger, Log;

unittest {
    auto l = new Syslogger("testapp");
    l.info("Test message");
    l.trace("Don't write this");
    l.warning("warning");
}

class Syslogger : Logger {
    import std.string : toStringz;

    @disable this();

    this(string appname = null,
            int options = LOG_CONS | LOG_NDELAY | LOG_PID,
            int facility = LOG_LOCAL0,
            Log level = Log.Info) {
        this.ident = appname.toStringz;
        this.options = options;
        this.facility = facility;
        this._level = level;

        openlog(ident, options, facility);
    }

    ~this() { closelog(); }

    import analog.mixins : GenProperty, GenLogWriterMethods;
    mixin(GenProperty!Log("level"));
    mixin(GenLogWriterMethods());

    private:

    nothrow
    void write(Log level)(string msg, string extra = "") in {
        // TODO: Check for 1024 byte max message size, other constraints.
        // Or just ignore anything past that, since the other loggers won't have
        // this constraint.
        // Probably: send multiple messages to syslog at the 1024-byte obundary.
        // "extra" also goes as separate messages.
        // Maybe allow taking a lambda so the application can choose what to do.
    } do {
        if (level >= this._level) {
            syslog(priorityMap[level], msg.toStringz());
        }
    }

    immutable(char)* ident = null;
    int options = 0;
    int facility = 0;

    enum int[Log] priorityMap = [
        Log.Trace: LOG_DEBUG,
        Log.Info: LOG_INFO,
        Log.Warning: LOG_WARNING,
        Log.Critical: LOG_CRIT,
        Log.Fatal: LOG_EMERG
    ];
}
