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

  shifu_cmd_arg -g --global-bin -- GLOBAL_BIN false true "A test global bin cmd arg"
  shifu_cmd_arg -G --global-def -- GLOBAL_DEF global_def "A test global def cmd arg"
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

  shifu_cmd_arg_loc -l --local-test -- LOCAL_TEST local-test "A test local cmd arg"
  shifu_cmd_arg_comp_enum local option test
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

  shifu_cmd_arg -f --fake-arg -- FAKE_ARG fake_default "fake argument help"
  shifu_cmd_arg -t --test-arg -- TEST_ARG test_default "test argument help"
  shifu_cmd_arg               -- POSITIONAL_ARG "positional argument help"
  shifu_cmd_arg               -- "remaining argument help"
}

shifu_test_leaf_func_one() {
  echo test_leaf_func_one $# "$@"
}

shifu_test_leaf_func_two() {
  leaf_two_args="$@"
}

shifu_test_leaf_three_func() {
  leaf_three_args="$@"
}

shifu_test_leaf_func_four() {
  leaf_four_args="$@"
}

shifu_test_all_options_cmd() {
  shifu_cmd_name all
  shifu_cmd_help "Test cmd all help"
  shifu_cmd_long "These are all the fancy things you can do with the all command"
  shifu_cmd_func no_op

  shifu_cmd_arg -f -- FLAG_BIN 0 1      "binary flag help"
  shifu_cmd_arg -a -- FLAG_REQ          "required flag help"
  shifu_cmd_arg -d -- FLAG_DEF def_flag "default argument flag help"
  shifu_cmd_arg --option-bin -- OPTION_BIN 0 1     "binary option help"
  shifu_cmd_arg --option-req -- OPTION_REQ         "required option help"
  shifu_cmd_arg --option-def -- OPTION_DEF def_opt "default argument option help"
  shifu_cmd_arg -F --flag-option-bin -- FLAG_OPTION_BIN 0 1 "binary flag/option help"
  shifu_cmd_arg -A --flag-option-req -- FLAG_OPTION_REQ     "required flag/option help"
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

no_op() { :; }

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
  expected="test_leaf_func_one 2 one two"
  actual=$(shifu_run shifu_test_root_cmd sub-one leaf-one one two 2>&1)
  shifu_assert_zero exit_code $?
  shifu_assert_strings_equal output "$expected" "$actual"
}

test_shifu_run_good_cmd_global_arg() {
  shifu_run shifu_test_root_cmd sub-two leaf-three -g -G global_val one two
  shifu_assert_zero exit_code $?
  shifu_assert_equal global_bin "$GLOBAL_BIN" true
  shifu_assert_equal global_def "$GLOBAL_DEF" global_val
  shifu_assert_equal leaf_three_args "$leaf_three_args" "one two"
}

test_shifu_run_good_cmd_global_and_local_arg() {
  shifu_run shifu_test_root_cmd sub-two -l local-val leaf-three -g -G global_val one two
  shifu_assert_zero exit_code $?
  shifu_assert_equal local_test "$LOCAL_TEST" "local-val"
  shifu_assert_equal global_bin "$GLOBAL_BIN" true
  shifu_assert_equal global_def "$GLOBAL_DEF" global_val
  shifu_assert_equal leaf_three_args "$leaf_three_args" "one two"
}

