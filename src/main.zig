const ioctl = @cImport(@cInclude("sys/ioctl.h"));
const stdio = @cImport(@cInclude("stdio.h"));
const unistd = @cImport(@cInclude("unistd.h"));
const std = @import("std");
const allocator = std.heap.page_allocator;
const DefaultPrng = std.rand.DefaultPrng;

fn get_winsize() ioctl.winsize {
    var winsize: ioctl.winsize = undefined;
    _ = ioctl.ioctl(unistd.STDOUT_FILENO, ioctl.TIOCGWINSZ, &winsize);
    return winsize;
}

var front: []u8 = undefined;
var back: []u8 = undefined;
var front_with_clear: []u8 = undefined;
var back_with_clear: []u8 = undefined;
var size: usize = undefined;
var width: isize = undefined;
var height: isize = undefined;
var rand: std.rand.Xoshiro256 = undefined;
const out = std.io.getStdOut();
const ALIVE: u8 = '#';
const DEAD: u8 = ' ';
pub fn main() void {
    rand = DefaultPrng.init(@bitCast(u64, std.time.milliTimestamp()));
    var winsize = get_winsize();
    size = @intCast(usize, winsize.ws_col) * @intCast(usize, winsize.ws_row);
    width = winsize.ws_col;
    height = winsize.ws_row;
    front_with_clear = allocator.alloc(u8, 4 + size) catch unreachable;
    back_with_clear = allocator.alloc(u8, 4 + size) catch unreachable;
    front = front_with_clear[4..];
    back = back_with_clear[4..];
    front_with_clear[0..4].* = "\x1b[2J".*;
    back_with_clear[0..4].* = "\x1b[2J".*;
    defer allocator.free(front);
    defer allocator.free(back);
    init_array();
    while (true) {
        updateArray();
        printArray();
    }
}

fn init_array() void {
    var i: usize = 0;
    while (i < size) {
        front[i] = if (rand.random().boolean()) ALIVE else DEAD;
        i += 1;
    }
}

fn printArray() void {
    _ = out.write(front) catch {};
}

fn updateArray() void {
    var y: isize = 0;
    while (y < height) {
        var x: isize = 0;
        while (x < width) {
            var neighbours: usize = 0;
            neighbours += @boolToInt(front[@bitCast(usize, @mod(y + 1, height) * width + @mod(x + 1, width))] == ALIVE);
            neighbours += @boolToInt(front[@bitCast(usize, @mod(y + 1, height) * width + x)] == ALIVE);
            neighbours += @boolToInt(front[@bitCast(usize, @mod(y + 1, height) * width + @mod(x - 1, width))] == ALIVE);
            neighbours += @boolToInt(front[@bitCast(usize, y * width + @mod(x + 1, width))] == ALIVE);
            neighbours += @boolToInt(front[@bitCast(usize, y * width + @mod(x - 1, width))] == ALIVE);
            neighbours += @boolToInt(front[@bitCast(usize, @mod(y - 1, height) * width + @mod(x + 1, width))] == ALIVE);
            neighbours += @boolToInt(front[@bitCast(usize, @mod(y - 1, height) * width + x)] == ALIVE);
            neighbours += @boolToInt(front[@bitCast(usize, @mod(y - 1, height) * width + @mod(x - 1, width))] == ALIVE);

            back[@bitCast(usize, y * width + x)] = if (neighbours == 3 or (neighbours == 2 and front[@bitCast(usize, y * width + x)] == ALIVE)) ALIVE else DEAD;
            x += 1;
        }
        y += 1;
    }
    var temp = front;
    front = back;
    back = temp;
}
