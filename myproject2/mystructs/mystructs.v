module mystructs

import gg
import gx
import math
import rand
import rand.seed

const (
	vec_up = Vec2{0, -1}
	vec_down = Vec2{0, 1}
	vec_left = Vec2{-1, 0}
	vec_right = Vec2{1, 0}
	vec_topleft = Vec2{-1, -1}
	vec_topright = Vec2{1, -1}
	vec_downleft = Vec2{-1, 1}
	vec_downright = Vec2{1, 1}
)

pub struct UserData {
pub mut:
	cross bool
	neighbor_test []int

	switch1 bool
	processed_map map[int]int
	open map[int]int
	ch chan DjmapRs

	gobj_map map[int]Gobj

	switch3 bool
	nextcell_map map[int]int // cell_id: reg_id
	gobj_cur_cell_map map[int]int
	select_area Selectarea

	nearest_enemy_map map[int]int
	nearest_enemy_map_chan chan map[int]int
}

pub fn fastinvsqrt(x f32) f32 {
	mut i := unsafe{*&int(&x)} // get bits for floating value
	i = 1597463007 - (i >> 1) // gives initial guess
	y := unsafe{*&f32(&i)} // convert bits back to float
	rs := 1.0/y * (1.5 - 0.5 * x * y * y) // Newton step
	rs2 := f32(math.floor(rs))
	rs3 := f32(math.ceil(rs))
	if rs2*rs2 == x {
		return rs2
	}
	if rs3*rs3 == x {
		return rs3
	}
	return rs
}

pub fn randomize() {
	seed_array := seed.time_seed_array(2)
	rand.seed(seed_array)
}

pub fn random_number_in_range(a int, b int) int {
	return rand.int_in_range(a, b + 1) or { 
		return a - 1
	}
}

fn rad_to_deg(rad f32) f32 {
	return f32(rad*180/math.pi)
}

fn deg_to_rad(deg f32) f32 {
	return f32(deg*math.pi/180)
}

pub fn lerp(start f32, end f32, t f32) f32 {
	return start + (end - start)*t
}
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
	return Vec2{x: vec.x - vec2.x y: vec.y - vec2.y}
}

pub fn (vec Vec2) plus(vec2 Vec2) Vec2 {
	return Vec2{x: vec.x + vec2.x y: vec.y + vec2.y}
}

pub fn (vec Vec2) multiply(n f32) Vec2 {
	return Vec2{x: vec.x * n y: vec.y * n}
}

pub fn (vec Vec2) devide(n f32) Vec2 {
	return Vec2{x: vec.x / n y: vec.y / n}
}

pub fn (vec Vec2) normalize(optimize bool) Vec2 {
	distance := vec.length(optimize)
	return vec.devide(distance)
}

fn (vec Vec2) rotate(angle f32) Vec2 {
    return Vec2{
		x: f32(vec.x * math.cos(angle) - vec.y * math.sin(angle))
		y: f32(vec.x * math.sin(angle) + vec.y * math.cos(angle))
	}
}
///////////////////////////////////////////////////////////////
/// STRUCT STEPS_MAP_RESULT
pub struct DjmapRs {
pub mut:
	id int
	rs map[int]int
	nextcell_map map[int]int
}

///////////////////////////////////////////////////////////////
/// STRUCT GRID
pub struct Grid {
pub mut:
	pos Vec2
	draw_pos Vec2
	cols int = 20
	rows int = 20
	cell_size f32 = 16
	cross_dist f32 = f32(math.sqrt(16*16 + 16*16))
	steps_map map[int]map[int]int
	walkable_map map[int]bool
	neighbors_data map[int][]int
	ch1 chan DjmapRs
	color gx.Color
	
}

pub fn (grid Grid) gridpos_to_id(gridpos Vec2) int {
	return int(gridpos.y * grid.cols + gridpos.x)
}

