module mystructs

import math
import rand
import rand.seed
import os
import irishgreencitrus.raylibv as r



pub const nsat = 4
pub const vec_up = Vec2{0, -1}
pub const vec_down = Vec2{0, 1}
pub const vec_left = Vec2{-1, 0}
pub const vec_right = Vec2{1, 0}
pub const vec_topleft = Vec2{-1, -1}
pub const vec_topright = Vec2{1, -1}
pub const vec_downleft = Vec2{-1, 1}
pub const vec_downright = Vec2{1, 1}
pub const number_keys = []int{len: 10, cap: 10, init: index + 48}

///////////////////////////////////////////////////////////////
// STRUCT VEC2
pub struct Vec2 {
pub mut:
	x f32
	y f32
}

pub fn (vec Vec2) length(optimize bool) f32 {
	if optimize {
		return fastinvsqrt(vec.x * vec.x + vec.y * vec.y)
	}
	return f32(math.sqrt(vec.x * vec.x + vec.y * vec.y))
}

pub fn (vec Vec2) minus(vec2 Vec2) Vec2 {
	return Vec2{
		x: vec.x - vec2.x
		y: vec.y - vec2.y
	}
}

pub fn (vec Vec2) plus(vec2 Vec2) Vec2 {
	return Vec2{
		x: vec.x + vec2.x
		y: vec.y + vec2.y
	}
}

pub fn (vec Vec2) multiply(n f32) Vec2 {
	return Vec2{
		x: vec.x * n
		y: vec.y * n
	}
}

pub fn (vec Vec2) devide(n f32) Vec2 {
	return Vec2{
		x: vec.x / n
		y: vec.y / n
	}
}

pub fn (vec Vec2) normalize(optimize bool) Vec2 {
	distance := vec.length(optimize)
	return vec.devide(distance)
}

pub fn (vec Vec2) rotate(angle f32) Vec2 {
	return Vec2{
		x: f32(vec.x * math.cos(angle) - vec.y * math.sin(angle))
		y: f32(vec.x * math.sin(angle) + vec.y * math.cos(angle))
	}
}

pub fn (vec Vec2) get_angle_radians() f32 {
	return f32(math.atan2(f64(vec.y), f64(vec.x)))
}

///////////////////////////////////////////////////////////////
/// STRUCT GRID
pub struct Grid {
pub mut:
	pos            Vec2
	draw_pos       Vec2
	cols           int = 100
	rows           int = 100
	cell_size      f32 = 32
	width          f32 = 32.0 * 100
	height         f32 = 32.0 * 100
	cross_dist     f32 = f32(math.sqrt(16 * 16 + 16 * 16))
	steps_map      map[int]map[int]int
	walkable_map   map[int]bool
	neighbors_data map[int][]int
	ch1            chan DjmapRs
	color          r.Color
}

pub fn (grid Grid) gridpos_to_id(gridpos Vec2) int {
	return int(gridpos.y * grid.cols + gridpos.x)
}

pub fn (grid Grid) id_to_gridpos(id int) Vec2 {
	row := id / grid.cols

	return Vec2{
		x: id - row * grid.cols
		y: row
	}
}

pub fn (grid Grid) gridpos_to_pixelpos(gridpos Vec2, center bool) Vec2 {
	if center {
		return Vec2{
			x: gridpos.x * grid.cell_size + grid.cell_size / 2 + grid.pos.x
			y: gridpos.y * grid.cell_size + grid.cell_size / 2 + grid.pos.y
		}
	}

	return Vec2{
		x: gridpos.x * grid.cell_size + grid.pos.x
		y: gridpos.y * grid.cell_size + grid.pos.y
	}
}

pub fn (grid Grid) pixelpos_to_gridpos(pp Vec2) Vec2 {
	return Vec2{
		x: int((pp.x - grid.pos.x) / grid.cell_size)
		y: int((pp.y - grid.pos.y) / grid.cell_size)
	}
}

pub fn (grid Grid) pixelpos_to_id(pp Vec2) int {
	return grid.gridpos_to_id(grid.pixelpos_to_gridpos(pp))
}

pub fn (grid Grid) id_to_pixelpos(id int, center bool) Vec2 {
	return grid.gridpos_to_pixelpos(grid.id_to_gridpos(id), center)
}

pub fn (grid Grid) is_pos_in_grid(pos Vec2) bool {
	grpos := grid.pixelpos_to_gridpos(pos)
	if grpos.x > grid.cols || grpos.x < 0 || grpos.y < 0 || grpos.y > grid.rows {
		return false
	}
	return true
}

pub fn (grid Grid) calc_steps(cell1 int, cell2 int) int {
	gp1 := grid.id_to_gridpos(cell1)
	gp2 := grid.id_to_gridpos(cell2)
	return math.abs(int(gp2.x - gp1.x)) + math.abs(int(gp2.y - gp1.y))
}

