demo:
	vhs assets/demo.tape

test-all:
	@if [ -n "$$(which ksh)" ]; then \
	echo "\n===========================  ksh   ============================"; \
	ksh test_shifu.sh ${VERBOSE}; \
	fi
	@if [ -n "$$(which dash)" ]; then \
	echo "\n===========================  dash  ============================"; \
	dash test_shifu.sh ${VERBOSE}; \
	fi
	@if [ -n "$$(which bash)" ]; then \
	echo "\n===========================  bash  ============================"; \
	bash test_shifu.sh ${VERBOSE}; \
	fi
	@if [ -n "$$(which zsh)" ]; then \
	echo "\n===========================  zsh   ============================"; \
	zsh test_shifu.sh ${VERBOSE}; \
	fi
	@echo


test-all-verbose: VERBOSE=-v
test-all-verbose: test-all
