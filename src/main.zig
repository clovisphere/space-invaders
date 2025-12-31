//------------------------------------------------------------------
// Standard library (memory, utilities) and Raylib bindings for
// windowing, input, and drawing.
//------------------------------------------------------------------
const std = @import("std");
const rl = @import("raylib");

//------------------------------------------------------------------
// Internal game modules.
// The beating heart of the game: rules, entities, and coordination.
//------------------------------------------------------------------
const Game = @import("libs/game.zig").Game;

pub fn main() !void {
    //------------------------------------------------------------------
    // Screen dimensions for the main game window.
    //------------------------------------------------------------------
    const screen_width = 750;
    const screen_height = 700;

    //------------------------------------------------------------------
    // Global heap allocator for the game.
    // Manages dynamic memory and detects leaks on exit.
    //------------------------------------------------------------------
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    //------------------------------------------------------------------
    // Initialize Raylib window and graphics context.
    //------------------------------------------------------------------
    rl.initWindow(screen_width, screen_height, "Space Invaders 🚀");
    defer rl.closeWindow();

    //------------------------------------------------------------------
    // Initialize audio system for music and sound effects.
    //------------------------------------------------------------------
    rl.initAudioDevice();
    defer rl.closeAudioDevice();

    // Set stable frame rate for consistent gameplay.
    rl.setTargetFPS(60);

    //------------------------------------------------------------------
    // Initialize the Game state and logic container.
    //------------------------------------------------------------------
    var game = try Game.init(gpa.allocator());
    defer game.deinit();

    //------------------------------------------------------------------
    // Load custom font for UI and HUD elements.
    //------------------------------------------------------------------
    const font = try rl.loadFontEx("assets/fonts/monogram.ttf", 32, null);
    defer rl.unloadFont(font);

    //------------------------------------------------------------------
    // Load spaceship texture for the life-counter UI.
    //------------------------------------------------------------------
    const spaceship_image = try rl.loadTexture("assets/shapes/spaceship.png");
    defer rl.unloadTexture(spaceship_image);

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(.black);

        //------------------------------------------------------------------
        // Refresh the background music buffer.
        //------------------------------------------------------------------
        rl.updateMusicStream(game.music);

        //------------------------------------------------------------------
        // Process player movement and update entity physics.
        //------------------------------------------------------------------
        try game.handleInput();
        try game.update();

        //------------------------------------------------------------------
        // Draw the decorative UI borders and separation lines.
        //------------------------------------------------------------------
        rl.drawRectangleRoundedLines(
            .{ .x = 10, .y = 10, .width = 730, .height = 680 },
            0.18,
            2,
            .yellow,
        );
        rl.drawLineEx(.{ .x = 25, .y = 615 }, .{ .x = 730, .y = 615 }, 2, .yellow);

        //------------------------------------------------------------------
        // Display current level status or Game Over message.
        //------------------------------------------------------------------
        if (game.run) {
            rl.drawTextEx(
                font,
                "LEVEL 01",
                .{ .x = 555, .y = 625 },
                @floatFromInt(font.baseSize),
                2,
                .yellow,
            );
        } else {
            rl.drawTextEx(
                font,
                "GAME OVER",
                .{ .x = 555, .y = 625 },
                @floatFromInt(font.baseSize),
                2,
                .yellow,
            );
        }

        //------------------------------------------------------------------
        // Render remaining player lives as a row of ship icons.
        //------------------------------------------------------------------
        var offset: f32 = 60;
        for (0..@intCast(game.lives)) |_| {
            rl.drawTextureV(spaceship_image, .{ .x = offset, .y = 625 }, .white);
            offset += 50;
        }

        // Render score label.
        rl.drawTextEx(
            font,
            "SCORE",
            .{ .x = 50, .y = 20 },
            @floatFromInt(font.baseSize),
            2,
            .yellow,
        );

        //------------------------------------------------------------------
        // Format score as a padded string (e.g., 00100).
        //------------------------------------------------------------------
        const scoreText = try std.fmt.allocPrintSentinel(gpa.allocator(), "{:0>5}", .{game.score}, 0);
        defer gpa.allocator().free(scoreText);

        // Draw numerical score.
        rl.drawTextEx(
            font,
            scoreText,
            .{ .x = 50, .y = 50 },
            @floatFromInt(font.baseSize),
            2,
            .yellow,
        );

        // Draw game entities (Aliens, Lasers, Player).
        game.draw();
    }
}
