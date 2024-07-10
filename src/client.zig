const std = @import("std");
const tls = @import("tls");
const Certificate = std.crypto.Certificate;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    // Init certificate bundle with ca
    const dir = try std.fs.cwd().openDir("src/cert", .{});
    var root_ca: Certificate.Bundle = .{};
    defer root_ca.deinit(allocator);
    try root_ca.addCertsFromFilePath(allocator, dir, "ca.pem");

    const host = "localhost";
    const port = 9443;

    var tcp = try std.net.tcpConnectToHost(allocator, host, port);
    defer tcp.close();

    var cli = try std.crypto.tls.Client.init(tcp, root_ca, host);

    var buf: [3 * 1024]u8 = undefined;
    var bytes: usize = 0;
    while (true) {
        const n = try cli.read(tcp, &buf);
        //if (verbose) std.debug.print("{s}", .{buf[0..n]});
        bytes += n;
        if (n == 0) break;
    }
    _ = try cli.writeEnd(tcp, "", true);
    std.debug.print("bytes: {}\n", .{bytes});
}
