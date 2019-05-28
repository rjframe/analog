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

    @property
    Log level() { return this._level; }
    @property
    void level(Log level) { this._level = level; }

    import analog.mixins : GenLogWriterMethods;
    mixin(GenLogWriterMethods());

    private:

    void write(Log level)(string msg, string extra = "") {
        // TODO: Check for 1024 byte max message size, other constraints.
        // TODO: Append extra to msg if within limit; or have separate
        // log file?
        if (level >= this._level) {
            syslog(priorityMap[level], msg.toStringz());
        }
    }

    immutable(char)* ident = null;
    int options = 0;
    int facility = 0;
    Log _level;

    enum int[Log] priorityMap = [
        Log.Trace: LOG_DEBUG,
        Log.Info: LOG_INFO,
        Log.Warning: LOG_WARNING,
        Log.Critical: LOG_CRIT,
        Log.Fatal: LOG_EMERG
    ];
}
