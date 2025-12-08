const std = @import("std");
const advent_of_code_zig = @import("advent_of_code_zig");

pub fn isOperator(val: []const u8) bool {
    return (std.mem.eql(u8, val, "*") or std.mem.eql(u8, val, "+"));
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var threaded: std.Io.Threaded = .init(allocator);
    defer threaded.deinit();

    const io = threaded.io();

    // DAY 6
    const file = try std.Io.Dir.cwd().openFile(io, "src/inputs/input-day6.txt", .{});
    defer file.close(io);

    var read_buffer: [4096]u8 = undefined;
    var file_reader = file.reader(io, &read_buffer);
    const reader = &file_reader.interface;

    var line_count: usize = 0;

    var values = try std.ArrayList([]const u32).initCapacity(allocator, 200);
    defer {
        for (values.items) |item| {
            allocator.free(item);
        }
        values.deinit(allocator);
    }

    var operators = try std.ArrayList([]const u8).initCapacity(allocator, 20);
    defer operators.deinit(allocator);

    while (true) {
        const line = reader.takeDelimiterExclusive('\n') catch |err| {
            if (err == error.EndOfStream) break else {
                return err;
            }
        };

        _ = reader.takeByte() catch |err| {
            if (err == error.EndOfStream) break else return err;
        };

        line_count += 1;

        var parts = std.mem.tokenizeAny(u8, line, " \n\r\t");

        if (parts.peek()) |val| {
            if (isOperator(val)) {
                // do operations
                std.debug.print("op line {d}\n", .{line_count});
                while (parts.next()) |next| {
                    try operators.append(allocator, next);
                }
            } else {
                // collect values
                std.debug.print("val line {d}\n", .{line_count});
                var line_values = try std.ArrayList(u32).initCapacity(allocator, 30);
                while (parts.next()) |next| {

                    // PART 1
                    const number = std.fmt.parseInt(u32, std.mem.trim(u8, next, " \t\n\r"), 10) catch |err| {
                        if (err == error.InvalidCharacter) std.debug.print("invalid: {s}\n", .{next});
                        continue;
                    };
                    try line_values.append(allocator, number);
                }
                try values.append(allocator, try line_values.toOwnedSlice(allocator));
            }
        }
        //std.debug.print("values: {d}, value_stings: {d}, operators: {d}\n", .{ values.items.len, values_str.items.len, operators.items.len });
    }

    // PART 1
    var sum: u64 = 0;
    const val_lines = values.items.len;
    for (values.items[0], 0..) |value, idx| {
        const operator = operators.items[idx];
        if (std.mem.eql(u8, operator, "*")) {
            var sub_sum: u64 = @intCast(value);
            //std.debug.print("{d}", .{sub_sum});

            for (1..val_lines) |below_val| {
                sub_sum *= values.items[below_val][idx];
                //std.debug.print(" * {d} ", .{values.items[below_val][idx]});
            }

            //std.debug.print("\nsubsum {d}\n", .{sub_sum});
            sum += sub_sum;
        } else if (std.mem.eql(u8, operator, "+")) {
            var sub_sum: u64 = @intCast(value);
            //std.debug.print("{d}", .{sub_sum});

            for (1..val_lines) |below_val| {
                sub_sum += values.items[below_val][idx];
                //std.debug.print(" + {d} ", .{values.items[below_val][idx]});
            }
            //std.debug.print("\nsubsum {d}\n", .{sub_sum});
            sum += sub_sum;
        } else {
            return error.InvalidOperator;
        }
    }
    std.debug.print("PT1: values: {d}, operators: {d}, lines: {d}, val_in_line: {d}\n", .{ values.items.len, operators.items.len, line_count, values.items[0].len });
    std.debug.print("sum: {d}\n", .{sum});

    // PART 2
    var sum2: u64 = 0;

    // Row
    for (values.items[0], 0..) |value, idx| {
        const operator = operators.items[idx];

        // get column
        var col_values = try std.ArrayList(u32).initCapacity(allocator, val_lines);
        defer col_values.deinit(allocator);

        try col_values.append(allocator, value);

        // get values from columns first instead of rows
        for (values.items, 0..) |col, i| {
            if (i == 0) continue;
            try col_values.append(allocator, col[idx]);
        }

        std.debug.print("col values...\n", .{});
        for (col_values.items) |v| {
            std.debug.print("{d} ", .{v});
        }

        std.debug.print("\n", .{});

        // extract column values
        var new_values = try std.ArrayList(u32).initCapacity(allocator, val_lines);
        defer new_values.deinit(allocator);

        var max_len: usize = 0;
        for (col_values.items) |val| {
            var buf: [32]u8 = undefined;
            const val_str = try std.fmt.bufPrint(&buf, "{}", .{val});
            if (val_str.len > max_len) max_len = val_str.len;
        }

        for (0..max_len) |_| {
            try new_values.append(allocator, 0);
        }

        for (col_values.items) |val| {
            var buf: [32]u8 = undefined;
            const val_str = try std.fmt.bufPrint(&buf, "{}", .{val});

            var i: usize = val_str.len;

            for (val_str) |char| {
                const prev = new_values.items[i - 1];
                const new = (prev * 10) + try std.fmt.charToDigit(char, 10);
                new_values.items[i - 1] = new;
                i -= 1;
            }
        }

        std.debug.print("new values...\n", .{});
        for (new_values.items) |v| {
            std.debug.print("{d} ", .{v});
        }
        std.debug.print("\n", .{});

        var sub_sum: u64 = 0;
        for (new_values.items, 0..) |val, i| {
            if (i == 0) {
                sub_sum = val;
            } else {
                if (std.mem.eql(u8, operator, "*")) {
                    sub_sum *= val;
                } else if (std.mem.eql(u8, operator, "+")) {
                    sub_sum += val;
                } else {
                    return error.InvalidOperator;
                }
            }
        }
        sum2 += sub_sum;
    }

    std.debug.print("PT2 sum: {d}\n", .{sum2});
}
