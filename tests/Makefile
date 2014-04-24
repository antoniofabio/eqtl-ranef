TESTS:=000 001

TARGETS:=$(TESTS:%=observed/%.stdout) $(TESTS:%=diffs/%) \
  $(TESTS:%=report-%)

SHELL:="/bin/bash"

.PHONY: all reports clean

all: $(TARGETS)

clean:
	@rm -rf observed diffs

reports: $(TESTS:%=report-%)

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
