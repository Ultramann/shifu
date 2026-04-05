set -u
SHIFU_DEBUG_CASE=1

. ./shifu

# to see more color options run:
#   for c in {0..15}; do tput setaf $c; tput setaf $c | echo $c: text; done
shifu_red="$(tput setaf 1 2>/dev/null || true)"
shifu_green="$(tput setaf 2 2>/dev/null || true)"
shifu_grey="$(tput setaf "${SHIFU_TEST_GREY:-0}" 2>/dev/null || true)"
shifu_reset="$(tput sgr0 2>/dev/null || true)"

shifu_test_root_cmd() {
  shifu_cmd_name root
  shifu_cmd_help "Test root cmd help"
  shifu_cmd_subs shifu_test_sub_one_cmd shifu_test_sub_two_cmd

  shifu_cmd_optb :defer: -g --defer-bin -- DEFER_BIN false true "A test deferred binary arg"
  shifu_cmd_optd :defer: -G --defer-def -- DEFER_DEF defer_def "A test deferred default arg"
  shifu_cmd_cpte defer_one defer_two defer_three
}

shifu_test_sub_one_cmd() {
  shifu_cmd_name sub-one
  shifu_cmd_help "Test sub one cmd help"
  shifu_cmd_subs shifu_test_leaf_one_cmd shifu_test_leaf_two_cmd

  shifu_cmd_optd :defer: -S --sub-defer -- SUB_DEFER sub_defer "A test sub-one deferred arg"
  shifu_cmd_cptf make_fake_sub_defer_threeompletions
}

shifu_test_sub_two_cmd() {
  shifu_cmd_name sub-two
  shifu_cmd_help "Test sub two cmd help"
  shifu_cmd_subs shifu_test_leaf_three_cmd shifu_test_leaf_four_cmd

  shifu_cmd_optd :eager: -e --eager-test -- EAGER_TEST eager-test "A test eager arg"
  shifu_cmd_cpte eager option test
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

  shifu_cmd_optd -f --fake-arg -- FAKE_ARG fake_default "fake argument help"
  shifu_cmd_optd -t --test-arg -- TEST_ARG test_default "test argument help"
  shifu_cmd_argr POSITIONAL_ARG "positional argument help"
  shifu_cmd_args "remaining argument help"
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

  shifu_cmd_optb -f -- FLAG_BIN 0 1      "binary flag help"
  shifu_cmd_optr -a -- FLAG_REQ          "required flag help"
  shifu_cmd_optd -d -- FLAG_DEF def_flag "default argument flag help"
  shifu_cmd_optb --option-bin -- OPTION_BIN 0 1     "binary option help"
  shifu_cmd_optr --option-req -- OPTION_REQ         "required option help"
  shifu_cmd_optd --option-def -- OPTION_DEF def_opt "default argument option help"
  shifu_cmd_optb -F --flag-option-bin -- FLAG_OPTION_BIN 0 1 "binary flag/option help"
  shifu_cmd_optr -A --flag-option-req -- FLAG_OPTION_REQ     "required flag/option help"
  shifu_cmd_cpte flag option arg
  shifu_cmd_optd -D --flag-option-def -- FLAG_OPTION_DEF def_flag_opt \
                                    "default argument flag/option help"
  shifu_cmd_cptf make_fake_option_completions
  shifu_cmd_argr POSITIONAL_ARG_1 "positional argument one help"
  shifu_cmd_cpte positional arg one
  shifu_cmd_argr POSITIONAL_ARG_2 "positional argument two help"
  shifu_cmd_cptf make_fake_positional_completions
  shifu_cmd_args "remaining arguments help"
  shifu_cmd_cptf make_fake_remaining_completions
}

no_op() { :; }

make_fake_option_completions() {
  shifu_add_cpts flag option default
}

make_fake_positional_completions() {
  shifu_add_cpts positional arg two
}

make_fake_remaining_completions() {
  shifu_add_cpts remaining args
}

make_fake_sub_defer_threeompletions() {
  shifu_add_cpts sub_defer_one sub_defer_two sub_defer_three
}

test_shifu_run_zero_args() {
  expected="shifu_run requires at least one argument, got 0"
  actual=$(shifu_run 2>&1)
  shifu_assert_non_zero exit_code $?
  shifu_assert_strings_equal output "$expected" "$actual"
}

test_shifu_run_one_arg() {
  expected="test_leaf_func_one 0"
  actual=$(shifu_run shifu_test_leaf_one_cmd 2>&1)
  shifu_assert_zero exit_code $?
  shifu_assert_strings_equal output "$expected" "$actual"
}

