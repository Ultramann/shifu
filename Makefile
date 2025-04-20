run-fake:
	./fake-cli test sub func "sh*" arg1 arg2

run-fake-log:
	./fake-cli --shifu-log test sub func "sh*" arg1 arg2

test-all:
	@if [ -n "$$(which ash)" ]; then \
	echo "\n===========================  ash   ============================"; \
	ash test_shifu.sh ${VERBOSE}; \
	fi
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
	@echo


test-all-verbose: VERBOSE=-v
test-all-verbose: test-all
