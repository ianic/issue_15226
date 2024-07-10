const std = @import("std");
const tls = @import("tls");
const Certificate = std.crypto.Certificate;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const dir = try std.fs.cwd().openDir("src/cert", .{});

    // Load server certificate
    var certificates: Certificate.Bundle = .{};
    defer certificates.deinit(allocator);
    try certificates.addCertsFromFilePath(allocator, dir, "server_cert.pem");

    // Load server private key
    const private_key_file = try dir.openFile("server_key.pem", .{});
    const private_key = try tls.PrivateKey.fromFile(allocator, private_key_file);
    private_key_file.close();

    // Tcp listener
    const port = 9443;
    const address = std.net.Address.initIp4([4]u8{ 127, 0, 0, 1 }, port);
    var server = try address.listen(.{
        .reuse_address = true,
    });

    var buf: [32 * 1024]u8 = undefined;
    for (&buf, 0..) |*b, i| {
        b.* = @truncate(i);
    }
    while (true) {
        // Tcp accept
        const tcp = try server.accept();
        // std.debug.print("accepted {}\n", .{tcp.address});
        defer tcp.stream.close();

        // Upgrade tcp to tls
        var conn = tls.server(tcp.stream, .{
            .authentication = .{
                .certificates = certificates,
                .private_key = private_key,
            },
        }) catch |err| {
            std.debug.print("tls failed with {}\n", .{err});
            continue;
        };

        for (0..128) |_| {
            try conn.writeAll(&buf);
        }
        try conn.close();
    }
}