test_shifu_run_good() {
  expected="test_leaf_func_one 2 one two"
  actual=$(shifu_run shifu_test_root_cmd sub-one leaf-one one two 2>&1)
  shifu_assert_zero exit_code $?
  shifu_assert_strings_equal output "$expected" "$actual"
}

test_shifu_run_good_cmd_defer_arg() {
  shifu_run shifu_test_root_cmd sub-two leaf-three -g -G defer_val one two
  shifu_assert_zero exit_code $?
  shifu_assert_equal defer_bin "$DEFER_BIN" true
  shifu_assert_equal defer_def "$DEFER_DEF" defer_val
  shifu_assert_equal leaf_three_args "$leaf_three_args" "one two"
}

test_shifu_run_good_cmd_defer_and_eager_arg() {
  shifu_run shifu_test_root_cmd sub-two -e eager-val leaf-three -g -G defer_val one two
  shifu_assert_zero exit_code $?
  shifu_assert_equal eager_test "$EAGER_TEST" "eager-val"
  shifu_assert_equal defer_bin "$DEFER_BIN" true
  shifu_assert_equal defer_def "$DEFER_DEF" defer_val
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

test_shifu_run_required_args_unset() {
  run_test() {
    shifu_test_params @cmd_args expected_error -- "$@"
    actual=$(shifu_run shifu_test_all_options_cmd $cmd_args)
    shifu_assert_non_zero exit_code $?
    shifu_assert_string_contains error_message "$actual" "$expected_error"
  }
  shifu_parameterize_test run_test \
  -- flag        ""  "Required variable, FLAG_REQ, is not set" \
  -- option      "-a flag_value"  "Required variable, OPTION_REQ, is not set" \
  -- flag_option "-a flag_value --option-req option_value" \
                   "Required variable, FLAG_OPTION_REQ, is not set" \
  -- positional  "-a flag_value --option-req option_value --flag-option-req flag_option_value" \
                   "Missing positional argument POSITIONAL_ARG_1"
}

shifu_test_required_options_cmd() {
  shifu_cmd_name required-options
  shifu_cmd_subs shifu_test_leaf_three_cmd

  shifu_cmd_optr :eager: -e --eager -- EAGER_TEST "A test required eager arg"
  shifu_cmd_optr :defer: -g --defer -- DEFER_TEST "A test required deferred arg"
}

test_shifu_run_required_eager_and_defer_options() {
  run_test() {
    shifu_test_params @cmd_args expected_exit expected_error -- "$@"
    actual=$(shifu_run shifu_test_required_options_cmd $cmd_args)
    shifu_assert_equal exit_code $expected_exit $?
    shifu_assert_string_contains error_message "$actual" "$expected_error"
  }
  shifu_parameterize_test run_test \
  -- both_set  "-e eager leaf-three -g defer"  0  "" \
  -- eager_set "-e eager leaf-three"  1  "Required variable, DEFER_TEST, is not set" \
  -- none_set  "leaf-three"  1  "Required variable, EAGER_TEST, is not set"
}

shifu_test_option_missing_value_cmd() {
  shifu_cmd_name option-missing-value
  shifu_cmd_help "Test cmd for option without value"
  shifu_cmd_func no_op

  shifu_cmd_optd -o --option-with-value -- OPTION_VALUE default_value "Option that requires a value"
  shifu_cmd_optd -t --test-opt -- TEST_OPT test_default "Test option with value"
}

test_shifu_run_option_missing_value() {
  run_test() {
    shifu_test_params option -- "$@"
    expected="Option $option requires a value"
    actual=$(shifu_run shifu_test_option_missing_value_cmd $option 2>&1)
    exit_code=$?
    shifu_assert_non_zero exit_code $exit_code
    shifu_assert_string_contains error_message "$actual" "$expected"
  }
  shifu_parameterize_test run_test \
  -- long_option  "--option-with-value" \
  -- short_option "-o"
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
  -g, --defer-bin
    A test deferred binary arg
    Default: false, set: true
  -G, --defer-def [DEFER_DEF]
    A test deferred default arg
    Default: defer_def
  -h, --help
    Show this help'
  )"
  # TODO: I don't think the defer option should show up in this help string
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
  -S, --sub-defer [SUB_DEFER]
    A test sub-one deferred arg
    Default: sub_defer
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
  -e, --eager-test [EAGER_TEST]
    A test eager arg
    Default: eager-test
  -h, --help
    Show this help'
  )"
  actual=$(shifu_run shifu_test_root_cmd sub-two leaf-bad one two 2>&1)
  shifu_assert_non_zero exit_code $?
  shifu_assert_strings_equal error_message "$expected" "$actual"
}

