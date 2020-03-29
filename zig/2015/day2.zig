const std = @import("std");
const io = std.io;
const expectEqual = std.testing.expectEqual;
const utils = @import("utils.zig");

const InvalidInput = error.InvalidInput;

const warn = std.debug.warn;

fn extractDims(dimString: []const u8) ![3]u8 {
    var dims: [3]u8 = undefined;
    var dim_idx: u2 = 0;
    var int_start: usize = 0;

    for (dimString) |char, idx| {
        if (std.ascii.isDigit(char)) {
            continue;
        } else if (char == 'x') {
            dims[dim_idx] = std.fmt.parseInt((@TypeOf(dims[0])), dimString[int_start..idx], 10) catch return InvalidInput;
            int_start = idx + 1;
            dim_idx += 1;
            if (dim_idx > 2) return InvalidInput;
        } else return InvalidInput;
    }

    dims[dim_idx] = std.fmt.parseInt(@TypeOf(dims[0]), dimString[int_start..dimString.len], 10) catch return InvalidInput;

    return dims;
}

test "extracting dimensions" {
    expectEqual(extractDims("2x3x4"), [3]u8{ 2, 3, 4 });
    expectEqual(extractDims("1x1x10"), [3]u8{ 1, 1, 10 });
    expectEqual(extractDims("30x30x30"), [3]u8{ 30, 30, 30 });
}

fn smallestSide(dimensions: [3]u8) [2]u8 {
    const small = std.math.min(dimensions[0], dimensions[1]);
    const medium = std.math.max(dimensions[0], dimensions[1]);

    if (dimensions[2] < small) {
        return .{ dimensions[2], small };
    } else if (dimensions[2] < medium) {
        return .{ small, dimensions[2] };
    } else {
        return .{ small, medium };
    }
}

test "finding the smallest side" {
    expectEqual(smallestSide(.{ 2, 3, 4 }), [2]u8{ 2, 3 });
    expectEqual(smallestSide(.{ 4, 3, 2 }), [2]u8{ 2, 3 });
    expectEqual(smallestSide(.{ 3, 4, 2 }), [2]u8{ 2, 3 });
}

pub fn squareFeet(dims: [3]u8) !u64 {
    var total: u13 = 0;
    var idx: u2 = 0;
    while (idx < 3) : (idx += 1) {
        var side: u11 = (@intCast(u10, dims[idx]) * dims[(idx + 1) % 3]);
        total += 2 * side;
    }
    const min_side = smallestSide(dims);
    total += @intCast(u10, min_side[0]) * min_side[1];

    return total;
}

test "calculating square feet of paper" {
    expectEqual(squareFeet(.{ 29, 13, 26 }), 3276);
    expectEqual(squareFeet(.{ 2, 3, 4 }), 58);
    expectEqual(squareFeet(.{ 1, 1, 10 }), 43);
}

pub fn ribbonLength(dims: [3]u8) !u64 {
    const min_side = smallestSide(dims);
    return 2 * (min_side[0] + min_side[1]) + (@intCast(u16, dims[0]) * dims[1] * dims[2]);
}

test "calculating ribbon length" {
    expectEqual(ribbonLength(.{ 2, 3, 4 }), 34);
    expectEqual(ribbonLength(.{ 1, 1, 10 }), 14);
    expectEqual(ribbonLength(.{ 29, 13, 26 }), 9880);
}

pub fn totalling(input: io.StreamSource.InStream) ![2]u64 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = &arena.allocator;

    var line = std.ArrayList(u8).init(allocator);
    var totalSqFt: u64 = 0;
    var totalRibbon: u64 = 0;

    while (input.readUntilDelimiterArrayList(&line, '\n', 10)) {
        var dims = try extractDims(line.span());
        totalSqFt += try squareFeet(dims);
        totalRibbon += try ribbonLength(dims);
    } else |err| switch (err) {
        error.EndOfStream => {},
        else => return err,
    }

    return [2]u64{ totalSqFt, totalRibbon };
}

test "reading an input stream" {
    const input = utils.fixedBufferStreamSource("2x3x4\n1x1x10\n").inStream();
    expectEqual(try totalling(input), [2]u64{ 101, 48 });
}

pub fn main() !void {
    const stdin = (io.StreamSource{ .file = io.getStdIn() }).inStream();
    const stdout = io.getStdOut().outStream();

    const totals = try totalling(stdin);

    try stdout.print("Total square footage: {}\n", .{totals[0]});
    try stdout.print("Total feet of ribbon: {}\n", .{totals[1]});
}
