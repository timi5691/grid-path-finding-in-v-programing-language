module main

import gg
import gx
import mystructs
import init_module
import events
import update_module
import draw_module
import drawgui



fn main() {
	mystructs.randomize()
	mut game := mystructs.Game{
		ctx: unsafe {0}
	}
    game.ctx = gg.new_context(
        bg_color: gx.black
        width: init_module.window_width
        height: init_module.window_height
        window_title: 'gg template'
		init_fn: init_module.init_game
		event_fn: events.on_event
        frame_fn: frame
		user_data: &game
	)
    game.ctx.run()
	
}

fn frame(mut game mystructs.Game) {
	game.start_frame()
	update_module.update(mut game)
	game.cam.update(mut game)
	game.grid.update_draw_pos(game.cam.pos)
	mut ctx := game.ctx
	ctx.begin()
	ctx.end()
	draw_module.draw(mut game)
	drawgui.draw_gui(mut game)
	game.end_frame()
}

