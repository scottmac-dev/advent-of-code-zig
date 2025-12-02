const std = @import("std");
const advent_of_code_zig = @import("advent_of_code_zig");

const MIN: usize = 0;
const MAX: usize = 99;
const START: u8 = 50;

const Side = enum {
    left,
    right,

    pub fn fromChar(char: u8) !Side {
        if (char == 'L') {
            return Side.left;
        } else if (char == 'R') {
            return Side.right;
        } else {
            return error.InvalidSide;
        }
    }
};

pub fn wrap(current: u8, amount: i32) u8 {
    return @intCast(@mod(@as(i32, current) + amount, 100));
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var threaded: std.Io.Threaded = .init(allocator);
    defer threaded.deinit();

    const io = threaded.io();

    // DAY 1, PART 1
    const file = try std.fs.openFileAbsolute("/home/mac/projects/zig/advent-of-code-zig/src/input-day1.txt", .{});
    defer file.close();

    // Very small buffer since we know lines are max 4 chars + newline
    var read_buffer: [8]u8 = undefined;
    var file_reader = file.reader(io, &read_buffer);
    const reader = &file_reader.interface;

    var pwd_0_count: usize = 0;
    var current: u8 = START;
    var line_num: usize = 0;

    // Process line by line in a small fixed buffer
    while (true) {
        const line = reader.takeDelimiterExclusive('\n') catch |err| {
            if (err == error.EndOfStream) break else return err;
        };

        if (line.len == 0) break;
        _ = try reader.takeByte();

        line_num += 1;
        const side: Side = try Side.fromChar(line[0]);
        const amount = try std.fmt.parseInt(i32, line[1..], 10);

        switch (side) {
            .left => current = wrap(current, -amount),
            .right => current = wrap(current, amount),
        }

        if (current == 0) pwd_0_count += 1;

        //std.debug.print("side: {any}, amount: {d}, current: {d}\n", .{ side, amount, current });
    }

    std.debug.print("password: {d}, lines: {d}\n", .{ pwd_0_count, line_num });
}

test "test wrap" {
    var current: u8 = 50;

    current = wrap(current, -68);
    try std.testing.expectEqual(current, 82);

    current = wrap(current, -30);
    try std.testing.expectEqual(current, 52);

    current = 99;
    current = wrap(current, -99);
    try std.testing.expectEqual(current, 0);
}
