module events

import gg
import mystructs

pub fn on_event(e &gg.Event, mut game mystructs.Game) {
	match e.typ {
		.key_down {
			if _ := game.key_pressed_map[e.key_code] {} else {
				game.key_pressed_map[e.key_code] = true
			}
			game.key_pressing_map[e.key_code] = true
			if e.key_code != game.last_key_pressed {
				game.last_key_pressed = e.key_code
			}
		}
		.key_up {
			if _ := game.key_pressed_map[e.key_code]{
				game.key_pressed_map.delete(e.key_code)
			}
			if _ := game.key_pressing_map[e.key_code] {
				game.key_pressing_map.delete(e.key_code)
			}
			if e.key_code == game.last_key_pressed {
				game.last_key_pressed = .invalid
			}
			game.key_released_map[e.key_code] = true
			
			
		}
		.resized, .restored, .resumed {
			game.resize()
		}
		.touches_began {
			
		}
		.touches_ended {
			
		}
		.mouse_down {
			match e.mouse_button {
				.left {
					game.left_mouse_pressed = true
					game.left_mouse_pressing = true
				}
				.right {
					game.right_mouse_pressed = true
					game.right_mouse_pressing = true
				}
				else {}
			}
		}
		.mouse_up {
			match e.mouse_button {
				.left {
					game.left_mouse_released = true
					game.left_mouse_pressing = false
				}
				.right {
					game.right_mouse_released = true
					game.right_mouse_pressing = false
				}
				else {}
			}
		}
		else {}
	}
}