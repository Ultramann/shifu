. ./shifu

set -u

# to see more color options run:
#   for c in {0..15}; do tput setaf $c; tput setaf $c | echo $c: text; done
shifu_grey="$(tput setaf 0)"
shifu_red="$(tput setaf 1)"
shifu_green="$(tput setaf 2)"
shifu_reset="$(tput sgr0)"

shifu_test_root_cmd() {
  shifu_cmd_name root
  shifu_cmd_help "Test root cmd help"
  shifu_cmd_subs shifu_test_sub_one_cmd shifu_test_sub_two_cmd

  shifu_cmd_arg_loc -l --local-test -- local_test false true "A test local cmd arg"
}

shifu_test_sub_one_cmd() {
  shifu_cmd_name sub-one
  shifu_cmd_help "Test sub one cmd help"
  shifu_cmd_subs shifu_test_leaf_one_cmd shifu_test_leaf_two_cmd
}

shifu_test_sub_two_cmd() {
  shifu_cmd_name sub-two
  shifu_cmd_help "Test sub two cmd help"
  shifu_cmd_subs shifu_test_leaf_three_cmd shifu_test_leaf_four_cmd

  shifu_cmd_arg -g --global -- global_test false true "A test global cmd arg"
}

shifu_test_leaf_one_cmd() {
  shifu_cmd_name leaf-one
  shifu_cmd_help "Test leaf one cmd help"
  shifu_cmd_func shifu_test_leaf_func_one
}

shifu_test_leaf_two_cmd() {
  shifu_cmd_name leaf-two
  shifu_cmd_help "Test leaf two cmd help"
  shifu_cmd_func shifu_test_leaf_func_two
}

shifu_test_leaf_three_cmd() {
  shifu_cmd_name leaf-three
  shifu_cmd_help "Test leaf three cmd help"
  shifu_cmd_func shifu_test_leaf_three_func
}

shifu_test_leaf_four_cmd() {
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

shifu_test_leaf_three_func() {
  leaf_three_args="$@"
}

shifu_test_leaf_func_four() {
  echo test leaf func four $# "$@"
}

shifu_test_all_options_cmd() {
  shifu_cmd_name all
  shifu_cmd_help "Test cmd all help"
  shifu_cmd_long "These are all the fancy things you can do with the all command"
  shifu_cmd_func no_op

  shifu_cmd_arg -f -- FLAG_BIN 0 1      "binary flag help"
  shifu_cmd_arg -a -- FLAG_ARG          "flag argument help"
  shifu_cmd_arg -d -- FLAG_DEF def_flag "default argument flag help"
  shifu_cmd_arg --option-bin -- OPTION_BIN 0 1     "binary option help"
  shifu_cmd_arg --option-arg -- OPTION_ARG         "argument option help"
  shifu_cmd_arg --option-def -- OPTION_DEF def_opt "default argument option help"
  shifu_cmd_arg -F --flag-option-bin -- FLAG_OPTION_BIN 0 1 "binary flag/option help"
  shifu_cmd_arg -A --flag-option-arg -- FLAG_OPTION_ARG     "argument flag/option help"
  shifu_cmd_arg_comp_enum flag option arg
  shifu_cmd_arg -D --flag-option-def -- FLAG_OPTION_DEF def_flag_opt \
                                    "default argument flag/option help"
  shifu_cmd_arg_comp_func make_fake_option_completions
  shifu_cmd_arg                      -- POSITIONAL_ARG_1 "positional argument one help"
  shifu_cmd_arg_comp_enum positional arg one
  shifu_cmd_arg                      -- POSITIONAL_ARG_2 "positional argument two help"
  shifu_cmd_arg_comp_func make_fake_positional_completions
  shifu_cmd_arg                      --                  "remaining arguments help"
  shifu_cmd_arg_comp_func make_fake_remaining_completions
}

no_op() {
  echo "" > /dev/null
}

make_fake_option_completions() {
  shifu_add_completions flag option default
}

make_fake_positional_completions() {
  shifu_add_completions positional arg two
}

make_fake_remaining_completions() {
  shifu_add_completions remaining args
}

test_shifu_run_good() {
  expected="test leaf func one 2 one two"
  actual=$(shifu_run shifu_test_root_cmd sub-one leaf-one one two 2>&1)
  shifu_assert_zero exit_code $?
  shifu_assert_strings_equal output "$expected" "$actual"
}

test_shifu_run_good_cmd_global_arg() {
  shifu_run shifu_test_root_cmd sub-two leaf-three -g one two
  shifu_assert_zero exit_code $?
  shifu_assert_equal global_test "$global_test" true
  shifu_assert_equal leaf_three_args "$leaf_three_args" "one two"
}

test_shifu_run_good_cmd_global_and_local_arg() {
  shifu_run shifu_test_root_cmd -l sub-two leaf-three -g one two
  shifu_assert_zero exit_code $?
  shifu_assert_equal local_test "$local_test" true
  shifu_assert_equal global_test "$global_test" true
  shifu_assert_equal leaf_three_args "$leaf_three_args" "one two"
}

test_shifu_run_bad_first_cmd() {
  expected="$(
    echo 'Unknown command: bad'
    printf 'Test root cmd help

Subcommands
  sub-one
    Test sub one cmd help
  sub-two
    Test sub two cmd help

Options
  -l, --local-test
    A test local cmd arg
    Default: false, set: true
  -h, --help
    Show this help'
  )"
  actual=$(shifu_run shifu_test_root_cmd bad sub-one leaf-two one two 2>&1)
  shifu_assert_non_zero exit_code $?
  shifu_assert_strings_equal error_message "$expected" "$actual"
}