pub fn (grid Grid) id_get_idneighbors(id int, cross bool) []int {
	gridpos := grid.id_to_gridpos(id)
	mut rs := []int{}
	mut nbup := false
	mut nbdown := false
	mut nbleft := false
	mut nbright := false

	mut next := gridpos.plus(mystructs.vec_up)
	mut cond_row := next.y >= 0 && next.y < grid.rows
	mut cond_col := next.x >= 0 && next.x < grid.cols
	mut nextid := grid.gridpos_to_id(next)
	mut walkable := grid.walkable_map[nextid]
	if cond_row && walkable {
		rs << nextid
		nbup = true
	}

	next = gridpos.plus(mystructs.vec_down)
	cond_row = next.y >= 0 && next.y < grid.rows
	nextid = grid.gridpos_to_id(next)
	walkable = grid.walkable_map[nextid]
	if cond_row && walkable {
		rs << nextid
		nbdown = true
	}

	next = gridpos.plus(mystructs.vec_left)
	cond_col = next.x >= 0 && next.x < grid.cols
	nextid = grid.gridpos_to_id(next)
	walkable = grid.walkable_map[nextid]
	if cond_col && walkable {
		rs << nextid
		nbleft = true
	}

	next = gridpos.plus(mystructs.vec_right)
	cond_col = next.x >= 0 && next.x < grid.cols
	nextid = grid.gridpos_to_id(next)
	walkable = grid.walkable_map[nextid]
	if cond_col && walkable {
		rs << nextid
		nbright = true
	}

	if cross {
		next = gridpos.plus(mystructs.vec_topleft)
		cond_row = next.y >= 0 && next.y < grid.rows
		cond_col = next.x >= 0 && next.x < grid.cols
		nextid = grid.gridpos_to_id(next)
		walkable = grid.walkable_map[nextid]
		if cond_row && cond_col && walkable && nbup && nbleft {
			rs << nextid
		}

		next = gridpos.plus(mystructs.vec_topright)
		cond_row = next.y >= 0 && next.y < grid.rows
		cond_col = next.x >= 0 && next.x < grid.cols
		nextid = grid.gridpos_to_id(next)
		walkable = grid.walkable_map[nextid]
		if cond_row && cond_col && walkable && nbup && nbright {
			rs << nextid
		}

		next = gridpos.plus(mystructs.vec_downleft)
		cond_row = next.y >= 0 && next.y < grid.rows
		cond_col = next.x >= 0 && next.x < grid.cols
		nextid = grid.gridpos_to_id(next)
		walkable = grid.walkable_map[nextid]
		if cond_row && cond_col && walkable && nbdown && nbleft {
			rs << nextid
		}

		next = gridpos.plus(mystructs.vec_downright)
		cond_row = next.y >= 0 && next.y < grid.rows
		cond_col = next.x >= 0 && next.x < grid.cols
		nextid = grid.gridpos_to_id(next)
		walkable = grid.walkable_map[nextid]
		if cond_row && cond_col && walkable && nbdown && nbright {
			rs << nextid
		}
	}
	return rs.reverse()
}

pub fn (grid Grid) create_steps_map(dest_id int, cross bool) DjmapRs {
	mut processed_map := {
		dest_id: 0
	}
	// mut nextcell_map := {
	// 	dest_id: dest_id
	// }
	mut open := {
		dest_id: 0
	}
	for open.len > 0 {
		mut new_open := map[int]int{}
		for id, cost in open {
			for nbid in grid.neighbors_data[id] {
				if _ := processed_map[nbid] {
					continue
				}
				processed_map[nbid] = cost + 1
				// nextcell_map[nbid] = id
				new_open[nbid] = cost + 1
			}
		}
		open = new_open.clone()
	}
	return DjmapRs{
		id: dest_id
		rs: processed_map
		// nextcell_map: nextcell_map
	}
}

pub fn (mut grid Grid) update_draw_pos(cam_pos Vec2) {
	grid.draw_pos = grid.pos.minus(cam_pos)
}

pub fn (grid Grid) get_walkable_cells() []int {
	mut rs := []int{}
	for id, walkable in grid.walkable_map {
		if walkable {
			rs << id
		}
	}
	return rs
}

pub fn (grid Grid) get_cells_around_in_nround(cell_to int, cur_cell_map map[int]int, cross bool, nround int) []int {
	// if grid.cells[cell_to].walkable {
	// 	return [cell_to]
	// }

	mut costs := {
		cell_to: 0
	}
	mut opentable := [cell_to]
	mut step := 1
	mut rs := []int{}

	for opentable.len != 0 {
		mut new_opentable := []int{}

		for cell in opentable {
			neighbors := grid.neighbors_data[cell]

			for id_n in neighbors {
				if _ := costs[id_n] {
				} else {
					costs[id_n] = step
					new_opentable << id_n
				}
			}

			for cell_id in new_opentable {
				mut dk := true
				if _ := cur_cell_map[cell_id] {
					dk = false
				}
				if grid.walkable_map[cell_id] && dk {
					rs << cell_id
				}
			}
		}

		opentable = new_opentable.clone()
		step += 1
		if step > nround {
			return rs
		}
	}

	return []int{}
}
///////////////////////////////////////////////////////////////
/// STRUCT STEPS_MAP_RESULT
pub struct DjmapRs {
pub mut:
	id           int
	rs           map[int]int
	// nextcell_map map[int]int
}
///////////////////////////////////////////////////////////////
/// STRUCT CAMERA
pub struct Camera {
pub mut:
	pos Vec2
	vel Vec2
}

pub fn (cam Camera) is_pos_in_camera_view(pos Vec2, window_width int, window_height int) bool {
	return pos.x >= cam.pos.x && pos.x <= cam.pos.x + window_width && pos.y >= cam.pos.y
		&& pos.y <= cam.pos.y + window_height
}

pub fn (mut cam Camera) update(mut game Game) {
	mut data := &game.data
	// update pos
	cam.pos = cam.pos.plus(cam.vel)
	if cam.pos.x < 0 {
		cam.pos.x = 0
	} else if cam.pos.x > game.grid.width - r.get_screen_width() {
		cam.pos.x = game.grid.width - r.get_screen_width()
	}
	if cam.pos.y < 0 {
		cam.pos.y = 0
	} else if cam.pos.y > game.grid.height - r.get_screen_height() + data.minimap.height {
		cam.pos.y = game.grid.height - r.get_screen_height() + data.minimap.height
	}

	camspd := r.get_frame_time() * 100.0 * data.margin
	if data.cursor.cur_pos.x <= data.margin {
		cam.vel.x = -camspd
	} else if data.cursor.cur_pos.x >= r.get_screen_width() - data.margin {
		cam.vel.x = camspd
	} else {
		cam.vel.x = 0
	}
	if data.cursor.cur_pos.y <= data.margin {
		cam.vel.y = -camspd
	} else if data.cursor.cur_pos.y >= r.get_screen_height() - data.margin {
		cam.vel.y = camspd
	} else {
		cam.vel.y = 0
	}
}

///////////////////////////////////////////////////////////////
/// STRUCT GOBJ
pub struct Gobj {
pub mut:
	id                  int
	cur_pos             Vec2
	next_pos            Vec2
	dest_pos            Vec2
	cur_cell            int
	spd                 f32 = 1.0
	vel                 Vec2
	vel1                Vec2
	vel2                Vec2
	vel3                Vec2
	vec_length_optimize bool = true
	next_cell           int  = -1
	new_dest_pos        Vec2
	state               string = 'normal'
	player_control      bool   = true
	player_selected     bool
	visited_cells       []int
	team                int
	see_range           f32 = 64.0
	attack_range        f32 = 32.0
	attack_time f32
	max_attack_time f32 = 0.2