pub fn (grid Grid) id_to_gridpos(id int) Vec2 {
	r := id / grid.cols

	return Vec2{
		x: id - r * grid.cols
		y: r
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

pub fn (grid Grid) calc_steps(cell1 int, cell2 int) int {
	gp1 := grid.id_to_gridpos(cell1)
	gp2 := grid.id_to_gridpos(cell2)
	return math.abs(int(gp2.x - gp1.x)) + math.abs(int(gp2.y - gp1.y))
}

pub fn (grid Grid) id_get_idneighbors(id int, cross bool) []int {
	gridpos :=  grid.id_to_gridpos(id)
	mut rs := []int{}
	mut nbup := false
	mut nbdown := false
	mut nbleft := false
	mut nbright := false

	mut next := gridpos.plus(vec_up)
	mut cond_row := next.y >= 0 && next.y < grid.rows
	mut cond_col := next.x >= 0 && next.x < grid.cols
	mut nextid := grid.gridpos_to_id(next)
	mut walkable := grid.walkable_map[nextid]
	if cond_row && walkable {
		rs << nextid 
		nbup = true
	}
	
	next = gridpos.plus(vec_down)
	cond_row = next.y >= 0 && next.y < grid.rows
	nextid = grid.gridpos_to_id(next)
	walkable = grid.walkable_map[nextid]
	if cond_row && walkable {
		rs << nextid
		nbdown = true
	}
	
	next = gridpos.plus(vec_left)
	cond_col = next.x >= 0 && next.x < grid.cols
	nextid = grid.gridpos_to_id(next)
	walkable = grid.walkable_map[nextid]
	if cond_col && walkable {
		rs << nextid
		nbleft = true
	}

	next = gridpos.plus(vec_right)
	cond_col = next.x >= 0 && next.x < grid.cols
	nextid = grid.gridpos_to_id(next)
	walkable = grid.walkable_map[nextid]
	if cond_col && walkable {
		rs << nextid
		nbright = true
	}
	
	if cross {
		next = gridpos.plus(vec_topleft)
		cond_row = next.y >= 0 && next.y < grid.rows
		cond_col = next.x >= 0 && next.x < grid.cols
		nextid = grid.gridpos_to_id(next)
		walkable = grid.walkable_map[nextid]
		if cond_row && cond_col && walkable && nbup && nbleft {rs << nextid}
		
		next = gridpos.plus(vec_topright)
		cond_row = next.y >= 0 && next.y < grid.rows
		cond_col = next.x >= 0 && next.x < grid.cols
		nextid = grid.gridpos_to_id(next)
		walkable = grid.walkable_map[nextid]
		if cond_row && cond_col && walkable && nbup && nbright {rs << nextid}

		next = gridpos.plus(vec_downleft)
		cond_row = next.y >= 0 && next.y < grid.rows
		cond_col = next.x >= 0 && next.x < grid.cols
		nextid = grid.gridpos_to_id(next)
		walkable = grid.walkable_map[nextid]
		if cond_row && cond_col && walkable && nbdown && nbleft {rs << nextid}

		next = gridpos.plus(vec_downright)
		cond_row = next.y >= 0 && next.y < grid.rows
		cond_col = next.x >= 0 && next.x < grid.cols
		nextid = grid.gridpos_to_id(next)
		walkable = grid.walkable_map[nextid]
		if cond_row && cond_col && walkable && nbdown && nbright {rs << nextid}

	
	}
	return rs.reverse()
}

pub fn (grid Grid) create_steps_map(dest_id int, cross bool) DjmapRs {
	mut processed_map := {dest_id: 0}
	mut nextcell_map := {dest_id: dest_id}
	mut open := {dest_id: 0}
	for open.len > 0 {
		mut new_open := map[int]int{}
		for id, cost in open {
			for nbid in grid.neighbors_data[id] {
				if _ := processed_map[nbid] {
					continue
				}
				processed_map[nbid] = cost + 1
				nextcell_map[nbid] = id
				new_open[nbid] = cost + 1
			}
		}
		open = new_open.clone()
	}
	return DjmapRs{id: dest_id rs: processed_map nextcell_map: nextcell_map}
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
///////////////////////////////////////////////////////////////
/// STRUCT CAMERA
pub struct Camera {
pub mut:
	pos Vec2
	vel Vec2
}

pub fn (cam Camera) is_pos_in_camera_view(pos Vec2, window_width int, window_height int) bool {
	return pos.x >= cam.pos.x && pos.x <= cam.pos.x + window_width && pos.y >= cam.pos.y && pos.y <= cam.pos.y + window_height
}

pub fn (mut cam Camera) update(mut game Game) {
	// update pos
	cam.pos = cam.pos.plus(cam.vel)

	// move camera up down left right
	camspd := game.grid.cell_size/2
	if game.is_key_pressed(.left) {
		cam.vel.x = -camspd
	} else if game.is_key_pressed(.right) {
		cam.vel.x = camspd
	}
	if game.is_key_pressed(.up) {
		cam.vel.y = -camspd
	} else if game.is_key_pressed(.down) {
		cam.vel.y = camspd
	}

	if game.is_key_released(.left) && cam.vel.x == -camspd {
		cam.vel.x = 0
	}
	if game.is_key_released(.right) && cam.vel.x == camspd {
		cam.vel.x = 0
	}
	if game.is_key_released(.up) && cam.vel.y == -camspd {
		cam.vel.y = 0
	}
	if game.is_key_released(.down) && cam.vel.y == camspd {
		cam.vel.y = 0
	}
}
///////////////////////////////////////////////////////////////
/// STRUCT GOBJ
pub struct Gobj {
pub mut:
	id int
	cur_pos Vec2
	next_pos Vec2
	dest_pos Vec2
	spd f32 = 1.0
	vel Vec2
	vel1 Vec2
	vel2 Vec2
	vel3 Vec2
	vec_length_optimize bool = true
	next_cell int = -1
	new_dest_pos Vec2
	state string = 'normal'
	player_control bool = true
	player_selected bool
	visited_cells []int
	stop_distance f32
	team int
	cur_cell int = -1
	hp f32 = 200
	maxhp f32 = 200
	
	nearest_enemy_id int = -1
	attack_range f32 = 16*1.5
	attack_alarm f32
	attack_alarm_max_time f32 = 3.0
	died bool
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

pub fn (gobj Gobj) is_destination_reached() bool {
	return gobj.cur_pos == gobj.dest_pos
}

pub fn (gobj Gobj) is_next_pos_reached() bool {
	return gobj.cur_pos == gobj.next_pos
}

pub fn (gobj Gobj) calculate_vel1(grid Grid) Vec2 {
	if gobj.is_destination_reached() {
		return Vec2{0, 0}
	}
	if gobj.is_next_pos_reached() {
		return Vec2{0, 0}
	}
	cn := gobj.next_pos.minus(gobj.cur_pos)
	cn_length := cn.length(gobj.vec_length_optimize)
	if cn_length <= gobj.spd {
		return gobj.next_pos.minus(gobj.cur_pos)
	}
	cn_nor := cn.devide(cn_length)
	return cn_nor.multiply(gobj.spd)
}

pub fn (gobj Gobj) distance_to_pos(pos Vec2) f32 {
	return pos.minus(gobj.cur_pos).length(gobj.vec_length_optimize)
}

pub fn  (gobj Gobj) is_stop_distance_reached() bool {
	return gobj.distance_to_pos(gobj.dest_pos) <= gobj.stop_distance
}

pub fn (mut gobj Gobj) moving_to_destination(mut game Game) {
	if gobj.is_next_pos_reached() {
		old_next_cell := gobj.next_cell
		if gobj.new_dest_pos != gobj.dest_pos {
			gobj.visited_cells.clear()
			gobj.set_dest_pos(gobj.new_dest_pos)
		}
		gobj.cur_cell = game.grid.pixelpos_to_id(gobj.cur_pos)
		if gobj.is_stop_distance_reached() {
			return
		}
		next_cell := gobj.find_next_cell(game)
		if gobj.next_cell != next_cell {
			gobj.next_pos = game.grid.id_to_pixelpos(next_cell, true)
			gobj.next_cell = next_cell
			gobj.visited_cells << old_next_cell
			
		}
		
		if _ := game.data.nextcell_map[old_next_cell] {
			game.data.nextcell_map.delete(old_next_cell)
		}
		game.data.nextcell_map[next_cell] = gobj.id
	}
	gobj.vel1 = gobj.calculate_vel1(game.grid)
	gobj.vel = gobj.vel1.plus(gobj.vel2).plus(gobj.vel3)
	gobj.cur_pos = gobj.cur_pos.plus(gobj.vel)
}

///////////////////////////////////////////////////////////////
// STRUCT SELECTAREA
pub struct Selectarea {
pub mut:
	x1 f32
	x2 f32
	y1 f32
	y2 f32
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
	select_area.renx = click_pos.x - cam_pos.x
	select_area.reny = click_pos.y - cam_pos.y
	select_area.renw = mouse_pos.x - click_pos.x
	select_area.renh = mouse_pos.y - click_pos.y
}

pub fn (select_area Selectarea) is_pos_in(pos Vec2) bool {
	in_x := pos.x >= select_area.x1 && pos.x <= select_area.x2
	in_y := pos.y >= select_area.y1 && pos.y <= select_area.y2
	return in_x && in_y
}

///////////////////////////////////////////////////////////////
// STRUCT GAME
pub struct Game {
pub mut:
	ctx &gg.Context
	w int
	h int
	dpi_scale f32 = 1.0
	
	gui_mouse_pos Vec2
	mouse_pos Vec2
	click_pos Vec2
	left_mouse_pressing bool
	right_mouse_pressing bool
	left_mouse_pressed bool
	right_mouse_pressed bool
	left_mouse_released bool
	right_mouse_released bool
	
	key_pressing_map map[gg.KeyCode]bool
	key_pressed_map map[gg.KeyCode]bool
	last_key_pressed gg.KeyCode = .invalid
	old_last_key_pressed gg.KeyCode = .invalid
	key_released_map map[gg.KeyCode]bool

	grid Grid
	n_grid_x int = 6
	n_grid_y int = 6
	sub_grid_cols int = 10
	sub_grid_rows int = 10
	sub_grid_map map[int]Grid
	cur_grid_id int = -1
	cell_neighbor_map map[int][]int
	cam Camera
	data UserData
	is_worker1_working bool = true
	is_worker2_working bool = true
	debug string
}

pub fn (mut game Game) start_frame() {
	game.gui_mouse_pos = Vec2{game.ctx.mouse_pos_x, game.ctx.mouse_pos_y}
	game.mouse_pos = game.gui_mouse_pos.plus(game.cam.pos)
	if game.is_left_mouse_pressed() {
		game.click_pos = game.mouse_pos
	}
	
	// if !game.data.switch2 {
	// 	spawn mystructs.calculate_distances_in_thread(game.data.gobj_map, game.data.chan_distance_map)
	// 	game.data.switch2 = true
	// }
	
	// if game.data.chan_distance_map.try_pop(mut game.data.gobj_distance_map) == .success {
	// 	game.data.have_distance_info = true
	// 	game.data.switch2 = false
	// }

	mut djmap_result := mystructs.DjmapRs{}
	if game.grid.ch1.try_pop(mut djmap_result) == .success {
		game.cur_grid_id = -1
		game.data.processed_map = djmap_result.rs.clone()
		game.grid.steps_map[djmap_result.id] = djmap_result.rs.clone()
	}

	for _, mut subgrid in game.sub_grid_map {
		mut subdjmap_rs := mystructs.DjmapRs{}
		if subgrid.ch1.try_pop(mut subdjmap_rs) == .success {
			game.data.processed_map = subdjmap_rs.rs.clone()
			subgrid.steps_map[subdjmap_rs.id] = subdjmap_rs.rs.clone()
		}
	}

	if game.data.nearest_enemy_map_chan.try_pop(mut game.data.nearest_enemy_map) == .success {

	}
}

pub fn (mut game Game) end_frame() {
	if game.left_mouse_pressed {
		game.left_mouse_pressed = false
	}
	if game.right_mouse_pressed {
		game.right_mouse_pressed = false
	}
	if game.left_mouse_released {
		game.left_mouse_released = false
	}
	if game.right_mouse_released {
		game.right_mouse_released = false
	}
	for k, _ in game.key_pressed_map {
		game.key_pressed_map[k] = false
	}
	for k, _ in game.key_released_map {
		game.key_released_map[k] = false
	}
	game.old_last_key_pressed = game.last_key_pressed
	for _, gobj in game.data.gobj_map {
		if gobj.hp <= 0.0 {
			// game.data.gobj_map.delete(gobj.id)
			game.data.gobj_map[gobj.id].died = true
			// if _ := game.data.nextcell_map[gobj.cur_cell] {
			// 	game.data.nextcell_map.delete(gobj.cur_cell)
			// }
		}
	}
	
	for cell_id, gobj_id in game.data.nextcell_map {
		if _ := game.data.gobj_map[gobj_id] {
			if game.data.gobj_map[gobj_id].died == true {
				game.data.nextcell_map.delete(cell_id)
			}
		} else {
			game.data.nextcell_map.delete(cell_id)
		}
	}
}

pub fn (mut game Game) resize() {
	window_size := game.ctx.window_size()
	game.w = window_size.width
	game.h = window_size.height
	game.dpi_scale = if game.ctx.scale == 0.0 {1.0} else {game.ctx.scale}
}

pub fn (game Game) is_key_pressing(k gg.KeyCode) bool {
	if _ := game.key_pressing_map[k] {
		return true
	}
	return false
}

pub fn (game Game) is_key_pressed(k gg.KeyCode) bool {
	if rs := game.key_pressed_map[k] {
		return rs
	}
	return false
}

pub fn (game Game) get_last_key_pressed() gg.KeyCode {
	if game.old_last_key_pressed == game.last_key_pressed {
		return .invalid
	}
	return game.last_key_pressed
}

pub fn (game Game) is_key_released(k gg.KeyCode) bool {
	if rs := game.key_released_map[k] {
		return rs
	}
	return false
}

pub fn (game Game) is_left_mouse_pressed() bool {
	return game.left_mouse_pressed
}

pub fn (game Game) is_right_mouse_pressed() bool {
	return game.right_mouse_pressed
}

pub fn (mut game Game) random_walkable_map(_percent_walkable int) {
	mut percent_walkable := _percent_walkable
	if _percent_walkable > 100 {
		percent_walkable = 100
	}
	if _percent_walkable < 0 {
		percent_walkable = 0
	}
	ncell := game.grid.cols*game.grid.rows
	mut not_walkable_cell := map[int]bool{}
	ncell_not_walkable := ncell - int(f32(percent_walkable)/100.0*f32(ncell))
	mut temp_cells := []int{len: ncell, cap: ncell, init: index}
	for _ in 0..ncell_not_walkable {
		nleft := temp_cells.len
		if nleft <= 0 {
			break
		}
		rd_i := mystructs.random_number_in_range(0, temp_cells.len - 1)
		cid := temp_cells[rd_i]
		not_walkable_cell[cid] = true
		temp_cells.delete(rd_i)
	}
	
	for i in 0..ncell {
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
	for cell_id in 0..ncell {
		game.grid.neighbors_data[cell_id] = game.grid.id_get_idneighbors(cell_id, game.data.cross)
	}
	for _, mut subgrid in game.sub_grid_map {
		subgrid_ncell := subgrid.cols*subgrid.rows
		for cell_id in 0..subgrid_ncell {
			subgrid.neighbors_data[cell_id] = subgrid.id_get_idneighbors(cell_id, game.data.cross)
		}
	}
	
}

pub fn (game Game) get_subgrid_id_from_global_gridpos(glgr_pos Vec2) int {
	coord := Vec2{int(glgr_pos.x/game.sub_grid_cols), int(glgr_pos.y/game.sub_grid_rows)}
	return int(coord.y * game.n_grid_x + coord.x)
}

pub fn (mut game Game) draw_grid(grid Grid, cl gx.Color) {
	for col in 0..grid.cols + 1 {
		x := col*grid.cell_size + grid.draw_pos.x
		y := grid.rows*grid.cell_size + grid.draw_pos.y
		is_in_screeen_width := x >= 0 && x <= game.ctx.window_size().width
		if !is_in_screeen_width {
			continue
		}
		game.ctx.draw_line(x, grid.draw_pos.y, x, y, cl)
	}

	for row in 0..grid.rows + 1 {
		x := grid.cols*grid.cell_size + grid.draw_pos.x
		y := row*grid.cell_size + grid.draw_pos.y
		is_in_screeen_height := y >= 0 && y <= game.ctx.window_size().height
		if !is_in_screeen_height {
			continue
		}
		game.ctx.draw_line(grid.draw_pos.x, y, x, y, cl)
	}
}




