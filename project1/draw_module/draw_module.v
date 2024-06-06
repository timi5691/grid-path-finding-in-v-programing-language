module draw_module

import mystructs
import irishgreencitrus.raylibv as r
// import math

pub fn draw(mut game mystructs.Game) {
	// draw_grid(mut game)
	draw_cells(mut game)
	draw_right_click_animation(mut game)
	draw_gobjs(mut game)
	draw_arrow_fxs(mut game)
	draw_select_area(mut game)

}

pub fn draw_grid(mut game mystructs.Game) {
	cl := r.Color{0, 0, 255, 50}
	for col in 0..game.grid.cols + 1 {
		x := col*game.grid.cell_size + game.grid.draw_pos.x
		y := game.grid.rows*game.grid.cell_size + game.grid.draw_pos.y
		is_in_screeen_width := x >= 0 && x <= r.get_screen_width()
		if !is_in_screeen_width {
			continue
		}
		r.draw_line(
			int(x), 
			int(game.grid.draw_pos.y), 
			int(x),
			int(y), 
			cl)
		
	}

	for row in 0..game.grid.rows + 1 {
		x := game.grid.cols*game.grid.cell_size + game.grid.draw_pos.x
		y := row*game.grid.cell_size + game.grid.draw_pos.y
		is_in_screeen_height := y >= 0 && y <= r.get_screen_height()
		if !is_in_screeen_height {
			continue
		}
		r.draw_line(
			int(game.grid.draw_pos.x), 
			int(y), 
			int(x), 
			int(y), 
			cl
		)
	}
}

fn draw_sub_grid_rect(mut game mystructs.Game) {
	for id, grid in game.sub_grid_map {
		draw_pos := grid.pos.minus(game.cam.pos)
		r.draw_rectangle_lines(
			int(draw_pos.x + 1),
			int(draw_pos.y + 1),
			int(game.grid.cell_size*game.sub_grid_cols - 2),
			int(game.grid.cell_size*game.sub_grid_rows - 2),
			game.sub_grid_map[id].color
		)
	}
}

fn draw_cells(mut game mystructs.Game) {
	for id, walkable in game.grid.walkable_map {
		pos := game.grid.id_to_pixelpos(id, false)
		in_cam_view := game.cam.is_pos_in_camera_view(
			pos.plus(mystructs.Vec2{game.grid.cell_size, game.grid.cell_size}), r.get_screen_width() + int(game.grid.cell_size), r.get_screen_height() + int(game.grid.cell_size))
		if !in_cam_view {
			continue
		}
		draw_pos := pos.minus(game.cam.pos)
		
		if walkable {
			r.draw_texture_pro(
				game.data.texture_map['grass'],
				r.Rectangle{0, 0, 32, 32},
				r.Rectangle{int(draw_pos.x), int(draw_pos.y), int(game.grid.cell_size), int(game.grid.cell_size)},
				r.Vector2{ 0, 0 },
				0,
				r.white
			)
			continue
		}
		
		r.draw_texture_pro(
			game.data.texture_map['wall'],
			r.Rectangle{0, 0, 32, 32},
			r.Rectangle{int(draw_pos.x), int(draw_pos.y), int(game.grid.cell_size), int(game.grid.cell_size)},
			r.Vector2{ 0, 0 },
			0,
			r.white
		)
	}
}

fn draw_gobjs(mut game mystructs.Game) {
	mut data := &game.data
	half_cell_size := game.grid.cell_size/2
	for incamview_obj in data.onscreen_gobj_list {
		gobj_pos := incamview_obj.cur_pos
		gobj_renpos := mystructs.Vec2{
			gobj_pos.x - game.cam.pos.x, 
			gobj_pos.y - game.cam.pos.y
		}
		mut cl := r.white
		// cl.a = 200
		if data.gobj_map[incamview_obj.id].player_selected {
			cl.a = 255
		}
		
		if data.gobj_map[incamview_obj.id].team == 1 {
			cl = r.yellow
		}

		gobj_size := if data.gobj_map[incamview_obj.id].team == 0 {game.grid.cell_size*3} else {game.grid.cell_size*1.8}
		r.draw_texture_pro(
			data.texture_map[data.aspr_map[incamview_obj.id].texture_name],
			data.frames_info[data.aspr_map[incamview_obj.id].current_action][int(data.aspr_map[incamview_obj.id].frame_idx)],
			r.Rectangle{gobj_renpos.x, gobj_renpos.y, gobj_size, gobj_size},
			r.Vector2{ gobj_size/2, gobj_size/2 },
			0,
			cl
		)
		if data.gobj_map[incamview_obj.id].player_selected {
			// r.draw_circle_lines(
			// 	int(gobj_renpos.x),
			// 	int(gobj_renpos.y),
			// 	int(game.grid.cell_size/2),
			// 	r.red
			// )

			maxhp := data.gobj_maxhp_map[incamview_obj.id]
			hp := data.gobj_hp_map[incamview_obj.id]
			hpbar_height := game.grid.cell_size/4
			r.draw_rectangle(
				int(gobj_renpos.x - half_cell_size),
				int(gobj_renpos.y - half_cell_size - hpbar_height),
				int(game.grid.cell_size*hp/maxhp),
				int(hpbar_height),
				r.red
				
			)
			r.draw_rectangle_lines(
				int(gobj_renpos.x - half_cell_size),
				int(gobj_renpos.y - half_cell_size - hpbar_height),
				int(game.grid.cell_size),
				int(hpbar_height),
				r.black
			)

			if data.gobj_map[incamview_obj.id].group != -1 {
				r.draw_text(
					data.gobj_map[incamview_obj.id].group.str().str,
					int(gobj_renpos.x + game.grid.cell_size/2),
					int(gobj_renpos.y + game.grid.cell_size/2),
					24,
					r.blue
				)
			}

			/// debug draw
			test := '${data.gobj_map[incamview_obj.id].state}'.str
			r.draw_text(
				test,
				int(gobj_renpos.x + game.grid.cell_size/2),
				int(gobj_renpos.y - game.grid.cell_size/2),
				24,
				r.blue
			)

			nearest_id := data.gobj_map[incamview_obj.id].nearest_enemy_id
			if nearest_id != -1 {
				nearest_enemy_pos := data.gobj_map[nearest_id].cur_pos.minus(game.cam.pos)
				r.draw_line(
					int(gobj_renpos.x),
					int(gobj_renpos.y),
					int(nearest_enemy_pos.x),
					int(nearest_enemy_pos.y),
					r.red
				)
			}
			///
		}
	}
}