	scan_vec_list    []Vec2 = []Vec2{len: mystructs.nsat, cap: mystructs.nsat}
	died             bool
	nearest_enemy_id int = -1
	nearest_ally_id int = -1
	lost_hp_ally_id int = -1

	facing               Vec2 = Vec2{0.0, 1.0}
	in_cam_view          bool
	target_enemy_id      int  = -1
	attack_in_see_range  bool = true
	cant_moving          bool
	cant_moving_time     f32
	max_cant_moving_time f32    = 0.2
	gobj_type            string = 'archer'
	group int = -1
}

pub fn (mut gobj Gobj) set_dest_pos(dest_pos Vec2) {
	gobj.dest_pos = dest_pos
}

pub fn (gobj Gobj) find_next_cell(game Game) int {
	cur_cell := game.grid.pixelpos_to_id(gobj.cur_pos)
	mut rs := cur_cell
	dest_cell := game.grid.pixelpos_to_id(gobj.dest_pos)
	if _ := game.grid.neighbors_data[cur_cell] {
		if _ := game.grid.steps_map[dest_cell] {
			mut best_cost := game.grid.steps_map[dest_cell][cur_cell]
			mut best_steps := game.grid.calc_steps(cur_cell, dest_cell)
			for neighbor in game.grid.neighbors_data[cur_cell] {
				if nbid := game.data.nextcell_map[neighbor] {
					if nbid != gobj.id {
						continue
					}
				}
				if neighbor in gobj.visited_cells {
					continue
				}
				cost := game.grid.steps_map[dest_cell][neighbor]
				steps := game.grid.calc_steps(cur_cell, neighbor)
				if cost < best_cost {
					rs = neighbor
					best_cost = cost
				} else if cost == best_cost {
					if steps < best_steps {
						rs = neighbor
						best_cost = cost
						best_steps = steps
					}
				}
			}
		}
	}
	return rs
}

pub fn (gobj Gobj) simple_find_next_cell(game Game) int {
	ab := gobj.dest_pos.minus(gobj.cur_pos)
	mut min_dist := ab.x * ab.x + ab.y * ab.y
	mut rs := gobj.cur_cell
	if neighbors := game.grid.neighbors_data[gobj.cur_cell] {
		for nb in neighbors {
			if nb_gobjid := game.data.nextcell_map[nb] {
				if nb_gobjid != gobj.id {
					continue
				}
			}
			if nb in gobj.visited_cells {
				continue
			}
			nb_pos := game.grid.id_to_pixelpos(nb, true)
			nbab := gobj.dest_pos.minus(nb_pos)
			nb_dist := nbab.x * nbab.x + nbab.y * nbab.y
			if nb_dist < min_dist {
				rs = nb
				min_dist = nb_dist
			}
		}
	}
	return rs
}

pub fn (gobj Gobj) is_destination_reached() bool {
	return gobj.cur_pos == gobj.dest_pos
}

pub fn (gobj Gobj) is_next_pos_reached() bool {
	return gobj.cur_pos == gobj.next_pos
}

pub fn (gobj Gobj) is_pos_center_cell(game Game) bool {
	center_pos := game.grid.id_to_pixelpos(gobj.cur_cell, true)
	return gobj.cur_pos == center_pos
}

pub fn (gobj Gobj) calculate_vel1(grid Grid, delta_time f32) Vec2 {
	if gobj.is_destination_reached() {
		return Vec2{0, 0}
	}
	if gobj.is_next_pos_reached() {
		return Vec2{0, 0}
	}
	cn := gobj.next_pos.minus(gobj.cur_pos)
	cn_length := cn.length(gobj.vec_length_optimize)
	if cn_length <= gobj.spd * delta_time {
		return gobj.next_pos.minus(gobj.cur_pos)
	}
	cn_nor := cn.devide(cn_length)
	return cn_nor.multiply(gobj.spd * delta_time)
}

pub fn (mut gobj Gobj) is_target_enemy_in_attack_range(mut game Game) bool {
	if gobj.target_enemy_id == -1 {
		return false
	}
	tgpos := game.data.gobj_map[gobj.nearest_enemy_id].cur_pos
	return is_two_pos_in_distance(gobj.cur_pos, tgpos, gobj.attack_range)
}

pub fn (mut gobj Gobj) moving_facing(mut game Game) {
	if gobj.facing != game.data.aspr_facing_map[gobj.id] {
		match gobj.facing {
			mystructs.vec_down {
				game.data.aspr_map[gobj.id].play('moving down', 0, 0.1)
			}
			mystructs.vec_downleft {
				game.data.aspr_map[gobj.id].play('moving down left', 0, 0.1)
			}
			mystructs.vec_left {
				game.data.aspr_map[gobj.id].play('moving left', 0, 0.1)
			}
			mystructs.vec_topleft {
				game.data.aspr_map[gobj.id].play('moving up left', 0, 0.1)
			}
			mystructs.vec_up {
				game.data.aspr_map[gobj.id].play('moving up', 0, 0.1)
			}
			mystructs.vec_topright {
				game.data.aspr_map[gobj.id].play('moving up right', 0, 0.1)
			}
			mystructs.vec_right {
				game.data.aspr_map[gobj.id].play('moving right', 0, 0.1)
			}
			mystructs.vec_downright {
				game.data.aspr_map[gobj.id].play('moving down right', 0, 0.1)
			}
			else {}
		}
		game.data.aspr_facing_map[gobj.id] = gobj.facing
	}
}