test_shifu_run_bad_sub_cmd() {
  expected="$(
    echo 'Unknown command: sub-bad'
    printf 'Test sub one cmd help

Subcommands
  leaf-one
    Test leaf one cmd help
  leaf-two
    Test leaf two cmd help

Options
  -h, --help
    Show this help'
  )"
  actual=$(shifu_run shifu_test_root_cmd sub-one sub-bad one two 2>&1)
  shifu_assert_non_zero exit_code $?
  shifu_assert_strings_equal error_message "$expected" "$actual"
}

test_shifu_run_bad_leaf_cmd() {
  expected="$(
    echo 'Unknown command: leaf-bad'
    printf 'Test sub two cmd help

Subcommands
  leaf-three
    Test leaf three cmd help
  leaf-four
    Test leaf four cmd help

Options
  -h, --help
    Show this help'
  )"
  actual=$(shifu_run shifu_test_root_cmd sub-two leaf-bad one two 2>&1)
  shifu_assert_non_zero exit_code $?
  shifu_assert_strings_equal error_message "$expected" "$actual"
}

test_shifu_run_args_all_set() {
  shifu_run shifu_test_all_options_cmd \
                   -f \
                   -a flag_value \
                   -d not_default_flag_value \
                   --option-bin \
                   --option-arg option_value \
                   --option-def not_default_option_value \
                   --flag-option-bin \
                   --flag-option-arg flag_option_value \
                   -D not_default_flag_option_value \
                   positional_arg_value_one positional_arg_value_two \
                   remaining arguments
  shifu_assert_zero exit_code $?
  # this acts as a proxy test for shifu_align_args, since we don't have $@ here
  shifu_assert_equal args_parsed $_shifu_args_parsed 17
  shifu_assert_equal flag_bin "$FLAG_BIN" 1
  shifu_assert_equal flag_arg "$FLAG_ARG" "flag_value"
  shifu_assert_equal flag_def "$FLAG_DEF" "not_default_flag_value"
  shifu_assert_equal option_bin "$OPTION_BIN" 1
  shifu_assert_equal option_arg "$OPTION_ARG" "option_value"
  shifu_assert_equal option_def "$OPTION_DEF" "not_default_option_value"
  shifu_assert_equal flag_option_bin "$FLAG_OPTION_BIN" 1
  shifu_assert_equal flag_option_arg "$FLAG_OPTION_ARG" "flag_option_value"
  shifu_assert_equal flag_option_def "$FLAG_OPTION_DEF" "not_default_flag_option_value"
  shifu_assert_equal positional_arg "$POSITIONAL_ARG_1" "positional_arg_value_one"
  shifu_assert_equal positional_arg "$POSITIONAL_ARG_2" "positional_arg_value_two"
}

test_shifu_run_args_all_unset() {
  shifu_run shifu_test_all_options_cmd positional_arg_value_one positional_arg_value_two
  shifu_assert_zero exit_code $?
  shifu_assert_equal args_parsed "$_shifu_args_parsed" 2
  shifu_assert_equal flag_bin "$FLAG_BIN" 0
  shifu_assert_empty flag_arg "$FLAG_ARG"
  shifu_assert_equal flag_def "$FLAG_DEF" "def_flag"
  shifu_assert_equal option_bin "$OPTION_BIN" 0
  shifu_assert_empty option_arg "$OPTION_ARG"
  shifu_assert_equal option_def "$OPTION_DEF" "def_opt"
  shifu_assert_equal flag_option_bin "$FLAG_OPTION_BIN" 0
  shifu_assert_empty flag_option_arg "$FLAG_OPTION_ARG"
  shifu_assert_equal flag_option_def "$FLAG_OPTION_DEF" "def_flag_opt"
  shifu_assert_equal positional_arg_1 "$POSITIONAL_ARG_1" "positional_arg_value_one"
  shifu_assert_equal positional_arg_2 "$POSITIONAL_ARG_2" "positional_arg_value_two"
  shifu_assert_equal array_length $# 0
}

