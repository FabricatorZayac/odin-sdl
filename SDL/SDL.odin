package SDL

import SDL "vendor:sdl2"

Error :: Maybe(string)

as_sdl_flags :: proc {
    init_flags_convert,
    window_flags_convert,
    renderer_flags_convert
}

InitFlags :: struct {
    timer: bool,
    audio: bool,
    video: bool,
    joystick: bool,
    haptic: bool,
    game_controller: bool,
    events: bool,
    sensor: bool,
}
init_flags_convert :: proc(flags: InitFlags) -> (sdl_flags: SDL.InitFlags) {
    if flags.timer { sdl_flags |= SDL.INIT_TIMER }
    if flags.audio { sdl_flags |= SDL.INIT_AUDIO }
    if flags.video { sdl_flags |= SDL.INIT_VIDEO }
    if flags.joystick { sdl_flags |= SDL.INIT_JOYSTICK }
    if flags.haptic { sdl_flags |= SDL.INIT_HAPTIC }
    if flags.game_controller { sdl_flags |= SDL.INIT_GAMECONTROLLER }
    if flags.events { sdl_flags |= SDL.INIT_EVENTS }
    if flags.sensor { sdl_flags |= SDL.INIT_SENSOR }
    return
}
init :: proc(flags: InitFlags) -> Error {
    init_flags := as_sdl_flags(flags)
    if SDL.Init(init_flags) != 0 {
        return SDL.GetErrorString()
    }
    return nil
}

Window :: struct {ptr: ^SDL.Window}
Context :: enum {
    default,
    opengl,
    vulkan,
    metal,
}
Visibility :: enum {
    default,
    shown,
    hidden,
}
Dimension :: enum {
    default,
    fullscreen,
    fullscreen_desktop,
    maximized,
    minimized,
}
WindowFlags :: struct {
    dim: Dimension,
    ctx: Context,
    vis: Visibility,
    borderless: bool,
    resizable: bool,
    input_grabbed: bool,
    input_focus: bool,
    mouse_focus: bool,
    wforeign: bool,
    allow_high_dpi: bool,
    mouse_capture: bool,
    always_on_top: bool,
    skip_taskbar: bool,
    utility: bool,
    tooltip: bool,
    popup_menu: bool,
}
window_flags_convert :: proc(flags: WindowFlags) -> (sdl_flags: SDL.WindowFlags) {
    switch flags.dim {
        case .default:
        case .fullscreen: sdl_flags |= SDL.WINDOW_FULLSCREEN
        case .fullscreen_desktop: sdl_flags |= SDL.WINDOW_FULLSCREEN_DESKTOP
        case .maximized: sdl_flags |= SDL.WINDOW_MAXIMIZED
        case .minimized: sdl_flags |= SDL.WINDOW_MINIMIZED
    }
    switch flags.ctx {
        case .default:
        case .metal: sdl_flags |= SDL.WINDOW_METAL
        case .opengl: sdl_flags |= SDL.WINDOW_OPENGL
        case .vulkan: sdl_flags |= SDL.WINDOW_VULKAN
    }
    switch flags.vis {
        case .default:
        case .shown: sdl_flags |= SDL.WINDOW_SHOWN
        case .hidden: sdl_flags |= SDL.WINDOW_HIDDEN
    }
    if flags.borderless { sdl_flags |= SDL.WINDOW_BORDERLESS }
    if flags.resizable { sdl_flags |= SDL.WINDOW_RESIZABLE }
    if flags.input_grabbed { sdl_flags |= SDL.WINDOW_INPUT_GRABBED }
    if flags.input_focus { sdl_flags |= SDL.WINDOW_INPUT_FOCUS }
    if flags.mouse_focus { sdl_flags |= SDL.WINDOW_MOUSE_FOCUS }
    if flags.wforeign { sdl_flags |= SDL.WINDOW_FOREIGN }
    if flags.allow_high_dpi { sdl_flags |= SDL.WINDOW_ALLOW_HIGHDPI }
    if flags.mouse_capture { sdl_flags |= SDL.WINDOW_MOUSE_CAPTURE }
    if flags.always_on_top { sdl_flags |= SDL.WINDOW_ALWAYS_ON_TOP }
    if flags.skip_taskbar { sdl_flags |= SDL.WINDOW_SKIP_TASKBAR }
    if flags.utility { sdl_flags |= SDL.WINDOW_UTILITY }
    if flags.tooltip { sdl_flags |= SDL.WINDOW_TOOLTIP }
    if flags.popup_menu { sdl_flags |= SDL.WINDOW_POPUP_MENU }
    return
}