test_shifu_run_args_all_set() {
  shifu_run shifu_test_all_options_cmd \
    -f \
    -a req_flag_value \
    -d not_default_flag_value \
    --option-bin \
    --option-req req_option_value \
    --option-def not_default_option_value \
    --flag-option-bin \
    --flag-option-req req_flag_option_value \
    -D not_default_flag_option_value \
    positional_arg_value_one positional_arg_value_two \
    remaining arguments
  shifu_assert_zero exit_code $?
  # this acts as a proxy test for shifu_align_args, since we don't have $@ here
  shifu_assert_equal args_parsed $_shifu_args_parsed 17
  shifu_assert_equal flag_bin "$FLAG_BIN" 1
  shifu_assert_equal flag_req "$FLAG_REQ" "req_flag_value"
  shifu_assert_equal flag_def "$FLAG_DEF" "not_default_flag_value"
  shifu_assert_equal option_bin "$OPTION_BIN" 1
  shifu_assert_equal option_req "$OPTION_REQ" "req_option_value"
  shifu_assert_equal option_def "$OPTION_DEF" "not_default_option_value"
  shifu_assert_equal flag_option_bin "$FLAG_OPTION_BIN" 1
  shifu_assert_equal flag_option_req "$FLAG_OPTION_REQ" "req_flag_option_value"
  shifu_assert_equal flag_option_def "$FLAG_OPTION_DEF" "not_default_flag_option_value"
  shifu_assert_equal positional_arg "$POSITIONAL_ARG_1" "positional_arg_value_one"
  shifu_assert_equal positional_arg "$POSITIONAL_ARG_2" "positional_arg_value_two"
}

test_shifu_run_args_not_required_unset() {
  shifu_run shifu_test_all_options_cmd \
    -a req_flag_value \
    --option-req req_option_value \
    --flag-option-req req_flag_option_value \
    positional_arg_value_one positional_arg_value_two
  shifu_assert_zero exit_code $?
  shifu_assert_equal args_parsed "$_shifu_args_parsed" 8
  shifu_assert_equal flag_bin "$FLAG_BIN" 0
  shifu_assert_equal flag_req "$FLAG_REQ" "req_flag_value"
  shifu_assert_equal flag_def "$FLAG_DEF" "def_flag"
  shifu_assert_equal option_bin "$OPTION_BIN" 0
  shifu_assert_equal option_req "$OPTION_REQ" "req_option_value"
  shifu_assert_equal option_def "$OPTION_DEF" "def_opt"
  shifu_assert_equal flag_option_bin "$FLAG_OPTION_BIN" 0
  shifu_assert_equal flag_option_req "$FLAG_OPTION_REQ" "req_flag_option_value"
  shifu_assert_equal flag_option_def "$FLAG_OPTION_DEF" "def_flag_opt"
  shifu_assert_equal positional_arg_1 "$POSITIONAL_ARG_1" "positional_arg_value_one"
  shifu_assert_equal positional_arg_2 "$POSITIONAL_ARG_2" "positional_arg_value_two"
  shifu_assert_equal array_length $# 0
}

test_shifu_run_required_options_unset() {
  run_test() {
    test_cmd_args="$1"
    _shifu_set_for_looping test_cmd_args test_cmd_args
    actual=$(shifu_run shifu_test_all_options_cmd $test_cmd_args)
    shifu_assert_non_zero exit_code $?
    shifu_assert_strings_equal error_message "$2" "$actual"
  }
  shifu_parameterize_test \
    run_test 2 \
    flag        ""                                        "Required variable, FLAG_REQ, is not set" \
    option      "-a flag_value"                           "Required variable, OPTION_REQ, is not set" \
    flag_option "-a flag_value --option-req option_value" "Required variable, FLAG_OPTION_REQ, is not set"
}

shifu_test_required_options_cmd() {
  shifu_cmd_name required-options
  shifu_cmd_subs shifu_test_leaf_three_cmd

  shifu_cmd_arg_loc -l --local -- LOCAL_TEST "A test required local cmd arg"
  shifu_cmd_arg -g --global -- GLOBAL_TEST "A test required global cmd arg"
}

test_shifu_run_required_local_and_global_options() {
  run_test() {
    test_cmd_args="$1"
    _shifu_set_for_looping test_cmd_args test_cmd_args
   actual=$(shifu_run shifu_test_required_options_cmd $test_cmd_args)
   shifu_assert_equal exit_code $2 $?
   shifu_assert_equal error_message "$3" "$actual"
  }
  shifu_parameterize_test \
    run_test 3 \
    both_set  "-l local leaf-three -g global" 0 "" \
    local_set "-l local leaf-three"           1 "Required variable, GLOBAL_TEST, is not set" \
    none_set  "leaf-three"                    1 "Required variable, LOCAL_TEST, is not set"
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
  -g, --global-bin
    A test global bin cmd arg
    Default: false, set: true
  -G, --global-def [GLOBAL_DEF]
    A test global def cmd arg
    Default: global_def
  -h, --help
    Show this help'
  )"
  # TODO: I don't think the global option should show up in this help string
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
  -l, --local-test [LOCAL_TEST]
    A test local cmd arg
    Default: local-test
  -h, --help
    Show this help'
  )"
  actual=$(shifu_run shifu_test_root_cmd sub-two leaf-bad one two 2>&1)
  shifu_assert_non_zero exit_code $?
  shifu_assert_strings_equal error_message "$expected" "$actual"
}