pub fn (mut gobj Gobj) facing_to_target_enemy_id(mut game Game) {
	if gobj.target_enemy_id != -1 {
		tgpos := game.data.gobj_map[gobj.target_enemy_id].cur_pos
		dir := tgpos.minus(gobj.cur_pos)
		mut facing := Vec2{}
		if dir.x < 0 {
			facing.x = -1
		} else if dir.x > 0 {
			facing.x = 1
		}
		if dir.y < 0 {
			facing.y = -1
		} else if dir.y > 0 {
			facing.y = 1
		}
		gobj.facing = facing
	}
	if gobj.facing != game.data.aspr_facing_map[gobj.id] {
		match gobj.facing {
			mystructs.vec_down {
				game.data.aspr_map[gobj.id].play('moving down', 0, 0.1)
			}
			mystructs.vec_downleft {
				game.data.aspr_map[gobj.id].play('moving down left', 0, 0.1)
			}
			mystructs.vec_left {
				game.data.aspr_map[gobj.id].play('moving left', 0, 0.1)
			}
			mystructs.vec_topleft {
				game.data.aspr_map[gobj.id].play('moving up left', 0, 0.1)
			}
			mystructs.vec_up {
				game.data.aspr_map[gobj.id].play('moving up', 0, 0.1)
			}
			mystructs.vec_topright {
				game.data.aspr_map[gobj.id].play('moving up right', 0, 0.1)
			}
			mystructs.vec_right {
				game.data.aspr_map[gobj.id].play('moving right', 0, 0.1)
			}
			mystructs.vec_downright {
				game.data.aspr_map[gobj.id].play('moving down right', 0, 0.1)
			}
			else {}
		}
		game.data.aspr_facing_map[gobj.id] = gobj.facing
	}
}

pub fn (mut gobj Gobj) facing_to_nearest_enemy_id(mut game Game) {
	if gobj.nearest_enemy_id != -1 {
		tgpos := game.data.gobj_map[gobj.nearest_enemy_id].cur_pos
		dir := tgpos.minus(gobj.cur_pos)
		mut facing := Vec2{}
		if dir.x < 0 {
			facing.x = -1
		} else if dir.x > 0 {
			facing.x = 1
		}
		if dir.y < 0 {
			facing.y = -1
		} else if dir.y > 0 {
			facing.y = 1
		}
		gobj.facing = facing
	}
	if gobj.facing != game.data.aspr_facing_map[gobj.id] {
		match gobj.facing {
			mystructs.vec_down {
				game.data.aspr_map[gobj.id].play('moving down', 0, 0.1)
			}
			mystructs.vec_downleft {
				game.data.aspr_map[gobj.id].play('moving down left', 0, 0.1)
			}
			mystructs.vec_left {
				game.data.aspr_map[gobj.id].play('moving left', 0, 0.1)
			}
			mystructs.vec_topleft {
				game.data.aspr_map[gobj.id].play('moving up left', 0, 0.1)
			}
			mystructs.vec_up {
				game.data.aspr_map[gobj.id].play('moving up', 0, 0.1)
			}
			mystructs.vec_topright {
				game.data.aspr_map[gobj.id].play('moving up right', 0, 0.1)
			}
			mystructs.vec_right {
				game.data.aspr_map[gobj.id].play('moving right', 0, 0.1)
			}
			mystructs.vec_downright {
				game.data.aspr_map[gobj.id].play('moving down right', 0, 0.1)
			}
			else {}
		}
		game.data.aspr_facing_map[gobj.id] = gobj.facing
	}
}

pub fn (mut gobj Gobj) facing_to_lost_hp_ally_id(mut game Game) {
	if gobj.lost_hp_ally_id != -1 {
		tgpos := game.data.gobj_map[gobj.lost_hp_ally_id].cur_pos
		dir := tgpos.minus(gobj.cur_pos)
		mut facing := Vec2{}
		if dir.x < 0 {
			facing.x = -1
		} else if dir.x > 0 {
			facing.x = 1
		}
		if dir.y < 0 {
			facing.y = -1
		} else if dir.y > 0 {
			facing.y = 1
		}
		gobj.facing = facing
	}
	if gobj.facing != game.data.aspr_facing_map[gobj.id] {
		match gobj.facing {
			mystructs.vec_down {
				game.data.aspr_map[gobj.id].play('moving down', 0, 0.1)
			}
			mystructs.vec_downleft {
				game.data.aspr_map[gobj.id].play('moving down left', 0, 0.1)
			}
			mystructs.vec_left {
				game.data.aspr_map[gobj.id].play('moving left', 0, 0.1)
			}
			mystructs.vec_topleft {
				game.data.aspr_map[gobj.id].play('moving up left', 0, 0.1)
			}
			mystructs.vec_up {
				game.data.aspr_map[gobj.id].play('moving up', 0, 0.1)
			}
			mystructs.vec_topright {
				game.data.aspr_map[gobj.id].play('moving up right', 0, 0.1)
			}
			mystructs.vec_right {
				game.data.aspr_map[gobj.id].play('moving right', 0, 0.1)
			}
			mystructs.vec_downright {
				game.data.aspr_map[gobj.id].play('moving down right', 0, 0.1)
			}
			else {}
		}
		game.data.aspr_facing_map[gobj.id] = gobj.facing
	}
}

pub fn (mut gobj Gobj) reg_cur_cell(mut game Game) {
	if gobj.is_next_pos_reached() {
		cur_cell := gobj.cur_cell
		new_cur_cell := game.grid.pixelpos_to_id(gobj.cur_pos)
		if new_cur_cell != cur_cell {
			game.data.cell_gobj_map[new_cur_cell] = gobj.id
			if id := game.data.cell_gobj_map[cur_cell] {
				if id == gobj.id {
					game.data.cell_gobj_map.delete(cur_cell)
				}
			}
			gobj.cur_cell = new_cur_cell
		}
	}
}

pub fn (mut gobj Gobj) on_destination_changed(mut game Game) {
	if gobj.is_next_pos_reached() {
		if gobj.new_dest_pos != gobj.dest_pos {
			gobj.visited_cells.clear()
			gobj.dest_pos = gobj.new_dest_pos
		}
	}
}

