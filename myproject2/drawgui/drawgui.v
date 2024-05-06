module drawgui

// import gg
import gx
import mystructs



pub fn draw_gui(mut game mystructs.Game) {
	mut ctx := game.ctx
	ctx.begin()
	ctx.draw_text(10, 10, 'w: ${game.w}', gx.TextCfg{size: 24 color: gx.black})
	ctx.draw_text(10, 34, 'h: ${game.h}', gx.TextCfg{size: 24 color: gx.black})
	ctx.draw_text(10, 62, 'debug: ${game.debug}', gx.TextCfg{size: 24 color: gx.black})
	ctx.end(how: .passthru)
}