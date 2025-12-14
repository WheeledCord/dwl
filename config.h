/* Taken from https://github.com/djpohly/dwl/issues/466 */
#define COLOR(hex)    { ((hex >> 24) & 0xFF) / 255.0f, \
                        ((hex >> 16) & 0xFF) / 255.0f, \
                        ((hex >> 8) & 0xFF) / 255.0f, \
                        (hex & 0xFF) / 255.0f }
/* appearance */
static const int sloppyfocus               = 1;  /* focus follows mouse */
static const int bypass_surface_visibility = 0;
static const unsigned int borderpx         = 1;
static const float rootcolor[]             = COLOR(0x000000ff);
static const float bordercolor[]           = COLOR(0x444444ff);
static const float focuscolor[]            = COLOR(0x005577ff);
static const float urgentcolor[]           = COLOR(0xff0000ff);
static const float fullscreen_bg[]         = {0.0f, 0.0f, 0.0f, 1.0f};

/* Grid font and frame colors (matching foot terminal VGA theme) */
static const char *grid_font_path          = "/home/fionn/.local/share/fonts/PxPlus_IBM_VGA_8x16.ttf";
static const int   grid_font_size          = 16;
static const uint32_t frame_bg_color       = 0xFF0000aa; /* blue background (focused) */
static const uint32_t frame_bg_inactive    = 0xFF000000; /* black background (inactive) */
static const uint32_t frame_fg_color       = 0xFFaaaaaa; /* gray text/lines */

/* tagging - TAGCOUNT must be no greater than 31 */
#define TAGCOUNT (9)

/* logging */
static int log_level = WLR_ERROR;

static const Rule rules[] = {
	/* app_id             title       tags mask     isfloating   monitor */
	{ "Gimp_EXAMPLE",     NULL,       0,            1,           -1 },
	{ "firefox_EXAMPLE",  NULL,       1 << 8,       0,           -1 },
};

/* layout(s) */
static const Layout layouts[] = {
	/* symbol     arrange function */
	{ "[@]",      dwindle },  /* dwindle (dynamic tiling) */
	{ "[]=",      tile },
	{ "><>",      NULL },    /* floating */
	{ "[M]",      monocle },
};

/* monitors */
static const MonitorRule monrules[] = {
	/* name       mfact  nmaster scale layout       rotate/reflect                x    y */
	{ NULL,       0.55f, 1,      1,    &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL,   -1,  -1 },
};

/* keyboard */
static const struct xkb_rule_names xkb_rules = {
	.options = NULL,
};

static const int repeat_rate = 25;
static const int repeat_delay = 600;

/* Trackpad */
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

/* Use Super (Win) key like your sway config */
#define MODKEY WLR_MODIFIER_LOGO

#define TAGKEYS(KEY,SKEY,TAG) \
	{ MODKEY,                    KEY,            view,            {.ui = 1 << TAG} }, \
	{ MODKEY|WLR_MODIFIER_SHIFT, SKEY,           tag,             {.ui = 1 << TAG} }

#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

/* commands */
static const char *termcmd[] = { "foot", NULL };
static const char *menucmd[] = { "wmenu-run", NULL };

static const Key keys[] = {
	/* modifier                  key                 function        argument */
	
	/* Basics - matching your sway config */
	{ MODKEY,                    XKB_KEY_Return,     spawn,          {.v = termcmd} },
	{ MODKEY,                    XKB_KEY_q,          killclient,     {0} },
	{ MODKEY,                    XKB_KEY_d,          togglelauncher, {0} },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_D,          spawn,          {.v = menucmd} },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_E,          quit,           {0} },
	
	/* Directional focus - hjkl and arrow keys */
	{ MODKEY,                    XKB_KEY_h,          focusdir,       {.i = DirLeft} },
	{ MODKEY,                    XKB_KEY_j,          focusdir,       {.i = DirDown} },
	{ MODKEY,                    XKB_KEY_k,          focusdir,       {.i = DirUp} },
	{ MODKEY,                    XKB_KEY_l,          focusdir,       {.i = DirRight} },
	{ MODKEY,                    XKB_KEY_Left,       focusdir,       {.i = DirLeft} },
	{ MODKEY,                    XKB_KEY_Down,       focusdir,       {.i = DirDown} },
	{ MODKEY,                    XKB_KEY_Up,         focusdir,       {.i = DirUp} },
	{ MODKEY,                    XKB_KEY_Right,      focusdir,       {.i = DirRight} },
	
	/* Swap window in direction - Shift+hjkl and Shift+arrows */
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_H,          swapdir,        {.i = DirLeft} },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_J,          swapdir,        {.i = DirDown} },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_K,          swapdir,        {.i = DirUp} },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_L,          swapdir,        {.i = DirRight} },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_Left,       swapdir,        {.i = DirLeft} },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_Down,       swapdir,        {.i = DirDown} },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_Up,         swapdir,        {.i = DirUp} },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_Right,      swapdir,        {.i = DirRight} },
	
	/* Layouts */
	{ MODKEY,                    XKB_KEY_f,          togglefullscreen, {0} },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_space,      togglefloating, {0} },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_R,          refresh,        {0} },
	
	/* Tags (workspaces) 1-9 */
	TAGKEYS(          XKB_KEY_1, XKB_KEY_exclam,                     0),
	TAGKEYS(          XKB_KEY_2, XKB_KEY_at,                         1),
	TAGKEYS(          XKB_KEY_3, XKB_KEY_numbersign,                 2),
	TAGKEYS(          XKB_KEY_4, XKB_KEY_dollar,                     3),
	TAGKEYS(          XKB_KEY_5, XKB_KEY_percent,                    4),
	TAGKEYS(          XKB_KEY_6, XKB_KEY_asciicircum,                5),
	TAGKEYS(          XKB_KEY_7, XKB_KEY_ampersand,                  6),
	TAGKEYS(          XKB_KEY_8, XKB_KEY_asterisk,                   7),
	TAGKEYS(          XKB_KEY_9, XKB_KEY_parenleft,                  8),
	
	/* Monitor focus */
	{ MODKEY,                    XKB_KEY_comma,      focusmon,       {.i = WLR_DIRECTION_LEFT} },
	{ MODKEY,                    XKB_KEY_period,     focusmon,       {.i = WLR_DIRECTION_RIGHT} },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_less,       tagmon,         {.i = WLR_DIRECTION_LEFT} },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_greater,    tagmon,         {.i = WLR_DIRECTION_RIGHT} },
	
	/* VT switching */
	#define CHVT(n) { WLR_MODIFIER_CTRL|WLR_MODIFIER_ALT,XKB_KEY_XF86Switch_VT_##n, chvt, {.ui = (n)} }
	CHVT(1), CHVT(2), CHVT(3), CHVT(4), CHVT(5), CHVT(6),
	CHVT(7), CHVT(8), CHVT(9), CHVT(10), CHVT(11), CHVT(12),
};

static const Button buttons[] = {
	{ MODKEY, BTN_LEFT,   moveresize,     {.ui = CurMove} },
	{ MODKEY, BTN_MIDDLE, togglefloating, {0} },
	{ MODKEY, BTN_RIGHT,  moveresize,     {.ui = CurResize} },
};
