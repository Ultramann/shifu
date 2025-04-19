. ./shifu

shifu_test_function_declaration='^(test_.*) ?\(\) {'
shifu_read_test_functions() {
  local test_script_path="$1"
  test_functions=$(
    cat "$test_script_path" | \
    # -r: extended regex, -n: don't echo lines to stdout
    sed -rn "/$shifu_test_function_declaration/!d;
            s/$shifu_test_function_declaration/\1/p"
  )
}

shifu_report_success() {
  if [ "$shifu_verbose_tests" = true ]; then
    printf "$shifu_green%-7s$shifu_reset%s\n" pass $1
  fi
}

shifu_report_failure() {
  printf "$shifu_red%-7s$shifu_reset%s\n" fail $1
}

shifu_report_context() {
  local header="$1"; shift
  printf "$shifu_grey%7s%s$shifu_reset\n" "" "$header"
  local argument
  for argument in "$@"; do
    printf "$shifu_grey%10s%s$shifu_reset\n" "" "$argument"
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

test_shifu_determine_function_to_call() {
  local script_functions="$(shifu_iterate "test_ test_sub_ test_sub_func")"

  local expected_function_to_call="test_sub_func"
  local expected_arguments_in_function="test sub func"

  local function_to_call
  local arguments_in_function
  shifu_determine_function_to_call test sub func arg1 arg2; local status=$?

  shifu_assert_zero $status
  shifu_assert_strings_equal "$function_to_call" "$expected_function_to_call"
  shifu_assert_strings_equal "$arguments_in_function" "$expected_arguments_in_function"
}

test_shifu_infer_function_with_underscore_arguments() {
  local script_functions="$(shifu_iterate "test_ test_sub_ test_sub_func")"

  local expected_function_to_call="test_sub_func"
  local expected_arguments_in_function="test_sub func"

  local function_to_call
  local arguments_in_function
  shifu_determine_function_to_call test_sub func arg1 arg2; local status=$?

  shifu_assert_zero $status
  shifu_assert_strings_equal "$function_to_call" "$expected_function_to_call"
  shifu_assert_strings_equal "$arguments_in_function" "$expected_arguments_in_function"
}

test_shifu_infer_function_and_arguments_only_subcommand() {
  local script_functions="$(shifu_iterate "test_ test_sub_ test_sub_func")"

  local expected_function_to_call=""
  local expected_arguments_in_function=""

  local function_to_call
  local arguments_in_function
  shifu_determine_function_to_call test sub arg1 arg2; local status=$?

  shifu_assert_non_zero $status
  shifu_assert_strings_equal "$function_to_call" "$expected_function_to_call"
  shifu_assert_strings_equal "$arguments_in_function" "$expected_arguments_in_function"
}

test_shifu_function_to_call_argument_length() {
  local arguments_in_function="arg1 arg2 arg3_arg4"

  local actual=$(shifu_function_to_call_argument_length)

  local expected=3

  shifu_assert_equal $actual $expected
}

shifu_run_test() {
  local test_function="$1"
  local errors=0
  "$test_function" 2> /dev/null
  return $errors
}

shifu_run_test_and_report() {
  local test_function="$1"
  message=$(shifu_run_test "$test_function")
  local test_result=$?
  if [ "$test_result" -eq 0 ]; then
    shifu_report_success "$test_function"
  else
    shifu_report_failure "$test_function"
    echo "$message"
  fi
  return $test_result
}

shifu_run_test_suite() {
  [ $# -gt 0 ] && [ "$1" = "-v" ] && shifu_verbose_tests=true

  local test_functions
  shifu_read_test_functions $(shifu_caller_script)

  local n_failed=0
  local n_tests=0
  for test_function in $(shifu_iterate "$test_functions"); do
    shifu_run_test_and_report "$test_function"
    n_failed=$(($n_failed + $?))
    n_tests=$(($n_tests + 1))
  done

  local n_passed=$(($n_tests - $n_failed))
  local percent_passed=$(echo "scale=2; $n_passed * 100 / $n_tests" | bc)
  if [ $n_failed -eq 0 ]; then
    local color="$shifu_green"
  else
    local color="$shifu_red"
  fi
  local test_report="$percent_passed% tests passed"
  echo "================ $color $test_report $shifu_reset ================"
  exit $failures
}

shifu_run_test_suite "$@"
