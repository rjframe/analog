module analog.mixins;

import analog : Log;

static string GenLogWriterMethods()() {
    import std.conv : to;
    import std.traits : EnumMembers;
    import std.uni : toLower;

    enum names = EnumMembers!Log;
    string ret = "";
    foreach (name; names) {
        ret ~= `public void ` ~ name.to!string.toLower() ~ `(string msg, string extra = "") {` ~ "\n"
            ~  "    import analog : Log;\n"
            ~  "    write!(Log." ~ name.to!string ~ ")(msg, extra);\n"
            ~ "}\n\n";
    }
    return ret;
}
