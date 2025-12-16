/* Minimal config.h - most configuration is now done via ~/.config/tbwm/config.scm */
/* This file only contains compile-time constants and arrays that can't be made dynamic */

#define COLOR(hex)    { ((hex >> 24) & 0xFF) / 255.0f, \
                        ((hex >> 16) & 0xFF) / 255.0f, \
                        ((hex >> 8) & 0xFF) / 255.0f, \
                        (hex & 0xFF) / 255.0f }

/* tagging - maximum tags (can be reduced at runtime via Scheme) */
#define TAGCOUNT (9)

/* Layout definitions - these are compile-time since they're function pointers */
static const Layout layouts[] = {
	/* symbol     arrange function */
	{ "[@]",      dwindle },  /* dwindle (dynamic tiling) */
	{ "[]=",      tile },
	{ "><>",      NULL },    /* floating */
	{ "[M]",      monocle },
};

/* Monitor rules - only used as defaults, can be overridden via Scheme */
static const MonitorRule monrules[] = {
	/* name       mfact  nmaster scale layout       rotate/reflect                x    y */
	{ NULL,       0.55f, 1,      1,    &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL,   -1,  -1 },
};

/* Default keyboard XKB rules - empty means system default */
static const struct xkb_rule_names xkb_rules = {
	.options = NULL,
};

/* These are only used as compile-time defaults, actual values come from cfg_* variables */
/* They exist here so old code doesn't break, but they're now superseded by runtime config */
static const int sloppyfocus               = 1;
static const int bypass_surface_visibility = 0;
static const unsigned int borderpx         = 1;
static const float rootcolor[]             = COLOR(0x000000ff);
static const float bordercolor[]           = COLOR(0x444444ff);
static const float focuscolor[]            = COLOR(0x005577ff);
static const float urgentcolor[]           = COLOR(0xff0000ff);
static const float fullscreen_bg[]         = {0.0f, 0.0f, 0.0f, 1.0f};
static const char *grid_font_path          = "/home/fionn/.local/share/fonts/PxPlus_IBM_VGA_8x16.ttf";
static const int   grid_font_size          = 16;
static const uint32_t frame_bg_color       = 0xFF0000aa;
static const uint32_t frame_bg_inactive    = 0xFF000000;
static const uint32_t frame_fg_color       = 0xFFaaaaaa;
static int log_level = WLR_ERROR;
static const int repeat_rate = 25;
static const int repeat_delay = 600;
static const int tap_to_click = 1;
static const int tap_and_drag = 1;
static const int drag_lock = 1;
static const int natural_scrolling = 0;
static const int disable_while_typing = 1;
static const int left_handed = 0;
static const int middle_button_emulation = 0;
static const enum libinput_config_scroll_method scroll_method = LIBINPUT_CONFIG_SCROLL_2FG;
static const enum libinput_config_click_method click_method = LIBINPUT_CONFIG_CLICK_METHOD_BUTTON_AREAS;
static const uint32_t send_events_mode = LIBINPUT_CONFIG_SEND_EVENTS_ENABLED;
static const enum libinput_config_accel_profile accel_profile = LIBINPUT_CONFIG_ACCEL_PROFILE_ADAPTIVE;
static const double accel_speed = 0.0;
static const enum libinput_config_tap_button_map button_map = LIBINPUT_CONFIG_TAP_MAP_LRM;

/* Window rules - empty by default, add via Scheme (add-rule) */
static const Rule rules[] = {
	/* app_id             title       tags mask     isfloating   monitor */
	{ NULL,               NULL,       0,            0,           -1 },  /* dummy entry */
};

/* Keybindings - empty by default, all bindings via Scheme (bind-key) */
static const Key keys[] = {
	/* modifier  key  function  argument */
	{ 0,         0,   NULL,     {0} },  /* dummy entry */
};

/* Mouse bindings - empty by default, all bindings via Scheme (bind-mouse) */
static const Button buttons[] = {
	/* modifier  button  function  argument */
	{ 0,         0,      NULL,     {0} },  /* dummy entry */
};
