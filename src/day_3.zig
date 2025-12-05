const std = @import("std");
const advent_of_code_zig = @import("advent_of_code_zig");

// PART 1 IMPL
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

// PART 2 IMPL
// 12 digits instead of 2
const TO_TURN_ON: usize = 12;
pub fn getMaxJoltagePart2(bank: []const u8) !usize {
    var sequence: [TO_TURN_ON]u8 = undefined;
    var stack: []u8 = sequence[0..0];

    var to_skip = bank.len - TO_TURN_ON;

    for (bank) |char| {
        const digit = std.fmt.charToDigit(char, 10) catch continue;

        // Pop if sequence can be improved
        // can be improved if:
        //      stack has values
        //      the current digit is greater than the last digit in the stack
        //      there is remaining values to skip
        while (stack.len > 0 and stack[stack.len - 1] < digit and to_skip > 0) {
            stack = stack[0 .. stack.len - 1]; // pop
            to_skip -= 1; // one more skipped
        }

        // Add digit if needed
        if (stack.len < TO_TURN_ON) {
            stack = sequence[0 .. stack.len + 1]; // grow sequence
            stack[stack.len - 1] = digit; // push digit
        } else {
            // can't add it, so we must skip it
            to_skip -= 1;
        }
    }

    // get volatage from top 12 values
    var joltage: usize = 0;
    for (sequence) |digit| {
        // base 10 multply each digit
        joltage = joltage * 10 + digit;
    }

    //std.debug.print("top 12 {any}, joltage: {d}\n", .{ sequence, joltage });
    return joltage;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var threaded: std.Io.Threaded = .init(allocator);
    defer threaded.deinit();

    const io = threaded.io();

    // DAY 3
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
        // trim input for accurate result
        total_joltage += try getMaxJoltagePart2(std.mem.trim(u8, line, " \n\r\t"));

        //if (line_count > 10) break;
    }

    std.debug.print("Lines: {d}, total joltage: {d}\n", .{ line_count, total_joltage });
}

test "test get voltage 1" {
    const t1 = "987654321111111";
    const t2 = "811111111111119";
    const t3 = "234234234234278";
    const t4 = "818181911112111";

    try std.testing.expectEqual(try getMaxJoltage(t1), 98);
    try std.testing.expectEqual(try getMaxJoltage(t2), 89);
    try std.testing.expectEqual(try getMaxJoltage(t3), 78);
    try std.testing.expectEqual(try getMaxJoltage(t4), 92);
}