fn draw_select_area(mut game mystructs.Game) {
	mut data := &game.data
	if r.is_mouse_button_down(0) {
		if mystructs.is_pos_in_rect(
			game.gui_click_pos, 
			data.minimap.top_left,
			mystructs.Vec2{
				data.minimap.width,
				data.minimap.height
			}
		) {
			return
		}
		r.draw_rectangle_lines(
			int(data.select_area.renx),
			int(data.select_area.reny),
			int(data.select_area.renw),
			int(data.select_area.renh),
			r.Color{0, 0, 255, 200}
		)
	}
}

fn draw_costs(mut game mystructs.Game) {
	mut data := &game.data
	for id, cost in data.processed_map {
		mut pos := game.grid.id_to_pixelpos(id, true)
		if game.cur_grid_id != -1 {
			pos = game.sub_grid_map[game.cur_grid_id].id_to_pixelpos(id, true)
		}
		in_cam_view := game.cam.is_pos_in_camera_view(pos, r.get_screen_width() + int(game.grid.cell_size), r.get_screen_height() + int(game.grid.cell_size))
		if in_cam_view {
			draw_pos := pos.minus(game.cam.pos)
			r.draw_text(
				'${cost}'.str,
				int(draw_pos.x), 
				int(draw_pos.y), 
				16,
				r.black
			)
		}
	}
}

fn draw_neighbor_test(mut game mystructs.Game) {
	for id in game.data.neighbor_test {
		pos := game.grid.id_to_pixelpos(id, false)
		draw_pos := pos.minus(game.cam.pos)
		r.draw_rectangle(
			int(draw_pos.x),
			int(draw_pos.y),
			int(game.grid.cell_size),
			int(game.grid.cell_size),
			r.Color{100, 255, 0, 100}
		)
	}
}

fn draw_right_click_animation(mut game mystructs.Game) {
	if !game.data.circle_animation.playing {
		return
	}
	circle_renpos := game.data.circle_pos.minus(game.cam.pos)
	r.draw_texture_pro(
		game.data.texture_map['right mouse click'],
		game.data.frames_info['right mouse click'][int(game.data.circle_animation.frame_idx)],
		r.Rectangle{circle_renpos.x, circle_renpos.y, game.grid.cell_size, game.grid.cell_size},
		r.Vector2{ game.grid.cell_size/2, game.grid.cell_size/2 },
		0,
		r.black
	)
}

fn draw_arrow_fxs(mut game mystructs.Game) {
	for arrow_fx in game.data.arrowfx_list {
		frame_info := game.data.frames_info[arrow_fx.aspr.current_action][int(arrow_fx.aspr.frame_idx)]
		a_w := int(frame_info.width)
		a_h := int(frame_info.height)
		arrow_draw_pos := mystructs.Vec2{
			x: arrow_fx.cur_pos.x - game.cam.pos.x
			y: arrow_fx.cur_pos.y - game.cam.pos.y
		}
		// r.draw_texture_pro(
		// 	game.data.texture_map['arrow_fx'],
		// 	r.Rectangle{0, 0, a_w, a_h},
		// 	r.Rectangle{arrow_draw_pos.x, arrow_draw_pos.y, a_w, a_h},
		// 	r.Vector2{ a_w/2, a_h/2 },
		// 	arrow_fx.rot,
		// 	r.white
		// )
		r.draw_texture_pro(
			game.data.texture_map[arrow_fx.aspr.texture_name],
			frame_info,
			r.Rectangle{arrow_draw_pos.x, arrow_draw_pos.y, a_w, a_h},
			r.Vector2{ a_w/2, a_h/2 },
			arrow_fx.rot,
			r.white
		)
	}
}