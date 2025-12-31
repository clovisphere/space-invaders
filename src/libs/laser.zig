//------------------------------------------------------------------
// Raylib bindings for rendering and screen metrics.
// Lasers serve as the primary interaction between entities.
//------------------------------------------------------------------
const rl = @import("raylib");

/// A projectile that moves vertically until it hits a target or leaves the screen.
pub const Laser = struct {
    active: bool = true,
    color: rl.Color,
    position: rl.Vector2,
    speed: f32,

    /// Initializes a laser with a trajectory; speed is positive for down, negative for up.
    pub fn init(position: rl.Vector2, speed: f32, color: rl.Color) @This() {
        return .{
            .position = position,
            .speed = speed,
            .color = color,
        };
    }

    /// Draws the laser as a slim rectangle if it is currently active.
    pub fn draw(self: @This()) void {
        if (self.active) {
            rl.drawRectangle(
                @intFromFloat(self.position.x),
                @intFromFloat(self.position.y),
                4,
                15,
                self.color,
            );
        }
    }

    /// Returns the hit-box for collision detection with ships or blocks.
    pub fn getRect(self: @This()) rl.Rectangle {
        return .{
            .x = self.position.x,
            .y = self.position.y,
            .width = 4,
            .height = 15,
        };
    }

    /// Updates vertical position and deactivates the laser if it exits play area.
    pub fn update(self: *@This()) void {
        if (self.active) {
            self.position.y += self.speed;

            // Boundary check: deactivates laser at top or near bottom UI line
            if (self.position.y > @as(f32, @floatFromInt(rl.getScreenHeight() - 100)) or self.position.y < 25) {
                self.active = false;
            }
        }
    }
};
