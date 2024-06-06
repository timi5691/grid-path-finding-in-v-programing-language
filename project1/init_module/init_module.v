module init_module

import mystructs
import rand
import irishgreencitrus.raylibv as r

pub const window_width = 960
pub const window_height = 640
pub const s = f32(window_width) / window_height

pub fn init_game(mut game mystructs.Game) {
	mut data := &game.data
	load_resources(mut game)
	r.hide_cursor()
	r.disable_cursor()
	// r.maximize_window()
	data.ch = chan mystructs.DjmapRs{cap: 1000}
	for i in 0 .. mystructs.nsat / 2 {
		data.scan_vec_list << mystructs.vec_right.rotate(mystructs.deg_to_rad(f32(i * (360 / (mystructs.nsat / 2)))))
	}
	for i in 0 .. mystructs.nsat / 2 {
		data.scan_vec_list << mystructs.vec_right.rotate(mystructs.deg_to_rad(f32(i * (360 / (mystructs.nsat / 2)))))
	}
	init_aspr(mut game)
	percent_walkable := 95
	set_up_game_grid(mut game)
	set_up_game_sub_grid(mut game)
	data.minimap.width = 128.0
	data.minimap.height = 128.0
	data.minimap.rate = data.minimap.width / game.grid.width
	game.random_walkable_map(percent_walkable)
	create_random_gobj(mut game)
	data.render_texture_map = {
		0: r.load_render_texture(int(game.grid.width), int(game.grid.height))
	}
	game.data.margin = game.grid.cell_size/4
	game.data.cursor.cur_pos = mystructs.Vec2{r.get_screen_width()/2, r.get_screen_height()/2}
	game.gui_mouse_pos = mystructs.Vec2{r.get_mouse_x(), r.get_mouse_y()}
	// r.set_window_icon(data.image_map['wall'])
}

fn load_resources(mut game mystructs.Game) {
	mut data := &game.data
	// data.image_map = {
	// 	'wall': r.load_image(mystructs.get_resource_path('img/wall.png').str)
	// }
	data.texture_map = {
		'wall': r.load_texture(mystructs.get_resource_path('img/wall.png').str)
		'grass': r.load_texture(mystructs.get_resource_path('img/grass.png').str)
		'character1_walking':   r.load_texture(mystructs.get_resource_path('img/character1_walking.png').str)
		'character1_attacking': r.load_texture(mystructs.get_resource_path('img/character1_shooting.png').str)
		'zombie_walking':       r.load_texture(mystructs.get_resource_path('img/zombie_walking.png').str)
		'zombie_attacking':     r.load_texture(mystructs.get_resource_path('img/zombie_attacking.png').str)
		'warrior_idle':     r.load_texture(mystructs.get_resource_path('img/warrior_idle.png').str)
		'warrior_walking':     r.load_texture(mystructs.get_resource_path('img/warrior_walking.png').str)
		'warrior_attacking':     r.load_texture(mystructs.get_resource_path('img/warrior_attacking.png').str)
		
		'archer_idle':     r.load_texture(mystructs.get_resource_path('img/archer_idle.png').str)
		'archer_walking':     r.load_texture(mystructs.get_resource_path('img/archer_walking.png').str)
		'archer_attacking':     r.load_texture(mystructs.get_resource_path('img/archer_attacking.png').str)
		
		'cleric_idle':     r.load_texture(mystructs.get_resource_path('img/cleric_idle.png').str)
		'cleric_walking':     r.load_texture(mystructs.get_resource_path('img/cleric_walking.png').str)
		'cleric_attacking':     r.load_texture(mystructs.get_resource_path('img/cleric_attacking.png').str)
		

		'right mouse click':    r.load_texture(mystructs.get_resource_path('img/circle_animation.png').str)
		'cursor':               r.load_texture(mystructs.get_resource_path('img/cursor.png').str)
		'arrow_fx':               r.load_texture(mystructs.get_resource_path('img/arrow_fx.png').str)
		'energy_ball': r.load_texture(mystructs.get_resource_path('img/energy_ball.png').str)
	}
	
	

	data.font_map['font1'] = r.load_font(mystructs.get_resource_path('fonts/robotomonoregular.ttf').str)
	data.font_map['font2'] = r.load_font(mystructs.get_resource_path('fonts/myfont/myfont.fnt').str)
	data.audio_map = {
		'shoot1':        r.load_sound(mystructs.get_resource_path('sounds/laserShoot.wav').str)
		'shoot2':        r.load_sound(mystructs.get_resource_path('sounds/shoot.wav').str)
		'attack1':       r.load_sound(mystructs.get_resource_path('sounds/hitHurt.wav').str)
		'zombie_attack': r.load_sound(mystructs.get_resource_path('sounds/zombie_attack.wav').str)
		'zombie_hurt':   r.load_sound(mystructs.get_resource_path('sounds/zombie_hurt.wav').str)
		'click':         r.load_sound(mystructs.get_resource_path('sounds/click.wav').str)
		'bipselect':     r.load_sound(mystructs.get_resource_path('sounds/bipselect.wav').str)
		'jump':          r.load_sound(mystructs.get_resource_path('sounds/jump.wav').str)
		'explosion':     r.load_sound(mystructs.get_resource_path('sounds/explosion.wav').str)
		'sword1':        r.load_sound(mystructs.get_resource_path('sounds/sword1.wav').str)
		'arrow_impact':        r.load_sound(mystructs.get_resource_path('sounds/arrow_impact.wav').str)
		
	}
	for sound_name, mut sound in data.audio_map {
		if sound_name == "attack1" {
			r.set_sound_volume(sound, 0.25)
		} else if sound_name == "sword1" {
			r.set_sound_volume(sound, 0.5)
		}
	}
}

