//------------------------------------------------------------------
// Standard library (memory, utilities) and Raylib bindings for
// windowing, input, and drawing.
//------------------------------------------------------------------
const std = @import("std");
const rl = @import("raylib");

/// Represents an individual invader in the alien swarm.
pub const Alien = struct {
    position: rl.Vector2,
    alien_images: [3]rl.Texture2D,
    type: i32,

    /// Creates a new alien of a specific type at the given starting position.
    pub fn init(_type: i32, position: rl.Vector2) !@This() {
        var alien = @This(){
            .alien_images = undefined,
            .position = position,
            .type = _type,
        };

        try alien.loadImages();
        return alien;
    }

    /// Renders the alien to the screen based on its current type and position.
    pub fn draw(self: @This()) void {
        const index: usize = @intCast(self.type - 1);
        const texture = self.alien_images[index];
        rl.drawTextureV(texture, self.position, .white);
    }

    /// Returns the collision boundaries of the alien using its texture dimensions.
    pub fn getRect(self: @This()) rl.Rectangle {
        const index: usize = @intCast(self.type - 1);
        return .{
            .x = self.position.x,
            .y = self.position.y,
            .width = @as(f32, @floatFromInt(self.alien_images[index].width)),
            .height = @as(f32, @floatFromInt(self.alien_images[index].height)),
        };
    }

    /// Cleans up GPU texture resources associated with the alien.
    pub fn deinit(self: *@This()) void {
        for (self.alien_images) |texture| {
            if (texture.id != 0) {
                rl.unloadTexture(texture);
            }
        }
    }

    /// Moves the alien horizontally based on the current swarm direction.
    pub fn update(self: *@This(), direction: f32) void {
        self.position.x += direction;
    }

    /// Internal helper to load the correct texture asset from disk based on type.
    fn loadImages(self: *@This()) !void {
        const index: usize = @intCast(self.type - 1);
        // Only load if the texture has not been initialized yet
        if (self.alien_images[index].id == 0) {
            self.alien_images[index] = switch (self.type) {
                2 => try rl.loadTexture("assets/shapes/alien_2.png"),
                3 => try rl.loadTexture("assets/shapes/alien_3.png"),
                else => try rl.loadTexture("assets/shapes/alien_1.png"),
            };
        }
    }
};
