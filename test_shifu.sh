. ./shifu

shifu_test_shell=$(ps -p $$ -o 'comm=')

shifu_read_test_functions() {
  # 1: test script path
  test_functions=$(
    cat "$1" | \
    # -r: extended regex, -n: don't echo lines to stdout
    sed -rn "/^(test_.*) ?\(\) {/!d;
            s/^(test_.*) ?\(\) {/\1/p"
  )
}

shifu_report_success() {
  # 1: function name
  if [ "$shifu_verbose_tests" = true ]; then
    printf "$shifu_green%-7s$shifu_reset%s\n" pass "$1"
  fi
}

shifu_report_failure() {
  # 1: function name
  printf "$shifu_red%-7s$shifu_reset%s\n" fail "$1"
}

shifu_report_context() {
  # 1: header
  printf "$shifu_grey%7s%s$shifu_reset\n" "" "$1"; shift
  shifu_var_store argument
  for argument in "$@"; do
    printf "$shifu_grey%10s%s$shifu_reset\n" "" "$argument"
  done
  shifu_var_restore argument
}

shifu_assert_impossible() {
  shifu_report_context "This code path should not be reached"
  errors=$(($errors + 1))
}

shifu_assert_zero_length() {
  # 1: value
  [ -z "$1" ] && return
  shifu_report_context "Expected length zero, got" "${#1}"
  errors=$(($errors + 1))
}

shifu_assert_zero() {
  # 1: value
  [ $1 = 0 ] && return
  shifu_report_context "Expected zero return code, got" $1
  errors=$(($errors + 1))
}

shifu_assert_non_zero() {
  # 1: value
  [ $1 != 0 ] && return
  shifu_report_context "Expected non-zero return code, got" $1
  errors=$(($errors + 1))
}

shifu_assert_equal() {
  # 1: first, 2: second
  [ "$1" = "$2" ] && return
  shifu_report_context "Expected values to be equal, got" "${1:-<empty>}" "${2:-<empty>}"
  errors=$(($errors + 1))
}

shifu_assert_strings_equal() {
  # 1: first, 2: second
  shifu_assert_equal "\"$1\"" "\"$2\""
}

var_store_restore_test_func() {
  shifu_var_store shifu_test_var_1 shifu_test_var_2
  shifu_test_var_1="new"
  shifu_test_var_2="newer"
  shifu_var_restore shifu_test_var_1 shifu_test_var_2
}

test_shifu_var_store_restore() {
  shifu_test_var_1="value"
  shifu_test_var_2="other"
  var_store_restore_test_func
  shifu_assert_strings_equal "$shifu_test_var_1" "value"
  shifu_assert_strings_equal "$shifu_test_var_2" "other"
}

test_shifu_iterate() {
  shifu_var_store actual expected
  actual=$(shifu_iterate "*sh two three")
  expected=$(printf "*sh\ntwo\nthree")
  shifu_assert_strings_equal "$actual" "$expected"
  shifu_var_store actual expected
}

test_shifu_array_length() {
  shifu_var_store actual expected
  actual=$(shifu_array_length "$(shifu_iterate "arg* other arg3")")
  expected=3
  shifu_assert_equal $actual $expected
  shifu_var_restore actual expected
}

test_shifu_array_append() {
  shifu_var_store actual actual_length expected expected_length
  actual=$(shifu_array_append "$(shifu_iterate "arg other arg3")" "new")
  actual_length=$(shifu_array_length "$actual")
  expected="$(shifu_iterate "arg other arg3 new")"
  expected_length=$(shifu_array_length "$expected")
  shifu_assert_equal $actual_length $expected_length
  shifu_assert_strings_equal "$actual" "$expected"
  shifu_var_restore actual actual_length expected expected_length
}

test_shifu_array_append_empty() {
  shifu_var_store actual actual_length expected expected_length
  actual=$(shifu_array_append "$(shifu_iterate "")" "new")
  actual_length=$(shifu_array_length "$actual")
  expected="$(shifu_iterate "new")"
  expected_length=$(shifu_array_length "$expected")
  shifu_assert_equal $actual_length $expected_length
  shifu_assert_strings_equal "$actual" "$expected"
  shifu_var_restore actual actual_length expected expected_length
}

test_shifu_array_contains_true() {
  shifu_var_store acutal expected
  actual=$(shifu_array_contains "$(shifu_iterate "arg other arg3")" "arg")
  expected=true
  shifu_assert_equal "$actual" "$expected"
  shifu_var_restore acutal expected
}

test_shifu_array_contains_false() {
  shifu_var_store acutal expected
  actual=$(shifu_array_contains "$(shifu_iterate "arg other arg3")" "nope")
  expected=false
  shifu_assert_equal "$actual" "$expected"
  shifu_var_restore acutal expected
}

test_shifu_array_filter_prefix() {
  shifu_var_store actual actual_length expected expected_length
  actual=$(shifu_array_filter_prefix "$(shifu_iterate "arg other arg3")" "arg")
  actual_length=$(shifu_array_length "$actual")
  expected="$(shifu_iterate "arg arg3")"
  expected_length=$(shifu_array_length "$expected")
  shifu_assert_equal $actual_length $expected_length
  shifu_assert_strings_equal "$actual" "$expected"
  shifu_var_restore actual actual_length expected expected_length
}

test_shifu_array_filter_prefix_empty_prefix() {
  shifu_var_store actual actual_length expected expected_length
  actual=$(shifu_array_filter_prefix "$(shifu_iterate "arg other arg3")" "")
  actual_length=$(shifu_array_length "$actual")
  expected="$(shifu_iterate "arg other arg3")"
  expected_length=$(shifu_array_length "$expected")
  shifu_assert_equal $actual_length $expected_length
  shifu_assert_strings_equal "$actual" "$expected"
  shifu_var_restore actual actual_length expected expected_length
}

test_shifu_determine_function_to_call() {
  shifu_var_store script_functions function_to_call arguments_in_function status
  script_functions="$(shifu_iterate "test_ test_sub_ test_sub_func")"
  shifu_determine_function_to_call test sub func arg1 arg2; status=$?
  shifu_assert_zero $status
  shifu_assert_strings_equal "$function_to_call" "test_sub_func"
  shifu_assert_strings_equal "$arguments_in_function" "test sub func"
  shifu_var_restore script_functions function_to_call arguments_in_function status
}

test_shifu_infer_function_with_underscore_arguments() {
  shifu_var_store script_functions function_to_call arguments_in_function status
  script_functions="$(shifu_iterate "test_ test_sub_ test_sub_func")"
  shifu_determine_function_to_call test_sub func arg1 arg2; status=$?
  shifu_assert_zero $status
  shifu_assert_strings_equal "$function_to_call" "test_sub_func"
  shifu_assert_strings_equal "$arguments_in_function" "test_sub func"
  shifu_var_restore script_functions function_to_call arguments_in_function status
}

test_shifu_infer_function_and_arguments_only_subcommand() {
  shifu_var_store script_functions function_to_call arguments_in_function status
  script_functions="$(shifu_iterate "test_ test_sub_ test_sub_func")"
  shifu_determine_function_to_call test sub arg1 arg2; status=$?
  shifu_assert_non_zero $status
  shifu_assert_strings_equal "$function_to_call" ""
  shifu_assert_strings_equal "$arguments_in_function" ""
  shifu_var_restore script_functions function_to_call arguments_in_function status
}

test_shifu_function_to_call_argument_length() {
  shifu_var_store arguments_in_function
  arguments_in_function="arg1 arg2 arg3_arg4"
  shifu_assert_equal $(shifu_function_to_call_argument_length) 3
  shifu_var_restore arguments_in_function
}

test_shifu_invalid_variable_name() {
  if shifu_invalid_variable_name good_var_name; then
    shifu_assert_impossible
  fi
  shifu_invalid_variable_name bad-var-name
  shifu_assert_non_zero $?
}

test_shifu_arg_oa_set() {
  shifu_var_store shifu_mode shifu_parsed shifu_one shifu_two test_option
  shifu_mode="$shifu_mode_init"
  shifu_arg_oa test-option test_option
  shifu_mode="$shifu_mode_parse"
  shifu_parsed=0
  shifu_one="--test-option"
  shifu_two="option_value"
  shifu_arg_oa test-option test_option
  shifu_assert_equal "$test_option" "option_value"
  shifu_assert_equal "$shifu_parsed" 2
  shifu_var_restore shifu_mode shifu_parsed shifu_one shifu_two test_option
}

test_shifu_arg_oa_unset() {
  shifu_var_store shifu_mode shifu_parsed shifu_one shifu_two test_option
  shifu_mode="$shifu_mode_init"
  shifu_arg_oa test-option test_option
  shifu_mode="$shifu_mode_parse"
  shifu_parsed=0
  shifu_one="--random-option"
  shifu_two="option_value"
  shifu_arg_oa test-option test_option
  shifu_assert_zero_length "$test_option"
  shifu_assert_equal "$shifu_parsed" 0
  shifu_var_restore shifu_mode shifu_parsed shifu_one shifu_two test_option
}

test_shifu_arg_ob_set() {
  shifu_var_store shifu_mode shifu_parsed shifu_one test_option
  shifu_mode="$shifu_mode_init"
  shifu_arg_ob test-option test_option true
  shifu_mode="$shifu_mode_parse"
  shifu_parsed=0
  shifu_one="--test-option"
  shifu_arg_ob test-option test_option true
  shifu_assert_equal "$test_option" true
  shifu_assert_equal "$shifu_parsed" 1
  shifu_var_restore shifu_mode shifu_parsed shifu_one test_option
}

test_shifu_arg_ob_unset() {
  shifu_var_store shifu_mode shifu_parsed shifu_one test_option
  shifu_mode="$shifu_mode_init"
  shifu_arg_ob test-option test_option true
  shifu_mode="$shifu_mode_parse"
  shifu_parsed=0
  shifu_one="--random-option"
  shifu_arg_ob test-option test_option true
  shifu_assert_equal "$test_option" false
  shifu_assert_equal "$shifu_parsed" 0
  shifu_var_restore shifu_mode shifu_parsed shifu_one test_option
}

test_shifu_arg_ob_bad_set() {
  shifu_var_store shifu_mode shifu_one test_option message
  shifu_mode="$shifu_mode_init"
  message=$(shifu_arg_ob test-option test_option bad)
  shifu_assert_non_zero $?
  shifu_assert_equal "$message" "Set value expected to be boolean, got: bad"
  shifu_var_restore shifu_mode shifu_one test_option message
}

parse_args_test__shifu() {
  shifu_arg_ob option-binary option_binary true "binary option help"
  shifu_arg_oa option-argument option_argument "argument option help"
}

test_shifu_parse_args_set() {
  shifu_var_store option_binary option_argument
  shifu_parse_args parse_args_test__shifu \
                   --option-binary \
                   --option-argument option_value
  shifu_assert_equal "$option_binary" true
  shifu_assert_equal "$option_argument" "option_value"
  shifu_var_restore option_binary option_argument
}

test_shifu_parse_args_unset() {
  shifu_var_store option_binary option_argument
  shifu_parse_args parse_args_test__shifu
  shifu_assert_equal "$option_binary" false
  shifu_assert_zero_length "$test_option"
  shifu_var_restore option_binary option_argument
}

shifu_run_test() {
  # 1: test function
  errors=0  # doesn't need to be stored/restored because always run in subshell
  $1 2> /dev/null
  return $errors
}

shifu_run_test_and_report() {
  # 1: test function
  shifu_var_store test_message test_result
  test_message=$(shifu_run_test "$1")
  test_result=$?
  if [ "$test_result" -eq 0 ]; then
    n_passed=$(($n_passed + 1))
    shifu_report_success "$1"
  else
    n_failed=$(($n_failed + 1))
    shifu_report_failure "$1"
    echo "$test_message"
  fi
  n_tests=$(($n_tests + 1))
  shifu_var_restore test_message test_result
}

shifu_run_test_suite() {
  # global variables only in this function because it is "main"

  [ $# -gt 0 ] && [ "$1" = "-v" ] && shifu_verbose_tests=true

  shifu_read_test_functions $(shifu_caller_script)
  n_tests=0
  n_passed=0
  n_failed=0
  for test_function in $(shifu_iterate "$test_functions"); do
    shifu_run_test_and_report "$test_function"
  done

  percent_passed=$(echo "scale=2; $n_passed * 100 / $n_tests" | bc)
  if [ $n_failed -eq 0 ]; then
    color="$shifu_green"
    percent_passed=100.0
  else
    color="$shifu_red"
  fi
  test_report="$percent_passed% tests passed"
  echo "==================== $color $test_report $shifu_reset ===================="
  exit $failures
}

shifu_run_test_suite "$@"