test_shifu_run_args_invalid_option() {
  expected=$(
    echo 'Invalid option: --invalid'
    printf 'Test root cmd help

Subcommands
  sub-one
    Test sub one cmd help
  sub-two
    Test sub two cmd help

Options
  -l, --local-test
    A test local cmd arg
    Default: false, set: true
  -h, --help
    Show this help'
  )
  actual=$(shifu_run shifu_test_root_cmd --invalid other -t 2>&1)
  shifu_assert_strings_equal error_message "$expected" "$actual"
}

shifu_test_bad_positional_global_arg_cmd() {
  shifu_cmd_name bad-global
  shifu_cmd_subs does not matter

  shifu_cmd_arg -- bad_positional "Bad help"
}

test_shifu_bad_positional_global_arg_cmd() {
  expected="Positional arguments cannot be global: bad_positional"
  actual=$(shifu_run shifu_test_bad_positional_global_arg_cmd does not matter 2>&1)
  shifu_assert_non_zero exit_code $?
  shifu_assert_strings_equal error_message "$expected" "$actual"
}

shifu_test_bad_positional_local_arg_cmd() {
  shifu_cmd_name bad-local
  shifu_cmd_subs does not matter

  shifu_cmd_arg_loc -- bad_positional "Bad help"
}

test_shifu_bad_positional_local_arg_cmd() {
  expected="Positional arguments cannot be local: bad_positional"
  actual=$(shifu_run shifu_test_bad_positional_local_arg_cmd does not matter 2>&1)
  shifu_assert_non_zero exit_code $?
  shifu_assert_strings_equal error_message "$expected" "$actual"
}

test_shifu_help() {
  expected='Test cmd all help

These are all the fancy things you can do with the all command

Usage
  all [OPTIONS] [POSITIONAL_ARG_1] [POSITIONAL_ARG_2] ...[REMAINING]

Arguments
  POSITIONAL_ARG_1
    positional argument one help
  POSITIONAL_ARG_2
    positional argument two help
  REMAINING
    remaining arguments help

Options
  -f
    binary flag help
    Default: 0, set: 1
  -a [FLAG_ARG]
    flag argument help
  -d [FLAG_DEF]
    default argument flag help
    Default: def_flag
  --option-bin
    binary option help
    Default: 0, set: 1
  --option-arg [OPTION_ARG]
    argument option help
  --option-def [OPTION_DEF]
    default argument option help
    Default: def_opt
  -F, --flag-option-bin
    binary flag/option help
    Default: 0, set: 1
  -A, --flag-option-arg [FLAG_OPTION_ARG]
    argument flag/option help
  -D, --flag-option-def [FLAG_OPTION_DEF]
    default argument flag/option help
    Default: def_flag_opt
  -h, --help
    Show this help'
  actual=$(_shifu_help shifu_test_all_options_cmd 1 2>&1)
  shifu_assert_non_zero exit_code $?
  shifu_assert_strings_equal help_message "$expected" "$actual"
}

test_shifu_help_subcommands() {
  expected='Test root cmd help

Subcommands
  sub-one
    Test sub one cmd help
  sub-two
    Test sub two cmd help

Options
  -l, --local-test
    A test local cmd arg
    Default: false, set: true
  -h, --help
    Show this help'
  actual=$(shifu_run shifu_test_root_cmd -h)
  shifu_assert_strings_equal help_message "$expected" "$actual"
}

test_shifu_help_global() {
  expected='Test leaf four cmd help

Options
  -g, --global
    A test global cmd arg
    Default: false, set: true
  -h, --help
    Show this help'
  actual=$(shifu_run shifu_test_root_cmd sub-two leaf-four -h 2>&1)
  shifu_assert_strings_equal help_message "$expected" "$actual"
}

test_shifu_complete_subcommands() {
  expected="sub-one sub-two"
  actual=$(_shifu_complete shifu_test_root_cmd --shifu-complete "")
  shifu_assert_strings_equal output "$expected" "$actual"
}

test_shifu_complete_nested_subcommands() {
  expected="leaf-one leaf-two"
  actual=$(_shifu_complete shifu_test_root_cmd --shifu-complete cur_word sub-one)
  shifu_assert_strings_equal output "$expected" "$actual"
}

test_shifu_complete_func_args_option_enum() {
  expected="flag option arg"
  actual=$(_shifu_complete shifu_test_all_options_cmd --shifu-complete cur_word -f -A)
  shifu_assert_strings_equal completion "$expected" "$actual"
}

test_shifu_complete_func_args_positional_enum() {
  expected="positional arg one"
  actual=$(_shifu_complete shifu_test_all_options_cmd --shifu-complete cur_word -f -A done)
  shifu_assert_strings_equal completion "$expected" "$actual"
}

