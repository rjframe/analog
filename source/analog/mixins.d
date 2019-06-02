module analog.mixins;

import analog : Log;

// TODO: The Gelf library uses sockets and I don't want to silently drop
// any raised exceptions. I need some alternative though because
// logging shouldn't throw.
// Writing functions currently are void; return false on failure?
// A failure message?
//
// Probably: Create a basic FileLogger, allow specifying that as a backup;
// If a logger can't write a message, it sends it to the backup. Failure
// to write any message is silently ignored.
enum WriterPolicy {
    Throwable,
    NoThrow
}

static string GenLogWriterMethods(WriterPolicy Policy = WriterPolicy.NoThrow)() {
    import std.conv : to;
    import std.traits : EnumMembers;
    import std.uni : toLower;

    enum names = EnumMembers!Log;
    string ret = "";

    static if (Policy == WriterPolicy.NoThrow) {
        enum thr = "nothrow ";
    } else { enum thr = ""; }

    foreach (name; names) {
        ret ~= thr ~ `public void ` ~ name.to!string.toLower() ~ `(string msg, string extra = "") {` ~ "\n"
            ~  "    import analog : Log;\n"
            ~  "    write!(Log." ~ name.to!string ~ ")(msg, extra);\n"
            ~ "}\n\n";
    }
    return ret;
}

/** Generate a read-write property of the provided type with the specified name.

    The property's visibility will be determined by the current access specifier
    section.

    A private member of the same name, prefixed with an underscore, will also be
    generated.
*/
static string GenProperty(T)(string name) {
    return
        "private " ~ T.stringof ~ " _" ~ name ~ ";\n"

      ~ "@property " ~ T.stringof ~ " " ~ name ~ "() { return this._" ~ name ~ "; }\n"

      ~ "@property void " ~ name ~ "(" ~ T.stringof ~ " " ~ name
      ~ ") { this._" ~ name ~ " = " ~ name ~ "; }\n\n";
}