test_shifu_run_bad_cmd_defer_and_eager_arg() {
  expected="$(
    echo 'Invalid option: -g'
    printf 'Test sub two cmd help

Subcommands
  leaf-three
    Test leaf three cmd help
  leaf-four
    Test leaf four cmd help

Options
  -e, --eager-test [EAGER_TEST]
    A test eager arg
    Default: eager-test
  -h, --help
    Show this help'
  )"
  actual=$(shifu_run shifu_test_root_cmd sub-two -e eager-test -g leaf-three one two)
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
  -g, --defer-bin
    A test deferred binary arg
    Default: false, set: true
  -G, --defer-def [DEFER_DEF]
    A test deferred default arg
    Default: defer_def
  -h, --help
    Show this help'
  )
  actual=$(shifu_run shifu_test_root_cmd --invalid other -t 2>&1)
  shifu_assert_strings_equal error_message "$expected" "$actual"
}

shifu_test_bad_positional_defer_arg_cmd() {
  shifu_cmd_name bad-defer
  shifu_cmd_subs does not matter

  shifu_cmd_argr bad_positional "Bad help"
}

test_shifu_run_bad_positional_defer_arg_cmd() {
  expected="Positional arguments can only be used in leaf commands"
  actual=$(shifu_run shifu_test_bad_positional_defer_arg_cmd does not matter 2>&1)
  shifu_assert_non_zero exit_code $?
  shifu_assert_strings_equal error_message "$expected" "$actual"
}

shifu_test_bad_positional_eager_arg_cmd() {
  shifu_cmd_name bad-eager
  shifu_cmd_subs does not matter

  shifu_cmd_argr bad_positional "Bad help"
}

test_shifu_run_bad_positional_eager_arg_cmd() {
  expected="Positional arguments can only be used in leaf commands"
  actual=$(shifu_run shifu_test_bad_positional_eager_arg_cmd does not matter 2>&1)
  shifu_assert_non_zero exit_code $?
  shifu_assert_strings_equal error_message "$expected" "$actual"
}

shifu_test_bad_missing_mode_cmd() {
  shifu_cmd_name bad-mode
  shifu_cmd_subs does not matter

  shifu_cmd_optd -o --opt -- OPT default "Missing mode"
}

test_shifu_run_bad_missing_mode() {
  expected="Mode :eager: or :defer: required in non-leaf commands"
  actual=$(shifu_run shifu_test_bad_missing_mode_cmd does not matter 2>&1)
  shifu_assert_non_zero exit_code $?
  shifu_assert_strings_equal error_message "$expected" "$actual"
}

shifu_test_bad_flag_format_cmd() {
  shifu_cmd_name bad-flag
  shifu_cmd_func does_not_matter

  shifu_cmd_optd oops -- OPT default "Flag without dash"
}

test_shifu_run_bad_flag_format() {
  expected="Option flags must start with - or --, got: oops"
  actual=$(shifu_run shifu_test_bad_flag_format_cmd 2>&1)
  shifu_assert_non_zero exit_code $?
  shifu_assert_strings_equal error_message "$expected" "$actual"
}

test_shifu_help() {
  _shifu_setup
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
  -g, --defer-bin
    A test deferred binary arg
    Default: false, set: true
  -G, --defer-def [DEFER_DEF]
    A test deferred default arg
    Default: defer_def
  -h, --help
    Show this help'
  actual=$(shifu_run shifu_test_root_cmd -h)
  shifu_assert_strings_equal help_message "$expected" "$actual"
}

test_shifu_help_defer() {
  expected='Test leaf three cmd help

Options
  -g, --defer-bin
    A test deferred binary arg
    Default: false, set: true
  -G, --defer-def [DEFER_DEF]
    A test deferred default arg
    Default: defer_def
  -h, --help
    Show this help'
  actual=$(shifu_run shifu_test_root_cmd sub-two leaf-three -h 2>&1)
  shifu_assert_strings_equal help_message "$expected" "$actual"
}

