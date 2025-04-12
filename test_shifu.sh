. ./shifu

shifu_test_function_declaration='^(test_.*) ?\(\) {'
shifu_read_test_functions() {
  local test_script_path=$1
  test_functions=$(
    cat "$test_script_path" | \
    # -r: extended regex, -n: don't echo lines to stdout
    sed -rn "/$shifu_test_function_declaration/!d;
            s/$shifu_test_function_declaration/\1/p"
  )
}

shifu_report_success() {
  if [ "$shifu_verbose_tests" = true ]; then
    printf "$shifu_green%-10s$shifu_reset%s\n" success $1
  fi
}

shifu_report_failure() {
  printf "$shifu_red%-10s$shifu_reset%s\n" fail $1
}

shifu_report_context() {
  local header=$1; shift
  printf "$shifu_grey%10s%s$shifu_reset\n" "" "$header"
  local arg
  for arg in "$@"; do
    printf "$shifu_grey%12s%s$shifu_reset\n" "" "$arg"
  done
}

shifu_assert_zero() {
  local value=$1
  local header="Expected zero return code, got"
  [ $value = 0 ] && return
  shifu_report_context "$header" $value
  errors=$(($errors + 1))
}

shifu_assert_non_zero() {
  local value=$1
  local header="Expected non-zero return code, got"
  [ $value != 0 ] && return
  shifu_report_context "$header" $value
  errors=$(($errors + 1))
}

shifu_assert_equal() {
  local one="${1:-<empty>}"
  local two="${2:-<empty>}"
  local header="Expected values to be equal, got"
  [ "$one" = "$two" ] && return
  shifu_report_context "$header" $one $two
  errors=$(($errors + 1))
}

shifu_assert_strings_equal() {
  shifu_assert_equal "\"$1\"" "\"$2\""
}

test_shifu_iterate() {
  local actual=$(shifu_iterate "*sh two three")
  local expected=$(printf "*sh\ntwo\nthree")

  shifu_assert_strings_equal "$actual" "$expected"
}

test_shifu_array_length() {
  local in_array="$(shifu_iterate "arg* other arg3")"

  local actual=$(shifu_array_length "$in_array")

  local expected=3

  shifu_assert_equal $actual $expected
}

test_shifu_array_append() {
  local in_array="$(shifu_iterate "arg other arg3")"

  local actual=$(shifu_array_append "$in_array" "new")
  local actual_array_length=$(shifu_array_length "$actual")

  local expected="$(shifu_iterate "arg other arg3 new")"
  local expected_array_length=$(shifu_array_length "$expected")

  shifu_assert_equal $actual_array_length $expected_array_length
  shifu_assert_strings_equal "$actual" "$expected"
}

test_shifu_array_append_empty() {
  local in_array="$(shifu_iterate "")"

  local actual=$(shifu_array_append "$in_array" "new")
  local actual_array_length=$(shifu_array_length "$actual")

  local expected="$(shifu_iterate "new")"
  local expected_array_length=$(shifu_array_length "$expected")

  shifu_assert_equal $actual_array_length $expected_array_length
  shifu_assert_strings_equal "$actual" "$expected"
}

test_shifu_array_contains() {
  local in_array="$(shifu_iterate "arg other arg3")"

  local actual=$(shifu_array_contains "$in_array" "arg")

  local expected=true

  shifu_assert_equal "$actual" "$expected"
}

test_shifu_array_filter_prefix() {
  local in_array="$(shifu_iterate "arg other arg3")"

  local actual=$(shifu_array_filter_prefix "$in_array" "arg")
  local actual_array_length=$(shifu_array_length "$actual")

  local expected="$(shifu_iterate "arg arg3")"
  local expected_array_length=$(shifu_array_length "$expected")

  shifu_assert_equal $actual_array_length $expected_array_length
  shifu_assert_strings_equal "$actual" "$expected"
}

test_shifu_array_filter_prefix_empty_prefix() {
  local in_array="$(shifu_iterate "arg other arg3")"

  local actual="$(shifu_array_filter_prefix "$in_array" "")"
  local actual_array_length=$(shifu_array_length "$actual")

  local expected="$(shifu_iterate "arg other arg3")"
  local expected_array_length=$(shifu_array_length "$expected")

  shifu_assert_equal $actual_array_length $expected_array_length
  shifu_assert_strings_equal "$actual" "$expected"
}

test_shifu_infer_function_to_call() {
  local script_functions="$(shifu_iterate "test_ test_sub_ test_sub_func")"

  local expected_function_to_call="test_sub_func"

  shifu_infer_function_to_call test sub func arg1 arg2; local status=$?

  shifu_assert_zero $status
  shifu_assert_strings_equal "$function_to_call" "$expected_function_to_call"
}

test_shifu_infer_function_and_glob_arguments() {
  shifu_report_context "TODO: test not implemented"
  errors=1
}

test_shifu_infer_function_and_arguments_only_subcommand() {
  local script_functions="$(shifu_iterate "test_ test_sub_ test_sub_func")"

  local expected_function_to_call=""

  shifu_infer_function_to_call test sub arg1 arg2; local status=$?

  shifu_assert_non_zero $status
  shifu_assert_strings_equal "$function_to_call" "$expected_function_to_call"
}

shifu_run_test() {
  local test_function=$1
  local errors=0
  "$test_function" 2> /dev/null
  return $errors
}

shifu_run_test_and_report() {
  local test_function=$1
  message=$(shifu_run_test "$test_function")
  local test_result=$?
  if [ "$test_result" -eq 0 ]; then
    shifu_report_success "$test_function"
  else
    shifu_report_failure "$test_function"
    echo "$message"
  fi
  return ${test_result}
}

shifu_run_test_suite() {
  [ $# -gt 0 ] && [ $1 = "-v" ] && shifu_verbose_tests=true
  shifu_read_test_functions $(shifu_caller_script)
  local failures=0
  local total=0
  for test_function in $(shifu_iterate "$test_functions"); do
    shifu_run_test_and_report "$test_function"
    failures=$(($failures + $?))
    total=$(($total + 1))
  done
  local successs=$(($total - $failures))
  local successful=$(echo "scale=2; $successs * 100 / $total" | bc)
  if [ $failures -eq 0 ]; then
    local color="$shifu_green"
  else
    local color="$shifu_red"
  fi
  local test_report="Tests $successful% successful"
  echo "============== $color $test_report $shifu_reset =============="
  exit $failures
}

shifu_run_test_suite $@
