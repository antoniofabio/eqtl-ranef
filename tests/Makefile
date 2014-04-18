TESTS:=000

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
	@echo running test $*
	@./test-$*.sh > $@ 2> observed/$*.stderr

diffs:
	@mkdir -p diffs

diffs/%: expected/%.stdout observed/%.stdout | diffs
	@diff $^ > $@

report-%: diffs/%
	@echo -n $*":	"
	@if [[ `wc -l < $<` -eq 0 ]] ; then echo "OK" ; else echo "FAIL" ; fi
