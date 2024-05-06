module update_module

import mystructs
import math
import time

pub fn update(mut game mystructs.Game) {
	
	if game.is_key_pressing(.left_control) && game.is_key_pressed(.kp_add) {
		game.ctx.scale += 0.1
	} else if game.is_key_pressing(.left_control) && game.is_key_pressed(.kp_subtract) {
		game.ctx.scale = math.max(game.ctx.scale - 0.1, 0.1)
	}

	if game.is_right_mouse_pressed() {
		cell_id_at_mouse := game.grid.pixelpos_to_id(game.mouse_pos)
		game.data.neighbor_test = game.grid.neighbors_data[cell_id_at_mouse]
		
		if _ := game.grid.steps_map[cell_id_at_mouse] {
			game.cur_grid_id = -1
			game.data.processed_map = game.grid.steps_map[cell_id_at_mouse].clone()
		} else {
			spawn fn (game mystructs.Game, cell_id int) {
				game.grid.ch1 <- game.grid.create_steps_map(cell_id, game.data.cross)
			} (game, cell_id_at_mouse)
		}
		for _, mut gobj in game.data.gobj_map {
			if !gobj.player_control {
				continue
			}
			if !gobj.player_selected {
				continue
			}
			mouse_center_pos := game.grid.id_to_pixelpos(cell_id_at_mouse, true)
			gobj.new_dest_pos = mouse_center_pos
		}
	}
	
	if game.is_left_mouse_pressed() {
		for _, mut gobj in game.data.gobj_map {
			dist_to_mouse := game.mouse_pos.minus(gobj.cur_pos).length(gobj.vec_length_optimize)
			if dist_to_mouse <= game.grid.cell_size/2.0 {
				gobj.player_selected = true
			} else {
				gobj.player_selected = false
			}
		}
	}
	
	if game.left_mouse_released {
		for _, mut gobj in game.data.gobj_map {
			if gobj.died == true {
				continue
			}
			game.data.select_area.calc_rect_info(game.click_pos, game.mouse_pos)
			in_select_area := game.data.select_area.is_pos_in(gobj.cur_pos)
			if in_select_area {
				gobj.player_selected = true
			}
		}
	}

	if game.left_mouse_pressing {
		game.data.select_area.calculate_draw_info(game.click_pos, game.mouse_pos, game.cam.pos)
	}

	for _, mut gobj in game.data.gobj_map {
		if gobj.died {
			continue
		}
		match gobj.state {
			'normal' {
				gobj.moving_to_destination(mut game)
			}
			else {}
		}
		if neid := game.data.nearest_enemy_map[gobj.id] {
			if _ := game.data.gobj_map[neid] {
				gobj.nearest_enemy_id = neid
				epos := game.data.gobj_map[neid].cur_pos
				distance := gobj.cur_pos.minus(epos).length(gobj.vec_length_optimize)
				if distance <= gobj.attack_range {
					if gobj.attack_alarm == 0.0 {
						game.data.gobj_map[neid].hp -= 20
						if game.data.gobj_map[neid].hp <= 0.0 {
							game.data.gobj_map[neid].hp = 0.0
						}
						gobj.attack_alarm = gobj.attack_alarm_max_time
					}
				}
				if gobj.attack_alarm > 0.0 {
					gobj.attack_alarm -= 0.1
					if gobj.attack_alarm <= 0.0 {
						gobj.attack_alarm = 0.0
					}
				}
			}
		}
	}

}



pub fn thread1_process(game mystructs.Game) {
	for game.is_worker1_working {
		mut team0 := []int{}
		mut team1 := []int{}
		for _, gobj in game.data.gobj_map {
			if gobj.team == 0 && gobj.died == false {
				team0 << gobj.id
			} 
			else if gobj.team == 1 && gobj.died == false {
				team1 << gobj.id
			}
		}

		mut rs := map[int]int{}
		for gobj_id in team0 {
			mut neid := -1
			mut min_distance := -1.0
			for enemy_id in team1 {
				distance := game.data.gobj_map[gobj_id].cur_pos.minus(game.data.gobj_map[enemy_id].cur_pos).length(game.data.gobj_map[gobj_id].vec_length_optimize)
				if neid == -1 {
					neid = enemy_id
					min_distance = distance
					continue
				}
				if distance < min_distance {
					neid = enemy_id
					min_distance = distance
				}
			}
			rs[gobj_id] = neid
		}
		for gobj_id in team1 {
			mut neid := -1
			mut min_distance := -1.0
			for enemy_id in team0 {
				distance := game.data.gobj_map[gobj_id].cur_pos.minus(game.data.gobj_map[enemy_id].cur_pos).length(game.data.gobj_map[gobj_id].vec_length_optimize)
				if neid == -1 {
					neid = enemy_id
					min_distance = distance
					continue
				}
				if distance < min_distance {
					neid = enemy_id
					min_distance = distance
				}
			}
			rs[gobj_id] = neid
		}
		game.data.nearest_enemy_map_chan <- rs or {panic(err)}
	}
	
}

pub fn thread2_process(game mystructs.Game) {
	for game.is_worker2_working {

		
		time.sleep(1000*time.millisecond)
	}
	
}





