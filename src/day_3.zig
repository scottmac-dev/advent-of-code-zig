const std = @import("std");
const advent_of_code_zig = @import("advent_of_code_zig");

pub fn getMaxJoltage(bank: []const u8) !usize {
    var max: usize = 0;

    for (bank, 0..) |char, i| {
        const d1 = std.fmt.charToDigit(char, 10) catch continue;
        for (bank[i + 1 ..]) |char2| {
            const d2 = std.fmt.charToDigit(char2, 10) catch continue;

            const value = (d1 * 10) + d2;
            if (value > max) max = value;
        }
    }

    return max;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var threaded: std.Io.Threaded = .init(allocator);
    defer threaded.deinit();

    const io = threaded.io();

    // DAY 3, PART 1
    const file = try std.Io.Dir.cwd().openFile(io, "src/inputs/input-day3.txt", .{});
    defer file.close(io);

    var read_buffer: [1024]u8 = undefined;
    var file_reader = file.reader(io, &read_buffer);
    const reader = &file_reader.interface;

    var line_count: usize = 0;
    var total_joltage: usize = 0;

    while (true) {
        // grab id range
        const line = reader.takeDelimiterExclusive('\n') catch |err| {
            if (err == error.EndOfStream) break else return err;
        };

        if (line.len == 0) break;
        _ = reader.takeByte() catch |err| {
            if (err == error.EndOfStream) break else return err;
        };

        line_count += 1;

        //std.debug.print("{s}\n", .{line});
        total_joltage += try getMaxJoltage(line);

        //if (line_count > 5) break;
    }

    std.debug.print("Lines: {d}, total joltage: {d}\n", .{ line_count, total_joltage });
}

test "test get volage" {
    const t1 = "987654321111111";
    const t2 = "811111111111119";
    const t3 = "234234234234278";
    const t4 = "818181911112111";

    try std.testing.expectEqual(try getMaxJoltage(t1), 98);
    try std.testing.expectEqual(try getMaxJoltage(t2), 89);
    try std.testing.expectEqual(try getMaxJoltage(t3), 78);
    try std.testing.expectEqual(try getMaxJoltage(t4), 92);
}
