module draw_module

import gg
import gx
import mystructs
// import math

pub fn draw(mut game mystructs.Game) {
	mut ctx := game.ctx
	ctx.begin()
	game.draw_grid(game.grid, gx.rgba(0, 0, 255, 50))
	ctx.end(how: .passthru)

	// ctx.begin()
	// for id, grid in game.sub_grid_map {
	// 	draw_pos := grid.pos.minus(game.cam.pos)
	// 	ctx.draw_rect(
	// 		gg.DrawRectParams{
	// 			x: draw_pos.x + 1
	// 			y: draw_pos.y + 1
	// 			w: game.grid.cell_size*game.sub_grid_cols - 2
	// 			h: game.grid.cell_size*game.sub_grid_rows - 2
	// 			color: game.sub_grid_map[id].color
	// 			// style: .fill
	// 			style: .stroke
	// 		}
	// 	)
	// }
	// ctx.end(how: .passthru)

	ctx.begin()
	for id, walkable in game.grid.walkable_map {
		if walkable {
			continue
		}
		pos := game.grid.id_to_pixelpos(id, false)

		in_cam_view := game.cam.is_pos_in_camera_view(pos.plus(mystructs.Vec2{game.grid.cell_size, game.grid.cell_size}), game.ctx.window_size().width + int(game.grid.cell_size), game.ctx.window_size().height + int(game.grid.cell_size))
		if in_cam_view {
			draw_pos := pos.minus(game.cam.pos)
			ctx.draw_rect(
				gg.DrawRectParams{
					x: draw_pos.x
					y: draw_pos.y
					w: game.grid.cell_size
					h: game.grid.cell_size
					color: gx.gray
					style: .fill
					// style: .stroke
				}
			)
		}
	}
	ctx.end(how: .passthru)

	// ctx.begin()
	// for id in game.data.neighbor_test {
	// 	pos := game.grid.id_to_pixelpos(id, false)
	// 	draw_pos := pos.minus(game.cam.pos)
	// 	ctx.draw_rect(
	// 		gg.DrawRectParams{
	// 			x: draw_pos.x
	// 			y: draw_pos.y
	// 			w: game.grid.cell_size
	// 			h: game.grid.cell_size
	// 			color: gx.rgba(100, 255, 0, 100)
	// 			style: .fill //.stroke
	// 		}
	// 	)
	// }
	// ctx.end(how: .passthru)

	// ctx.begin()
	// for id, cost in game.data.processed_map {
	// 	mut pos := game.grid.id_to_pixelpos(id, true)
	// 	if game.cur_grid_id != -1 {
	// 		pos = game.sub_grid_map[game.cur_grid_id].id_to_pixelpos(id, true)
	// 	}
	// 	in_cam_view := game.cam.is_pos_in_camera_view(pos, game.ctx.window_size().width + int(game.grid.cell_size), game.ctx.window_size().height + int(game.grid.cell_size))
	// 	if in_cam_view {
	// 		draw_pos := pos.minus(game.cam.pos)
	// 		ctx.draw_text(int(draw_pos.x), int(draw_pos.y), '${cost}', gx.TextCfg{size: 8 color: gx.black align: .center vertical_align: .middle})
	// 	}
	// }
	// ctx.end(how: .passthru)

	ctx.begin()
	mut gobj_list := game.data.gobj_map.values()
	gobj_list.sort(a.cur_pos.y < b.cur_pos.y)
	for gobj in gobj_list {
		if gobj.died == true {
			continue
		}
		gobj_pos := gobj.cur_pos
		gobj_renpos := mystructs.Vec2{
			gobj_pos.x - game.cam.pos.x, 
			gobj_pos.y - game.cam.pos.y
		}
		mut cl := gx.red
		if gobj.team == 1 {
			cl = gx.black
		}
		cl.a = 200
		in_cam_view := game.cam.is_pos_in_camera_view(gobj.cur_pos, game.ctx.window_size().width + int(game.grid.cell_size), game.ctx.window_size().height + int(game.grid.cell_size))
		if in_cam_view {
			ctx.draw_circle_filled(
				gobj_renpos.x,
				gobj_renpos.y,
				game.grid.cell_size/2 - 2,
				cl
			)
			half_cell_size := game.grid.cell_size/2.0
			
			if gobj.player_selected {
				ctx.draw_rect(
					gg.DrawRectParams{
						x: gobj_renpos.x - half_cell_size
						y: gobj_renpos.y - half_cell_size - 4
						w: gobj.hp/gobj.maxhp*game.grid.cell_size
						h: game.grid.cell_size/4.0
						color: cl
						style: .fill
						// style: .stroke
					}
					
				)
				ctx.draw_rect(
					gg.DrawRectParams{
						x: gobj_renpos.x - half_cell_size
						y: gobj_renpos.y - half_cell_size - 4
						w: game.grid.cell_size
						h: game.grid.cell_size/4.0
						color: gx.rgba(255, 0, 0, 255)
						// style: .fill
						style: .stroke
					}
				)
				ctx.draw_circle_empty(
					gobj_renpos.x,
					gobj_renpos.y,
					game.grid.cell_size/2,
					gx.red
				)
				
			}

			// test := '${gobj.id}, ${gobj.nearest_enemy_id}'
			// ctx.draw_text(
			// 	int(gobj_renpos.x),
			// 	int(gobj_renpos.y - game.grid.cell_size/2),
			// 	test,
			// 	gx.TextCfg{
			// 		size: 16
			// 		color: gx.blue
			// 	}
			// )
		}
	}
	ctx.end(how: .passthru)

	ctx.begin()
	if game.left_mouse_pressing {
		ctx.draw_rect(
			gg.DrawRectParams{
				x: game.data.select_area.renx
				y: game.data.select_area.reny
				w: game.data.select_area.renw
				h: game.data.select_area.renh
				color: gx.rgba(100, 255, 0, 100)
				style: .fill //.stroke
			}
		)
	}
	ctx.end(how: .passthru)
}