pub fn (mut gobj Gobj) reg_next_cell(mut game Game) {
	if gobj.is_next_pos_reached() {
		next_cell := gobj.find_next_cell(game)
		old_next_cell := gobj.next_cell
		if old_next_cell != next_cell {
			gobj.next_pos = game.grid.id_to_pixelpos(next_cell, true)
			gobj.next_cell = next_cell
			gobj.visited_cells << old_next_cell
			old_next_gridpos := game.grid.id_to_gridpos(old_next_cell)
			next_gridpos := game.grid.id_to_gridpos(next_cell)
			gobj.facing = next_gridpos.minus(old_next_gridpos)
		}

		if _ := game.data.nextcell_map[old_next_cell] {
			game.data.nextcell_map.delete(old_next_cell)
		}
		game.data.nextcell_map[next_cell] = gobj.id
	}
}

pub fn (mut gobj Gobj) simple_reg_next_cell(mut game Game) {
	if gobj.is_next_pos_reached() {
		next_cell := gobj.simple_find_next_cell(game)
		old_next_cell := gobj.next_cell
		if old_next_cell != next_cell {
			gobj.next_pos = game.grid.id_to_pixelpos(next_cell, true)
			gobj.next_cell = next_cell
			gobj.visited_cells << old_next_cell
			old_next_gridpos := game.grid.id_to_gridpos(old_next_cell)
			next_gridpos := game.grid.id_to_gridpos(next_cell)
			gobj.facing = next_gridpos.minus(old_next_gridpos)
		}

		if _ := game.data.nextcell_map[old_next_cell] {
			game.data.nextcell_map.delete(old_next_cell)
		}
		game.data.nextcell_map[next_cell] = gobj.id
	}
}

pub fn (mut gobj Gobj) moving_to_destination(mut game Game) {
	if gobj.is_next_pos_reached() {
		// have new dest cell then change dest cell
		if gobj.new_dest_pos != gobj.dest_pos {
			gobj.visited_cells.clear()
			gobj.dest_pos = gobj.new_dest_pos
		}
		// reg cur cell
		cur_cell := gobj.cur_cell
		new_cur_cell := game.grid.pixelpos_to_id(gobj.cur_pos)
		if new_cur_cell != cur_cell {
			game.data.cell_gobj_map[new_cur_cell] = gobj.id
			if id := game.data.cell_gobj_map[cur_cell] {
				if id == gobj.id {
					game.data.cell_gobj_map.delete(cur_cell)
				}
			}
			gobj.cur_cell = new_cur_cell
		}
		// reg next cell
		next_cell := gobj.find_next_cell(game)
		old_next_cell := gobj.next_cell
		if old_next_cell != next_cell {
			gobj.next_pos = game.grid.id_to_pixelpos(next_cell, true)
			gobj.next_cell = next_cell
			gobj.visited_cells << old_next_cell
			old_next_gridpos := game.grid.id_to_gridpos(old_next_cell)
			next_gridpos := game.grid.id_to_gridpos(next_cell)
			gobj.facing = next_gridpos.minus(old_next_gridpos)
		}

		if _ := game.data.nextcell_map[old_next_cell] {
			game.data.nextcell_map.delete(old_next_cell)
		}
		game.data.nextcell_map[next_cell] = gobj.id
		//
	}
	gobj.vel1 = gobj.calculate_vel1(game.grid, game.delta_time)
	gobj.vel = gobj.vel1.plus(gobj.vel2).plus(gobj.vel3)
	gobj.cur_pos = gobj.cur_pos.plus(gobj.vel)
}

pub fn (mut gobj Gobj) simple_moving_to_destination(mut game Game) {
	gobj.on_destination_changed(mut game)
	gobj.reg_cur_cell(mut game)
	gobj.simple_reg_next_cell(mut game)
	gobj.vel1 = gobj.calculate_vel1(game.grid, game.delta_time)
	gobj.vel = gobj.vel1.plus(gobj.vel2).plus(gobj.vel3)
	gobj.cur_pos = gobj.cur_pos.plus(gobj.vel)
}

pub fn (mut gobj Gobj) rereg_next_cell_to_cur_cell(mut game Game) {
	if !gobj.is_next_pos_reached() {
		mut data := &game.data
		old_next_cell := gobj.next_cell
		next_cell := gobj.cur_cell
		gobj.next_cell = next_cell
		gobj.next_pos = game.grid.id_to_pixelpos(next_cell, true)
		gobj.visited_cells.clear()
		if _ := data.nextcell_map[old_next_cell] {
			data.nextcell_map.delete(old_next_cell)
		}
		data.nextcell_map[next_cell] = gobj.id
	}
}

///////////////////////////////////////////////////////////////
// STRUCT SELECTAREA
pub struct Selectarea {
pub mut:
	x1   f32
	x2   f32
	y1   f32
	y2   f32
	renx f32
	reny f32
	renw f32
	renh f32
}

pub fn (mut select_area Selectarea) calc_rect_info(click_pos Vec2, mouse_pos Vec2) {
	select_area.x1 = click_pos.x
	select_area.y1 = click_pos.y
	select_area.x2 = mouse_pos.x
	select_area.y2 = mouse_pos.y
	if mouse_pos.x < click_pos.x {
		select_area.x1 = mouse_pos.x
		select_area.x2 = click_pos.x
	}
	if mouse_pos.y < click_pos.y {
		select_area.y1 = mouse_pos.y
		select_area.y2 = click_pos.y
	}
}

pub fn (mut select_area Selectarea) calculate_draw_info(click_pos Vec2, mouse_pos Vec2, cam_pos Vec2) {
	select_area.renx = if mouse_pos.x > click_pos.x {
		click_pos.x - cam_pos.x
	} else {
		mouse_pos.x - cam_pos.x
	}
	select_area.reny = if mouse_pos.y > click_pos.y {
		click_pos.y - cam_pos.y
	} else {
		mouse_pos.y - cam_pos.y
	}
	select_area.renw = if mouse_pos.x > click_pos.x {
		mouse_pos.x - click_pos.x
	} else {
		click_pos.x - mouse_pos.x
	}
	select_area.renh = if mouse_pos.y > click_pos.y {
		mouse_pos.y - click_pos.y
	} else {
		click_pos.y - mouse_pos.y
	}
}

pub fn (select_area Selectarea) is_pos_in(pos Vec2) bool {
	in_x := pos.x >= select_area.x1 && pos.x <= select_area.x2
	in_y := pos.y >= select_area.y1 && pos.y <= select_area.y2
	return in_x && in_y
}

