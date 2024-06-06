module update_module

import mystructs
import irishgreencitrus.raylibv as r

/// EVENTS
fn on_left_mouse_pressed(mut game mystructs.Game) {
}

fn on_right_mouse_pressed(mut game mystructs.Game) {
	mut data := &game.data
	r.play_sound(data.audio_map['click'])
	create_pathfinding_data_to_mouse_pos_in_thread(mut game)

	data.circle_pos = game.mouse_pos
	if data.minimap.is_mouse_in {
		global_mouse_pos := data.minimap.gui_pos_to_global(data.cursor.cur_pos)
		data.circle_pos = global_mouse_pos
	}
	data.circle_animation.play('right mouse click', 0, 0.2)
}

fn on_left_mouse_released(mut game mystructs.Game) {
	if mystructs.is_pos_in_rect(game.gui_click_pos, game.data.minimap.top_left, mystructs.Vec2{game.data.minimap.width, game.data.minimap.height}) {
		return
	}

	game.data.select_area.calc_rect_info(game.click_pos, game.mouse_pos)

	if game.click_count >= 2 {
		cell_id_at_mouse := game.grid.pixelpos_to_id(game.mouse_pos)
		if gobj_id_at_mouse := game.data.cell_gobj_map[cell_id_at_mouse] {
			gobj_team_at_mouse := game.data.gobj_map[gobj_id_at_mouse].team
			for incamview_obj in game.data.onscreen_gobj_list {
				if game.data.gobj_map[incamview_obj.id].team == gobj_team_at_mouse
					&& game.data.gobj_map[incamview_obj.id].gobj_type == game.data.gobj_map[gobj_id_at_mouse].gobj_type {
					game.data.gobj_map[incamview_obj.id].player_selected = true
				}
			}
		}
	}
}

fn on_left_mouse_down(mut game mystructs.Game) {
	mut data := &game.data
	if mystructs.is_pos_in_rect(game.gui_click_pos, data.minimap.top_left, mystructs.Vec2{data.minimap.width, data.minimap.height}) {
		real_mouse_pos := data.minimap.gui_pos_to_global(data.cursor.cur_pos).minus(mystructs.Vec2{f32(r.get_screen_width()) / 2.0, f32(r.get_screen_height()) / 2.0})
		game.cam.pos = real_mouse_pos
		return
	}
	data.select_area.calculate_draw_info(game.click_pos, game.mouse_pos, game.cam.pos)
}

/// PROCS
fn create_pathfinding_data_to_mouse_pos_in_thread(mut game mystructs.Game) {
	mut data := &game.data
	if !mystructs.is_pos_in_rect(game.mouse_pos, game.grid.pos, mystructs.Vec2{game.grid.width, game.grid.height}) {
		return
	}
	mut cell_id_at_mouse := game.mouse_cell
	if data.minimap.is_mouse_in {
		global_mouse_pos := data.minimap.gui_pos_to_global(data.cursor.cur_pos)
		cell_id_at_mouse = game.grid.pixelpos_to_id(global_mouse_pos)
	}
	if _ := game.grid.steps_map[cell_id_at_mouse] {
		game.cur_grid_id = -1
		data.processed_map = game.grid.steps_map[cell_id_at_mouse].clone()
	} else {
		spawn fn (game mystructs.Game, cell_id int) {
			game.grid.ch1 <- game.grid.create_steps_map(cell_id, game.data.cross)
		}(game, cell_id_at_mouse)
	}
}

fn create_pathfinding_data_to_pos_in_thread(pos mystructs.Vec2, mut game mystructs.Game) {
	// mut data := &game.data
	if !mystructs.is_pos_in_rect(pos, game.grid.pos, mystructs.Vec2{game.grid.width, game.grid.height}) {
		return
	}
	mut cell_id := game.grid.pixelpos_to_id(pos)
	spawn fn (game mystructs.Game, cell_id int) {
		game.grid.ch1 <- game.grid.create_steps_map(cell_id, game.data.cross)
	}(game, cell_id)
}

