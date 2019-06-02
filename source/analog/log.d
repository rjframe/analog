module analog.log;

// TODO: Can I statically take logger choices and create loggers without
// instantiating any structs/classes? Is that even a good idea?


// TODO: Supported backends: syslog, GELF, systemd journal, Windows eventlog
// syslog will silently ignore elements it won't support, unless an alternative
// output method is provided (e.g., stack traces to a separate file).
// TODO: Create std.experimental.logger-compatible interface?

// TODO: Make this empty and use CT checks - would be more flexible w/
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

mixin(GenWriterMethods());

unittest {
    import log = analog;
    log.loggers ~= new log.Syslogger("myappname");
    log.info("Logged message.");
}

Logger[] loggers;

private:

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

