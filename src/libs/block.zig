//------------------------------------------------------------------
// Raylib bindings for drawing primitives.
// Blocks are the fundamental units of destructible cover.
//------------------------------------------------------------------
const rl = @import("raylib");

/// A single destructible pixel/cell within a defensive bunker.
pub const Block = struct {
    position: rl.Vector2,

    /// Initializes a block at a specific coordinate.
    pub fn init(position: rl.Vector2) @This() {
        return .{
            .position = position,
        };
    }

    /// Renders the block as a small 3x3 square.
    pub fn draw(self: @This()) void {
        rl.drawRectangle(
            @intFromFloat(self.position.x),
            @intFromFloat(self.position.y),
            3,
            3,
            .light_gray,
        );
    }

    /// Returns the 3x3 collision area for projectile detection.
    pub fn getRect(self: @This()) rl.Rectangle {
        return .{
            .x = self.position.x,
            .y = self.position.y,
            .width = 3,
            .height = 3,
        };
    }
};
