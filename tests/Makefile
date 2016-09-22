TESTS:=$(shell ls test-*.sh)
TESTS:=$(TESTS:test-%.sh=%)

OBSERVED:=$(TESTS:%=observed/%.stdout)
DIFFS:=$(TESTS:%=diffs/%)
REPORTS:=$(TESTS:%=report-%)

.DEFAULT: reports

SHELL:=/bin/bash

# debugging support
# OLD_SHELL := $(SHELL)
# SHELL = $(warning [$@ ($^) ($?)])$(OLD_SHELL)

print-%: ; @echo $* is $($*)
# end debugging support

TARGETS:=$(TESTS:%=observed/%.stdout) $(TESTS:%=diffs/%) \
  $(TESTS:%=report-%)

.PHONY: all reports clean

all: $(TARGETS)

clean:
	@rm -rf observed diffs

reports: $(REPORTS)

observed:
	@mkdir -p observed

observed/%.stdout: | observed
	@echo -n "running test $*:	"
	@/usr/bin/time -v -o observed/$*.time ./test-$*.sh > $@ 2> observed/$*.stderr
	@echo "OK"

diffs:
	@mkdir -p diffs

diffs/%: expected/%.stdout observed/%.stdout | diffs
	@diff $^ > $@

report-%: diffs/%
	@echo -n "checking $* output:	"
	@if [[ `wc -l < $<` -eq 0 ]] ; then echo "OK" ; else echo "FAIL" ; fi