fn sat_process(mut game mystructs.Game) {
	mut data := &game.data
	data.scan_rot += data.scan_spd
	if data.scan_rot >= 2.0 * 3.14 / f32(mystructs.nsat / 2.0) {
		data.scan_level += 1
		data.scan_rot = 0.0
	}
	if data.scan_level >= data.scan_max_level {
		data.scan_level = 0
	}
}

fn gobjs_process(mut game mystructs.Game) {
	mut data := &game.data
	data.onscreen_gobj_list.clear()
	for sound_name, _ in data.sound_count {
		data.sound_count[sound_name] = 0
	}
	for _, mut gobj in data.gobj_map {
		game.control_gobj_attack_time(mut gobj)
		match gobj.state {
			'moving' {
				// gobj_scan_nearest_gobj(mut gobj, mut game)
				data.aspr_map[gobj.id].texture_name = if data.gobj_map[gobj.id].team == 0 {
					if data.gobj_map[gobj.id].gobj_type == 'sword man' {
						'warrior_walking'
					} else if data.gobj_map[gobj.id].gobj_type == 'archer' {
						'archer_walking'
					} else if data.gobj_map[gobj.id].gobj_type == 'cleric' {
						'cleric_walking'
					} else {
						'character1_walking'
					}
				} else {
					'zombie_walking'
				}
				gobj.nearest_enemy_id = -1
				gobj_right_mouse_pressed_change_destination_to_mouse_pos(mut gobj, mut
					game)
				gobj_to_incamview(mut gobj, mut game)
				gobj_selection(mut gobj, mut game)

				if gobj.target_enemy_id != -1 && gobj.is_next_pos_reached() {
					tgpos := data.gobj_map[gobj.target_enemy_id].cur_pos
					in_attack_range := mystructs.is_two_pos_in_distance(gobj.cur_pos, tgpos, gobj.attack_range)
					if in_attack_range {
						gobj.new_dest_pos = gobj.cur_pos
						gobj.dest_pos = gobj.cur_pos
					}
					if data.gobj_hp_map[gobj.target_enemy_id] <= 0 {
						gobj.new_dest_pos = gobj.cur_pos
						gobj.dest_pos = gobj.cur_pos
						gobj.target_enemy_id = -1
					}
				}

				if gobj.lost_hp_ally_id != -1 && gobj.gobj_type == 'cleric' && gobj.is_next_pos_reached() {
					tgpos := data.gobj_map[gobj.lost_hp_ally_id].cur_pos
					in_attack_range := mystructs.is_two_pos_in_distance(gobj.cur_pos, tgpos, gobj.attack_range)
					if in_attack_range {
						gobj.new_dest_pos = gobj.cur_pos
						gobj.dest_pos = gobj.cur_pos
					}
					if data.gobj_hp_map[gobj.lost_hp_ally_id] <= 0 {
						gobj.new_dest_pos = gobj.cur_pos
						gobj.dest_pos = gobj.cur_pos
						gobj.lost_hp_ally_id = -1
					}
				}

				dest_cell := game.grid.pixelpos_to_id(gobj.dest_pos)
				if _ := game.grid.steps_map[dest_cell] {
					gobj.moving_to_destination(mut game)
				} else {
					gobj.simple_moving_to_destination(mut game)
				}

				gobj.moving_facing(mut game)

				if !gobj.cant_moving {
					gobj.cant_moving_time = 0.0
				} else {
					gobj.cant_moving_time += game.delta_time
					if gobj.cant_moving_time >= gobj.max_cant_moving_time && gobj.is_next_pos_reached() {
						gobj.cant_moving_time = 0
						gobj.new_dest_pos = gobj.cur_pos
						gobj.dest_pos = gobj.cur_pos
						gobj.target_enemy_id = -1
					}
				}
				gobj.cant_moving = !gobj.is_destination_reached() && gobj.next_pos == gobj.cur_pos
				data.aspr_map[gobj.id].update(mut game)

				if gobj.is_destination_reached() {
					gobj.state = 'idle'
				}
				if data.gobj_hp_map[gobj.id] <= 0 {
					gobj.state = 'died'
				}
			}
			'idle' {
				data.aspr_map[gobj.id].texture_name = if data.gobj_map[gobj.id].team == 0 {
					if data.gobj_map[gobj.id].gobj_type == 'sword man' {
						'warrior_idle'
					} else if data.gobj_map[gobj.id].gobj_type == 'archer' {
						'archer_idle'
					} else if data.gobj_map[gobj.id].gobj_type == 'cleric' {
						'cleric_idle'
					} else {
						'character1_walking'
					}
				} else {
					'zombie_walking'
				}
				gobj_scan_nearest_gobj(mut gobj, mut game)
				gobj_right_mouse_pressed_change_destination_to_mouse_pos(mut gobj, mut
					game)
				gobj_to_incamview(mut gobj, mut game)
				gobj_selection(mut gobj, mut game)
				
				if gobj.target_enemy_id != -1 && gobj.is_next_pos_reached () {
					epos := data.gobj_map[gobj.target_enemy_id].cur_pos
					if mystructs.is_two_pos_in_distance(gobj.cur_pos, epos, gobj.attack_range) {
						gobj.new_dest_pos = gobj.cur_pos
						gobj.dest_pos = gobj.cur_pos
						gobj.visited_cells.clear()
						gobj.state = 'attacking target'
					} else {
						e_destpos := data.gobj_map[gobj.target_enemy_id].dest_pos
						gobj.new_dest_pos = e_destpos
						gobj.dest_pos = e_destpos
					}
				} else {
					if gobj.nearest_enemy_id != -1 {
						gobj.target_enemy_id = gobj.nearest_enemy_id
						epos := data.gobj_map[gobj.target_enemy_id].cur_pos
						if mystructs.is_two_pos_in_distance(gobj.cur_pos, epos, gobj.attack_range) {
							gobj.new_dest_pos = gobj.cur_pos
							gobj.dest_pos = gobj.cur_pos
							gobj.visited_cells.clear()
							gobj.state = 'attacking target'
						} else {
							// e_destpos := data.gobj_map[gobj.target_enemy_id].dest_pos
							e_destpos := data.gobj_map[gobj.target_enemy_id].next_pos
							gobj.new_dest_pos = e_destpos
							gobj.dest_pos = e_destpos
						}
					}
				}
				
				if gobj.lost_hp_ally_id != -1 && gobj.gobj_type == 'cleric' && gobj.is_next_pos_reached() {
					epos := data.gobj_map[gobj.lost_hp_ally_id].cur_pos
					if mystructs.is_two_pos_in_distance(gobj.cur_pos, epos, gobj.attack_range) {
						gobj.new_dest_pos = gobj.cur_pos
						gobj.dest_pos = gobj.cur_pos
						gobj.visited_cells.clear()
						gobj.state = 'healing target'
					} else {
						e_destpos := data.gobj_map[gobj.lost_hp_ally_id].next_pos
						gobj.new_dest_pos = e_destpos
						gobj.dest_pos = e_destpos
					}
				}
				
				gobj.moving_to_destination(mut game)
				gobj.moving_facing(mut game)
				if !gobj.cant_moving {
					gobj.cant_moving_time = 0.0
				} else {
					gobj.cant_moving_time += game.delta_time
					if gobj.cant_moving_time >= gobj.max_cant_moving_time {
						gobj.cant_moving_time = 0
						gobj.new_dest_pos = gobj.cur_pos
						gobj.dest_pos = gobj.cur_pos
					}
				}
				gobj.cant_moving = !gobj.is_destination_reached() && gobj.next_pos == gobj.cur_pos
				data.aspr_map[gobj.id].update(mut game)

				if !gobj.is_destination_reached() {
					gobj.state = 'moving'
				}
				if data.gobj_hp_map[gobj.id] <= 0 {
					gobj.state = 'died'
				}
			}
			'attacking target' {
				data.aspr_map[gobj.id].texture_name = if data.gobj_map[gobj.id].team == 0 {
					if data.gobj_map[gobj.id].gobj_type == 'sword man' {
						'warrior_attacking'
					} else if data.gobj_map[gobj.id].gobj_type == 'archer' {
						'archer_attacking'
					} else if data.gobj_map[gobj.id].gobj_type == 'cleric' {
						'cleric_attacking'
					} else {
						'character_walking'
					}
				} else {
					'zombie_attacking'
				}
				gobj.rereg_next_cell_to_cur_cell(mut game)
				gobj_scan_nearest_gobj(mut gobj, mut game)
				gobj_right_mouse_pressed_change_destination_to_mouse_pos(mut gobj, mut
					game)
				gobj_to_incamview(mut gobj, mut game)
				gobj_selection(mut gobj, mut game)
				gobj.moving_to_destination(mut game)
				if gobj.target_enemy_id != -1 {
					if data.gobj_hp_map[gobj.target_enemy_id] <= 0 {
						if gobj.nearest_enemy_id == gobj.target_enemy_id {
							gobj.nearest_enemy_id = -1
						}
						gobj.target_enemy_id = -1
						gobj.state = 'idle'
					}
				}
				if gobj.target_enemy_id != -1 {
					gobj.facing_to_target_enemy_id(mut game)
					epos := data.gobj_map[gobj.target_enemy_id].cur_pos
					in_attack_range := mystructs.is_two_pos_in_distance(gobj.cur_pos, epos, gobj.attack_range)
					if !in_attack_range {
						gobj.state = 'idle'
					} else {
						if gobj.attack_time == 0 && data.aspr_map[gobj.id].frame_idx >= 2 {
							if gobj.in_cam_view {
								if gobj.team == 0 {
									if data.sound_count['sword1'] < 1 {
										if !r.is_sound_playing(data.audio_map['sword1']) {
											if gobj.gobj_type == 'sword man' {
												r.play_sound(data.audio_map['sword1'])
											} else if gobj.gobj_type == 'archer' {
												r.play_sound(data.audio_map['arrow_impact'])
											}
											data.sound_count['sword1'] += 1
										}
									}
									if gobj.gobj_type == 'archer' {
										game.data.arrowfx_list << mystructs.create_arrow_fx(epos, gobj.cur_pos, 5.0, 'arrow_fx', 'arrow_fx')
									} else if gobj.gobj_type == 'cleric' {
										game.data.arrowfx_list << mystructs.create_arrow_fx(epos, gobj.cur_pos, 5.0, 'energy_ball', 'energy_ball')
									}
								} else if gobj.team == 1 {
									if data.sound_count['attack1'] < 1 {
										if !r.is_sound_playing(data.audio_map['attack1']) {
											r.play_sound(data.audio_map['attack1'])
											data.sound_count['attack1'] += 1
										}
									}
								}
							}
							data.gobj_hp_map[gobj.target_enemy_id] -= 5
							if data.gobj_hp_map[gobj.target_enemy_id] < 0 {
								data.gobj_hp_map[gobj.target_enemy_id] = 0
							}
							gobj.attack_time = gobj.max_attack_time
						}
					}
				}
				if gobj.target_enemy_id == -1 {
					gobj.state = "idle"
				}
				data.aspr_map[gobj.id].update(mut game)
				if !gobj.is_destination_reached() {
					gobj.state = 'moving'
				}
				if data.gobj_hp_map[gobj.id] <= 0 {
					gobj.state = 'died'
				}
			}
			'healing target' {
				data.aspr_map[gobj.id].texture_name = if data.gobj_map[gobj.id].team == 0 {
					if data.gobj_map[gobj.id].gobj_type == 'sword man' {
						'warrior_attacking'
					} else if data.gobj_map[gobj.id].gobj_type == 'archer' {
						'archer_attacking'
					} else if data.gobj_map[gobj.id].gobj_type == 'cleric' {
						'cleric_attacking'
					} else {
						'character_walking'
					}
				} else {
					'zombie_attacking'
				}
				gobj.rereg_next_cell_to_cur_cell(mut game)
				gobj_scan_nearest_gobj(mut gobj, mut game)
				gobj_right_mouse_pressed_change_destination_to_mouse_pos(mut gobj, mut
					game)
				gobj_to_incamview(mut gobj, mut game)
				gobj_selection(mut gobj, mut game)
				gobj.moving_to_destination(mut game)
				if gobj.lost_hp_ally_id != -1 {
					if data.gobj_hp_map[gobj.lost_hp_ally_id] <= 0 {
						if gobj.nearest_enemy_id == gobj.lost_hp_ally_id {
							gobj.nearest_enemy_id = -1
						}
						gobj.lost_hp_ally_id = -1
						gobj.state = 'idle'
					}
				}
				if gobj.lost_hp_ally_id != -1 {
					gobj.facing_to_lost_hp_ally_id(mut game)
					epos := data.gobj_map[gobj.lost_hp_ally_id].cur_pos
					in_attack_range := mystructs.is_two_pos_in_distance(gobj.cur_pos, epos, gobj.attack_range)
					if !in_attack_range {
						gobj.state = 'idle'
					} else {
						if gobj.attack_time == 0 && data.aspr_map[gobj.id].frame_idx >= 2 {
							if gobj.in_cam_view {
								if gobj.team == 0 {
									if data.sound_count['sword1'] < 1 {
										if !r.is_sound_playing(data.audio_map['sword1']) {
											if gobj.gobj_type == 'sword man' {
												r.play_sound(data.audio_map['sword1'])
											} else if gobj.gobj_type == 'archer' {
												r.play_sound(data.audio_map['arrow_impact'])
											}
											data.sound_count['sword1'] += 1
										}
									}
									if gobj.gobj_type == 'cleric' {
										game.data.arrowfx_list << mystructs.create_arrow_fx(epos, gobj.cur_pos, 5.0, 'energy_ball', 'energy_ball')
									}
								} else if gobj.team == 1 {
									if data.sound_count['attack1'] < 1 {
										if !r.is_sound_playing(data.audio_map['attack1']) {
											r.play_sound(data.audio_map['attack1'])
											data.sound_count['attack1'] += 1
										}
									}
								}
							}
							data.gobj_hp_map[gobj.lost_hp_ally_id] += 2
							if data.gobj_hp_map[gobj.lost_hp_ally_id] >= data.gobj_maxhp_map[gobj.lost_hp_ally_id] {
								data.gobj_hp_map[gobj.lost_hp_ally_id] = data.gobj_maxhp_map[gobj.lost_hp_ally_id]
							}
							gobj.attack_time = gobj.max_attack_time
						}
					}
				}
				if gobj.lost_hp_ally_id == -1 {
					gobj.state = "idle"
				}
				data.aspr_map[gobj.id].update(mut game)
				if !gobj.is_destination_reached() {
					gobj.state = 'moving'
				}
				if data.gobj_hp_map[gobj.id] <= 0 {
					gobj.state = 'died'
				}
			}
			'died' {
				if _ := data.gobj_died_map[gobj.id] {} else {
					data.gobj_died_map[gobj.id] = true
				}
			}
			else {}
		}
		if _ := game.data.gobj_map[gobj.nearest_enemy_id] {
			if game.data.gobj_hp_map[gobj.nearest_enemy_id] <= 0 {
				gobj.nearest_enemy_id = -1
			}
		} else {
			gobj.nearest_enemy_id = -1
		}
		if _ := game.data.gobj_map[gobj.nearest_ally_id] {
			if game.data.gobj_hp_map[gobj.nearest_ally_id] <= 0 {
				gobj.nearest_ally_id = -1
			}
		} else {
			gobj.nearest_ally_id = -1
		}
		if _ := game.data.gobj_map[gobj.lost_hp_ally_id] {
			if game.data.gobj_hp_map[gobj.lost_hp_ally_id] == game.data.gobj_maxhp_map[gobj.lost_hp_ally_id] {
				gobj.lost_hp_ally_id = -1
			}
		} else {
			gobj.lost_hp_ally_id = -1
		}
	}
	data.onscreen_gobj_list.sort(a.cur_pos.y < b.cur_pos.y)
}

