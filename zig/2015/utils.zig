const io = @import("std").io;

pub fn fixedBufferStreamSource(buffer: var) io.StreamSource {
    return .{ .const_buffer = io.fixedBufferStream(buffer) };
}
