const std = @import("std");
const advent_of_code_zig = @import("advent_of_code_zig");

// PART 2
const Range = struct {
    start: u64,
    end: u64,
};

fn lessThan(_: void, a: Range, b: Range) bool {
    return a.start < b.start;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var threaded: std.Io.Threaded = .init(allocator);
    defer threaded.deinit();

    const io = threaded.io();

    // DAY 5
    const file = try std.Io.Dir.cwd().openFile(io, "src/inputs/input-day5.txt", .{});
    defer file.close(io);

    var read_buffer: [1024]u8 = undefined;
    var file_reader = file.reader(io, &read_buffer);
    const reader = &file_reader.interface;

    var line_count: usize = 0;
    var blank_reached: bool = false;

    var ranges = try std.ArrayList([]const u8).initCapacity(allocator, 200);
    defer {
        for (ranges.items) |item| {
            allocator.free(item);
        }
        ranges.deinit(allocator);
    }

    var ids = try std.ArrayList([]const u8).initCapacity(allocator, 200);
    defer {
        for (ids.items) |item| {
            allocator.free(item);
        }
        ids.deinit(allocator);
    }

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
        const trimmed = std.mem.trim(u8, line, " \n\r\t");

        if (trimmed.len == 0) {
            blank_reached = true;
            //std.debug.print("blank line at lc {d}\n", .{line_count});
            continue;
        }

        const line_cpy = try allocator.dupe(u8, line);

        if (blank_reached) {
            try ids.append(allocator, line_cpy);
        } else {
            try ranges.append(allocator, line_cpy);
        }
        //std.debug.print("{d}: {s}\n", .{ line_count, line_cpy });
        //if (line_count > 10) break;
    }
    //std.debug.print("line count: {d}, range count: {d}, id count: {d}\n", .{ line_count, ranges.items.len, ids.items.len });
    // part 1
    var fresh_id_count: usize = 0;

    for (ids.items) |id| {
        const i_id = try std.fmt.parseInt(u64, std.mem.trim(u8, id, " \t\n\r"), 10);

        for (ranges.items) |range| {
            // get range parts
            var parts = std.mem.splitSequence(u8, range, "-");
            const start = parts.first();
            const end = if (parts.next()) |num| num else return error.InvalidRange;

            // convert to int
            const i_start = try std.fmt.parseInt(u64, std.mem.trim(u8, start, " \t\n\r"), 10);
            const i_end = try std.fmt.parseInt(u64, std.mem.trim(u8, end, " \t\n\r"), 10);

            if (i_id >= i_start and i_id <= i_end) {
                //std.debug.print("id: {d} is fresh, r: {d}-{d}\n", .{ i_id, i_start, i_end });
                fresh_id_count += 1;
                break;
            }
        }
    }
    std.debug.print("total fresh: {d}\n", .{fresh_id_count});

    // PART 2
    var total_fresh_ids: u64 = 0;
    var wrapped_ranges = try std.ArrayList(Range).initCapacity(allocator, ranges.items.len);
    defer wrapped_ranges.deinit(allocator);

    for (ranges.items) |range| {
        // get range parts
        var parts = std.mem.splitSequence(u8, range, "-");
        const start = parts.first();
        const end = if (parts.next()) |num| num else return error.InvalidRange;

        // convert to int
        const i_start = try std.fmt.parseInt(u64, std.mem.trim(u8, start, " \t\n\r"), 10);
        const i_end = try std.fmt.parseInt(u64, std.mem.trim(u8, end, " \t\n\r"), 10);

        try wrapped_ranges.append(allocator, Range{ .start = i_start, .end = i_end });
    }

    // sort ranges
    var sorted_ranges = try wrapped_ranges.toOwnedSlice(allocator);
    defer allocator.free(sorted_ranges);
    std.mem.sort(Range, sorted_ranges, {}, lessThan);

    std.debug.print("total ranges: {d}\n", .{sorted_ranges.len});

    // get inital range
    var current_start = sorted_ranges[0].start;
    var current_end = sorted_ranges[0].end;

    // iterate over sorted ranges 1..end
    for (sorted_ranges[1..]) |range| {

        // if overlap found
        if (range.start <= current_end + 1) {
            // find largest end value to merge the ranges
            current_end = @max(current_end, range.end);
        } else {

            // no overlap
            // count previous merged range to get unique ids
            total_fresh_ids += current_end - current_start + 1; // inclusive count
            current_start = range.start; // update for next loop
            current_end = range.end;
        }
    }

    // last merged range post loop
    total_fresh_ids += current_end - current_start + 1;
    std.debug.print("uuids: {d}\n", .{total_fresh_ids});
}