fn set_up_game_grid(mut game mystructs.Game) {
	game.data.cross = true
	game.grid.cell_size = 32
	game.n_grid_x = 1
	game.n_grid_y = 1
	game.sub_grid_cols = 150
	game.sub_grid_rows = 150
	game.grid.width = game.grid.cell_size * game.n_grid_x * game.sub_grid_cols
	game.grid.height = game.grid.cell_size * game.n_grid_y * game.sub_grid_rows
	game.grid.cross_dist = mystructs.ceil(f32(mystructs.sqrt(
		game.grid.cell_size * game.grid.cell_size + game.grid.cell_size * game.grid.cell_size)))
	game.grid.cols = game.sub_grid_cols * game.n_grid_x
	game.grid.rows = game.sub_grid_rows * game.n_grid_y
	game.data.scan_radius = game.grid.cell_size
}

fn set_up_game_sub_grid(mut game mystructs.Game) {
	for row in 0 .. game.n_grid_y {
		for col in 0 .. game.n_grid_x {
			game.sub_grid_map[row * game.n_grid_x + col] = mystructs.Grid{
				pos: mystructs.Vec2{
					x: col * game.grid.cell_size * game.sub_grid_cols
					y: row * game.grid.cell_size * game.sub_grid_rows
				}
				cols: game.sub_grid_cols
				rows: game.sub_grid_rows
				cell_size: game.grid.cell_size
				color: r.Color{u8(mystructs.random_number_in_range(0, 255)), u8(mystructs.random_number_in_range(0,
					255)), u8(mystructs.random_number_in_range(0, 255)), 255}
			}
		}
	}
}

fn create_random_gobj(mut game mystructs.Game) {
	mut walkable_cells := game.grid.get_walkable_cells()
	rand.shuffle(mut walkable_cells) or { panic(err) }
	gobj_numbers := 500
	half_gobj_number := gobj_numbers / 2
	for i in 0 .. gobj_numbers {
		walkable_cell := walkable_cells.pop()
		pos := game.grid.id_to_pixelpos(walkable_cell, true)
		game.data.gobj_map[i] = mystructs.Gobj{
			id: i
			cur_pos: pos
			next_pos: pos
			dest_pos: pos
			new_dest_pos: pos
			cur_cell: walkable_cell
			vec_length_optimize: false
			spd: 100.0
			player_control: true
			team: if i < half_gobj_number { 0 } else { 1 }
			state: 'idle'
			gobj_type: ['archer', 'sword man', 'cleric'][mystructs.random_number_in_range(0, 2)]
		}
		if game.data.gobj_map[i].team == 1 {
			game.data.gobj_map[i].gobj_type = ['zombie', 'monster', 'undead'][mystructs.random_number_in_range(0, 2)]
		}
		game.data.gobj_maxhp_map[i] = if game.data.gobj_map[i].team == 0 {
			if game.data.gobj_map[i].gobj_type == 'archer' {
				100
			} else if game.data.gobj_map[i].gobj_type == 'cleric' {
				150
			} else {
				200
			}
		} else {
			300
		}
		game.data.gobj_hp_map[i] = game.data.gobj_maxhp_map[i]
		game.data.cell_gobj_map[walkable_cell] = i

		game.data.aspr_map[i] = mystructs.AnimatedSprite{}
		game.data.aspr_map[i].texture_name = if game.data.gobj_map[i].team == 0 {
			'character1_walking'
		} else {
			'zombie_walking'
		}
		game.data.aspr_map[i].play('moving down', 0, 0.1)
		game.data.aspr_facing_map[i] = mystructs.vec_down
		game.data.gobj_y_map[i] = pos.y
		game.data.gobj_map[i].attack_range = if game.data.gobj_map[i].team == 0 {
			if game.data.gobj_map[i].gobj_type in ['sword man'] {
				game.grid.cross_dist * 1

			} else {
				game.grid.cross_dist * 3
			}
		} else {
			game.grid.cross_dist * 1
		}
		
		game.data.gobj_map[i].see_range = if game.data.gobj_map[i].team == 0 {
			game.grid.cross_dist * 4
		} else {
			game.grid.cross_dist * 4
		}
	}
}