///////////////////////////////////////////////////////////////
// STRUCT AnimatedSprite
pub struct AnimatedSprite {
pub mut:
	texture_name   string
	current_action string
	frame_idx      f32
	speed          f32 = 0.2
	playing        bool
	pause          bool
}

pub fn (mut aspr AnimatedSprite) play(action string, start_frame_idx int, speed f32) {
	aspr.speed = speed
	aspr.current_action = action
	aspr.frame_idx = start_frame_idx
	aspr.playing = true
	aspr.pause = false
}

pub fn (mut aspr AnimatedSprite) update(mut game Game) {
	if !aspr.playing {
		return
	}
	if aspr.pause {
		return
	}
	frames_len := game.data.frames_info[aspr.current_action].len
	loop := game.data.loop_info[aspr.current_action]
	aspr.frame_idx += aspr.speed
	if aspr.frame_idx >= frames_len - 1 {
		if !loop {
			aspr.playing = false
			return
		}
		aspr.frame_idx = 0
	}
}

///////////////////////////////////////////////////////////////
// STRUCT YSORT_OBJ
pub struct InCamViewObj {
pub mut:
	id      int
	cur_pos Vec2
}

///////////////////////////////////////////////////////////////
// STRUCT MINI MAP
pub struct Minimap {
pub mut:
	bot_right   Vec2
	top_left    Vec2
	width       f32 = 128
	height      f32 = 128
	is_mouse_in bool
	rate        f32 = 1.0 / 5.0
}

pub fn (mm Minimap) gui_pos_to_global(gui_pos Vec2) Vec2 {
	return gui_pos.minus(mm.top_left).devide(mm.rate)
}

pub fn (mm Minimap) global_pos_to_minimap_pos(global_pos Vec2) Vec2 {
	return mm.top_left.plus(global_pos.multiply(mm.rate))
}

pub fn (mm Minimap) is_click_in(game Game) bool {
	return is_pos_in_rect(game.gui_click_pos, mm.top_left, Vec2{mm.width, mm.height})
}

///////////////////////////////////////////////////////////////
// STRUCT CURSOR
pub struct Cursor {
pub mut:
	cur_pos Vec2
	aspr    AnimatedSprite = AnimatedSprite{
		current_action: 'cursor_normal'
	}
}

///////////////////////////////////////////////////////////////
// STRUCT ARROW
pub struct ArrowFx {
pub mut:
	texture_name string = 'arrow_fx'
	cur_pos Vec2
	dest_pos Vec2
	speed f32 = 100.0
	vel_normal Vec2
	rot f32
	aspr AnimatedSprite = AnimatedSprite{
		current_action: 'arrow_fx'
	}
}

pub fn create_arrow_fx(dest_pos Vec2, cur_pos Vec2, speed f32, texture_name string, current_action string) ArrowFx {
	vn := dest_pos.minus(cur_pos).normalize(false)
	return ArrowFx{
		cur_pos: cur_pos
		dest_pos: dest_pos
		speed: speed
		vel_normal: vn
		rot: rad_to_deg(vn.get_angle_radians())
		aspr: AnimatedSprite{
			texture_name: texture_name
			current_action: current_action
		}
	}
}

pub fn (arrow ArrowFx) is_destination_reached() bool {
	return arrow.cur_pos == arrow.dest_pos
}

pub fn (mut arrow ArrowFx) moving_to_destination(delta_time f32) {
	if arrow.is_destination_reached() {
		return
	}
	dx0 := arrow.dest_pos.x - arrow.cur_pos.x
	dy0 := arrow.dest_pos.y - arrow.cur_pos.y
	dist0 := dx0*dx0 + dy0*dy0
	new_pos := Vec2{
		x: arrow.cur_pos.x + arrow.vel_normal.x*arrow.speed*100.0*delta_time
		y: arrow.cur_pos.y + arrow.vel_normal.y*arrow.speed*100.0*delta_time
	}
	dx := new_pos.x - arrow.cur_pos.x
	dy := new_pos.y - arrow.cur_pos.y
	dist := dx*dx + dy*dy
	if dist <= dist0 {
		arrow.cur_pos = new_pos
	} else {
		arrow.cur_pos = arrow.dest_pos
	}

}
///////////////////////////////////////////////////////////////
// STRUCT TEXT ANIMATION
pub struct TextAnimation {
pub mut:
	text string
	from int
	iidx int
	fidx f32
	speed f32 = 0.1
	finished bool
	playing bool
	font_size int = 18
	spacing int = 1
	draw_char_idx int

	text_width f32 = 320.0
	box_height f32 = 240.0
	lines []string
	visible bool
}

pub fn (mut ta TextAnimation) update(delta_time f32) {
	if !ta.playing {
		return
	}
	maxidx := ta.text.len
	ta.finished = ta.fidx >= maxidx
	if ta.finished {
		ta.playing = false
		return
	}
	new_fidx := ta.fidx + ta.speed*100.0*delta_time
	if new_fidx <= maxidx {
		ta.fidx = new_fidx
		ta.iidx = int(ta.fidx)
		return
	}
	ta.fidx = maxidx
	ta.iidx = int(ta.fidx)
}

pub fn (mut ta TextAnimation) play(text string, speed f32, game Game) {
	if text.len == 0 {
		return
	}
	
	mut data := &game.data
	ta.text = ''
	ta.lines.clear()
	mut word_list := text.split(' ')
	println(word_list)
	word_list = word_list.reverse()
	mut line := word_list.pop()
	for word_list.len > 0 {
		new_word := word_list.pop()
		lnew := '$line $new_word'
		lnew_size := r.measure_text_ex(
			data.font_map['font2'],
			lnew.str,
			ta.font_size,
			ta.spacing
		)
		if lnew_size.x > ta.text_width {
			ta.lines << line
			line = new_word
			continue
		}
		line = '$line $new_word'
		
	}
	ta.lines << line

	for idx, l in ta.lines {
		if idx == 0 {
			ta.text = '$l'	
			continue
		}
		ta.text = '$ta.text\n$l'
	}
	ta.iidx = 0
	ta.fidx = 0
	ta.speed = speed
	ta.draw_char_idx = 0
	ta.playing = true
	ta.visible = true
}

