module analog.gelf;

// TODO: flag for compression.
// TODO: If I always chunk, does it auto-chunk or always? Always.

public import std.typecons : Yes, No;
import analog.log : Logger, Log;

unittest {
    auto l = new Gelflogger("testapp", "localhost");
    l.info("Test message");
    l.trace("Don't write this");
    l.warning("warning", "some problem");
}

private enum uint UdpMaxPacketBytes = 8192;

class Gelflogger : Logger {
    import std.typecons : Flag;
    import gelf;

    @disable this();

    this(string source,
            string gelfServer,
            ushort gelfPort = 12201,
            Log level = Log.Info,
            Flag!"compress" compress = No.compress,
            uint chunkAt = UdpMaxPacketBytes)
    in {
        assert(chunkAt <= UdpMaxPacketBytes,
                "The maximum chunk size is 8192 bytes.");
    } do {
        this.source = source;
        this.server = gelfServer;
        this.port = gelfPort;
        this.chunkSize = chunkAt;
        this._level = level;
    }

    import analog.mixins : GenProperty, GenLogWriterMethods, WriterPolicy;
    mixin(GenProperty!Log("level"));
    mixin(GenLogWriterMethods!(WriterPolicy.Throwable));

    @property
    uint chunkAt() { return this.chunkSize; }
    @property
    void chunkAt(uint bytes) in(bytes <= UdpMaxPacketBytes) { this.chunkSize = bytes; }

    private:

    void write(Log level)(string msg, string extra) {
        import std.datetime : Clock;
        import std.socket : UdpSocket, InternetAddress;
        import gz = std.zlib;

        if (level < this._level) return;

        auto gm = Message(source, msg)
            .timestamp(Clock.currTime)
            .level(priorityMap[level]);

        if (extra.length) gm.fullMessage = extra;

        auto data = this.compress ? gz.compress(gm.toBytes()) : gm.toBytes();

        auto sock = new UdpSocket();
        sock.connect(new InternetAddress(server, port));
        if (data.length > chunkSize) {
            foreach (chunk; Chunks(data, chunkSize)) {
                sock.send(chunk);
            }
        } else {
            sock.send(data);
        }

        sock.close();
    }

    string source = "";
    string server = "";
    uint chunkSize = UdpMaxPacketBytes;
    ushort port = 12201;
    bool compress = false;

    enum Level[Log] priorityMap = [
        Log.Trace: Level.DEBUG,
        Log.Info: Level.INFO,
        Log.Warning: Level.WARNING,
        Log.Critical: Level.CRITICAL,
        Log.Fatal: Level.EMERGENCY
    ];
}
