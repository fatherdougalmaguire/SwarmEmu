
TYPE=debug

ifeq ($(TYPE),release)
OUTPUTDIR=release
YUI=java -jar tools/yuicompressor-2.4.6.jar --type js
else
OUTPUTDIR=debug
YUI=cat
endif

VERSION=$(shell git describe)
UPDATE_DATE=$(shell date "+%Y-%m-%d")

OBJDIR=$(OUTPUTDIR)/objs

NANOWASP_JS=nanowasp.js crtc.js crtcmemory.js keyboard.js latchrom.js memmapper.js memory.js microbee.js utils.js z80cpu.js virtualtape.js
Z80_JS=z80/z80_full.js z80/z80_ops_full.js

ROMS=$(wildcard data/roms/*.rom)
ROMS_JS=$(ROMS:data/roms/%.rom=$(OBJDIR)/%.js)

MWBS=$(wildcard data/mwb/*.mwb)
MWBS_JS=$(MWBS:data/mwb/%.mwb=$(OBJDIR)/%.js)

IMAGES=$(OUTPUTDIR)/dave.jpg $(OUTPUTDIR)/monitor.jpg

HTML=$(OUTPUTDIR)/index.html $(OUTPUTDIR)/about.html $(OUTPUTDIR)/help.html $(OUTPUTDIR)/main.css

.PHONY: nanowasp
nanowasp: $(OUTPUTDIR)/nanowasp.js $(OUTPUTDIR)/z80.js $(OUTPUTDIR)/data.js $(OUTPUTDIR)/.htaccess $(HTML) $(IMAGES)

$(OUTPUTDIR)/index.html: nanowasp.html | $(OUTPUTDIR)
	cat "$<" | sed -e 's/#UPDATE_DATE#/$(UPDATE_DATE)/' | sed -e 's/#VERSION#/$(VERSION)/' > "$@"

$(OUTPUTDIR)/%.html: %.html | $(OUTPUTDIR)
	cp "$<" "$@"

$(OUTPUTDIR)/.htaccess: htaccess | $(OUTPUTDIR)
	cp $< $@

$(OUTPUTDIR)/main.css: main.css | $(OUTPUTDIR)
	cp $< $@

$(IMAGES): $(OUTPUTDIR)/%: images/% | $(OUTPUTDIR)
	cp $< $@

$(OUTPUTDIR)/nanowasp.js: $(NANOWASP_JS) | $(OUTPUTDIR)
	cat $(NANOWASP_JS) | $(YUI) > $@
	gzip -c $@ > $@.gz

$(OUTPUTDIR)/z80.js: $(Z80_JS) | $(OUTPUTDIR) z80
	cat $(Z80_JS) | $(YUI) > $@
	gzip -c $@ > $@.gz

$(OUTPUTDIR)/data.js: $(OBJDIR)/nanowasp-data.js | $(OUTPUTDIR)
	cat $< | $(YUI) > $@
	gzip -c $@ > $@.gz

$(OBJDIR)/nanowasp-data.js: $(ROMS_JS) $(MWBS_JS) | $(OBJDIR)
	echo "var nanowasp = nanowasp || {};" > $@
	echo "nanowasp.data = {};" >> $@
	echo "nanowasp.data.roms = {};" >> $@
	cat $(ROMS_JS:%="%") >> $@
	echo "nanowasp.data.mwbs = {};" >> $@
	cat $(MWBS_JS:%="%") >> $@

$(OBJDIR)/%.js: data/roms/%.rom | $(OBJDIR)
	echo "nanowasp.data.roms['$*'] = \"$$(openssl base64 -in "$<" | sed -e "$$ ! s/$$/\\\\/")\";" > "$@"

$(OBJDIR)/%.js: data/mwb/%.mwb | $(OBJDIR)
	echo "nanowasp.data.mwbs['$*'] = \"$$(openssl base64 -in "$<" | sed -e "$$ ! s/$$/\\\\/")\";" > "$@"


.PHONY: z80
z80:
	cd z80 && $(MAKE)

$(OUTPUTDIR):
	mkdir -p $@

$(OBJDIR):
	mkdir -p $@