fn gobj_selection(mut gobj mystructs.Gobj, mut game mystructs.Game) {
	mut data := &game.data
	if !(r.is_mouse_button_released(0) && gobj.player_control) {
		return
	}
	if game.click_count >= 2 {
		return
	}
	if data.minimap.is_click_in(game) {
		return
	}
	if data.select_area.renw > 0.5 && data.select_area.renh > 0.5 {
		in_select_area := data.select_area.is_pos_in(gobj.cur_pos)
		if in_select_area {
			gobj.player_selected = true
		} else {
			if !r.is_key_down(r.key_left_shift) {
				gobj.player_selected = false
			}
		}
		return
	}

	if data.minimap.is_mouse_in {
		return
	}
	selected :=
		mystructs.abs(game.mouse_pos.x - gobj.cur_pos.x) <= game.grid.cell_size / 2
		&& mystructs.abs(game.mouse_pos.y - gobj.cur_pos.y) <= game.grid.cell_size / 2
		&& !data.minimap.is_mouse_in
	if selected {
		gobj.player_selected = true
	} else {
		if !r.is_key_down(r.key_left_shift) {
			gobj.player_selected = false
		}
	}
	if gobj.player_selected {
		r.play_sound(data.audio_map['bipselect'])
	}
}

fn gobj_right_mouse_pressed_change_destination_to_mouse_pos(mut gobj mystructs.Gobj, mut game mystructs.Game) {
	if r.is_mouse_button_pressed(1) {
		mut data := &game.data
		if gobj.player_control && gobj.player_selected {
			mut cell_id_at_mouse := game.grid.pixelpos_to_id(game.mouse_pos)
			gobj.target_enemy_id = -1
			gobj.nearest_enemy_id = -1
			gobj.lost_hp_ally_id = -1
			if tgeid := data.cell_gobj_map[cell_id_at_mouse] {
				tgteam := data.gobj_map[tgeid].team
				if tgteam != gobj.team {
					gobj.target_enemy_id = tgeid
				} else {
					if data.gobj_hp_map[tgeid] < data.gobj_maxhp_map[tgeid] {
						gobj.lost_hp_ally_id = tgeid
					}
				}
			}
			if data.minimap.is_mouse_in {
				global_mouse_pos := data.minimap.gui_pos_to_global(data.cursor.cur_pos)
				cell_id_at_mouse = game.grid.pixelpos_to_id(global_mouse_pos)
			}
			mouse_center_pos := game.grid.id_to_pixelpos(cell_id_at_mouse, true)
			gobj.new_dest_pos = mouse_center_pos
		}
	}
}