test_shifu_complete() {
  run_test() {
    shifu_test_params cmd @complete_args expected -- "$@"
    actual=$(_shifu_complete $cmd --shifu-complete $complete_args)
    shifu_assert_strings_equal completion "$expected" "$actual"
  }
  shifu_parameterize_test run_test \
  -- subcommands \
     shifu_test_root_cmd "cur_word" "sub-one sub-two" \
  -- nested_subcommands \
     shifu_test_root_cmd "cur_word sub-one" "leaf-one leaf-two" \
  -- func_args_option_enum \
     shifu_test_all_options_cmd "cur_word -f -A" "flag option arg" \
  -- func_args_positional_enum \
     shifu_test_all_options_cmd "cur_word -f -A flag" \
     "positional arg one" \
  -- func_args_option_func \
     shifu_test_all_options_cmd "cur_word -f -D" \
     "flag option default" \
  -- func_args_positional_func \
     shifu_test_all_options_cmd "cur_word -f one" \
     "positional arg two" \
  -- func_args_remaining_func \
     shifu_test_all_options_cmd "cur_word one two" "remaining args" \
  -- func_args_eager_func \
     shifu_test_root_cmd "cur_word sub-two -e" "eager option test" \
  -- func_args_eager_func_bad \
     shifu_test_root_cmd "cur_word -e" "" \
  -- func_args_options \
     shifu_test_all_options_cmd "--op" \
     "--option-bin --option-req --option-def" \
  -- func_args_flags \
     shifu_test_all_options_cmd "-f" "-f" \
  -- func_args_flag_options \
     shifu_test_all_options_cmd "--flag" \
     "--flag-option-bin --flag-option-req --flag-option-def" \
  -- single_dash_double_dash_only \
     shifu_test_all_options_cmd "-" \
     "--option-bin --option-req --option-def --flag-option-bin --flag-option-req --flag-option-def --help" \
  -- options_only_when_dash \
     shifu_test_all_options_cmd "cur_word" "positional arg one" \
  -- defer_option_names \
     shifu_test_root_cmd "--defer sub-one leaf-one" \
     "--defer-bin --defer-def" \
  -- defer_option_names_no_func \
     shifu_test_root_cmd "--defer sub-one" "" \
  -- eager_option_names_on_sub \
     shifu_test_root_cmd "--eager sub-two" "--eager-test" \
  -- defer_option_values \
     shifu_test_root_cmd "cur_word sub-one leaf-one -G" \
     "defer_one defer_two defer_three" \
  -- defer_option_values_no_func \
     shifu_test_root_cmd "cur_word sub-one -G" "" \
  -- defer_option_values_at_root \
     shifu_test_root_cmd "cur_word -G" "" \
  -- defer_option_func_values \
     shifu_test_root_cmd "cur_word sub-one leaf-one -S" \
     "sub_defer_one sub_defer_two sub_defer_three" \
  -- defer_option_func_values_none \
     shifu_test_root_cmd "cur_word sub-one -S" ""
}

test_shifu_complete_single_dash_with_config_shows_all_options() {
  shifu_complete_single_dash_options=true
  expected="-f -a -d --option-bin --option-req --option-def -F --flag-option-bin -A --flag-option-req -D --flag-option-def -h --help"
  actual=$(_shifu_complete shifu_test_all_options_cmd --shifu-complete -)
  shifu_assert_strings_equal completion "$expected" "$actual"
}

shifu_test_path_files_cmd() {
  shifu_cmd_name path-files
  shifu_cmd_func no_op
  shifu_cmd_optd -f --file -- FILE_ARG file_default "File argument"
  shifu_cmd_cptp :files:
  shifu_cmd_argr PATH_ARG "Path argument"
  shifu_cmd_cptp :files:
}

shifu_test_path_dirs_cmd() {
  shifu_cmd_name path-dirs
  shifu_cmd_func no_op
  shifu_cmd_optd -d --dir -- DIR_ARG dir_default "Directory argument"
  shifu_cmd_cptp :dirs:
}

shifu_test_path_glob_cmd() {
  shifu_cmd_name path-glob
  shifu_cmd_func no_op
  shifu_cmd_optd -g --glob -- GLOB_ARG glob_default "Glob argument"
  shifu_cmd_cptp :glob: "*.txt"
}

shifu_test_path_glob_no_pattern_cmd() {
  shifu_cmd_name path-glob-no-pattern
  shifu_cmd_func no_op
  shifu_cmd_optd -g --glob -- GLOB_ARG glob_default "Glob argument"
  shifu_cmd_cptp :glob:
}

shifu_test_defer_path_files_cmd() {
  shifu_cmd_name defer-path-files
  shifu_cmd_subs shifu_test_leaf_one_cmd
  shifu_cmd_optd :defer: -c --config -- CONFIG config_default "Config file"
  shifu_cmd_cptp :files:
}

shifu_test_defer_path_dirs_cmd() {
  shifu_cmd_name defer-path-dirs
  shifu_cmd_subs shifu_test_leaf_one_cmd
  shifu_cmd_optd :defer: -d --dir -- DIR_ARG dir_default "Directory argument"
  shifu_cmd_cptp :dirs:
}

