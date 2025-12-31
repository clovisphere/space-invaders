//------------------------------------------------------------------
// Standard library for memory management and Raylib for math.
// Obstacles are bunkers built from many individual Block entities.
//------------------------------------------------------------------
const std = @import("std");
const rl = @import("raylib");

//------------------------------------------------------------------
// Internal block module representing a single "pixel" of cover.
//------------------------------------------------------------------
const Block = @import("block.zig").Block;

/// A defensive bunker composed of a dynamic list of destructible blocks.
pub const Obstacle = struct {
    allocator: std.mem.Allocator,
    blocks: std.ArrayList(Block) = .empty,
    position: rl.Vector2,

    /// Builds a bunker by translating the 2D grid mask into Block entities.
    pub fn init(allocator: std.mem.Allocator, position: rl.Vector2) !@This() {
        var obstacle = @This(){
            .allocator = allocator,
            .position = position,
        };

        // Pre-allocate memory based on the grid dimensions to avoid reallocations.
        try obstacle.blocks.ensureTotalCapacity(
            obstacle.allocator,
            grid.len * grid[0].len,
        );

        // Iterate through the bitmask to spawn blocks at the correct world coordinates.
        for (grid, 0..) |row, row_idx| {
            for (row, 0..) |cell, col_idx| {
                if (cell == 1) {
                    const block = Block.init(.{
                        .x = obstacle.position.x + @as(f32, @floatFromInt(col_idx)) * 3.0,
                        .y = obstacle.position.y + @as(f32, @floatFromInt(row_idx)) * 3.0,
                    });
                    try obstacle.blocks.append(obstacle.allocator, block);
                }
            }
        }

        return obstacle;
    }

    /// Renders all remaining blocks in the bunker.
    pub fn draw(self: @This()) void {
        for (self.blocks.items) |*block| {
            block.draw();
        }
    }

    /// Frees the memory used by the blocks list.
    pub fn deinit(self: *@This()) void {
        self.blocks.deinit(self.allocator);
    }
};

//------------------------------------------------------------------
// Grid mask defining the bunker's physical shape.
// 1 = Block present, 0 = Empty space.
//------------------------------------------------------------------
pub const grid = [13][23]i32{
    [_]i32{ 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0 },
    [_]i32{ 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0 },
    [_]i32{ 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0 },
    [_]i32{ 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0 },
    [_]i32{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
    [_]i32{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
    [_]i32{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
    [_]i32{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
    [_]i32{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
    [_]i32{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
    [_]i32{ 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1 },
    [_]i32{ 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1 },
    [_]i32{ 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1 },
};
