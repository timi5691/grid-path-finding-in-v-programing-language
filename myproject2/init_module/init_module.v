module init_module

import mystructs
import gx
import math
import rand
import update_module

pub const (
	window_width = 640
	window_height = 480
	s = 640.0/480
)

pub fn init_game(mut game mystructs.Game) {
	game.data.cross = true
	game.ctx.set_bg_color(gx.white)
	
	game.grid.cell_size = 16
	game.grid.cross_dist = f32(math.sqrt(game.grid.cell_size*game.grid.cell_size + game.grid.cell_size*game.grid.cell_size))
	game.n_grid_x = 1
	game.n_grid_y = 1
	game.sub_grid_cols = 200
	game.sub_grid_rows = 200
	game.grid.cols = game.sub_grid_cols*game.n_grid_x
	game.grid.rows = game.sub_grid_rows*game.n_grid_y
	
	for row in 0..game.n_grid_y {
		for col in 0..game.n_grid_x {
			game.sub_grid_map[row*game.n_grid_x + col] = mystructs.Grid{
				pos: mystructs.Vec2{
					x: col*game.grid.cell_size*game.sub_grid_cols
					y: row*game.grid.cell_size*game.sub_grid_rows
				}
				cols: game.sub_grid_cols
				rows: game.sub_grid_rows
				cell_size: game.grid.cell_size
				color: gx.rgba(
					u8(mystructs.random_number_in_range(0, 255)), 
					u8(mystructs.random_number_in_range(0, 255)), 
					u8(mystructs.random_number_in_range(0, 255)), 
					255
				)
			}
		}
	}
	
	game.resize()
	
	
	percent_walkable := 95
	game.random_walkable_map(percent_walkable)
	
	mut walkable_cells := game.grid.get_walkable_cells()
	rand.shuffle(mut walkable_cells) or {panic(err)}
	
	gobj_numbers := 2_000
	half_gobj_number := gobj_numbers/2
	for i in 0..gobj_numbers {
		walkable_cell := walkable_cells.pop()
		pos := game.grid.id_to_pixelpos(walkable_cell, true)
		game.data.gobj_map[i] = mystructs.Gobj{
			id: i 
			cur_pos: pos 
			next_pos: pos 
			dest_pos: pos 
			vec_length_optimize: false
			spd: 0.5
			player_control: true//i < half_gobj_number
			stop_distance: 0.0
			team: if i < half_gobj_number {0} else {1}
			attack_range: game.grid.cross_dist
		}
	}
	spawn update_module.thread1_process(game)
	spawn update_module.thread2_process(game)
}