pub fn (mut ta TextAnimation) draw_text(pos r.Vector2, game Game) {
	if !ta.visible {
		return
	}
	r.draw_rectangle(
		int(pos.x),
		int(pos.y),
		int(ta.text_width),
		int(ta.box_height),
		r.Color{255, 255, 255, 50}
	)
	mut txt := ta.text[ta.draw_char_idx..ta.iidx].str
	mut txt_size := r.measure_text_ex(
		game.data.font_map['font2'],
		txt,
		ta.font_size,
		ta.spacing
	)
	for txt_size.y >  ta.box_height {
		ta.draw_char_idx += 1
		txt = ta.text[ta.draw_char_idx..ta.iidx].str
		txt_size = r.measure_text_ex(
			game.data.font_map['font2'],
			txt,
			ta.font_size,
			ta.spacing
		)
	}
	r.draw_text_ex(game.data.font_map['font2'], txt, pos, ta.font_size, ta.spacing, r.white)
	
}

///////////////////////////////////////////////////////////////
// STRUCT GAME
pub struct Game {
pub mut:
	w         int
	h         int
	dpi_scale f32 = 1.0

	gui_mouse_pos Vec2
	mouse_cell    int
	mouse_pos     Vec2
	click_pos     Vec2
	gui_click_pos Vec2
	click_count   int
	click_time    f32

	grid              Grid
	n_grid_x          int = 6
	n_grid_y          int = 6
	sub_grid_cols     int = 10
	sub_grid_rows     int = 10
	sub_grid_map      map[int]Grid
	cur_grid_id       int = -1
	cell_neighbor_map map[int][]int
	cam               Camera
	data              UserData
	state             string = 'normal'
	delta_time        f32
	mouse_motion      Vec2
	debug             string
}

pub fn (mut game Game) start_frame() {
	mut data := &game.data
	new_gui_mouse_pos := Vec2{r.get_mouse_x(), r.get_mouse_y()}
	if new_gui_mouse_pos != game.gui_mouse_pos {
		cursor_vel := new_gui_mouse_pos.minus(game.gui_mouse_pos)
		data.cursor.cur_pos = data.cursor.cur_pos.plus(cursor_vel)
		if data.cursor.cur_pos.x < data.margin {
			data.cursor.cur_pos.x = data.margin
		} else if data.cursor.cur_pos.x > r.get_screen_width() - data.margin {
			data.cursor.cur_pos.x = r.get_screen_width() - data.margin
		}
		if data.cursor.cur_pos.y < data.margin {
			data.cursor.cur_pos.y = data.margin
		} else if data.cursor.cur_pos.y > r.get_screen_height() - data.margin {
			data.cursor.cur_pos.y = r.get_screen_height() - data.margin
		}
		game.gui_mouse_pos = new_gui_mouse_pos
	}
	game.mouse_pos = data.cursor.cur_pos.plus(game.cam.pos)
	game.mouse_cell = game.grid.pixelpos_to_id(game.mouse_pos)
	

	data.minimap.bot_right = Vec2{r.get_screen_width() - 1, r.get_screen_height() - 1}
	data.minimap.top_left = Vec2{r.get_screen_width() - 1, r.get_screen_height() - 1}.minus(Vec2{128.0, 128.0})
	data.minimap.is_mouse_in = is_pos_in_rect(data.cursor.cur_pos, data.minimap.top_left,
		Vec2{data.minimap.width, data.minimap.height})

	if r.is_mouse_button_pressed(0) {
		game.click_pos = game.mouse_pos
		game.gui_click_pos = data.cursor.cur_pos
		game.click_count += 1
	}

	mut djmap_result := DjmapRs{}
	if game.grid.ch1.try_pop(mut djmap_result) == .success {
		game.cur_grid_id = -1
		data.processed_map = djmap_result.rs.clone()
		game.grid.steps_map[djmap_result.id] = djmap_result.rs.clone()
	}

	for _, mut subgrid in game.sub_grid_map {
		mut subdjmap_rs := DjmapRs{}
		if subgrid.ch1.try_pop(mut subdjmap_rs) == .success {
			data.processed_map = subdjmap_rs.rs.clone()
			subgrid.steps_map[subdjmap_rs.id] = subdjmap_rs.rs.clone()
		}
	}
}

pub fn (mut game Game) end_frame() {
	mut data := &game.data
	if game.click_time > 0.5 {
		game.click_count = 0
		game.click_time = 0
	}
	for gobj_id, _ in data.gobj_died_map {
		if _ := data.nextcell_map[data.gobj_map[gobj_id].next_cell] {
			data.nextcell_map.delete(data.gobj_map[gobj_id].next_cell)
		}
		if _ := data.cell_gobj_map[data.gobj_map[gobj_id].cur_cell] {
			data.cell_gobj_map.delete(data.gobj_map[gobj_id].cur_cell)
		}
		if _ := data.gobj_group_map[data.gobj_map[gobj_id].group][gobj_id] {
			data.gobj_group_map[data.gobj_map[gobj_id].group].delete(gobj_id)
		}
		data.gobj_map.delete(gobj_id)
		data.gobj_died_map.delete(gobj_id)
	}
	game.delta_time = r.get_frame_time()
}

