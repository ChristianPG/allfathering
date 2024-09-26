package jormungandr

import "core:fmt"
import "core:math"
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
// NOTE: Decrease the tick rate to make Jormungandr faster
TICK_RATE :: 0.1
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
session_score: int
alternate_slide: bool

render_sprite :: proc(
	sprite: rl.Texture2D,
	position: Vec2i,
	rotation: f32 = 0,
	should_flip_vertically: bool = false,
) {
	source := rl.Rectangle {
		0,
		0,
		f32(sprite.width),
		f32(sprite.height) * (should_flip_vertically ? -1 : 1),
	}
	dest := rl.Rectangle {
		f32(position.x) * CELL_SIZE + 0.5 * CELL_SIZE,
		f32(position.y) * CELL_SIZE + 0.5 * CELL_SIZE,
		CELL_SIZE,
		CELL_SIZE,
	}
	rl.DrawTexturePro(sprite, source, dest, {CELL_SIZE, CELL_SIZE} * 0.5, rotation, rl.WHITE)
}

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
	jormungandr[1] = start_head_position - {1, 0}
	// NOTE: For testing
	jormungandr[2] = start_head_position - {2, 0}
	jormungandr[3] = start_head_position - {3, 0}
	jormungandr[4] = start_head_position - {4, 0}
	jormungandr[5] = start_head_position - {5, 0}
	jormungandr_current_length = 6
	move_direction = {1, 0}
	game_over = false
	place_new_food()
}