shifu_test_defer_path_glob_cmd() {
  shifu_cmd_name defer-path-glob
  shifu_cmd_subs shifu_test_leaf_one_cmd
  shifu_cmd_optd :defer: -g --glob -- GLOB_ARG glob_default "Glob argument"
  shifu_cmd_cptp :glob: "*.txt"
}

shifu_test_defer_path_glob_no_pattern_cmd() {
  shifu_cmd_name defer-path-glob-no-pattern
  shifu_cmd_subs shifu_test_leaf_one_cmd
  shifu_cmd_optd :defer: -g --glob -- GLOB_ARG glob_default "Glob argument"
  shifu_cmd_cptp :glob:
}

shifu_test_eager_bin_cmd() {
  shifu_cmd_name eager-bin
  shifu_cmd_help "Test cmd with eager bin"
  shifu_cmd_subs shifu_test_leaf_three_cmd shifu_test_leaf_four_cmd

  shifu_cmd_optb :eager: -b --bin-flag -- BIN_FLAG false true "A test eager bin flag"
}

shifu_test_eager_root_cmd() {
  shifu_cmd_name eager-root
  shifu_cmd_help "Test root with eager option"
  shifu_cmd_subs shifu_test_sub_multi_eager_cmd shifu_test_leaf_three_cmd

  shifu_cmd_optd :eager: -r --eager-root -- EAGER_ROOT eager_root "A test eager root option"
  shifu_cmd_cpte root_one root_two root_three
}

shifu_test_sub_multi_eager_cmd() {
  shifu_cmd_name sub-multi-eager
  shifu_cmd_help "Test sub with multiple eager options"
  shifu_cmd_subs shifu_test_leaf_three_cmd shifu_test_leaf_four_cmd

  shifu_cmd_optb :eager: -b --bin-opt -- BIN_OPT false true "A test eager binary option"
  shifu_cmd_optd :eager: -d --def-opt -- DEF_OPT default "A test eager default option"
  shifu_cmd_cpte data_one data_two data_three
}

test_shifu_complete_subcmds_after_eager_optb() {
  expected="leaf-three leaf-four"
  actual=$(_shifu_complete shifu_test_eager_bin_cmd --shifu-complete "" -b)
  shifu_assert_strings_equal output "$expected" "$actual"
}

test_shifu_complete_subcmds_after_eager_optd() {
  expected="leaf-three leaf-four"
  actual=$(_shifu_complete shifu_test_root_cmd --shifu-complete "" sub-two -e some_value)
  shifu_assert_strings_equal output "$expected" "$actual"
}

test_shifu_complete_subcmds_after_eager_optr() {
  expected="leaf-three"
  actual=$(_shifu_complete shifu_test_required_options_cmd --shifu-complete "" -e some_value)
  shifu_assert_strings_equal output "$expected" "$actual"
}

test_shifu_complete_subcmds_after_multi_eager() {
  expected="leaf-three leaf-four"
  actual=$(_shifu_complete shifu_test_sub_multi_eager_cmd --shifu-complete "" -b -d some_value)
  shifu_assert_strings_equal output "$expected" "$actual"
}

test_shifu_complete_leaf_options_through_eager_parent() {
  expected="--fake-arg"
  actual=$(_shifu_complete shifu_test_root_cmd --shifu-complete --f sub-two -e some_value leaf-four)
  shifu_assert_strings_equal output "$expected" "$actual"
}

test_shifu_complete_defer_option_values_through_eager_parent() {
  expected="defer_one defer_two defer_three"
  actual=$(_shifu_complete shifu_test_root_cmd --shifu-complete "" sub-two -e some_value leaf-four -G)
  shifu_assert_strings_equal output "$expected" "$actual"
}

test_shifu_complete_nested_eager_at_multiple_levels() {
  expected="leaf-three leaf-four"
  actual=$(_shifu_complete shifu_test_eager_root_cmd --shifu-complete "" -r root_one sub-multi-eager -b -d data_one)
  shifu_assert_strings_equal output "$expected" "$actual"
}

