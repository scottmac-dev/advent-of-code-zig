const std = @import("std");
const advent_of_code_zig = @import("advent_of_code_zig");

pub fn isPattern(num: u64) bool {
    var buf: [64]u8 = undefined;
    const num_str = std.fmt.bufPrint(&buf, "{}", .{num}) catch return false;

    const len = num_str.len;
    if (len % 2 != 0) return false; // must repeat twice and therefore must be even

    const pattern_len: usize = len / 2;
    const pattern = num_str[0..pattern_len];

    if (std.mem.eql(u8, pattern, num_str[pattern_len..])) {
        return true;
    }
    return false;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var threaded: std.Io.Threaded = .init(allocator);
    defer threaded.deinit();

    const io = threaded.io();

    // DAY 2, PART 1
    const file = try std.Io.Dir.cwd().openFile(io, "src/input-day2.txt", .{});
    defer file.close(io);

    var read_buffer: [1024]u8 = undefined;
    var file_reader = file.reader(io, &read_buffer);
    const reader = &file_reader.interface;

    var id_range_count: usize = 0;
    var end: bool = false;

    var invalid_id_count: usize = 0;
    var invalid_id_sum: u64 = 0;

    while (!end) {
        // grab id range
        const id_range = try reader.takeDelimiterExclusive(',');

        if (id_range.len == 0) break;
        _ = reader.takeByte() catch |err| {
            if (err == error.EndOfStream) end = true else return err;
        };

        id_range_count += 1;

        // get start end numbers from byte string
        var parts = std.mem.splitSequence(u8, id_range, "-");
        const startId = parts.first();
        const endId = if (parts.next()) |id| id else return error.InvalidIdRange;

        // convet to int
        const startAsNum = try std.fmt.parseInt(u64, std.mem.trim(u8, startId, " \t\n\r"), 10);
        const endAsNum = try std.fmt.parseInt(u64, std.mem.trim(u8, endId, " \t\n\r"), 10);

        //std.debug.print("\nid range num: {d} -> {d}\n", .{ startAsNum, endAsNum });
        for (startAsNum..endAsNum) |num| {
            if (isPattern(num)) {
                //std.debug.print("{d} is invalid\n", .{num});
                invalid_id_count += 1;
                invalid_id_sum += num;
            }
        }
    }

    std.debug.print("invalid count: {d}, sum: {d}\n", .{ invalid_id_count, invalid_id_sum });
}

test "test" {}