main :: proc() {
	// NOTE: Activates vsync so the game does not refresh faster than the monitor
	rl.SetConfigFlags({.VSYNC_HINT})
	// NOTE: Opens a new window with the specified size
	rl.InitWindow(WINDOW_SIZE, WINDOW_SIZE, "Jörmungandr")
	rl.InitAudioDevice()

	restart()

	// NOTE: This has to be done after initializing the window to avoid segmentation faults 
	food_sprite := rl.LoadTexture("assets/food.png")
	head_sprite := rl.LoadTexture("assets/head.png")
	body1_sprite := rl.LoadTexture("assets/body1.png")
	body2_sprite := rl.LoadTexture("assets/body2.png")
	left_down_corner_sprite := rl.LoadTexture("assets/left-down-corner.png")
	tail_sprite := rl.LoadTexture("assets/tail.png")

	eating_sound := rl.LoadSound("assets/eat.wav")
	crashing_sound := rl.LoadSound("assets/crash.wav")

	// NOTE: The game will keep running until the window is closed
	for !rl.WindowShouldClose() {
		if game_over {
			if rl.IsKeyPressed(.ENTER) ||
			   rl.IsGamepadButtonPressed(0, .MIDDLE_LEFT) ||
			   rl.IsGamepadButtonPressed(0, .MIDDLE_RIGHT) {
				restart()
			}
		} else {
			if (rl.IsKeyPressed(.UP) || rl.IsGamepadButtonPressed(0, .LEFT_FACE_UP)) &&
			   move_direction != DOWN_DIRECTION {
				move_direction = {0, -1}
			} else if (rl.IsKeyPressed(.DOWN) || rl.IsGamepadButtonPressed(0, .LEFT_FACE_DOWN)) &&
			   move_direction != UP_DIRECTION {
				move_direction = {0, 1}
			} else if (rl.IsKeyPressed(.RIGHT) ||
				   rl.IsGamepadButtonPressed(0, .LEFT_FACE_RIGHT)) &&
			   move_direction != LEFT_DIRECTION {
				move_direction = {1, 0}
			} else if (rl.IsKeyPressed(.LEFT) || rl.IsGamepadButtonPressed(0, .LEFT_FACE_LEFT)) &&
			   move_direction != RIGHT_DIRECTION {
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

			if !food.eaten {
				food.eaten =
					food.position.x == horizontal_position_of_head &&
					food.position.y == vertical_position_of_head
			}

			if !game_over &&
			   (horizontal_position_of_head < 0 ||
					   horizontal_position_of_head >= GRID_WIDTH ||
					   vertical_position_of_head < 0 ||
					   vertical_position_of_head >= GRID_WIDTH) {
				game_over = true
				jormungandr[0] = previous_part_position
				rl.PlaySound(crashing_sound)
			} else {
				// NOTE: One way of writing a for loop
				for index := 1; index < jormungandr_current_length; index += 1 {
					current_body_part := jormungandr[index]
					if previous_part_position.x == jormungandr[0].x &&
					   previous_part_position.y == jormungandr[0].y {
						rl.PlaySound(crashing_sound)
						game_over = true
						break
					}
					jormungandr[index] = previous_part_position
					previous_part_position = current_body_part
				}
				tick_timer = TICK_RATE + tick_timer
				alternate_slide = !alternate_slide
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
			render_sprite(food_sprite, food.position)
		} else {
			place_new_food()
			jormungandr[jormungandr_current_length] = jormungandr[jormungandr_current_length - 1]
			jormungandr_current_length += 1
			session_score += 1
			rl.PlaySound(eating_sound)
		}

		// NOTE: One way of writing a for loop
		for index in 0 ..< jormungandr_current_length {
			// Create a new rectangle to render it in the initial position
			// head_rect := rl.Rectangle {
			// 	f32(jormungandr[index].x * CELL_SIZE),
			// 	f32(jormungandr[index].y * CELL_SIZE),
			// 	CELL_SIZE,
			// 	CELL_SIZE,
			// }
			// rl.DrawRectangleRec(head_rect, index == 0 ? rl.RED : rl.WHITE)

			part_sprite: rl.Texture2D = head_sprite
			should_flip_vertically := false
			part_direction: Vec2i = jormungandr[index] - jormungandr[index + 1]

			if index == jormungandr_current_length - 1 {
				part_direction = jormungandr[index - 1] - jormungandr[index]
				part_sprite = tail_sprite
			} else if index > 0 {
				part_direction = jormungandr[index - 1] - jormungandr[index]
			}

			rotation := math.atan2(f32(part_direction.y), f32(part_direction.x)) * math.DEG_PER_RAD

			// TODO: Refactor the following logic to make it nicer
			if 0 < index && index < (jormungandr_current_length - 1) {
				previous_direction := jormungandr[index] - jormungandr[index + 1]
				should_flip_vertically = false
				part_sprite = left_down_corner_sprite
				if (previous_direction.x == 1 && part_direction.y == 1) ||
				   (previous_direction.y == -1 && part_direction.x == -1) {
					rotation = 0
				} else if (previous_direction.x == -1 && part_direction.y == -1) ||
				   (previous_direction.y == 1 && part_direction.x == 1) {
					rotation = 180
				} else if (previous_direction.x == 1 && part_direction.y == -1) ||
				   (previous_direction.y == 1 && part_direction.x == -1) {
					rotation = 90
				} else if (previous_direction.x == -1 && part_direction.y == 1) ||
				   (previous_direction.y == -1 && part_direction.x == 1) {
					rotation = 270
				} else {
					part_sprite = index %% 2 == 0 ? body1_sprite : body2_sprite
					should_flip_vertically = alternate_slide
				}
			}

			render_sprite(part_sprite, jormungandr[index], rotation, should_flip_vertically)
		}

		if game_over {
			rl.DrawText("GAME OVER", 4, 4, 25, rl.RED)
			rl.DrawText("Press Enter to play again", 4, 30, 15, rl.BLACK)
		}

		// NOTE: Substracting the initial length from the score
		score := jormungandr_current_length - 2
		score_str := fmt.ctprintf("Score: %v", score)
		rl.DrawText(score_str, 4, CANVAS_SIZE - 24, 12, rl.GRAY)

		session_score_str := fmt.ctprintf("Session Score: %v", session_score)
		rl.DrawText(session_score_str, 4, CANVAS_SIZE - 14, 10, rl.GRAY)

		rl.EndMode2D()
		rl.EndDrawing()

		free_all(context.temp_allocator)
	}

	rl.UnloadTexture(food_sprite)
	rl.UnloadTexture(head_sprite)
	rl.UnloadTexture(body1_sprite)
	rl.UnloadTexture(body2_sprite)
	rl.UnloadTexture(left_down_corner_sprite)
	rl.UnloadTexture(tail_sprite)

	rl.UnloadSound(eating_sound)
	rl.UnloadSound(crashing_sound)

	rl.CloseAudioDevice()
	rl.CloseWindow()
}
