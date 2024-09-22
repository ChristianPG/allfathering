package jormungandr

import "core:fmt"
import "core:math/rand"
import rl "vendor:raylib"

// Types
Vec2i :: [2]int
Food :: struct {
	position: Vec2i,
	eaten:    bool,
}

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
food: Food

place_new_food :: proc() {
	occupied: [GRID_WIDTH][GRID_WIDTH]bool

	for i in 0 ..< jormungandr_current_length {
		occupied[jormungandr[i].x][jormungandr[i].y] = true
	}

	// NOTE: temp_allocator mark the memory used by free_cells to be removed later
	free_cells := make([dynamic]Vec2i, context.temp_allocator)

	for x in 0 ..< GRID_WIDTH {
		for y in 0 ..< GRID_WIDTH {
			if !occupied[x][y] {
				append(&free_cells, Vec2i{x, y})
			}
		}
	}

	if len(free_cells) > 0 {
		random_cell_index := rl.GetRandomValue(0, i32(len(free_cells)) - 1)
		food = {
			position = free_cells[random_cell_index],
			eaten    = false,
		}
	}
}

restart :: proc() {
	start_head_position := Vec2i{GRID_WIDTH / 2, GRID_WIDTH / 2}
	jormungandr[0] = start_head_position
	// NOTE: For testing
	// jormungandr[1] = start_head_position - {1, 0}
	// jormungandr[2] = start_head_position - {2, 0}
	// jormungandr[3] = start_head_position - {3, 0}
	// jormungandr[4] = start_head_position - {4, 0}
	jormungandr_current_length = 5
	move_direction = {0, 0}
	game_over = false
	place_new_food()
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
			horizontal_position_of_head := jormungandr[0].x
			vertical_position_of_head := jormungandr[0].y
			game_over =
				horizontal_position_of_head < 0 ||
				horizontal_position_of_head >= GRID_WIDTH ||
				vertical_position_of_head < 0 ||
				vertical_position_of_head >= GRID_WIDTH
			if !food.eaten {
				food.eaten =
					food.position.x == horizontal_position_of_head &&
					food.position.y == vertical_position_of_head
			}

			if game_over {
				jormungandr[0] = previous_part_position
			} else {
				// NOTE: One way of writing a for loop
				for index := 1; index < jormungandr_current_length; index += 1 {
					current_body_part := jormungandr[index]
					jormungandr[index] = previous_part_position
					previous_part_position = current_body_part
					if current_body_part.x == jormungandr[0].x &&
					   current_body_part.y == jormungandr[0].y {
						game_over = true
						break
					}
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

		// NOTE: Render the food
		if !food.eaten {
			head_rect := rl.Rectangle {
				f32(food.position.x * CELL_SIZE),
				f32(food.position.y * CELL_SIZE),
				CELL_SIZE,
				CELL_SIZE,
			}
			rl.DrawRectangleRec(head_rect, rl.PINK)
		} else {
			place_new_food()
			jormungandr[jormungandr_current_length] = jormungandr[jormungandr_current_length - 1]
			jormungandr_current_length += 1
		}

		// NOTE: One way of writing a for loop
		for index in 0 ..< jormungandr_current_length {
			// NOTE: Create a new rectangle to render it in the initial position
			head_rect := rl.Rectangle {
				f32(jormungandr[index].x * CELL_SIZE),
				f32(jormungandr[index].y * CELL_SIZE),
				CELL_SIZE,
				CELL_SIZE,
			}
			rl.DrawRectangleRec(head_rect, index == 0 ? rl.RED : rl.WHITE)
		}

		if game_over {
			rl.DrawText("GAME OVER", 4, 4, 25, rl.RED)
			rl.DrawText("Press Enter to play again", 4, 30, 15, rl.BLACK)
		}

		rl.EndMode2D()
		rl.EndDrawing()

		free_all(context.temp_allocator)
	}

	rl.CloseWindow()
}
