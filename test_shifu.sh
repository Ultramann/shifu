. ./shifu

shifu_test_shell=$(ps -p $$ -o 'comm=')

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

shifu_run_test_root_cmd() {
  shifu_cmd_name root
  shifu_cmd_help Test root cmd help
  shifu_cmd_subs shifu_run_test_sub_one_cmd shifu_run_test_sub_two_cmd
}

shifu_run_test_sub_one_cmd() {
  shifu_cmd_name sub-one
  shifu_cmd_help Test sub one cmd help
  shifu_cmd_subs shifu_run_test_leaf_one_cmd shifu_run_test_leaf_two_cmd
}

shifu_run_test_sub_two_cmd() {
  shifu_cmd_name sub-two
  shifu_cmd_help Test sub two cmd help
  shifu_cmd_subs shifu_run_test_leaf_two_cmd shifu_run_test_leaf_four_cmd
}

shifu_run_test_leaf_one_cmd() {
  shifu_cmd_name leaf-one
  shifu_cmd_help Test leaf one cmd help
  shifu_cmd_func shifu_test_leaf_func_one
}

shifu_run_test_leaf_two_cmd() {
  shifu_cmd_name leaf-two
  shifu_cmd_help Test leaf two cmd help
  shifu_cmd_func shifu_test_leaf_func_two
}

shifu_run_test_leaf_three_cmd() {
  shifu_cmd_name leaf-three
  shifu_cmd_help Test leaf three cmd help
  shifu_cmd_func shifu_test_leaf_func_three
}

shifu_run_test_leaf_four_cmd() {
  shifu_cmd_name leaf-four
  shifu_cmd_help Test leaf four cmd help
  shifu_cmd_func shifu_test_leaf_func_four
}

shifu_test_leaf_func_one() {
  echo test leaf func one $# "$@"
}

shifu_test_leaf_func_two() {
  echo test leaf func two $# "$@"
}

shifu_test_leaf_func_three() {
  echo test leaf func three $# "$@"
}

shifu_test_leaf_func_four() {
  echo test leaf func four $# "$@"
}

test_shifu_run_good() {
  shifu_var_store expected actual
  shifu_root_cmds shifu_run_test_root_cmd
  expected="test leaf func two 2 one two"
  actual=$(shifu_run root sub-one leaf-two one two)
  shifu_assert_zero $#
  shifu_assert_equal "$expected" "$actual"
  shifu_var_restore expected actual
}

test_shifu_run_bad_root_cmd() {
  shifu_var_store expected actual
  shifu_root_cmds shifu_run_test_root_cmd
  expected="unknown command: bad"
  actual=$(shifu_run bad sub-one leaf-two one two)
  shifu_assert_non_zero $?
  shifu_assert_equal "$expected" "$actual"
  shifu_var_restore expected actual
}

test_shifu_run_bad_sub_cmd() {
  shifu_var_store expected actual
  shifu_root_cmds shifu_run_test_root_cmd
  expected="unknown command: sub-bad"
  actual=$(shifu_run root sub-bad leaf-two one two)
  shifu_assert_non_zero $?
  shifu_assert_equal "$expected" "$actual"
  shifu_var_restore expected actual
}

test_shifu_run_bad_leaf_cmd() {
  shifu_var_store expected actual
  shifu_root_cmds shifu_run_test_root_cmd
  expected="unknown command: leaf-bad"
  actual=$(shifu_run root sub-two leaf-bad one two)
  shifu_assert_non_zero $?
  shifu_assert_equal "$expected" "$actual"
  shifu_var_restore expected actual
}