WindowPosition :: struct {
    pos: enum {default,centered,absolute},
    abs: i32,
}

create_window :: proc(title: cstring,
                      wx: WindowPosition,
                      wy: WindowPosition,
                      w: i32,
                      h: i32,
                      flags: WindowFlags) -> (Window, Error) {
    x : i32
    switch wx.pos {
        case .default: x = SDL.WINDOWPOS_UNDEFINED
        case .centered: x = SDL.WINDOWPOS_CENTERED
        case .absolute: x = wx.abs
    }
    y : i32
    switch wy.pos {
        case .default: y = SDL.WINDOWPOS_UNDEFINED
        case .centered: y = SDL.WINDOWPOS_CENTERED
        case .absolute: y = wy.abs
    }
    window := SDL.CreateWindow(title, x, y, w, h, as_sdl_flags(flags))
    if window == nil {
        return {nil}, SDL.GetErrorString()
    }
    return {window}, nil 
}

Renderer :: struct {ptr: ^SDL.Renderer}
RendererFlags :: struct {
    software: bool,
    accelerated: bool,
    present_vsync: bool,
    target_texture: bool,
}
renderer_flags_convert :: proc(flags: RendererFlags) -> (sdl_flags: SDL.RendererFlags) {
    if flags.software { sdl_flags |= SDL.RENDERER_SOFTWARE }
    if flags.accelerated { sdl_flags |= SDL.RENDERER_ACCELERATED }
    if flags.present_vsync { sdl_flags |= SDL.RENDERER_PRESENTVSYNC }
    if flags.target_texture { sdl_flags |= SDL.RENDERER_TARGETTEXTURE }
    return
}

create_renderer :: proc(window: Window,
                        index: Maybe(i32),
                        flags: RendererFlags) -> (Renderer, Error) {
    renderer := SDL.CreateRenderer(window.ptr, index.? or_else -1, as_sdl_flags(flags));
    if renderer == nil {
        return {nil}, SDL.GetErrorString()
    }
    return {renderer}, nil
}

Color :: SDL.Color

ColorFromRGBA :: proc(rgba: u32) -> Color {
    return {u8(rgba >> 24), u8(rgba >> 16), u8(rgba >> 8), u8(rgba)}
}

ColorFromRGB :: proc(rgb: u32) -> Color {
    return {u8(rgb >> 16), u8(rgb >> 8), u8(rgb), 0xFF}
}

@(private)
set_render_draw_color :: proc(renderer: Renderer, r: u8, g: u8, b: u8, a: u8) -> Error {
    return set_color(renderer, Color{r, g, b, a})
}

set_color_rgba :: proc(renderer: Renderer, rgba: u32) -> Error {
    return set_color(renderer, ColorFromRGBA(rgba))
}

@(private)
set_color_rgb :: proc(renderer: Renderer, rgb: u32) -> Error {
    return set_color(renderer, ColorFromRGB(rgb))
}

@(private)
set_draw_color :: proc(renderer: Renderer, color: Color) -> Error {
    if SDL.SetRenderDrawColor(renderer.ptr, color.r, color.g, color.b, color.a) != 0 {
        return SDL.GetErrorString()
    }
    return nil
}

set_color :: proc {
    set_draw_color,
    set_render_draw_color,
    set_color_rgb,
}

render_fill_rect :: proc(renderer: Renderer, rect: SDL.Rect) -> Error {
    rect := rect
    if SDL.RenderFillRect(renderer.ptr, &rect) != 0 {
        return SDL.GetErrorString()
    }
    return nil
}

render_draw_rect :: proc(renderer: Renderer, rect: SDL.Rect) -> Error {
    rect := rect
    if SDL.RenderDrawRect(renderer.ptr, &rect) != 0 {
        return SDL.GetErrorString()
    }
    return nil
}

render_present :: proc(renderer: Renderer) {
    SDL.RenderPresent(renderer.ptr)
}

render_clear :: proc(renderer: Renderer) -> Error {
    if SDL.RenderClear(renderer.ptr) != 0 {
        return SDL.GetErrorString()
    }
    return nil
}

quit :: SDL.Quit

destroy_window :: proc(window: Window) {
    SDL.DestroyWindow(window.ptr)
}

destroy_renderer :: proc(renderer: Renderer) {
    SDL.DestroyRenderer(renderer.ptr)
}

Event :: SDL.Event
EventType :: SDL.EventType
poll_event :: proc() -> Maybe(Event) {
    event : Event
    if (SDL.PollEvent(&event)) {
        return event
    }
    return nil
}

Rect :: SDL.Rect