test_shifu_run_bad_cmd_global_and_local_arg() {
  expected="$(
    echo 'Invalid option: -g'
    printf 'Test sub two cmd help

Subcommands
  leaf-three
    Test leaf three cmd help
  leaf-four
    Test leaf four cmd help

Options
  -l, --local-test [LOCAL_TEST]
    A test local cmd arg
    Default: local-test
  -h, --help
    Show this help'
  )"
  actual=$(shifu_run shifu_test_root_cmd sub-two -l local-test -g leaf-three one two)
  shifu_assert_non_zero exit_code $?
  shifu_assert_strings_equal error_message "$expected" "$actual"
}

test_shifu_run_bad_cmd_option_after_positional() {
  expected="$(
    echo 'No options allowed after any positional argument: -t'
    printf 'Test leaf four cmd help

Usage
  leaf-four [OPTIONS] [POSITIONAL_ARG] ...[REMAINING]

Arguments
  POSITIONAL_ARG
    positional argument help
  REMAINING
    remaining argument help

Options
  -f, --fake-arg [FAKE_ARG]
    fake argument help
    Default: fake_default
  -t, --test-arg [TEST_ARG]
    test argument help
    Default: test_default
  -h, --help
    Show this help'
  )"
  actual=$(shifu_run shifu_test_leaf_four_cmd test -t fake)
  shifu_assert_non_zero exit_code $?
  shifu_assert_strings_equal error_message "$expected" "$actual"
}

test_shifu_run_bad_cmd_option_in_remaining() {
  expected="$(
    echo 'No options allowed after any positional argument: -t'
    printf 'Test leaf four cmd help

Usage
  leaf-four [OPTIONS] [POSITIONAL_ARG] ...[REMAINING]

Arguments
  POSITIONAL_ARG
    positional argument help
  REMAINING
    remaining argument help

Options
  -f, --fake-arg [FAKE_ARG]
    fake argument help
    Default: fake_default
  -t, --test-arg [TEST_ARG]
    test argument help
    Default: test_default
  -h, --help
    Show this help'
  )"
  actual=$(shifu_run shifu_test_leaf_four_cmd fake -t test positional)
  shifu_assert_non_zero exit_code $?
  shifu_assert_strings_equal error_message "$expected" "$actual"
}

