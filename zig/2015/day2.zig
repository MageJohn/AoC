const std = @import("std");
const io = std.io;
const expectEqual = std.testing.expectEqual;
const utils = @import("utils.zig");

const InvalidInput = error.InvalidInput;

const warn = std.debug.warn;

pub fn squareFeet(dimensions: []const u8) !u64 {
    var dims: [3]u8 = undefined;
    var dim_idx: u8 = 0;
    var int_start: usize = 0;

    for (dimensions) |char, idx| {
        if (std.ascii.isDigit(char)) {
            continue;
        } else if (char == 'x') {
            dims[dim_idx] = std.fmt.parseInt(u8, dimensions[int_start..idx], 10) catch return InvalidInput;
            int_start = idx + 1;
            dim_idx += 1;
            if (dim_idx > 2) return InvalidInput;
        } else return InvalidInput;
    }

    dims[dim_idx] = std.fmt.parseInt(u8, dimensions[int_start..dimensions.len], 10) catch return InvalidInput;

    var total: u64 = 0;
    var min_side: u64 = std.math.maxInt(u64);
    for (dims) |dim, idx| {
        var side: u64 = (dim * dims[(idx + 1) % 3]);
        min_side = std.math.min(side, min_side);
        total += 2 * side;
    }
    total += min_side;

    return total;
}

test "2x3x4" {
    expectEqual(squareFeet("2x3x4"), 58);
}

test "1x1x10" {
    expectEqual(squareFeet("1x1x10"), 43);
}

pub fn summedFootage(input: io.StreamSource.InStream) !u64 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = &arena.allocator;

    var line = std.ArrayList(u8).init(allocator);
    var total: u64 = 0;

    while (input.readUntilDelimiterArrayList(&line, '\n', 10)) {
        total += try squareFeet(line.span());
    } else |err| switch (err) {
        error.EndOfStream => {
            total += try squareFeet(line.span());
        },
        else => return err,
    }

    return total;
}

test "two lines" {
    const input = utils.fixedBufferStreamSource("2x3x4\n1x1x10").inStream();
    expectEqual(try summedFootage(input), 101);
}

pub fn main() !void {
    const stdin = (io.StreamSource{ .file = io.getStdIn() }).inStream();
    const stdout = io.getStdOut().outStream();

    const total = try summedFootage(stdin);

    try stdout.print("Total square footage: {}\n", .{total});
}
