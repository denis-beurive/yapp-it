SHELL := /bin/bash

PARSER_DIR    = ./parsers
EYAPP_OPTIONS = -Cv

# --------------------------------------------
# Build the parsers
# --------------------------------------------

${PARSER_DIR}/basic.pm: basic.yp
	eyapp -Cv -o $@ $<
	mv basic.output ${PARSER_DIR}/

${PARSER_DIR}/multiline.pm: multiline.yp
	eyapp -Cv -o $@ $<
	mv multiline.output ${PARSER_DIR}/

${PARSER_DIR}/comments.pm: comments.yp
	eyapp -Cv -o $@ $<
	mv comments.output ${PARSER_DIR}/

${PARSER_DIR}/declarations.pm: declarations.yp
	eyapp -Cv -o $@ $<
	mv declarations.output ${PARSER_DIR}/


# --------------------------------------------
# Generic rules
# --------------------------------------------

all: ${PARSER_DIR}/basic.pm \
     ${PARSER_DIR}/multiline.pm \
     ${PARSER_DIR}/comments.pm \
     ${PARSER_DIR}/declarations.pm

test: all
	perl test.pl

clean:
	rm -f ${PARSER_DIR}/*.pm
	rm -f ${PARSER_DIR}/*.output