test_shifu_complete_path() {
  run_test() {
    shifu_test_params cmd @complete_args expected -- "$@"
    actual=$(_shifu_complete "$cmd" --shifu-complete cur_word $complete_args)
    shifu_assert_strings_equal completion "$expected" "$actual"
  }
  shifu_parameterize_test run_test \
  -- eager_files_option     shifu_test_path_files_cmd           "-f"           "SHIFU_COMP_PATH_FILES" \
  -- eager_files_positional shifu_test_path_files_cmd           "-f filled"    "SHIFU_COMP_PATH_FILES" \
  -- eager_dirs             shifu_test_path_dirs_cmd            "-d"           "SHIFU_COMP_PATH_DIRS" \
  -- eager_glob             shifu_test_path_glob_cmd            "-g"           "SHIFU_COMP_PATH_GLOB:*.txt" \
  -- eager_glob_no_pattern  shifu_test_path_glob_no_pattern_cmd "-g"           "" \
  -- defer_files            shifu_test_defer_path_files_cmd     "leaf-one -c"  "SHIFU_COMP_PATH_FILES" \
  -- defer_files_no_sub     shifu_test_defer_path_files_cmd     "-c"           "" \
  -- defer_dirs             shifu_test_defer_path_dirs_cmd      "leaf-one -d"  "SHIFU_COMP_PATH_DIRS" \
  -- defer_dirs_no_sub      shifu_test_defer_path_dirs_cmd      "-d"           "" \
  -- defer_glob             shifu_test_defer_path_glob_cmd      "leaf-one -g"  "SHIFU_COMP_PATH_GLOB:*.txt" \
  -- defer_glob_no_sub      shifu_test_defer_path_glob_cmd      "-g"           "" \
  -- defer_glob_no_pattern  shifu_test_defer_path_glob_no_pattern_cmd "leaf-one -g" ""
}

shifu_test_bad_multiple_completions_single_arg_cmd() {
  shifu_cmd_name bad-multi-arg-completion
  shifu_cmd_func no_op

  shifu_cmd_argr positional "Bad help"
  shifu_cmd_cpte one two
  shifu_cmd_cptf make_fake_positional_completions
}

test_shifu_bad_multiple_cmd_args_complete_calls() {
  expected="Can only add one completion per argument"
  actual=$(_shifu_complete shifu_test_bad_multiple_completions_single_arg_cmd --shifu-complete cur_word)
  shifu_assert_non_zero exit_code $?
  shifu_assert_strings_equal completion "$expected" "$actual"
}

test_shifu_set_variable() {
  run_test() {
    shifu_test_params var expected_exit expected_output -- "$@"
    actual=$(_shifu_set_variable "$var" any)
    shifu_assert_equal exit_code $expected_exit $?
    shifu_assert_strings_equal output "$expected_output" "$actual"
  }
  shifu_parameterize_test run_test \
  -- good-var  good_var  0  "" \
  -- bad-var   bad-var   1  "Invalid variable name: bad-var"
}

test_shifu_case_loop_error() {
  shifu_case_stmt="case \"\$1\" in *) ;; esac"
  actual=$(SHIFU_DEBUG_CASE=0 _shifu_case_loop_error 2>&1)
  shifu_assert_non_zero exit_code $?
  shifu_assert_strings_equal message "Internal error" "$actual"
}

test_shifu_case_loop_error_with_debug() {
  shifu_case_stmt='case "$1" in test-pattern) ;; esac'
  actual=$(_shifu_case_loop_error 2>&1)
  shifu_assert_string_contains output "$actual" 'case "$1" in test-pattern) ;; esac'
}

test_shifu_case_eval_error() {
  shifu_case_stmt="case \"\$1\" in bad-syntax"
  actual=$(SHIFU_DEBUG_CASE=0 _shifu_case_eval_error 2>&1)
  shifu_assert_non_zero exit_code $?
  shifu_assert_strings_equal message "Internal error" "$actual"
}

test_shifu_case_eval_error_with_debug() {
  shifu_case_stmt='case "$1" in test-syntax-pattern'
  actual=$(_shifu_case_eval_error 2>&1)
  shifu_assert_string_contains output "$actual" 'case "$1" in test-syntax-pattern'
}

test_shifu_complete_bad_case_stmt_exits_silently() {
  actual=$(_shifu_complete shifu_test_root_cmd --shifu-complete "" -g 2>&1)
  exit_code=$?
  shifu_assert_non_zero exit_code $exit_code
  shifu_assert_empty output "$actual"
}

test_shifu_complete_help_flags() {
  run_test() {
    shifu_test_params help_flags cur_word expected -- "$@"
    shifu_help_flags="$help_flags"
    actual=$(_shifu_complete shifu_test_all_options_cmd --shifu-complete $cur_word)
    shifu_assert_strings_equal completion "$expected" "$actual"
  }
  shifu_parameterize_test run_test \
  -- default  "-h --help"  "--hel"  "--help" \
  -- custom   "--info"     "--inf"  "--info" \
  -- empty    ""           "--hel"  ""
}

