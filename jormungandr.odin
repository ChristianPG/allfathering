package jormungandr

import "core:fmt"
import rl "vendor:raylib"

// Types
Vec2i :: [2]int

// Global Constants
WINDOW_SIZE :: 500
GRID_WIDTH :: 20
CELL_SIZE :: 16
CANVAS_SIZE :: GRID_WIDTH * CELL_SIZE
TICK_RATE :: 0.13
MAX_SNAKE_LENGTH :: GRID_WIDTH * GRID_WIDTH
UP_DIRECTION :: Vec2i{0, -1}
DOWN_DIRECTION :: Vec2i{0, 1}
RIGHT_DIRECTION :: Vec2i{1, 0}
LEFT_DIRECTION :: Vec2i{-1, 0}

// Global Variables
tick_timer: f32 = TICK_RATE
move_direction: Vec2i
jormungandr: [MAX_SNAKE_LENGTH]Vec2i = {}
jormungandr_current_length: int
game_over := false

restart :: proc() {
	start_head_position := Vec2i{GRID_WIDTH / 2, GRID_WIDTH / 2}
	jormungandr[0] = start_head_position
	jormungandr[1] = start_head_position - {0, 1}
	jormungandr[1] = start_head_position - {0, 2}
	jormungandr[1] = start_head_position - {0, 3}
	jormungandr_current_length = 4
	move_direction = {0, 0}
	game_over = false
}

main :: proc() {
	// NOTE: Activates vsync so the game does not refresh faster than the monitor
	rl.SetConfigFlags({.VSYNC_HINT})

	restart()

	// NOTE: Opens a new window with the specified size
	rl.InitWindow(WINDOW_SIZE, WINDOW_SIZE, "Jörmungandr")

	// NOTE: The game will keep running until the window is closed
	for !rl.WindowShouldClose() {
		if game_over {
			if rl.IsKeyPressed(.ENTER) {
				restart()
			}
		} else {
			if rl.IsKeyDown(.UP) && move_direction != DOWN_DIRECTION {
				move_direction = {0, -1}
			}
			if rl.IsKeyDown(.DOWN) && move_direction != UP_DIRECTION {
				move_direction = {0, 1}
			}
			if rl.IsKeyDown(.RIGHT) && move_direction != LEFT_DIRECTION {
				move_direction = {1, 0}
			}
			if rl.IsKeyDown(.LEFT) && move_direction != RIGHT_DIRECTION {
				move_direction = {-1, 0}
			}
			// NOTE: Delays the new position setting to make the movement visible
			tick_timer -= rl.GetFrameTime()
		}

		if tick_timer <= 0 {
			previous_part_position := jormungandr[0]
			jormungandr[0] += move_direction
			game_over =
				jormungandr[0].x < 0 ||
				jormungandr[0].x >= GRID_WIDTH ||
				jormungandr[0].y < 0 ||
				jormungandr[0].y >= GRID_WIDTH

			if game_over {
				jormungandr[0] = previous_part_position
			} else {
				// NOTE: One way of writing a for loop
				for index := 1; index < jormungandr_current_length; index += 1 {
					current_body_part := jormungandr[index]
					jormungandr[index] = previous_part_position
					previous_part_position = current_body_part
				}
				tick_timer = TICK_RATE + tick_timer
			}
		}

		rl.BeginDrawing()
		rl.ClearBackground({76, 53, 83, 255})

		// NOTE: Create a camera to make the window fit the size of the canvas
		camera := rl.Camera2D {
			zoom = f32(WINDOW_SIZE) / CANVAS_SIZE,
		}
		rl.BeginMode2D(camera)

		// NOTE: One way of writing a for loop
		for index in 0 ..< jormungandr_current_length {
			// NOTE: Create a new rectangle to render it in the initial position
			head_rect := rl.Rectangle {
				f32(jormungandr[index].x * CELL_SIZE),
				f32(jormungandr[index].y * CELL_SIZE),
				CELL_SIZE,
				CELL_SIZE,
			}
			rl.DrawRectangleRec(head_rect, rl.WHITE)
		}

		if game_over {
			rl.DrawText("GAME OVER", 4, 4, 25, rl.RED)
			rl.DrawText("Press Enter to play again", 4, 30, 15, rl.BLACK)
		}

		rl.EndMode2D()
		rl.EndDrawing()
	}

	rl.CloseWindow()
}
