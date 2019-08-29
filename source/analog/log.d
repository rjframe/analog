module analog.log;

// TODO: Supported backends: syslog, GELF, systemd journal, Windows eventlog
// syslog will silently ignore elements it won't support, unless an alternative
// output method is provided (e.g., stack traces to a separate file).

// TODO: Make this empty and use CT checks? - would be more flexible w/
// templated methods, accepting non-strings, etc.
interface Logger {
    void trace(string msg, string extra = "");
    void info(string msg, string extra = "");
    void warning(string msg, string extra = "");
    void critical(string msg, string extra = "");
    void fatal(string msg, string extra = "");
    @property void level(Log level);
    @property Log level();
}

enum Log {
    Trace,
    Info,
    Warning,
    Critical,
    Fatal
}

// TODO: Message format
void log(Log level)(string msg) {
    import std.conv : to;
    import std.uni : toLower;
    mixin(level.to!string.toLower() ~ "(msg);");
}

void setLevel(Log level) {
    foreach (l; loggers) {
        l.level = level;
    }
}

@("Set the level for all loggers")
unittest {
    import std.conv : text;
    import analog.mixins;

    class LogA : Logger {
        mixin(GenProperty!Log("level"));
        mixin(GenLogWriterMethods());
        nothrow void write(Log level)(string msg, string extra = "") {}
        this() { _level = Log.Info; }
    }
    class LogB : Logger {
        mixin(GenProperty!Log("level"));
        mixin(GenLogWriterMethods());
        nothrow void write(Log level)(string msg, string extra = "") {}
        this() { _level = Log.Info; }
    }

    auto a = new LogA();
    auto b = new LogB();
    loggers ~= a;
    loggers ~= b;

    setLevel(Log.Warning);
    assert(a.level == Log.Warning, "A: " ~ a.level.text);
    assert(b.level == Log.Warning, "B: " ~ a.level.text);
}

/** Change the level of loggers of the specified type. */
void setLevel(L)(Log level) if (is(L : Logger)) {
    foreach (logger; loggers) {
        if (auto l = cast(L) logger) {
            l.level = level;
        }
    }
}

@("Set the level for loggers of the specified type")
unittest {
    import std.conv : text;
    import analog.mixins;

    class LogA : Logger {
        mixin(GenProperty!Log("level"));
        mixin(GenLogWriterMethods());
        nothrow void write(Log level)(string msg, string extra = "") {}
        this() { _level = Log.Info; }
    }
    class LogB : Logger {
        mixin(GenProperty!Log("level"));
        mixin(GenLogWriterMethods());
        nothrow void write(Log level)(string msg, string extra = "") {}
        this() { _level = Log.Info; }
    }

    auto a = new LogA();
    auto b = new LogB();
    loggers ~= a;
    loggers ~= b;

    setLevel!LogB(Log.Warning);
    assert(a.level == Log.Info, "A: " ~ a.level.text);
    assert(b.level == Log.Warning, "B: " ~ b.level.text);
}

mixin(GenWriterMethods());

version(Posix) {
    unittest {
        import log = analog;
        log.loggers ~= new log.Syslogger("myappname");
        log.info("Logged message.");
    }
}

Logger[] loggers;
Logger backupLogger;

static this() {
    backupLogger = new NullLogger();
}

private:

// TODO: I want all of these to be nothrow.
static string GenWriterMethods()() {
    import std.conv : to;
    import std.traits : EnumMembers;
    import std.uni : toLower;
    enum names = EnumMembers!Log;
    string ret = "";
    foreach (name; names) {
        ret ~= "public void " ~ name.to!string.toLower() ~ "(string msg) {\n"
            ~  "    foreach (logger; loggers) {\n"
            ~  "        logger." ~ name.to!string.toLower() ~ "(msg);\n"
            ~  "    }\n"
            ~ "}\n\n";
    }
    return ret;
}

class NullLogger : Logger {
    import analog.mixins : GenProperty, GenLogWriterMethods;
    mixin(GenProperty!Log("level"));
    mixin(GenLogWriterMethods());

    nothrow void write(Log level)(string msg, string extra = "") {}
}
