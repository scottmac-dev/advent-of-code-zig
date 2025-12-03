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

pub fn getRotationsPastZero(current: i32, amount: i32) usize {
    const result = @abs(@divFloor((current + amount), 100));
    return @intCast(result);
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

        const currentAsI32: i32 = @intCast(current);

        switch (side) {
            .left => {
                pwd_0_count += getRotationsPastZero(currentAsI32, -amount);
                current = wrap(current, -amount);
            },
            .right => {
                pwd_0_count += getRotationsPastZero(currentAsI32, amount);
                current = wrap(current, amount);
            },
        }

        //if (current == 0) pwd_0_count += 1;

        //if (line_num > 20) break;

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

test "count rotations" {
    var current: i32 = 50;
    try std.testing.expectEqual(10, getRotationsPastZero(current, 1000));

    current = 20;
    try std.testing.expectEqual(1, getRotationsPastZero(current, -70));

    // TEST CASE FROM SITE
    var count: usize = 0;
    current = 50;
    count += getRotationsPastZero(current, -68);

    current = 82;
    count += getRotationsPastZero(current, -30);

    current = 52;
    count += getRotationsPastZero(current, 48);

    current = 0;
    count += getRotationsPastZero(current, -5);

    current = 95;
    count += getRotationsPastZero(current, 60);

    current = 55;
    count += getRotationsPastZero(current, -55);

    current = 0;
    count += getRotationsPastZero(current, -1);

    current = 99;
    count += getRotationsPastZero(current, -99);

    current = 0;
    count += getRotationsPastZero(current, 14);

    current = 14;
    count += getRotationsPastZero(current, -82);

    try std.testing.expectEqual(6, count);
}