test_shifu_complete_help_flags_short() {
  shifu_complete_single_dash_options=true
  actual=$(_shifu_complete shifu_test_all_options_cmd --shifu-complete -h)
  shifu_assert_strings_equal completion "-h" "$actual"
}

test_shifu_help_text_configurable_flags() {
  run_test() {
    shifu_test_params help_flags expected_contains expected_not_contains -- "$@"
    shifu_help_flags="$help_flags"
    _shifu_setup
    actual=$(_shifu_help shifu_test_all_options_cmd 0 2>&1)
    shifu_assert_string_contains contains "$actual" "$expected_contains"
    shifu_assert_string_not_contains not_contains "$actual" "$expected_not_contains"
  }
  shifu_parameterize_test run_test \
  -- custom_flag_shown   "--info"     "--info"            "-h, --help" \
  -- default_flag_shown  "-h --help"  "-h, --help"        "--info" \
  -- empty_no_help_line  ""           "binary flag help"  "Show this help"
}

test_shifu_run_configurable_help_flags() {
  run_test() {
    shifu_test_params help_flags flag expected -- "$@"
    shifu_help_flags="$help_flags"
    actual=$(shifu_run shifu_test_root_cmd sub-one leaf-one $flag 2>&1)
    shifu_assert_string_contains output "$actual" "$expected"
  }
  shifu_parameterize_test run_test \
  -- custom_flag              "--info"  "--info"  "Test leaf one cmd help" \
  -- removed_default_invalid  "--help"  "-h"      "Invalid option: -h" \
  -- empty_disables_help      ""        "--help"  "Invalid option: --help"
}

test_shifu_help_case_pattern() {
  run_test() {
    shifu_test_params help_flags expected -- "$@"
    shifu_help_flags="$help_flags"
    _shifu_help_case_pattern
    shifu_assert_strings_equal pattern "$expected" "$shifu_help_pattern"
  }
  shifu_parameterize_test run_test \
  -- default  "-h --help"  "-h|--help" \
  -- single   "--help"     "--help" \
  -- empty    ""           ""
}

test_shifu_help_display_flags() {
  run_test() {
    shifu_test_params help_flags expected -- "$@"
    shifu_help_flags="$help_flags"
    _shifu_help_display_flags
    shifu_assert_strings_equal display "$expected" "$shifu_help_display"
  }
  shifu_parameterize_test run_test \
  -- default  "-h --help"  "-h, --help" \
  -- single   "--help"     "--help" \
  -- empty    ""           ""
}

test_shifu_help_flags_validation() {
  run_test() {
    shifu_test_params help_flags expected -- "$@"
    shifu_help_flags="$help_flags"
    actual=$(shifu_run shifu_test_root_cmd)
    shifu_assert_strings_equal error_message "$expected" "$actual"
  }
  shifu_parameterize_test run_test \
  -- no_dash        "help"     "Option flags must start with - or --, got: help" \
  -- glob_question  "-?"       "Help flag contains glob character: -?" \
  -- glob_star      "--*"      "Help flag contains glob character: --*" \
  -- glob_bracket   "--[abc]"  "Help flag contains glob character: --[abc]"
}

