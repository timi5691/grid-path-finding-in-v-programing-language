module drawgui

import mystructs
import irishgreencitrus.raylibv as r

const (
	unit_color_map = {
		0: r.blue
		1: r.white
	}
)

pub fn draw_gui(mut game mystructs.Game) {
	draw_gui_panel_at_bot(mut game)
	draw_minimap(mut game)
	draw_minicam(mut game)
	draw_gobjs_on_minimap(mut game)
	draw_cursor(mut game)
	draw_test(mut game)
	r.draw_text('Fps: ${r.get_fps()}'.str, 0, 0, 24, r.green)
	game.data.ta.draw_text(r.Vector2{0, r.get_screen_height()/2}, game)
}

fn draw_test(mut game mystructs.Game) {
	mut test := 'key pressed: ${r.is_key_down(r.key_left_shift)}'
	r.draw_text_ex(game.data.font_map['font2'], test.str, r.Vector2{10, 42}, 24, 1, r.black)
}

fn draw_minimap(mut game mystructs.Game) {
	r.draw_rectangle(
		int(game.data.minimap.top_left.x),
		int(game.data.minimap.top_left.y),
		int(game.data.minimap.width),
		int(game.data.minimap.height),
		r.Color{0, 0, 0, 100}
	)
	r.draw_rectangle_lines(
		int(game.data.minimap.top_left.x),
		int(game.data.minimap.top_left.y),
		int(game.data.minimap.width),
		int(game.data.minimap.height),
		r.black
	)
	// r.draw_texture_pro(
	// 	r.Texture2D(game.data.render_texture_map[0].texture),
	// 	r.Rectangle{0, 0, game.data.render_texture_map[0].texture.width, -game.data.render_texture_map[0].texture.height},
	// 	r.Rectangle{
	// 		int(game.data.minimap.top_left.x),
	// 		int(game.data.minimap.top_left.y),
	// 		game.data.minimap.width, 
	// 		game.data.minimap.height},
	// 	r.Vector2{ 0, 0 },
	// 	0,
	// 	r.white
	// )
}

fn draw_minicam(mut game mystructs.Game) {
	if !mystructs.is_pos_in_rect(game.cam.pos, game.grid.pos.minus(mystructs.Vec2{r.get_screen_width()/2, r.get_screen_height()/2}), mystructs.Vec2{game.grid.width + r.get_screen_width(), game.grid.height + r.get_screen_height()}) {
		return
	}
	if r.is_mouse_button_down(0) {
		if !game.data.minimap.is_mouse_in {
			return
		}
	}
	mut minicam_pos := game.data.minimap.global_pos_to_minimap_pos(game.cam.pos)
	minicam_width := game.data.minimap.rate*r.get_screen_width()
	minicam_height := game.data.minimap.rate*r.get_screen_height()
	r.draw_rectangle(
		int(minicam_pos.x),
		int(minicam_pos.y),
		int(minicam_width),
		int(minicam_height),
		r.Color{255, 255, 255, 100}
	)
	r.draw_rectangle_lines(
		int(minicam_pos.x),
		int(minicam_pos.y),
		int(minicam_width),
		int(minicam_height),
		r.black
	)
}

fn draw_gobjs_on_minimap(mut game mystructs.Game) {
	for _, gobj in game.data.gobj_map {
		pos := game.data.minimap.global_pos_to_minimap_pos(gobj.cur_pos)
		radius := 1
		mut cl := unit_color_map[gobj.team]
		cl.a = u8(50)
		
		if gobj.player_selected {
			cl = r.green
			cl.a = u8(255)
		}
		r.draw_circle(int(pos.x), int(pos.y), radius, cl)
	}
}

fn draw_cursor(mut game mystructs.Game) {
	r.draw_texture_pro(
		game.data.texture_map['cursor'],
		game.data.frames_info[game.data.cursor.aspr.current_action][int(game.data.cursor.aspr.frame_idx)],
		r.Rectangle{game.data.cursor.cur_pos.x, game.data.cursor.cur_pos.y, game.grid.cell_size*2, game.grid.cell_size*2},
		r.Vector2{ game.grid.cell_size, game.grid.cell_size },
		0,
		r.Color{0, 255, 0, 200}
	)
}

fn draw_gui_panel_at_bot(mut game mystructs.Game) {
	r.draw_rectangle(
		1,
		int(game.data.minimap.top_left.y) - 1,
		r.get_screen_width() - 2,
		int(game.data.minimap.height + 2),
		r.Color{50, 50, 50, 200}
	)
}