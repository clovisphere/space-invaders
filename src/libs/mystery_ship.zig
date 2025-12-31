//------------------------------------------------------------------
// Raylib bindings for rendering and logic.
// The Mystery Ship is a high-value bonus target that spawns
// occasionally at the top of the screen.
//------------------------------------------------------------------
const rl = @import("raylib");

// Padding to prevent the ship from clipping into the UI border.
const horizontal_padding = 25;

/// A bonus enemy that traverses the screen horizontally.
pub const MysteryShip = struct {
    alive: bool = false,
    position: rl.Vector2,
    speed: f32 = 0.0,
    texture: rl.Texture2D,

    /// Loads the mystery ship texture and initializes default state.
    pub fn init() !@This() {
        return .{
            .position = .{ .x = 0, .y = 0 },
            .texture = try rl.loadTexture("assets/shapes/mystery.png"),
        };
    }

    /// Renders the ship only when it is active in the play area.
    pub fn draw(self: @This()) void {
        if (self.alive) {
            rl.drawTextureV(self.texture, self.position, .white);
        }
    }

    /// Returns the ship's hit-box; returns a zero-sized rect if inactive.
    pub fn getRect(self: @This()) rl.Rectangle {
        return switch (self.alive) {
            true => .{
                .x = self.position.x,
                .y = self.position.y,
                .width = @as(f32, @floatFromInt(self.texture.width)),
                .height = @as(f32, @floatFromInt(self.texture.height)),
            },
            else => .{
                .x = self.position.x,
                .y = self.position.y,
                .width = 0,
                .height = 0,
            },
        };
    }

    /// Randomly places the ship on the left or right and sets it in motion.
    pub fn spawn(self: *@This()) void {
        self.position.y = 90;

        if (rl.getRandomValue(0, 1) == 0) {
            // Spawn on the left, move right
            self.position.x = horizontal_padding;
            self.speed = 3;
        } else {
            // Spawn on the right, move left
            self.position.x = @as(f32, @floatFromInt(rl.getScreenWidth() - self.texture.width - horizontal_padding));
            self.speed = -3;
        }

        self.alive = true;
    }

    /// Updates horizontal position and despawns if it hits screen boundaries.
    pub fn update(self: *@This()) void {
        if (self.alive) {
            self.position.x += self.speed;

            const right_bound = @as(f32, @floatFromInt(rl.getScreenWidth() - self.texture.width - horizontal_padding));
            if (self.position.x > right_bound or self.position.x < horizontal_padding) {
                self.alive = false;
            }
        }
    }

    /// Frees the ship's texture from GPU memory.
    pub fn deinit(self: *@This()) void {
        rl.unloadTexture(self.texture);
    }
};