# Testing utilities
shifu_parameterize_test() {
  # run test function over many test cases, test cases are separated with --.
  # Test case args that contain multiple words should be passed as a single string
  # and # unpacked with an @-prefixed name in shifu_test_params for word-splitting.
  # Usage:
  # shifu_parameterize_test <test function> \
  # -- <case_name> args...
  # -- <case_name> args...
  pt_test_name=$1; shift
  pt_passed=0
  pt_failed=0
  while [ $# -ne 0 ]; do
    if [ "$1" != "--" ]; then
      echo "shifu_parameterize_test: expected --, got $1"
      exit 1
    fi
    shift
    pt_run_name=$1; shift
    pt_count=0
    for pt_arg in "$@"; do
      [ "$pt_arg" = "--" ] && break
      pt_count=$((pt_count + 1))
    done
    pt_errors_before=$errors
    pt_buffer=""
    unset p_run_name
    "$pt_test_name" "$@"
    if [ $errors -eq $pt_errors_before ]; then
      pt_passed=$((pt_passed + 1))
      if [ "${shifu_verbose_tests:-}" = true ]; then
        printf "   $shifu_green%-4s$shifu_reset%s\n" "+" "$pt_run_name"
      fi
    else
      pt_failed=$((pt_failed + 1))
      printf "   $shifu_red%-4s$shifu_reset%s\n" "x" "$pt_run_name"
      [ -n "$pt_buffer" ] && echo "$pt_buffer"
    fi
    shift $pt_count
  done
  echo "PARAMETERIZED_TEST_COUNTS $pt_passed $pt_failed"
}

shifu_test_params() {
  # variable names before -- are assigned from positional args passed after --
  # @-prefixed names are prepared for word-splitting via _shifu_set_for_looping
  ua_count=0
  while [ "$1" != "--" ]; do
    eval "ua_var_$ua_count=$1"
    ua_count=$((ua_count + 1))
    shift
  done
  shift
  if [ "$pt_count" -ne "$ua_count" ]; then
    echo "shifu_test_params: expected $ua_count args, got $pt_count"
    exit 1
  fi
  ua_idx=0
  while [ $ua_idx -lt $ua_count ]; do
    eval "ua_full=\$ua_var_$ua_idx"
    case "$ua_full" in
      @*)
        ua_name=${ua_full#@}
        eval "$ua_name=\$1"
        _shifu_set_for_looping "$ua_name" "$ua_name"
        ;;
      *)
        eval "$ua_full=\$1"
        ;;
    esac
    shift
    ua_idx=$((ua_idx + 1))
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

shifu_assert_string_contains() {
  # 1: identifier, 2: string to search in, 3: string to search for
  case "$2" in
    *"$3"*) return 0 ;;
  esac
  [ "${shifu_trace_tests:-}" = true ] && set +x
  shifu_report_context "${p_run_name+$p_run_name }$1: expected string to be contained" \
    "string: \"${2:-<empty>}\"" "search: \"${3:-<empty>}\""
  errors=$(($errors + 1))
  [ "${shifu_trace_tests:-}" = true ] && set -x || return 0
}

shifu_assert_string_not_contains() {
  # 1: identifier, 2: string to search in, 3: string to search for
  case "$2" in
    *"$3"*) ;;
    *) return 0 ;;
  esac
  [ "${shifu_trace_tests:-}" = true ] && set +x
  shifu_report_context "${p_run_name+$p_run_name }$1: expected string to not be contained" \
    "string: \"${2:-<empty>}\"" "search: \"${3:-<empty>}\""
  errors=$(($errors + 1))
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
  pt_line=$(printf "$shifu_grey%7s%s$shifu_reset\n" "" "$1"); shift
  for argument in "$@"; do
    pt_line="$pt_line
$(printf "$shifu_grey%10s%s$shifu_reset\n" "" "$argument")"
  done
  if [ "${pt_buffer+set}" = set ]; then
    pt_buffer="${pt_buffer:+$pt_buffer
}$pt_line"
  else
    echo "$pt_line"
  fi
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
  test_func=$1
  test_output=$(shifu_run_test "$test_func")
  test_result=$?
  pt_last_line=${test_output##*"
"}
  case "$pt_last_line" in
    PARAMETERIZED_TEST_COUNTS*)
      test_output=${test_output%"$pt_last_line"}
      test_output=${test_output%"
"}
      pt_passed=${pt_last_line#PARAMETERIZED_TEST_COUNTS }
      pt_failed=${pt_passed#* }
      pt_passed=${pt_passed%% *}
      n_passed=$(($n_passed + $pt_passed))
      n_failed=$(($n_failed + $pt_failed))
      n_tests=$(($n_tests + $pt_passed + $pt_failed))
      ;;
    *)
      n_tests=$(($n_tests + 1))
      if [ $test_result -eq 0 ]; then
        n_passed=$(($n_passed + 1))
      else
        n_failed=$(($n_failed + 1))
      fi
      ;;
  esac
  if [ $test_result -eq 0 ]; then
    shifu_report_success "$test_func"
  else
    shifu_report_failure "$test_func"
  fi
  [ -n "$test_output" ] && echo "$test_output"
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

  if [ $n_failed -eq 0 ]; then
    color="$shifu_green"
    percent_passed=100
  elif [ $n_tests -eq 0 ]; then
    color="$shifu_red"
    percent_passed=0
  else
    color="$shifu_red"
    percent_passed=$((n_passed * 100 / n_tests))
  fi
  summary=$(printf " %3s%% (%s/%s) tests passed " "$percent_passed" "$n_passed" "$n_tests")
  pad_len=$(( (63 - ${#summary}) / 2 ))
  pad=$(printf '%.*s' $pad_len "================================")
  printf "%s%s%s%s%s\n" "$pad" "$color" "$summary" "$shifu_reset" "$pad"
  exit $n_failed
}

shifu_read_test_functions() {
  test_functions=$(grep -E "^test_.* ?\(\)" "$this_script" | sed 's/() {$//' | sed 's/() $//' | sed 's/ $//')
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
