. ./shifu

# to see more color options run:
#   for c in {0..15}; do tput setaf $c; tput setaf $c | echo $c: text; done
shifu_grey="$(tput setaf 0)"
shifu_red="$(tput setaf 1)"
shifu_green="$(tput setaf 2)"
shifu_reset="$(tput sgr0)"

test_shifu_var_store_restore() {
  shifu_test_var_1="value"
  shifu_test_var_2="other"
  shifu_var_store shifu_test_var_1 shifu_test_var_2
  shifu_test_var_1="new"
  shifu_test_var_2="newer"
  shifu_var_restore shifu_test_var_1 shifu_test_var_2
  shifu_assert_zero status $?
  shifu_assert_strings_equal shifu_test_var_1 "$shifu_test_var_1" "value"
  shifu_assert_strings_equal shifu_test_var_2 "$shifu_test_var_2" "other"
  unset -v shifu_test_var_1
  unset -v shifu_test_var_2
}

test_shifu_var_store_shifu_var_fails() {
  bad_var=5
  shifu_bad_var_shifu="Shouldn't use this"
  error_message=$(shifu_var_store bad_var shifu_bad_var_shifu)
  shifu_assert_non_zero status $?
  shifu_assert_strings_equal error_message "$error_message" "Cannot use variable 'shifu_bad_var_shifu'"
  unset -v bad_var
  unset -v shifu_bad_var_shifu
  unset -v error_message
}

shifu_run_test_root_cmd() {
  shifu_cmd_name root
  shifu_cmd_help "Test root cmd help"
  shifu_cmd_subs shifu_run_test_sub_one_cmd shifu_run_test_sub_two_cmd

  shifu_arg -t --test -- intermediate_test false true "A test intermediate cmd arg."
}

shifu_run_test_sub_one_cmd() {
  shifu_cmd_name sub-one
  shifu_cmd_help "Test sub one cmd help"
  shifu_cmd_subs shifu_run_test_leaf_one_cmd shifu_run_test_leaf_two_cmd
}

shifu_run_test_sub_two_cmd() {
  shifu_cmd_name sub-two
  shifu_cmd_help "Test sub two cmd help"
  shifu_cmd_subs shifu_run_test_leaf_three_cmd shifu_run_test_leaf_four_cmd

  shifu_arg_global -g --global -- global_test false true "A test global cmd arg."
}

shifu_run_test_leaf_one_cmd() {
  shifu_cmd_name leaf-one
  shifu_cmd_help "Test leaf one cmd help"
  shifu_cmd_func shifu_test_leaf_func_one
}

shifu_run_test_leaf_two_cmd() {
  shifu_cmd_name leaf-two
  shifu_cmd_help "Test leaf two cmd help"
  shifu_cmd_func shifu_test_leaf_func_two
}

shifu_run_test_leaf_three_cmd() {
  shifu_cmd_name leaf-three
  shifu_cmd_help "Test leaf three cmd help"
  shifu_cmd_func shifu_test_leaf_func_three
}

shifu_run_test_leaf_four_cmd() {
  shifu_cmd_name leaf-four
  shifu_cmd_help "Test leaf four cmd help"
  shifu_cmd_func shifu_test_leaf_func_four
}

shifu_test_leaf_func_one() {
  echo test leaf func one $# "$@"
}

shifu_test_leaf_func_two() {
  leaf_two_args="$@"
}

shifu_test_leaf_func_three() {
  shifu_parse_args shifu_test_leaf_func_three_cmd "$@"
  eval "$shifu_shift_remaining"
  leaf_three_args="$@"
}

shifu_test_leaf_func_four() {
  echo test leaf func four $# "$@"
}

test_shifu_run_good() {
  shifu_var_store expected actual
  expected="test leaf func one 2 one two"
  actual=$(shifu_run_cmd shifu_run_test_root_cmd sub-one leaf-one one two)
  shifu_assert_zero status $#
  shifu_assert_equal output "$expected" "$actual"
  shifu_var_restore expected actual
}

test_shifu_run_good_cmd_intermediate_arg() {
  shifu_var_store intermediate_test leaf_two_args
  shifu_run_cmd shifu_run_test_root_cmd -t sub-one leaf-two one two
  shifu_assert_zero status $#
  shifu_assert_equal intermediate_test "$intermediate_test" true
  shifu_assert_equal leaf_two_args "$leaf_two_args" "one two"
  shifu_var_restore intermediate_test leaf_two_args
}

test_shifu_run_good_cmd_global_arg() {
  shifu_var_store global_test leaf_three_args
  shifu_run_cmd shifu_run_test_root_cmd sub-two leaf-three -g one two
  shifu_assert_zero status $#
  shifu_assert_equal global_test "$global_test" true
  shifu_assert_equal leaf_three_args "$leaf_three_args" "one two"
  shifu_var_restore global_test leaf_three_args
}

test_shifu_run_good_cmd_global_and_intermediate_arg() {
  shifu_var_store intermediate_test global_test leaf_three_args
  shifu_run_cmd shifu_run_test_root_cmd -t sub-two leaf-three -g one two
  shifu_assert_zero status $#
  shifu_assert_equal intermediate_test "$intermediate_test" true
  shifu_assert_equal global_test "$global_test" true
  shifu_assert_equal leaf_three_args "$leaf_three_args" "one two"
  shifu_var_restore intermediate_test global_test leaf_three_args
}