fn gobj_scan_nearest_gobj(mut gobj mystructs.Gobj, mut game mystructs.Game) {
	mut data := &game.data
	for idx in 0 .. mystructs.nsat {
		if idx < mystructs.nsat / 2 {
			gobj.scan_vec_list[idx] = data.scan_vec_list[idx].rotate(data.scan_rot).multiply(data.scan_radius * (
				1 + data.scan_level))
		} else {
			gobj.scan_vec_list[idx] = data.scan_vec_list[idx].rotate(data.scan_rot).multiply(data.scan_radius * (
				data.scan_max_level + 1) - data.scan_radius * (1 + data.scan_level))
		}
		pos_check_nearest_enemy := gobj.cur_pos.plus(gobj.scan_vec_list[idx])
		cell_check := game.grid.pixelpos_to_id(pos_check_nearest_enemy)
		if near_gobj_id := data.cell_gobj_map[cell_check] {
			if data.gobj_map[near_gobj_id].team != gobj.team
				&& data.gobj_hp_map[near_gobj_id] > 0 {
				near_gobj_pos := data.gobj_map[near_gobj_id].cur_pos
				if !game.grid.is_pos_in_grid(near_gobj_pos) {
					continue
				}
				dx := near_gobj_pos.x - gobj.cur_pos.x
				dy := near_gobj_pos.y - gobj.cur_pos.y
				dist := dx * dx + dy * dy
				if gobj.nearest_enemy_id == -1 {
					gobj.nearest_enemy_id = near_gobj_id
				} else {
					nearest_gobj_pos := data.gobj_map[gobj.nearest_enemy_id].cur_pos
					dx0 := nearest_gobj_pos.x - gobj.cur_pos.x
					dy0 := nearest_gobj_pos.y - gobj.cur_pos.y
					dist0 := dx0 * dx0 + dy0 * dy0
					if dist < dist0 {
						gobj.nearest_enemy_id = near_gobj_id
					}
				}
			} else if data.gobj_map[near_gobj_id].team == gobj.team
				&& data.gobj_hp_map[near_gobj_id] > 0 && near_gobj_id != gobj.id {
				near_gobj_pos := data.gobj_map[near_gobj_id].cur_pos
				if !game.grid.is_pos_in_grid(near_gobj_pos) {
					continue
				}
				dx := near_gobj_pos.x - gobj.cur_pos.x
				dy := near_gobj_pos.y - gobj.cur_pos.y
				dist := dx * dx + dy * dy
				if gobj.nearest_ally_id == -1 {
					gobj.nearest_ally_id = near_gobj_id
				} else {
					nearest_gobj_pos := data.gobj_map[gobj.nearest_ally_id].cur_pos
					dx0 := nearest_gobj_pos.x - gobj.cur_pos.x
					dy0 := nearest_gobj_pos.y - gobj.cur_pos.y
					dist0 := dx0 * dx0 + dy0 * dy0
					if dist < dist0 {
						gobj.nearest_ally_id = near_gobj_id
					}
				}
				if gobj.lost_hp_ally_id == -1 {
					if data.gobj_hp_map[near_gobj_id] < data.gobj_maxhp_map[near_gobj_id] {
						gobj.lost_hp_ally_id = near_gobj_id
					}
				}
			}
		}
	}
}

