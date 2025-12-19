const std = @import("std");

const Vector2i = struct {
    x: i32,
    y: i32,
};

const Grid = struct {
    size: Vector2i,
    data: []?u8,
    allocator: std.mem.Allocator,

    fn at(self: *const Grid, pos: Vector2i) ?u8 {
        const index: usize = @intCast(pos.x + self.size.x * pos.y);
        return self.data[index];
    }

    fn deinit(self: *Grid) void {
        self.allocator.free(self.data);
    }
};

const OpType = enum {
    add,
    multiply,
};

const Op = struct {
    type: OpType,
    start: i32,
    end: i32,
};

fn pushDigit(num: u64, digit: u8) u64 {
    return num * 10 + digit;
}

fn isDigit(c: u8) bool {
    return c >= '0' and c <= '9';
}

fn parseDigits(data: []const []const u8, allocator: std.mem.Allocator) !Grid {
    var digits = try std.ArrayList(?u8).initCapacity(allocator, 50);

    var width: ?i32 = null;

    for (data) |line| {
        var count: usize = 0;

        for (line) |c| {
            std.debug.print("char: {d} {c}\n", .{ c, c });
            if (c == '*' or c == '+' or c == '\n' or c == '\r' or c == '\t') {
                break;
            }

            if (c == ' ') {
                try digits.append(allocator, null);
            } else {
                std.debug.assert(isDigit(c));
                try digits.append(allocator, c - '0');
            }
            count += 1;
        }

        if (width == null) {
            width = @intCast(count);
        } else {
            std.debug.assert(count == @as(usize, @intCast(width.?)));
        }
    }

    std.debug.assert(width != null);
    const w = width.?;
    std.debug.assert(digits.items.len % @as(usize, @intCast(w)) == 0);

    const height: i32 = @intCast(digits.items.len / @as(usize, @intCast(w)));

    return Grid{
        .size = Vector2i{ .x = w, .y = height },
        .data = try digits.toOwnedSlice(allocator),
        .allocator = allocator,
    };
}

fn parseOps(data: []const []const u8, allocator: std.mem.Allocator) ![]Op {
    var ops = try std.ArrayList(Op).initCapacity(allocator, 50);

    var op: ?Op = null;
    var count: i32 = 0;

    for (data) |line| {
        for (line) |c| {
            if (c != ' ' and c != '+' and c != '*') {
                continue;
            }
            if (c == '+' or c == '*') {
                if (op) |*o| {
                    o.start = count - 2;
                    try ops.append(allocator, o.*);
                }
                const op_type: OpType = if (c == '+') .add else .multiply;
                op = Op{
                    .type = op_type,
                    .start = count - 1,
                    .end = count - 1,
                };
            }
            count += 1;
        }
        // finish last op
        if (op) |*o| {
            o.start = count - 1;
            try ops.append(allocator, o.*);
            op = null;
        }
    }
    return try ops.toOwnedSlice(allocator);
}

fn solve(data: []const []const u8, allocator: std.mem.Allocator) !u64 {
    var grid = try parseDigits(data, allocator);
    defer grid.deinit();

    const ops = try parseOps(data, allocator);
    defer allocator.free(ops);

    var total: u64 = 0;

    for (ops) |op| {
        var result: u64 = if (op.type == .add) 0 else 1;

        var x = op.start;
        while (x > op.end) : (x -= 1) {
            var num: u64 = 0;

            var y: i32 = 0;
            while (y < grid.size.y) : (y += 1) {
                if (grid.at(Vector2i{ .x = x, .y = y })) |digit| {
                    num = pushDigit(num, digit);
                }
            }

            if (op.type == .add) {
                result += num;
            } else {
                result *= num;
            }
        }

        total += result;
    }

    return total;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var threaded = std.Io.Threaded.init(allocator);
    defer threaded.deinit();

    const io = threaded.io();

    const file = try std.Io.Dir.cwd().openFile(io, "src/inputs/input-day6.txt", .{});
    defer file.close(io);

    var read_buffer: [4096]u8 = undefined;
    var file_reader = file.reader(io, &read_buffer);
    const reader = &file_reader.interface;

    var data_lines = try std.ArrayList([]const u8).initCapacity(allocator, 5);
    defer {
        for (data_lines.items) |line| {
            allocator.free(line);
        }
        data_lines.deinit(allocator);
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

        const line_cpy = try allocator.dupe(u8, line);
        try data_lines.append(allocator, line_cpy);
    }

    const result = try solve(data_lines.items, allocator);
    std.debug.print("total: {d}\n", .{result});
}