test_shifu_run_bad_cmd_option_w_allow_options_anywhere() {
  shifu_allow_options_anywhere=true
  shifu_run shifu_test_leaf_four_cmd fake -t test positional
  shifu_assert_zero exit_code $?
  shifu_assert_strings_equal positional "$POSITIONAL_ARG" "fake"
  shifu_assert_strings_equal remaining "$leaf_four_args" "-t test positional"
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
  -g, --global-bin
    A test global bin cmd arg
    Default: false, set: true
  -G, --global-def [GLOBAL_DEF]
    A test global def cmd arg
    Default: global_def
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

test_shifu_run_bad_positional_global_arg_cmd() {
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

test_shifu_run_bad_positional_local_arg_cmd() {
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
  -a [FLAG_REQ]
    required flag help
    Required
  -d [FLAG_DEF]
    default argument flag help
    Default: def_flag
  --option-bin
    binary option help
    Default: 0, set: 1
  --option-req [OPTION_REQ]
    required option help
    Required
  --option-def [OPTION_DEF]
    default argument option help
    Default: def_opt
  -F, --flag-option-bin
    binary flag/option help
    Default: 0, set: 1
  -A, --flag-option-req [FLAG_OPTION_REQ]
    required flag/option help
    Required
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
  -g, --global-bin
    A test global bin cmd arg
    Default: false, set: true
  -G, --global-def [GLOBAL_DEF]
    A test global def cmd arg
    Default: global_def
  -h, --help
    Show this help'
  actual=$(shifu_run shifu_test_root_cmd -h)
  shifu_assert_strings_equal help_message "$expected" "$actual"
}

test_shifu_help_global() {
  expected='Test leaf three cmd help

Options
  -g, --global-bin
    A test global bin cmd arg
    Default: false, set: true
  -G, --global-def [GLOBAL_DEF]
    A test global def cmd arg
    Default: global_def
  -h, --help
    Show this help'
  actual=$(shifu_run shifu_test_root_cmd sub-two leaf-three -h 2>&1)
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

test_shifu_complete_func_args_local_func() {
  expected="local option test"
  actual=$(_shifu_complete shifu_test_root_cmd --shifu-complete cur_word sub-two -l)
  shifu_assert_strings_equal completion "$expected" "$actual"
}

test_shifu_complete_func_args_local_func_bad() {
  expected=""
  actual=$(_shifu_complete shifu_test_root_cmd --shifu-complete cur_word -l)
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
  shifu_assert_non_zero exit_code $?
  shifu_assert_strings_equal completion "$expected" "$actual"
}

test_shifu_set_variable() {
  run_test() {
    actual=$(_shifu_set_variable "$1" any)
    shifu_assert_equal exit_code $2 $?
    shifu_assert_strings_equal output "$3" "$actual"
  }
  shifu_parameterize_test \
    run_test 3 \
    good-var good_var 0 "" \
    bad-var bad-var 1 "Invalid variable name: bad-var"
}

# Testing utilities
shifu_parameterize_test() {
  # 1: name of test function to run, 2: number of arguments the function accepts
  # remaining: groups of arguments describing different tests
  # * first element of the each group is the parameterized run name, used in error reporting
  # * remaining elements are passed to the test function
  p_test_name="$1"; n_args=$2; shift 2
  if [ $(($# % ($n_args + 1))) -ne 0 ]; then
    echo "${p_test_name} received incorrect number of arguments"
    exit 1
  fi
  while [ $# -ne 0 ]; do
    p_run_name="$1"; shift
    "$p_test_name" "$@"
    shift $n_args
  done
}

shifu_assert_empty() {
  # 1: identifier, 2: value
  [ -z "$2" ] && return
  [ "${shifu_trace_tests:-}" = true ] && set +x
  shifu_report_context "${p_run_name+$p_run_name }$1: expected empty, got" "${#1}"
  errors=$(($errors + 1))
  [ "${shifu_trace_tests:-}" = true ] && set -x || return 0
}

shifu_assert_zero() {
  # 1: identifier, 2: value
  [ $2 -eq 0 ] && return
  [ "${shifu_trace_tests:-}" = true ] && set +x
  shifu_report_context "${p_run_name+$p_run_name }$1: expected zero value, got" $2
  errors=$(($errors + 1))
  [ "${shifu_trace_tests:-}" = true ] && set -x || return 0
}

shifu_assert_non_zero() {
  # 1: identifier, 2: value
  [ $2 -ne 0 ] && return
  [ "${shifu_trace_tests:-}" = true ] && set +x
  shifu_report_context "${p_run_name+$p_run_name }$1: expected non-zero value, got" $2
  errors=$(($errors + 1))
  [ "${shifu_trace_tests:-}" = true ] && set -x || return 0
}

shifu_assert_equal() {
  # 1: identifier, 2: first, 3: second
  [ "$2" = "$3" ] && return
  [ "${shifu_trace_tests:-}" = true ] && set +x
  shifu_report_context "${p_run_name+$p_run_name }$1: expected values to be equal, got" \
    "${2:-<empty>}" "${3:-<empty>}"
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
  "$1"
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

this_script="$0"  # at global scope for zsh compatibility
shifu_run_test_suite "$@"
