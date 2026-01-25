# Requires cc65 toolchain installed

CC = cc65
AS = ca65
AR = ar65
CC65_HOME    = /usr/local/share/cc65
MAX6502_HOME =~/Developments/6502/max6502
#MAX6502_HOME = ~/6502/max6502
TARGET       = replica1
INCLUDES     = -I $(MAX6502_HOME)/include
LIB_DIR      = $(MAX6502_HOME)/lib
INCLUDE_DIR  = $(MAX6502_HOME)/include
MAN_DIR      = $(MAX6502_HOME)/man
DOC_DIR      = $(MAX6502_HOME)/doc
TESTS        = $(MAX6502_HOME)/tests
