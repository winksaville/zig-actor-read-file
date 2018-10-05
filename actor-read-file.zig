const std = @import("std");
const warn = std.debug.warn;
const Allocator = std.mem.Allocator;

/// Actor that reads a file
const ReadFileThreadContext = struct {
    const Self = @This();

    pAllocator: *Allocator,
    path: []const u8,
    result: error![]u8,

    pub fn init(pSelf: *Self, pAllocator: *Allocator, path: []const u8) void {
        pSelf.pAllocator = pAllocator;
        pSelf.path = path;
        pSelf.result = undefined;
    }

    fn readFile(pSelf: *ReadFileThreadContext) void {
        warn("readFile:+ {}\n", pSelf.path);
        defer warn("readFile:- {}\n", pSelf.path);

        pSelf.result = std.io.readFileAlloc(pSelf.pAllocator, pSelf.path);
    }
};

test "readFile.thread" {
    warn("\n");

    var raw_bytes: [200 * 1024]u8 = undefined;
    var pAllocator = &std.heap.FixedBufferAllocator.init(raw_bytes[0..]).allocator;

    var rf_context: ReadFileThreadContext = undefined;
    rf_context.init(pAllocator, "./test-file1.zig");

    var io_thread = try std.os.spawnThread(&rf_context, ReadFileThreadContext.readFile);
    io_thread.wait();
    var data: []u8 = try rf_context.result;
    defer pAllocator.free(data);

    warn("data:\n{}", data);
}