pub fn (mut game Game) random_walkable_map(_percent_walkable int) {
	mut percent_walkable := _percent_walkable
	if _percent_walkable > 100 {
		percent_walkable = 100
	}
	if _percent_walkable < 0 {
		percent_walkable = 0
	}
	ncell := game.grid.cols * game.grid.rows
	mut not_walkable_cell := map[int]bool{}
	ncell_not_walkable := ncell - int(f32(percent_walkable) / 100.0 * f32(ncell))
	mut temp_cells := []int{len: ncell, cap: ncell, init: index}
	for _ in 0 .. ncell_not_walkable {
		nleft := temp_cells.len
		if nleft <= 0 {
			break
		}
		rd_i := random_number_in_range(0, temp_cells.len - 1)
		cid := temp_cells[rd_i]
		not_walkable_cell[cid] = true
		temp_cells.delete(rd_i)
	}

	for i in 0 .. ncell {
		if _ := not_walkable_cell[i] {
			game.grid.walkable_map[i] = false
		} else {
			game.grid.walkable_map[i] = true
		}
	}

	///
	for cell_id, walkable in game.grid.walkable_map {
		cell_gridpos := game.grid.id_to_gridpos(cell_id)
		subgrid_id := game.get_subgrid_id_from_global_gridpos(cell_gridpos)
		cell_pos := game.grid.id_to_pixelpos(cell_id, true)
		subcell_id := game.sub_grid_map[subgrid_id].pixelpos_to_id(cell_pos)
		game.sub_grid_map[subgrid_id].walkable_map[subcell_id] = walkable
	}

	///
	for cell_id in 0 .. ncell {
		game.grid.neighbors_data[cell_id] = game.grid.id_get_idneighbors(cell_id, game.data.cross)
	}
	for _, mut subgrid in game.sub_grid_map {
		subgrid_ncell := subgrid.cols * subgrid.rows
		for cell_id in 0 .. subgrid_ncell {
			subgrid.neighbors_data[cell_id] = subgrid.id_get_idneighbors(cell_id, game.data.cross)
		}
	}
}

pub fn (game Game) get_subgrid_id_from_global_gridpos(glgr_pos Vec2) int {
	coord := Vec2{int(glgr_pos.x / game.sub_grid_cols), int(glgr_pos.y / game.sub_grid_rows)}
	return int(coord.y * game.n_grid_x + coord.x)
}

pub fn (mut game Game) control_gobj_attack_time(mut gobj Gobj) {
	if gobj.attack_time > 0 {
		gobj.attack_time -= game.delta_time
		if gobj.attack_time < 0 {
			gobj.attack_time = 0
		}
	}
}

///////////////////////////////////////////////////////////////
// STRUCT USER DATA
pub struct UserData {
pub mut:
	// image_map map[string]r.Image
	texture_map   map[string]r.Texture2D
	font_map      map[string]r.Font
	audio_map     map[string]r.Sound
	cross         bool
	neighbor_test []int

	switch1       bool
	processed_map map[int]int
	open          map[int]int
	ch            chan DjmapRs

	gobj_map       map[int]Gobj
	gobj_hp_map    map[int]f32
	gobj_maxhp_map map[int]f32
	gobj_y_map     map[int]f32
	nextcell_map   map[int]int // cell_id: reg_id
	select_area    Selectarea

	cell_gobj_map map[int]int

	scan_vec_list []Vec2 = []Vec2{}

	scan_rot       f32
	scan_radius    f32 = 32.0
	scan_level     int
	scan_spd       f32 = 0.2
	scan_max_level int = 5

	frames_info        map[string][]r.Rectangle
	loop_info          map[string]bool
	aspr_test          AnimatedSprite
	aspr_map           map[int]AnimatedSprite
	aspr_facing_map    map[int]Vec2
	onscreen_gobj_list []InCamViewObj
	minimap            Minimap

	circle_pos       Vec2
	circle_texture   string = 'right mouse click'
	circle_animation AnimatedSprite = AnimatedSprite{}

	cursor            Cursor
	margin f32 = 8
	steps_map_waiting map[int]bool

	gobj_died_map map[int]bool
	gobj_group_map map[int]map[int]bool = {
		0: map[int]bool,
		1: map[int]bool,
		2: map[int]bool,
		3: map[int]bool,
		4: map[int]bool,
		5: map[int]bool,
		6: map[int]bool,
		7: map[int]bool,
		8: map[int]bool,
		9: map[int]bool,
		
	}
	render_texture_map map[int]r.RenderTexture2D
	sound_count map[string]int = {
		'sword1': 0, 
		'attack1`': 0,
		'arrow_impact': 0,
	}
	arrowfx_list []ArrowFx
	ta TextAnimation
}

///////////////////////////////////////////////////////////////
// CONVENIENT FUNCTIONS 
pub fn get_resource_path(pth string) string { // pth is relative to assets folder, example: 'img/unit.png' 'img/move_dir.png', ...
	$if android {
		return os.read_apk_asset(pth)
	}
	return os.resource_abs_path('assets/${pth}')
}

pub fn abs(number f32) f32 {
	return math.abs(number)
}

pub fn sqrt(number f64) f64 {
	return math.sqrt(number)
}

pub fn shuffle(mut id_list []int) {
	rand.shuffle(mut id_list) or { panic(err) }
}

pub fn ceil(x f32) f32 {
	return f32(math.ceil(x))
}

pub fn fastinvsqrt(x f32) f32 {
	mut i := unsafe { *&int(&x) } // get bits for floating value
	i = 1597463007 - (i >> 1) // gives initial guess
	y := unsafe { *&f32(&i) } // convert bits back to float
	rs := 1.0 / y * (1.5 - 0.5 * x * y * y) // Newton step
	// rs2 := f32(math.floor(rs))
	// rs3 := f32(math.ceil(rs))
	// if rs2*rs2 == x {
	// 	return rs2
	// }
	// if rs3*rs3 == x {
	// 	return rs3
	// }
	return rs
}

pub fn randomize() {
	seed_array := seed.time_seed_array(2)
	rand.seed(seed_array)
}

pub fn random_number_in_range(a int, b int) int {
	return rand.int_in_range(a, b + 1) or { return a - 1 }
}

pub fn rad_to_deg(rad f32) f32 {
	return f32(rad * 180 / math.pi)
}

pub fn deg_to_rad(deg f32) f32 {
	return f32(deg * math.pi / 180)
}

pub fn lerp(start f32, end f32, t f32) f32 {
	return start + (end - start) * t
}

pub fn is_pos_in_rect(pos Vec2, rect_pos Vec2, rect_size Vec2) bool {
	in_x := pos.x >= rect_pos.x && pos.x <= rect_pos.x + rect_size.x
	in_y := pos.y >= rect_pos.y && pos.y <= rect_pos.y + rect_size.y
	return in_x && in_y
}

pub fn is_two_pos_in_distance(pos1 Vec2, pos2 Vec2, distance f32) bool {
	dx := pos1.x - pos2.x
	dy := pos1.y - pos2.y
	if dx * dx + dy * dy <= distance * distance {
		return true
	}
	return false
}

