const std = @import("std");
const io = std.io;
const expectEqual = std.testing.expectEqual;
const expectError = std.testing.expectError;

const InstrResult = struct {
    floor: i64 = 0,
    basement: u64 = 0,
};

/// Consumes instruction chars one at a time from instr_stream and tracks the
/// current floor and when the basement is first entered.
///
/// Returns:
/// - error.InvalidInput if there are any characters other than ')' and '('.
/// - InstrResult with the final floor and basement values otherwise.
pub fn followInstr(instr_stream: io.StreamSource.InStream) !InstrResult {
    // Makes sure zig always panics safely in case the input overflows the 64
    // bit integers.
    @setRuntimeSafety(true);

    var res = InstrResult{};
    var found_basement = false;

    while (instr_stream.readByte()) |instr| {
        switch (instr) {
            '(' => {
                res.floor += 1;
            },
            ')' => {
                res.floor -= 1;
            },
            else => {
                return error.InvalidInput;
            },
        }

        if (!found_basement) {
            res.basement += 1;
            found_basement = res.floor < 0;
        }
    } else |err| switch (err) {
        error.EndOfStream => {
            return res;
        },
        else => {
            return err;
        },
    }
}

fn expectSameFloor(a: []const u8, b: []const u8, floor: i64) void {
    const instream1 = (io.StreamSource{ .const_buffer = io.fixedBufferStream(a) }).inStream();
    const instream2 = (io.StreamSource{ .const_buffer = io.fixedBufferStream(b) }).inStream();

    const res1 = followInstr(instream1) catch unreachable;
    const res2 = followInstr(instream2) catch unreachable;

    expectEqual(res1.floor, floor);
    expectEqual(res1.floor, res2.floor);
}

test "example 1: both 0" {
    expectSameFloor("(())", "()()", 0);
}

test "example 2: both 3" {
    expectSameFloor("(((", "(()(()(", 3);
}

test "example 3: difference" {
    const instream = (io.StreamSource{ .const_buffer = io.fixedBufferStream("))(((((") }).inStream();
    const res = try followInstr(instream);
    expectEqual(res.floor, 3);
}

test "example 4: both -1" {
    expectSameFloor("())", "))(", -1);
}

test "example 5: both -3" {
    expectSameFloor(")))", ")())())", -3);
}

test "example 6: basement at position 1" {
    const instream = (io.StreamSource{ .const_buffer = io.fixedBufferStream(")") }).inStream();
    const res = try followInstr(instream);
    expectEqual(res.basement, 1);
}

test "example 7: basement at position 5" {
    const instream = (io.StreamSource{ .const_buffer = io.fixedBufferStream("()())") }).inStream();
    const res = try followInstr(instream);
    expectEqual(res.basement, 5);
}

test "invalid input" {
    const instream = (io.StreamSource{ .const_buffer = io.fixedBufferStream("hello santa") }).inStream();
    expectError(error.InvalidInput, followInstr(instream));
}

pub fn main() !void {
    const stdin = (io.StreamSource{ .file = io.getStdIn() }).inStream();
    const stdout = io.getStdOut().outStream();

    const res = followInstr(stdin) catch |err| switch (err) {
        error.InvalidInput => {
            //std.debug.warn("Error: Invalid character encountered\n", .{});
            return err;
        },
        else => unreachable,
    };

    try stdout.print("Santa ends up on floor number {}\n", .{res.floor});
    try stdout.print("The first instruction to send him into the basement was at position {}\n", .{res.basement});
}
