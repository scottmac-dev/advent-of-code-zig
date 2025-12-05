const std = @import("std");
const advent_of_code_zig = @import("advent_of_code_zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var threaded: std.Io.Threaded = .init(allocator);
    defer threaded.deinit();

    const io = threaded.io();

    // DAY 4
    const file = try std.Io.Dir.cwd().openFile(io, "src/inputs/input-day4.txt", .{});
    defer file.close(io);

    var read_buffer: [1024]u8 = undefined;
    var file_reader = file.reader(io, &read_buffer);
    const reader = &file_reader.interface;

    var line_count: usize = 0;

    var grid = try std.ArrayList([]const u8).initCapacity(allocator, 135);
    defer {
        for (grid.items) |item| {
            allocator.free(item);
        }
        grid.deinit(allocator);
    }

    while (true) {
        const line = reader.takeDelimiterExclusive('\n') catch |err| {
            if (err == error.EndOfStream) break else return err;
        };

        if (line.len == 0) break;
        _ = reader.takeByte() catch |err| {
            if (err == error.EndOfStream) break else return err;
        };

        line_count += 1;
        const trimmed = std.mem.trim(u8, line, " \n\r\t");

        const line_cpy = try allocator.dupe(u8, trimmed);
        try grid.append(allocator, line_cpy);
    }

    var accessible_rolls: usize = 0;
    const grid_len: usize = grid.items.len - 1;
    for (grid.items, 0..) |line, idx| {
        std.debug.print("{d}: ", .{idx});
        const line_len = line.len - 1;
        for (line, 0..) |char, i| {
            if (char != '@') {
                std.debug.print("{c}", .{char});
                continue;
            }

            var count: usize = 0;
            // Left
            if (i > 0 and line[i - 1] == '@') count += 1;
            // Right
            if (i < line_len and line[i + 1] == '@') count += 1;

            // Top row
            if (idx > 0) {
                const prev_line = grid.items[idx - 1];
                if (i > 0 and prev_line[i - 1] == '@') count += 1;
                if (prev_line[i] == '@') count += 1;
                if (i < line_len and prev_line[i + 1] == '@') count += 1;
            }

            // Bottom row
            if (idx < grid_len) {
                const next_line = grid.items[idx + 1];
                if (i > 0 and next_line[i - 1] == '@') count += 1;
                if (next_line[i] == '@') count += 1;
                if (i < line_len and next_line[i + 1] == '@') count += 1;
            }

            if (count < 4) {
                accessible_rolls += 1;
                std.debug.print("x", .{});
            } else {
                std.debug.print("@", .{});
            }
        }
        std.debug.print("\n", .{});
    }

    std.debug.print("Lines: {d}, grid lines: {d}, rolls: {d}\n", .{ line_count, grid.items.len, accessible_rolls });
}
test "test" {}
