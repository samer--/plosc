LIBLO_CFLAGS=$(shell pkg-config --cflags liblo)
LIBLO_LIBS=$(shell pkg-config --libs liblo)
TARGET=plosc

CFLAGS+=$(LIBLO_CFLAGS) 
SOBJ=$(PACKSODIR)/$(TARGET).$(SOEXT)
LIBS=$(LIBLO_LIBS)

all:	$(SOBJ)

$(SOBJ): c/$(TARGET).o
	mkdir -p $(PACKSODIR)
	$(LD) $(LDSOFLAGS) -o $@ $(SWISOLIB) $< $(LIBS)
	strip -x $@

check::
install::
clean:
	rm -f c/$(TARGET).o

distclean: clean
	rm -f $(SOBJ)

install-me:
	swipl -f none -g "pack_install('file:.',[upgrade(true)]), halt"

publish:
	swipl -f none -g "pack_property(plosc,download(D)), pack_install(D,[upgrade(true),interactive(false)]), halt"


