# Top-level Makefile for AVR libraries

SUBDIRS = ds1302 fatfs sdcard spi timer uart-mega uart-tiny i2c bme280 font-transform ssd1306 rf433 mcp41xxx wheel ssd1680 ili948x

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
