//------------------------------------------------------------------
// Standard library (memory, utilities) and Raylib bindings.
//------------------------------------------------------------------
const std = @import("std");
const rl = @import("raylib");

//------------------------------------------------------------------
// Internal game modules.
// Orchestrates all entities into a cohesive game loop.
//------------------------------------------------------------------
const o = @import("obstacle.zig");
const Alien = @import("alien.zig").Alien;
const Laser = @import("laser.zig").Laser;
const MysteryShip = @import("mystery_ship.zig").MysteryShip;
const Spaceship = @import("spaceship.zig").Spaceship;

// Alias the obstacle grid for local use.
const grid = o.grid;

pub const Game = struct {
    allocator: std.mem.Allocator,
    alien_lasers: std.ArrayList(Laser) = .empty,
    alien_laser_shoot_interval: f64 = undefined,
    aliens: std.ArrayList(Alien) = .empty,
    aliens_direction: f32 = undefined,
    high_score: u32 = undefined,
    lives: i32 = undefined,
    music: rl.Music = undefined,
    mystery_ship: MysteryShip = undefined,
    mystery_ship_spawn_interval: i32 = undefined,
    obstacles: std.ArrayList(o.Obstacle) = .empty,
    score: u32 = undefined,
    spaceship: Spaceship = undefined,
    s_explosion: rl.Sound = undefined,
    time_last_alien_fired_shot: f64 = undefined,
    time_last_spawn: f64 = undefined,
    run: bool = undefined,

    /// Sets up the initial game state and memory.
    pub fn init(allocator: std.mem.Allocator) !@This() {
        var game = @This(){
            .allocator = allocator,
        };
        try game.setup();
        return game;
    }

    /// Primary render pass for all game entities and projectiles.
    pub fn draw(self: @This()) void {
        self.spaceship.draw();

        for (self.spaceship.lasers.items) |*laser| laser.draw();
        for (self.aliens.items) |*alien| alien.draw();
        for (self.alien_lasers.items) |*laser| laser.draw();
        for (self.obstacles.items) |*obstacle| obstacle.draw();

        self.mystery_ship.draw();
    }

    /// Updates game logic, timers, movement, and collision checks.
    pub fn update(self: *@This()) !void {
        if (self.run) {
            // Randomly spawn the bonus mystery ship
            if (rl.getTime() - self.time_last_spawn > @as(f32, @floatFromInt(self.mystery_ship_spawn_interval))) {
                self.mystery_ship.spawn();
                self.time_last_spawn = rl.getTime();
                self.mystery_ship_spawn_interval = rl.getRandomValue(10, 20);
            }

            // Move projectiles and units
            for (self.spaceship.lasers.items) |*laser| laser.update();
            self.moveAliens();
            try self.alienShootLaser();
            for (self.alien_lasers.items) |*laser| laser.update();

            // Cleanup and state resolution
            self.deleteInactiveLasers();
            self.mystery_ship.update();
            self.checkForCollisions();
        } else {
            // Wait for restart command on game over
            if (rl.isKeyDown(.enter)) {
                self.reset();
                try self.setup();
            }
        }
    }

    /// Maps user hardware input to player ship actions.
    pub fn handleInput(self: *@This()) !void {
        if (self.run) {
            if (rl.isKeyDown(.left)) {
                self.spaceship.moveLeft();
            } else if (rl.isKeyDown(.right)) {
                self.spaceship.moveRight();
            } else if (rl.isKeyPressed(.space)) {
                try self.spaceship.fireLaser();
            }
        }
    }

    /// Gracefully unloads all GPU assets and clears heap allocations.
    pub fn deinit(self: *@This()) void {
        // Unload textures for nested entities within the lists
        for (self.aliens.items) |*alien| alien.deinit();
        for (self.obstacles.items) |*obstacle| obstacle.deinit();

        // Release the memory buffers for all dynamic arrays
        self.alien_lasers.deinit(self.allocator);
        self.aliens.deinit(self.allocator);
        self.obstacles.deinit(self.allocator);

        // Destroy the bonus ship and player ship, releasing their GPU textures.
        self.mystery_ship.deinit();
        self.spaceship.deinit();

        // Final cleanup of global audio assets
        rl.unloadMusicStream(self.music);
        rl.unloadSound(self.s_explosion);
    }

    /// Spawns a laser fired from a random alien if the firing interval has elapsed.
    fn alienShootLaser(self: *@This()) !void {
        if (rl.getTime() - self.time_last_alien_fired_shot >= self.alien_laser_shoot_interval and self.aliens.items.len != 0) {
            const randomIndex: usize = @intCast(rl.getRandomValue(0, @intCast(self.aliens.items.len - 1)));
            const alien = self.aliens.items[randomIndex];
            const index: usize = @intCast(alien.type - 1);

            try self.alien_lasers.append(
                self.allocator,
                Laser.init(
                    .{
                        .x = alien.position.x + @as(f32, @floatFromInt(@divFloor(alien.alien_images[index].width, 2))),
                        .y = alien.position.y + @as(f32, @floatFromInt(@divFloor(alien.alien_images[index].height, 6))),
                    },
                    6,
                    .red,
                ),
            );

            self.time_last_alien_fired_shot = rl.getTime();
        }
    }

    /// Main collision matrix: resolves hits between lasers, ships, and blocks.
    fn checkForCollisions(self: *@This()) void {
        var it: usize = undefined;

        // Player laser interactions
        for (self.spaceship.lasers.items) |*laser| {
            if (!laser.active) continue;

            // Check Aliens
            it = self.aliens.items.len;
            while (it > 0) : (it -= 1) {
                const alien = &self.aliens.items[it - 1];
                if (rl.checkCollisionRecs(laser.getRect(), alien.getRect())) {
                    rl.playSound(self.s_explosion);
                    self.score += switch (alien.type) {
                        1 => 1,
                        2 => 5,
                        else => 10,
                    };
                    _ = self.aliens.orderedRemove(it - 1);
                    laser.active = false;
                }
            }

            // Check Obstacle Blocks
            for (self.obstacles.items) |*obstacle| {
                it = obstacle.blocks.items.len;
                while (it > 0) : (it -= 1) {
                    const block = &obstacle.blocks.items[it - 1];
                    if (rl.checkCollisionRecs(laser.getRect(), block.getRect())) {
                        rl.playSound(self.s_explosion);
                        _ = obstacle.blocks.orderedRemove(it - 1);
                        laser.active = false;
                    }
                }
            }

            // Check Mystery Ship
            if (rl.checkCollisionRecs(self.mystery_ship.getRect(), laser.getRect())) {
                rl.playSound(self.s_explosion);
                self.mystery_ship.alive = false;
                laser.active = false;
                self.score += 30;
            }

            if (self.score > self.high_score) {
                self.high_score = self.score;
            }
        }

        // Enemy laser interactions
        for (self.alien_lasers.items) |*laser| {
            if (rl.checkCollisionRecs(laser.getRect(), self.spaceship.getRect())) {
                laser.active = false;
                self.lives -= 1;
                if (self.lives == 0) self.gameOver();
            }

            for (self.obstacles.items) |*obstacle| {
                it = obstacle.blocks.items.len;
                while (it > 0) : (it -= 1) {
                    const block = &obstacle.blocks.items[it - 1];
                    if (rl.checkCollisionRecs(laser.getRect(), block.getRect())) {
                        _ = obstacle.blocks.orderedRemove(it - 1);
                        laser.active = false;
                    }
                }
            }
        }

        // Physical collision: Aliens touching obstacles or player
        for (self.aliens.items) |alien| {
            for (self.obstacles.items) |*obstacle| {
                it = obstacle.blocks.items.len;
                while (it > 0) : (it -= 1) {
                    if (rl.checkCollisionRecs(alien.getRect(), obstacle.blocks.items[it - 1].getRect())) {
                        _ = obstacle.blocks.orderedRemove(it - 1);
                    }
                }
            }
            if (rl.checkCollisionRecs(alien.getRect(), self.spaceship.getRect())) self.gameOver();
        }
    }

    /// Populates the alien swarm in a grid formation.
    fn createAliens(self: *@This()) !void {
        for (0..5) |row| {
            for (0..11) |col| {
                try self.aliens.append(
                    self.allocator,
                    try Alien.init(
                        switch (row) {
                            0 => 3,
                            1, 2 => 2,
                            else => 1,
                        },
                        .{
                            .x = @as(f32, @floatFromInt(75 + col * 55)),
                            .y = @as(f32, @floatFromInt(110 + row * 55)),
                        },
                    ),
                );
            }
        }
    }

    /// Populates the defensive bunkers across the screen.
    fn createObstacles(self: *@This()) !void {
        const obstacleWidth: i32 = @intCast(grid[0].len * 3);
        const gap = @as(f32, @floatFromInt(rl.getScreenWidth() - 4 * obstacleWidth)) / 5;

        for (0..4) |i| {
            try self.obstacles.append(
                self.allocator,
                try o.Obstacle.init(
                    self.allocator,
                    .{
                        .x = gap * @as(f32, @floatFromInt(i + 1)) + @as(f32, @floatFromInt(i * obstacleWidth)),
                        .y = @floatFromInt(rl.getScreenHeight() - 200),
                    },
                ),
            );
        }
    }

    /// Stops the game loop when a fail condition is met.
    fn gameOver(self: *@This()) void {
        self.run = false;
    }

    /// Handles horizontal movement and descent logic for the alien swarm.
    fn moveAliens(self: *@This()) void {
        for (self.aliens.items) |*alien| {
            const texture = alien.alien_images[@intCast(alien.type - 1)];

            // Bounce off right edge
            if (alien.position.x + @as(f32, @floatFromInt(texture.width)) > @as(f32, @floatFromInt(rl.getScreenWidth() - 25))) {
                self.aliens_direction = -1;
                self.moveDownAliens(4);
            }
            // Bounce off left edge
            if (alien.position.x < 25) {
                self.aliens_direction = 1;
                self.moveDownAliens(4);
            }

            alien.update(self.aliens_direction);
        }
    }

    /// Shifts the entire alien formation down.
    fn moveDownAliens(self: *@This(), distance: f32) void {
        for (self.aliens.items) |*alien| {
            alien.position.y += distance;
        }
    }

    /// Sweeps the laser lists and removes objects that are no longer active.
    fn deleteInactiveLasers(self: *@This()) void {
        removeInactive(&self.spaceship.lasers);
        removeInactive(&self.alien_lasers);
    }

    /// Internal helper to remove elements from a laser list while iterating.
    fn removeInactive(lasers: *std.ArrayList(Laser)) void {
        var i: usize = lasers.items.len;
        while (i > 0) : (i -= 1) {
            if (!lasers.items[i - 1].active)
                _ = lasers.orderedRemove(i - 1);
        }
    }

    /// Wipes the current game state to prepare for a fresh session.
    fn reset(self: *@This()) void {
        // Clean up standalone entities
        self.mystery_ship.deinit();
        self.spaceship.reset();

        // Release GPU resources for all aliens and empty the list
        for (self.aliens.items) |*alien| alien.deinit();
        self.aliens.clearRetainingCapacity();

        // Release GPU resources for all bunker blocks and empty the list
        for (self.obstacles.items) |*obstacle| obstacle.deinit();
        self.obstacles.clearRetainingCapacity();

        // Clear remaining projectiles without freeing the list's internal buffer
        self.alien_lasers.clearRetainingCapacity();
    }

    /// Configures initial parameters, audio, and entity placement.
    fn setup(self: *@This()) !void {
        self.alien_laser_shoot_interval = 0.35;
        self.aliens_direction = 1.0;
        self.high_score = 0;
        self.lives = 3;
        self.music = try rl.loadMusicStream("assets/sounds/music.ogg");
        self.mystery_ship = try MysteryShip.init();
        self.mystery_ship_spawn_interval = rl.getRandomValue(10, 20);
        self.score = 0;
        self.spaceship = try Spaceship.init(self.allocator);
        self.s_explosion = try rl.loadSound("assets/sounds/explosion.ogg");
        self.time_last_alien_fired_shot = 0.0;
        self.time_last_spawn = 0.0;
        self.run = true;

        // Start background music playback and initialize the game world entities.
        rl.playMusicStream(self.music);

        try self.createAliens(); // Generate the initial invader formation
        try self.createObstacles(); // Construct the defensive bunkers
    }
};
