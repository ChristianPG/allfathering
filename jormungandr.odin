package jormungandr

import "core:fmt"
import rl "vendor:raylib"

// NOTE: Global Constants 
WINDOW_SIZE :: 500
GRID_WIDTH :: 20
CELL_SIZE :: 16
CANVAS_SIZE :: GRID_WIDTH * CELL_SIZE
TICK_RATE :: 0.13

// NOTE: Types 
Vec2i :: [2]int

// NOTE: Global Variables 
snake_head_position: Vec2i
tick_timer: f32 = TICK_RATE
move_direction: Vec2i

main :: proc() {
	// NOTE: Activates vsync so the game does not refresh faster than the monitor
	rl.SetConfigFlags({.VSYNC_HINT})

	snake_head_position = {GRID_WIDTH / 2, GRID_WIDTH / 2}
	move_direction = {0, 0}

	// NOTE: Opens a new window with the specified size
	rl.InitWindow(WINDOW_SIZE, WINDOW_SIZE, "Jörmungandr")

	// NOTE: The game will keep running until the window is closed
	for !rl.WindowShouldClose() {
		if rl.IsKeyDown(.UP) {
			move_direction = {0, -1}
		}
		if rl.IsKeyDown(.DOWN) {
			move_direction = {0, 1}
		}
		if rl.IsKeyDown(.RIGHT) {
			move_direction = {1, 0}
		}
		if rl.IsKeyDown(.LEFT) {
			move_direction = {-1, 0}
		}

		// NOTE: Delays the new position setting to make the movement visible
		tick_timer -= rl.GetFrameTime()
		if tick_timer <= 0 {
			snake_head_position += move_direction
			tick_timer = TICK_RATE + tick_timer
		}

		rl.BeginDrawing()
		rl.ClearBackground({76, 53, 83, 255})

		// NOTE: Create a camera to make the window fit the size of the canvas
		camera := rl.Camera2D {
			zoom = f32(WINDOW_SIZE) / CANVAS_SIZE,
		}
		rl.BeginMode2D(camera)

		// NOTE: Create a new rectangle to render it in the initial position
		head_rect := rl.Rectangle {
			f32(snake_head_position.x * CELL_SIZE),
			f32(snake_head_position.y * CELL_SIZE),
			CELL_SIZE,
			CELL_SIZE,
		}
		rl.DrawRectangleRec(head_rect, rl.WHITE)

		rl.EndMode2D()
		rl.EndDrawing()
	}

	rl.CloseWindow()
}
