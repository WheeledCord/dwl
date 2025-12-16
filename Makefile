.POSIX:
.SUFFIXES:

include config.mk

# flags for compiling
TBWMCPPFLAGS = -I. -DWLR_USE_UNSTABLE -D_POSIX_C_SOURCE=200809L \
	-DVERSION=\"$(VERSION)\" $(XWAYLAND)
TBWMDEVCFLAGS = -g -Wpedantic -Wall -Wextra -Wdeclaration-after-statement \
	-Wno-unused-parameter -Wshadow -Wunused-macros -Werror=strict-prototypes \
	-Werror=implicit -Werror=return-type -Werror=incompatible-pointer-types \
	-Wfloat-conversion

# CFLAGS / LDFLAGS
PKGS      = wayland-server xkbcommon libinput pangocairo freetype2 pixman-1 $(XLIBS)
TBWMCFLAGS = `$(PKG_CONFIG) --cflags $(PKGS)` $(WLR_INCS) $(TBWMCPPFLAGS) $(TBWMDEVCFLAGS) $(CFLAGS)
LDLIBS    = `$(PKG_CONFIG) --libs $(PKGS)` $(WLR_LIBS) -lm $(LIBS)

all: tbwm
tbwm: tbwm.o util.o s7.o
	$(CC) tbwm.o util.o s7.o $(TBWMCFLAGS) $(LDFLAGS) $(LDLIBS) -ldl -o $@
tbwm.o: tbwm.c client.h config.h config.mk s7.h cursor-shape-v1-protocol.h \
	pointer-constraints-unstable-v1-protocol.h wlr-layer-shell-unstable-v1-protocol.h \
	wlr-output-power-management-unstable-v1-protocol.h xdg-shell-protocol.h
util.o: util.c util.h
s7.o: s7.c s7.h
	$(CC) -c -O2 -I. s7.c -o s7.o

# wayland-scanner is a tool which generates C headers and rigging for Wayland
# protocols, which are specified in XML. wlroots requires you to rig these up
# to your build system yourself and provide them in the include path.
WAYLAND_SCANNER   = `$(PKG_CONFIG) --variable=wayland_scanner wayland-scanner`
WAYLAND_PROTOCOLS = `$(PKG_CONFIG) --variable=pkgdatadir wayland-protocols`

cursor-shape-v1-protocol.h:
	$(WAYLAND_SCANNER) enum-header \
		$(WAYLAND_PROTOCOLS)/staging/cursor-shape/cursor-shape-v1.xml $@
pointer-constraints-unstable-v1-protocol.h:
	$(WAYLAND_SCANNER) enum-header \
		$(WAYLAND_PROTOCOLS)/unstable/pointer-constraints/pointer-constraints-unstable-v1.xml $@
wlr-layer-shell-unstable-v1-protocol.h:
	$(WAYLAND_SCANNER) enum-header \
		protocols/wlr-layer-shell-unstable-v1.xml $@
wlr-output-power-management-unstable-v1-protocol.h:
	$(WAYLAND_SCANNER) server-header \
		protocols/wlr-output-power-management-unstable-v1.xml $@
xdg-shell-protocol.h:
	$(WAYLAND_SCANNER) server-header \
		$(WAYLAND_PROTOCOLS)/stable/xdg-shell/xdg-shell.xml $@

config.h:
	cp config.def.h $@
clean:
	rm -f tbwm *.o *-protocol.h

dist: clean
	mkdir -p tbwm-$(VERSION)
	cp -R LICENSE* Makefile CHANGELOG.md README.md client.h config.def.h \
		config.mk protocols tbwm.1 tbwm.c util.c util.h tbwm.desktop \
		tbwm-$(VERSION)
	tar -caf tbwm-$(VERSION).tar.gz tbwm-$(VERSION)
	rm -rf tbwm-$(VERSION)

install: tbwm
	mkdir -p $(DESTDIR)$(PREFIX)/bin
	rm -f $(DESTDIR)$(PREFIX)/bin/tbwm
	cp -f tbwm $(DESTDIR)$(PREFIX)/bin
	chmod 755 $(DESTDIR)$(PREFIX)/bin/tbwm
	mkdir -p $(DESTDIR)$(MANDIR)/man1
	cp -f tbwm.1 $(DESTDIR)$(MANDIR)/man1
	chmod 644 $(DESTDIR)$(MANDIR)/man1/tbwm.1
	mkdir -p $(DESTDIR)$(DATADIR)/wayland-sessions
	cp -f tbwm.desktop $(DESTDIR)$(DATADIR)/wayland-sessions/tbwm.desktop
	chmod 644 $(DESTDIR)$(DATADIR)/wayland-sessions/tbwm.desktop
uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/tbwm $(DESTDIR)$(MANDIR)/man1/tbwm.1 \
		$(DESTDIR)$(DATADIR)/wayland-sessions/tbwm.desktop

.SUFFIXES: .c .o
.c.o:
	$(CC) $(CPPFLAGS) $(TBWMCFLAGS) -o $@ -c $<
