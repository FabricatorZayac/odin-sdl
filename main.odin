package main

import "core:fmt"
import SDL "SDL"

WINDOW_WIDTH :: 800
WINDOW_HEIGHT :: 600

CELL_SIZE :: 10
CELLS_Y :: WINDOW_HEIGHT / CELL_SIZE
CELLS_X :: WINDOW_WIDTH / CELL_SIZE

CELL_COLOR :: 0xfb4934
CELL_OUTLINE :: 0x928374

BACKGROUND_COLOR :: 0x1d2021

make_cell :: proc(x, y: i32) -> SDL.Rect {
    return {
        x * CELL_SIZE,
        y * CELL_SIZE,
        CELL_SIZE,
        CELL_SIZE,
    }
}

render_cell :: proc(renderer: SDL.Renderer, rect: SDL.Rect) -> SDL.Error {
    SDL.set_color(renderer, CELL_COLOR) or_return
    SDL.render_fill_rect(renderer, rect) or_return
    SDL.set_color(renderer, CELL_OUTLINE) or_return
    return SDL.render_draw_rect(renderer, rect)
}

draw_demo :: proc(renderer: SDL.Renderer) -> SDL.Error {
    for i in 0..<CELLS_Y {
        render_cell(renderer, make_cell(i32(i), i32(i))) or_return
    }
    return nil
}

sdl_loop :: proc(renderer: SDL.Renderer) -> SDL.Error {
    sdl_loop : for {
        for {
            event, ok := SDL.poll_event().?
            if !ok { break }

            #partial switch event.type {
            case SDL.EventType.QUIT:
                break sdl_loop
            }
        }

        draw_demo(renderer) or_return

        SDL.render_present(renderer)
        SDL.set_color(renderer, BACKGROUND_COLOR) or_return
        SDL.render_clear(renderer) or_return
    }
    return nil
}

sdl_main :: proc() -> SDL.Error {
    SDL.init({
        video = true,
    }) or_return
    defer SDL.quit()

    window := SDL.create_window(
        "SDL2 Example",
        {pos=.centered},
        {pos=.centered},
        WINDOW_WIDTH,
        WINDOW_HEIGHT,
        {vis=.shown, resizable=true},
    ) or_return
    defer SDL.destroy_window(window)

    renderer := SDL.create_renderer(window, nil, {accelerated=true}) or_return
    defer SDL.destroy_renderer(renderer)

    return sdl_loop(renderer)
}

main :: proc() {
    err := sdl_main()
    if err != nil {
        fmt.eprintln(err)
    }
}