fn arrow_fx_process(mut game mystructs.Game)  {
	for arrow_idx, mut arrow_fx in game.data.arrowfx_list {
		arrow_fx.aspr.update(mut game)
		if arrow_fx.is_destination_reached() {
			game.data.arrowfx_list.delete(arrow_idx)
		} else {
			arrow_fx.moving_to_destination(game.delta_time)
		}
	}
}

fn update_cursor(mut game mystructs.Game) {
	if gobj_id_at_mouse := game.data.cell_gobj_map[game.mouse_cell] {
		if game.data.gobj_map[gobj_id_at_mouse].team == 0 {
			if game.data.cursor.aspr.current_action != 'cursor_select_unit' {
				game.data.cursor.aspr.play('cursor_select_unit', 0, 0.5)
			}
		} else {
			if game.data.cursor.aspr.current_action != 'cursor_select_target' {
				game.data.cursor.aspr.play('cursor_select_target', 0, 0.1)
			}
		}
	} else {
		if game.data.cursor.aspr.current_action != 'cursor_normal' {
			game.data.cursor.aspr.play('cursor_normal', 0, 0.1)
		}
	}
	game.data.cursor.aspr.update(mut game)
}

/// MAIN UPDATE
pub fn update(mut game mystructs.Game) {
	if r.is_mouse_button_pressed(0) {
		on_left_mouse_pressed(mut game)
	}
	if r.is_mouse_button_pressed(1) {
		on_right_mouse_pressed(mut game)
	}
	if r.is_mouse_button_released(0) {
		on_left_mouse_released(mut game)
	}
	if r.is_mouse_button_down(0) {
		on_left_mouse_down(mut game)
	}
	if r.is_key_pressed(r.key_home) {
		game.data.ta.play(
			'Thạch Sanh: là tên một truyện thơ Nôm Việt Nam, viết theo thể lục bát ra đời vào cuối thế kỉ 18, đầu thế kỉ 19 do một tác giả khuyết danh và được người dân kể lại dưới nhiều dị bản. Thạch Sanh đã trở thành hình tượng điển hình cho người tốt, hào hiệp, thật thà còn Lí Thông là hình tượng người xấu, gian xảo, tham lam trong văn hóa Việt Nam. Tổng quan: Hiện có ít nhất 3 dị bản truyện thơ Thạch Sanh, đều bằng thể lục bát, nhưng trình độ nghệ thuật không đồng đều. Bản có lời văn chải chuốt nhất và được lưu hành rộng rãi nhất, gồm 1.812 câu lục bát và 2 bài thơ đề từ (một bằng chữ Hán, một bằng chữ Nôm). Bản in xưa nhất hiện còn được xuất bản vào năm Duy Tân thứ 6 (1912). Nội dung truyện thơ Thạch Sanh và truyện cổ tích có cùng tên khá giống nhau, nhưng truyện thơ ra đời muộn hơn. Truyện Thạch Sanh thuộc loại truyện cổ tích thần kỳ, nằm trong một kiểu truyện rất phổ biến ở Đông Nam Á, đó là kiểu "Dũng sĩ diệt đại bàng (hay chằn tinh) cứu người đẹp". Có thể kể đến những truyện như Xin Xay ở Lào; Xanxênky, Thạch Sanh chém chằn ở Campuchia; Ramayana ở Ấn Độ; Cô gái tóc thơm, Hai ông vua giao chiến của người Thái... Ở Việt Nam, kiểu truyện này còn xuất hiện trong các câu chuyện cổ, như truyện Chàng Rôk của người Kor; Rok và Xét của người Ba Na; Đơm Tơrít của người Cơ Tu, Azit đánh bại đại bàng của người Gia Rai...Đối với người Kinh, đề tài này không những xuất hiện trong truyện cổ tích, truyện thơ mà nó còn được dàn dựng thành phim, thành kịch; và còn xuất hiện trong tranh Đông Hồ.',
			// 'kỳ lạ thiệt, ngủ li bỳ luôn!'
			0.5,
			game
		)
	}
	if game.click_count > 0 {
		game.click_time += game.delta_time
	}
	
	key_pressed := r.get_key_pressed()
	if key_pressed in mystructs.number_keys {
		game.debug = key_pressed.str()
		if r.is_key_down(r.key_left_control) {
			for _, mut gobj in game.data.gobj_map {
				if !gobj.player_selected {
					continue
				}
				for group_id, _ in game.data.gobj_group_map {
					if _ := game.data.gobj_group_map[group_id][gobj.id] {
						game.data.gobj_group_map[group_id].delete(gobj.id)
					}
				}
				gobj.group = key_pressed - 48
				game.data.gobj_group_map[key_pressed - 48][gobj.id] = true
			}
		} else {
			for _, mut gobj in game.data.gobj_map {
				if _ := game.data.gobj_group_map[key_pressed - 48][gobj.id] {
					gobj.player_selected = true
				} else {
					if !r.is_key_down(r.key_left_shift) {
						gobj.player_selected = false
					}
				}
			}
		}
	}

	sat_process(mut game)
	game.data.aspr_test.update(mut game)
	game.data.circle_animation.update(mut game)
	update_cursor(mut game)
	gobjs_process(mut game)
	arrow_fx_process(mut game)
	game.data.ta.update(game.delta_time)
}

fn gobj_to_incamview(mut gobj mystructs.Gobj, mut game mystructs.Game) {
	gobj.in_cam_view = game.cam.is_pos_in_camera_view(gobj.cur_pos, r.get_screen_width() +
		int(game.grid.cell_size), r.get_screen_height() + int(game.grid.cell_size))
	if gobj.in_cam_view {
		game.data.onscreen_gobj_list << mystructs.InCamViewObj{
			id: gobj.id
			cur_pos: gobj.cur_pos
		}
	}
}