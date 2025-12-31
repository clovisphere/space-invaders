//------------------------------------------------------------------
// Standard library for memory and Raylib for visuals/input.
// The Spaceship is the player's avatar and primary source of lasers.
//------------------------------------------------------------------
const std = @import("std");
const rl = @import("raylib");

//------------------------------------------------------------------
// Projectile module for ship-fired attacks.
//------------------------------------------------------------------
const Laser = @import("laser.zig").Laser;

// Margin to keep the ship within the decorative UI borders.
const horizontal_padding = 25;

/// The player-controlled ship which can move and fire lasers.
pub const Spaceship = struct {
    allocator: std.mem.Allocator,
    lasers: std.ArrayList(Laser) = .empty,
    position: rl.Vector2,
    s_laser: rl.Sound,
    shot_interval: f64 = 0.0,
    speed: f32 = 5.0,
    texture: rl.Texture2D,

    /// Loads the ship asset and centers it at the bottom of the screen.
    pub fn init(allocator: std.mem.Allocator) !@This() {
        const image = try rl.loadImage("assets/shapes/spaceship.png");
        defer rl.unloadImage(image);

        return .{
            .allocator = allocator,
            .s_laser = try rl.loadSound("assets/sounds/laser.ogg"),
            .texture = try rl.loadTextureFromImage(image),
            .position = .{
                .x = @floatFromInt(@divExact(rl.getScreenWidth() - image.width, 2)),
                .y = @floatFromInt(rl.getScreenHeight() - image.height - 100),
            },
        };
    }

    /// Renders the ship at its current world coordinates.
    pub fn draw(self: @This()) void {
        rl.drawTextureV(self.texture, self.position, .white);
    }

    /// Returns the ship's collision rectangle for enemy fire detection.
    pub fn getRect(self: @This()) rl.Rectangle {
        return .{
            .x = self.position.x,
            .y = self.position.y,
            .width = @as(f32, @floatFromInt(self.texture.width)),
            .height = @as(f32, @floatFromInt(self.texture.height)),
        };
    }

    /// Shifts the ship left, clamping it to the left border.
    pub fn moveLeft(self: *@This()) void {
        self.position.x -= self.speed;
        if (self.position.x < horizontal_padding) {
            self.position.x = horizontal_padding;
        }
    }

    /// Shifts the ship right, clamping it to the right border.
    pub fn moveRight(self: *@This()) void {
        self.position.x += self.speed;
        const right_bound = @as(f32, @floatFromInt(rl.getScreenWidth() - self.texture.width - horizontal_padding));
        if (self.position.x > right_bound) {
            self.position.x = right_bound;
        }
    }

    /// Spawns a new laser at the ship's center, moving upward.
    pub fn fireLaser(self: *@This()) !void {
        rl.playSound(self.s_laser);
        const bullet = Laser.init(
            .{
                .x = self.position.x + @as(f32, @floatFromInt(self.texture.width)) / 2.0 - 2.0,
                .y = self.position.y,
            },
            -6, // Negative speed moves the laser up the screen
            .yellow,
        );
        try self.lasers.append(self.allocator, bullet);
    }

    /// Returns the ship to the starting position and clears active lasers.
    pub fn reset(self: *@This()) void {
        self.position.x = @floatFromInt(@divExact(rl.getScreenWidth() - self.texture.width, 2));
        self.position.y = @floatFromInt(rl.getScreenHeight() - self.texture.height - 100);

        // Explicitly clear and free the laser list to prevent leaks during reset.
        self.lasers.clearAndFree(self.allocator);
    }

    /// Clean up textures and allocated laser memory.
    pub fn deinit(self: *@This()) void {
        rl.unloadTexture(self.texture);
        rl.unloadSound(self.s_laser);
        self.lasers.deinit(self.allocator);
    }
};
