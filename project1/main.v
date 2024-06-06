module main

import mystructs
import init_module
import update_module
import draw_module
import drawgui
import irishgreencitrus.raylibv as r

fn main() {
	mystructs.randomize()
	mut game := mystructs.Game{}
	r.init_window(init_module.window_width, init_module.window_height, 'simple rts'.str)
	// r.set_window_state(r.flag_window_resizable)
	r.init_audio_device()
	init_module.init_game(mut game)
	r.set_target_fps(60)
	for !r.window_should_close() {
		game.start_frame()
		update_module.update(mut game)
		game.cam.update(mut game)
		game.grid.update_draw_pos(game.cam.pos)

		r.begin_drawing()
		r.clear_background(r.gray)
		for id, mut rdtexture in game.data.render_texture_map {
			match id {
				0 {
					r.begin_texture_mode(rdtexture)
					r.clear_background(r.gray)
					draw_module.draw(mut game)
					r.end_texture_mode()
				}
				else {}
			}
		}
		r.draw_texture_pro(
			r.Texture2D(game.data.render_texture_map[0].texture),
			r.Rectangle{0, 0, game.data.render_texture_map[0].texture.width, -game.data.render_texture_map[0].texture.height},
			r.Rectangle{
				0, 
				0, 
				game.grid.width, 
				game.grid.height},
			r.Vector2{ 0, 0 },
			0,
			r.white
		)
		// draw_module.draw(mut game)
		drawgui.draw_gui(mut game)
		r.end_drawing()

		game.end_frame()
	}

	// unload resources
	// for image_name, image in game.data.image_map {
	// 	r.unload_image(image)
	// 	game.data.image_map.delete(image_name)
	// }
	for texture_name, texture in game.data.texture_map {
		r.unload_texture(texture)
		game.data.texture_map.delete(texture_name)
	}

	for font_name, font in game.data.font_map {
		r.unload_font(font)
		game.data.font_map.delete(font_name)
	}

	for audio_name, audio in game.data.audio_map {
		r.unload_sound(audio)
		game.data.audio_map.delete(audio_name)
	}
	for id, rdtexture in game.data.render_texture_map {
		r.unload_render_texture(rdtexture)
		game.data.render_texture_map.delete(id)
	}

	r.close_audio_device()
	r.close_window()
}
