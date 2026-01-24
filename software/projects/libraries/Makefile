# Top-level Makefile for 6502 libraries

SUBDIRS = spi timer sdcard fatfs

.PHONY: all install install-all clean all-mcus $(SUBDIRS)

all:
	@for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir all || exit 1; \
	done

install:
	@for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir install || exit 1; \
	done

install-all:
	@for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir install-all || exit 1; \
	done

clean:
	@for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir clean || exit 1; \
	done

all-mcus:
	@for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir all-mcus || exit 1; \
	done