fn init_aspr(mut game mystructs.Game) {
	tex_w := game.data.texture_map['character1_walking'].width
	tex_h := game.data.texture_map['character1_walking'].height
	tex_col := 4
	tex_row := 8
	frame_w := tex_w / tex_col
	frame_h := tex_h / tex_row

	game.data.loop_info = {
		////// gobjs frames
		'moving down':          true
		'moving down left':     true
		'moving left':          true
		'moving up left':       true
		'moving up':            true
		'moving up right':      true
		'moving right':         true
		'moving down right':    true
		///
		'shooting down':        false
		'shooting down left':   false
		'shooting left':        false
		'shooting up left':     false
		'shooting up':          false
		'shooting up right':    false
		'shooting right':       false
		'shooting down right':  false
		////// circle frames
		'right mouse click':    false
		////// cursor frames
		'cursor_normal':        true
		'cursor_select_unit':   true
		'cursor_x':             true
		'cursor_select_target': true
		///// arrow frames
		'arrow_fx': false
		///// energy ball frames
		'energy_ball': true
	}

	game.data.frames_info = {
		////// gobj frames
		'moving down':          [
			r.Rectangle{0 * frame_w, 0 * frame_h, frame_w, frame_h},
			r.Rectangle{1 * frame_w, 0 * frame_h, frame_w, frame_h},
			r.Rectangle{2 * frame_w, 0 * frame_h, frame_w, frame_h},
			r.Rectangle{3 * frame_w, 0 * frame_h, frame_w, frame_h},
		]
		'moving down left':     [
			r.Rectangle{0 * frame_w, 1 * frame_h, frame_w, frame_h},
			r.Rectangle{1 * frame_w, 1 * frame_h, frame_w, frame_h},
			r.Rectangle{2 * frame_w, 1 * frame_h, frame_w, frame_h},
			r.Rectangle{3 * frame_w, 1 * frame_h, frame_w, frame_h},
		]
		'moving left':          [
			r.Rectangle{0 * frame_w, 2 * frame_h, frame_w, frame_h},
			r.Rectangle{1 * frame_w, 2 * frame_h, frame_w, frame_h},
			r.Rectangle{2 * frame_w, 2 * frame_h, frame_w, frame_h},
			r.Rectangle{3 * frame_w, 2 * frame_h, frame_w, frame_h},
		]
		'moving up left':       [
			r.Rectangle{0 * frame_w, 3 * frame_h, frame_w, frame_h},
			r.Rectangle{1 * frame_w, 3 * frame_h, frame_w, frame_h},
			r.Rectangle{2 * frame_w, 3 * frame_h, frame_w, frame_h},
			r.Rectangle{3 * frame_w, 3 * frame_h, frame_w, frame_h},
		]
		'moving up':            [
			r.Rectangle{0 * frame_w, 4 * frame_h, frame_w, frame_h},
			r.Rectangle{1 * frame_w, 4 * frame_h, frame_w, frame_h},
			r.Rectangle{2 * frame_w, 4 * frame_h, frame_w, frame_h},
			r.Rectangle{3 * frame_w, 4 * frame_h, frame_w, frame_h},
		]
		'moving up right':      [
			r.Rectangle{0 * frame_w, 5 * frame_h, frame_w, frame_h},
			r.Rectangle{1 * frame_w, 5 * frame_h, frame_w, frame_h},
			r.Rectangle{2 * frame_w, 5 * frame_h, frame_w, frame_h},
			r.Rectangle{3 * frame_w, 5 * frame_h, frame_w, frame_h},
		]
		'moving right':         [
			r.Rectangle{0 * frame_w, 6 * frame_h, frame_w, frame_h},
			r.Rectangle{1 * frame_w, 6 * frame_h, frame_w, frame_h},
			r.Rectangle{2 * frame_w, 6 * frame_h, frame_w, frame_h},
			r.Rectangle{3 * frame_w, 6 * frame_h, frame_w, frame_h},
		]
		'moving down right':    [
			r.Rectangle{0 * frame_w, 7 * frame_h, frame_w, frame_h},
			r.Rectangle{1 * frame_w, 7 * frame_h, frame_w, frame_h},
			r.Rectangle{2 * frame_w, 7 * frame_h, frame_w, frame_h},
			r.Rectangle{3 * frame_w, 7 * frame_h, frame_w, frame_h},
		]
		///
		'shooting down':        [
			r.Rectangle{0 * frame_w, 0 * frame_h, frame_w, frame_h},
			r.Rectangle{1 * frame_w, 0 * frame_h, frame_w, frame_h},
			r.Rectangle{2 * frame_w, 0 * frame_h, frame_w, frame_h},
			r.Rectangle{3 * frame_w, 0 * frame_h, frame_w, frame_h},
		]
		'shooting down left':   [
			r.Rectangle{0 * frame_w, 1 * frame_h, frame_w, frame_h},
			r.Rectangle{1 * frame_w, 1 * frame_h, frame_w, frame_h},
			r.Rectangle{2 * frame_w, 1 * frame_h, frame_w, frame_h},
			r.Rectangle{3 * frame_w, 1 * frame_h, frame_w, frame_h},
		]
		'shooting left':        [
			r.Rectangle{0 * frame_w, 2 * frame_h, frame_w, frame_h},
			r.Rectangle{1 * frame_w, 2 * frame_h, frame_w, frame_h},
			r.Rectangle{2 * frame_w, 2 * frame_h, frame_w, frame_h},
			r.Rectangle{3 * frame_w, 2 * frame_h, frame_w, frame_h},
		]
		'shooting up left':     [
			r.Rectangle{0 * frame_w, 3 * frame_h, frame_w, frame_h},
			r.Rectangle{1 * frame_w, 3 * frame_h, frame_w, frame_h},
			r.Rectangle{2 * frame_w, 3 * frame_h, frame_w, frame_h},
			r.Rectangle{3 * frame_w, 3 * frame_h, frame_w, frame_h},
		]
		'shooting up':          [
			r.Rectangle{0 * frame_w, 4 * frame_h, frame_w, frame_h},
			r.Rectangle{1 * frame_w, 4 * frame_h, frame_w, frame_h},
			r.Rectangle{2 * frame_w, 4 * frame_h, frame_w, frame_h},
			r.Rectangle{3 * frame_w, 4 * frame_h, frame_w, frame_h},
		]
		'shooting up right':    [
			r.Rectangle{0 * frame_w, 5 * frame_h, frame_w, frame_h},
			r.Rectangle{1 * frame_w, 5 * frame_h, frame_w, frame_h},
			r.Rectangle{2 * frame_w, 5 * frame_h, frame_w, frame_h},
			r.Rectangle{3 * frame_w, 5 * frame_h, frame_w, frame_h},
		]
		'shooting right':       [
			r.Rectangle{0 * frame_w, 6 * frame_h, frame_w, frame_h},
			r.Rectangle{1 * frame_w, 6 * frame_h, frame_w, frame_h},
			r.Rectangle{2 * frame_w, 6 * frame_h, frame_w, frame_h},
			r.Rectangle{3 * frame_w, 6 * frame_h, frame_w, frame_h},
		]
		'shooting down right':  [
			r.Rectangle{0 * frame_w, 7 * frame_h, frame_w, frame_h},
			r.Rectangle{1 * frame_w, 7 * frame_h, frame_w, frame_h},
			r.Rectangle{2 * frame_w, 7 * frame_h, frame_w, frame_h},
			r.Rectangle{3 * frame_w, 7 * frame_h, frame_w, frame_h},
		]
		////// circle frames
		'right mouse click':    [
			r.Rectangle{0 * 32, 0 * 32, 32, 32},
			r.Rectangle{1 * 32, 0 * 32, 32, 32},
			r.Rectangle{2 * 32, 0 * 32, 32, 32},
			r.Rectangle{3 * 32, 0 * 32, 32, 32},
			r.Rectangle{4 * 32, 0 * 32, 32, 32},
			r.Rectangle{5 * 32, 0 * 32, 32, 32},
			r.Rectangle{6 * 32, 0 * 32, 32, 32},
		]
		////// cursor frames
		'cursor_normal':        [
			r.Rectangle{0 * 32, 3 * 32, 32, 32},
		]
		'cursor_select_unit':   [
			r.Rectangle{1 * 32, 5 * 32, 32, 32},
		]
		'cursor_x':             [
			r.Rectangle{6 * 32, 6 * 32, 32, 32},
		]
		'cursor_select_target': [
			r.Rectangle{1 * 32, 5 * 32, 32, 32},
			// r.Rectangle{1*32, 0*32, 32, 32},
			// r.Rectangle{0*32, 0*32, 32, 32},
		]
		///// arrow frames
		'arrow_fx': [
			r.Rectangle{0 * 53, 0 * 13, 53, 13},
		]
		///// energy ball frames
		'energy_ball': [
			r.Rectangle{0 * 32, 0 * 32, 32, 32},
			
		]
	}
	game.data.aspr_test = mystructs.AnimatedSprite{}
	game.data.aspr_test.texture_name = 'character1_walking'
	game.data.aspr_test.play('moving down', 0, 0.1)
}