parse_args_test_cmd_all() {
  shifu_arg -f -- flag_bin 0 1      "binary flag help"
  shifu_arg -a -- flag_arg          "flag argument help"
  shifu_arg -d -- flag_def def_flag "default argument flag help"
  shifu_arg --option-bin -- option_bin 0 1     "binary option help"
  shifu_arg --option-arg -- option_arg         "argument option help"
  shifu_arg --option-def -- option_def def_opt "default argument option help"
  shifu_arg -F --flag-option-bin -- flag_option_bin 0 1 "binary flag/option help"
  shifu_arg -A --flag-option-arg -- flag_option_arg     "argument flag/option help"
  shifu_arg -D --flag-option-def -- flag_option_def def_flag_opt \
                                    "default argument flag/option help"
  shifu_arg                      -- positional_arg "positional argument help"
  shifu_arg                      --                "remaining arguments help"
}

test_shifu_parse_args_all_set() {
  shifu_var_store flag_bin flag_arg flag_arg_d \
                  option_bin option_arg option_arg_d \
                  flag_option_bin flag_option_arg flag_option_arg_d
  shifu_parse_args parse_args_test_cmd_all \
                   -f \
                   -a flag_value \
                   -d not_default_flag_value \
                   --option-bin \
                   --option-arg option_value \
                   --option-def not_default_option_value \
                   --flag-option-bin \
                   --flag-option-arg flag_option_value \
                   -D not_default_flag_option_value \
                   positional_arg_value remaining arguments
  eval "set -- $shifu_remaining_args"
  shifu_assert_equal "$flag_bin" 1
  shifu_assert_equal "$flag_arg" "flag_value"
  shifu_assert_equal "$flag_def" "not_default_flag_value"
  shifu_assert_equal "$option_bin" 1
  shifu_assert_equal "$option_arg" "option_value"
  shifu_assert_equal "$option_def" "not_default_option_value"
  shifu_assert_equal "$flag_option_bin" 1
  shifu_assert_equal "$flag_option_arg" "flag_option_value"
  shifu_assert_equal "$flag_option_def" "not_default_flag_option_value"
  shifu_assert_equal "$positional_arg" "positional_arg_value"
  shifu_assert_equal $# 2
  shifu_assert_equal "$1" "remaining"
  shifu_assert_equal "$2" "arguments"
  shifu_var_restore flag_bin flag_arg flag_arg_d \
                    option_bin option_arg option_arg_d \
                    flag_option_bin flag_option_arg flag_option_arg_d
}

test_shifu_parse_args_all_unset() {
  shifu_var_store flag_bin flag_arg flag_arg_d \
                  option_bin option_arg option_arg_d \
                  flag_option_bin flag_option_arg flag_option_arg_d \
                  positional_arg
  shifu_parse_args parse_args_test_cmd_all positional_arg_value
  eval "set -- $shifu_remaining_args"
  shifu_assert_equal "$flag_bin" 0
  shifu_assert_zero_length "$flag_arg"
  shifu_assert_equal "$flag_def" "def_flag"
  shifu_assert_equal "$option_bin" 0
  shifu_assert_zero_length "$option_arg"
  shifu_assert_equal "$option_def" "def_opt"
  shifu_assert_equal "$flag_option_bin" 0
  shifu_assert_zero_length "$flag_option_arg"
  shifu_assert_equal "$flag_option_def" "def_flag_opt"
  shifu_assert_equal "$positional_arg" "positional_arg_value"
  shifu_assert_equal $# 0
  shifu_var_restore flag_bin flag_arg flag_arg_d \
                    option_bin option_arg option_arg_d \
                    flag_option_bin flag_option_arg flag_option_arg_d \
                    positional_arg
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

  shifu_read_test_functions
  n_tests=0
  n_passed=0
  n_failed=0
  for test_function in $test_functions; do
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

shifu_read_test_functions() {
  # 1: test script path
  test_functions=$(
    cat $(realpath $(basename $0)) | \
    # -r: extended regex, -n: don't echo lines to stdout
    sed -rn "/^(test_.*) ?\(\) {/!d;
            s/^(test_.*) ?\(\) {/\1/p"
  )
}


shifu_run_test_suite "$@"