test_shifu_run_bad_first_cmd() {
  shifu_var_store expected actual
  expected="$(
    echo 'Unknown command: bad'
    printf 'Test root cmd help

Options
  -t, --test
    A test intermediate cmd arg. Set: true, default: false
  -h, --help
    Show this help'
  )"
  actual=$(shifu_run_cmd shifu_run_test_root_cmd bad sub-one leaf-two one two)
  shifu_assert_non_zero status $?
  shifu_assert_strings_equal error_message "$expected" "$actual"
  shifu_var_restore expected actual
}

test_shifu_run_bad_sub_cmd() {
  shifu_var_store expected actual
  expected="$(
    echo 'Unknown command: sub-bad'
    printf 'Test sub one cmd help

Options
  -h, --help
    Show this help'
  )"
  actual=$(shifu_run_cmd shifu_run_test_root_cmd sub-one sub-bad one two)
  shifu_assert_non_zero status $?
  shifu_assert_strings_equal error_message "$expected" "$actual"
  shifu_var_restore expected actual
}

test_shifu_run_bad_leaf_cmd() {
  shifu_var_store expected actual
  expected="$(
    echo 'Unknown command: leaf-bad'
    printf 'Test sub two cmd help

Options
  -g, --global
    A test global cmd arg. Set: true, default: false
  -h, --help
    Show this help'
  )"
  actual=$(shifu_run_cmd shifu_run_test_root_cmd sub-two leaf-bad one two)
  shifu_assert_non_zero status $?
  shifu_assert_strings_equal error_message "$expected" "$actual"
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
  shifu_assert_zero status $?
  shifu_assert_equal args_parsed "$_shifu_args_parsed" "1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1"
  shifu_assert_equal flag_bin "$flag_bin" 1
  shifu_assert_equal flag_arg "$flag_arg" "flag_value"
  shifu_assert_equal flag_def "$flag_def" "not_default_flag_value"
  shifu_assert_equal option_bin "$option_bin" 1
  shifu_assert_equal option_arg "$option_arg" "option_value"
  shifu_assert_equal option_def "$option_def" "not_default_option_value"
  shifu_assert_equal flag_option_bin "$flag_option_bin" 1
  shifu_assert_equal flag_option_arg "$flag_option_arg" "flag_option_value"
  shifu_assert_equal flag_option_def "$flag_option_def" "not_default_flag_option_value"
  shifu_assert_equal positional_arg "$positional_arg" "positional_arg_value"
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
  shifu_assert_zero status $?
  shifu_assert_equal args_parsed "$_shifu_args_parsed" "1"
  shifu_assert_equal flag_bin "$flag_bin" 0
  shifu_assert_empty flag_arg "$flag_arg"
  shifu_assert_equal flag_def "$flag_def" "def_flag"
  shifu_assert_equal option_bin "$option_bin" 0
  shifu_assert_empty option_arg "$option_arg"
  shifu_assert_equal option_def "$option_def" "def_opt"
  shifu_assert_equal flag_option_bin "$flag_option_bin" 0
  shifu_assert_empty flag_option_arg "$flag_option_arg"
  shifu_assert_equal flag_option_def "$flag_option_def" "def_flag_opt"
  shifu_assert_equal positional_arg "$positional_arg" "positional_arg_value"
  shifu_assert_equal array_length $# 0
  shifu_var_restore flag_bin flag_arg flag_arg_d \
                    option_bin option_arg option_arg_d \
                    flag_option_bin flag_option_arg flag_option_arg_d \
                    positional_arg
}

test_shifu_parse_args_invalid_option() {
  shifu_var_store expected actual
  expected=$(
    echo 'Invalid option: --invalid'
    printf 'Test root cmd help

Options
  -t, --test
    A test intermediate cmd arg. Set: true, default: false
  -h, --help
    Show this help'
  )
  actual=$(shifu_parse_args shifu_run_test_root_cmd --invalid other -t)
  shifu_assert_strings_equal error_message "$expected" "$actual"
  shifu_var_restore expected actual
}

# Testing utilities
shifu_assert_empty() {
  # 1: identifier, 2: value
  [ -z "$2" ] && return
  shifu_report_context "$1: expected empty, got" "${#1}"
  errors=$(($errors + 1))
}

shifu_assert_zero() {
  # 1: identifier, 2: value
  [ $2 = 0 ] && return
  shifu_report_context "$1, expected zero value, got" $1
  errors=$(($errors + 1))
}

shifu_assert_non_zero() {
  # 1: identifier, 2: value
  [ $2 != 0 ] && return
  shifu_report_context "$1: expected non-zero value, got" $1
  errors=$(($errors + 1))
}

shifu_assert_equal() {
  # 1: identifier, 2: first, 3: second
  [ "$2" = "$3" ] && return
  shifu_report_context "$1: expected values to be equal, got" "${2:-<empty>}" "${3:-<empty>}"
  errors=$(($errors + 1))
}

shifu_assert_strings_equal() {
  # 1: identifier, 2: first, 3: second
  shifu_assert_equal "$1" "\"$2\"" "\"$3\""
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

  [ $# -gt 0 ] && [ "$1" = "-v" ] && { shifu_verbose_tests=true; shift; }

  if [ $# -gt 0 ]; then
    test_functions="$@"
  else
    shifu_read_test_functions
  fi
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
  exit $n_failed
}

shifu_read_test_functions() {
  # 1: test script path
  test_functions=$(
    cat "$this_script" | \
    # -r: extended regex, -n: don't echo lines to stdout
    sed -rn "/^(test_.*) ?\(\) {/!d;
            s/^(test_.*) ?\(\) {/\1/p"
  )
}

this_script=$(realpath $(basename "$0"))  # at global for zsh compatibility
shifu_run_test_suite "$@"