test_shifu_complete_func_args_option_func() {
  expected="flag option default"
  actual=$(_shifu_complete shifu_test_all_options_cmd --shifu-complete cur_word -f -D)
  shifu_assert_strings_equal completion "$expected" "$actual"
}

test_shifu_complete_func_args_positional_func() {
  expected="positional arg two"
  actual=$(_shifu_complete shifu_test_all_options_cmd --shifu-complete cur_word -f one)
  shifu_assert_strings_equal completion "$expected" "$actual"
}

test_shifu_complete_func_args_remaining_func() {
  expected="remaining args"
  actual=$(_shifu_complete shifu_test_all_options_cmd --shifu-complete cur_word one two)
  shifu_assert_strings_equal completion "$expected" "$actual"
}

shifu_test_bad_multiple_completions_single_arg_cmd() {
  shifu_cmd_name bad-multi-arg-completion
  shifu_cmd_func no_op

  shifu_cmd_arg -- positional "Bad help"
  shifu_cmd_arg_comp_enum one two
  shifu_cmd_arg_comp_func make_fake_positional_completions
}

test_shifu_bad_multiple_cmd_args_complete_calls() {
  expected="Can only add one completion per argument"
  actual=$(_shifu_complete shifu_test_bad_multiple_completions_single_arg_cmd --shifu-complete cur_word)
  shifu_assert_non_zero status $?
  shifu_assert_strings_equal completion "$expected" "$actual"
}

# Testing utilities
shifu_assert_empty() {
  # 1: identifier, 2: value
  [ -z "$2" ] && return
  [ "${shifu_trace_tests:-}" = true ] && set +x
  shifu_report_context "$1: expected empty, got" "${#1}"
  errors=$(($errors + 1))
  [ "${shifu_trace_tests:-}" = true ] && set -x || return 0
}

shifu_assert_zero() {
  # 1: identifier, 2: value
  [ $2 -eq 0 ] && return
  [ "${shifu_trace_tests:-}" = true ] && set +x
  shifu_report_context "$1: expected zero value, got" $2
  errors=$(($errors + 1))
  [ "${shifu_trace_tests:-}" = true ] && set -x || return 0
}

shifu_assert_non_zero() {
  # 1: identifier, 2: value
  [ $2 -ne 0 ] && return
  [ "${shifu_trace_tests:-}" = true ] && set +x
  shifu_report_context "$1: expected non-zero value, got" $2
  errors=$(($errors + 1))
  [ "${shifu_trace_tests:-}" = true ] && set -x || return 0
}

shifu_assert_equal() {
  # 1: identifier, 2: first, 3: second
  [ "$2" = "$3" ] && return
  [ "${shifu_trace_tests:-}" = true ] && set +x
  shifu_report_context "$1: expected values to be equal, got" "${2:-<empty>}" "${3:-<empty>}"
  errors=$(($errors + 1))
  [ "${shifu_trace_tests:-}" = true ] && set -x || return 0
}

shifu_assert_strings_equal() {
  # 1: identifier, 2: first, 3: second
  [ "${shifu_trace_tests:-}" = true ] && set +x
  shifu_assert_equal "$1" "\"$2\"" "\"$3\""
  [ "${shifu_trace_tests:-}" = true ] && set -x || return 0
}

shifu_report_success() {
  # 1: function name
  if [ "${shifu_verbose_tests:-}" = true ]; then
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
  for argument in "$@"; do
    printf "$shifu_grey%10s%s$shifu_reset\n" "" "$argument"
  done
}

shifu_run_test() {
  # 1: test function
  errors=0
  [ "${shifu_trace_tests:-}" = true ] && set -x
  $1 # 2> /dev/null
  exit_code=$?
  [ "${shifu_trace_tests:-}" = true ] && set +x
  errors=$(($errors + $exit_code))
  return $errors
}

shifu_run_test_and_report() {
  # 1: test function
  test_message=$(shifu_run_test "$1")
  if [ $? -eq 0 ]; then
    n_passed=$(($n_passed + 1))
    shifu_report_success "$1"
  else
    n_failed=$(($n_failed + 1))
    shifu_report_failure "$1"
    echo "$test_message"
  fi
  n_tests=$(($n_tests + 1))
}

shifu_run_test_suite() {
  while true; do
    case "${1:-}" in
      -v) shifu_verbose_tests=true ;;
      -x) shifu_trace_tests=true ;;
      *) break ;;
    esac; shift
  done

  shifu_set_test_functions "$@"
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

shifu_set_test_functions() {
  if [ $# -gt 0 ]; then
    test_functions="$@"
  else
    shifu_read_test_functions
  fi
  [ -n "${ZSH_VERSION:-}" ] && eval "test_functions=( \${=test_functions} )"
}

this_script="$0"  # at global for zsh compatibility
shifu_run_test_suite "$@"
