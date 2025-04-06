source ./shifu

shifu_test_function_declaration='^(test_.*) ?\(\) {'
shifu_read_test_functions() {
  local test_script_path=$1
  test_functions=($(
    cat "${test_script_path}" | \
    # -r: extended regex, -n: don't echo lines to stdout
    sed -rn "/${shifu_test_function_declaration}/!d;
            s/${shifu_test_function_declaration}/\1/p"
  ))
}

shifu_report_success() {
  printf "${shifu_green}%-8s${shifu_reset} %s\n" success $1
}

shifu_report_failure() {
  printf "${shifu_red}%-8s${shifu_reset} %s\n" fail $1
}

shifu_assert_zero() {
  local error_message="         ${shifu_grey}Expected zero return code, got
           $1${shifu_reset}"
  [ $1 != 0 ] && { echo "${error_message}"; return 1; }
  return 0
}

shifu_assert_non_zero() {
  local error_message="         ${shifu_grey}Expected non-zero return code, got
           $1${shifu_reset}"
  [ $1 = 0 ] && { echo "${error_message}"; return 1; }
  return 0
}

shifu_assert_equal() {
  local first="${1:-<empty>}"
  local second="${2:-<empty>}"
  local error_message="         ${shifu_grey}Expected values to be equal, got
           ${first}
           ${second}${shifu_reset}"
  [ "${first}" != "${second}" ] && { echo "${error_message}"; return 1; }
  return 0
}

shifu_assert_arrays_equal() {
  local all=("$@")
  local midpoint=$(expr "${#all[@]}" / "2")
  local array1=("${all[@]:0:$midpoint}")
  local array2=("${all[@]:$midpoint}")
  local error_message="         ${shifu_grey}Expected arrays to be equal, got
           $(shifu_array_fmt "${array1[@]}")
           $(shifu_array_fmt "${array2[@]}")${shifu_reset}"
  [ "${#array1[@]}" -ne ${#array2[@]} ] && { echo "${error_message}"; return 1; }
  local i
  for i in $(seq 0 "${midpoint}"); do
    [ "${array1[$i]}" != "${array2[$i]}" ] && { echo "${error_message}"; return 1; }
  done
  return 0
}

test_shifu_array_filter_prefix() {
  local in_array=(arg other arg3)
  local actual=($(shifu_array_filter_prefix "arg" "${in_array[@]}"))
  local expected=(arg arg3)
  shifu_assert_arrays_equal "${actual[@]}" "${expected[@]}"
}

test_shifu_array_filter_prefix_empty_prefix() {
  local in_array=(arg other arg3)
  local actual=($(shifu_array_filter_prefix "" "${in_array[@]}"))
  local expected=(arg other arg3)
  shifu_assert_arrays_equal "${actual[@]}" "${expected[@]}"
}

test_shifu_array_contains() {
  local in_array=(arg other arg3)
  local actual=($(shifu_array_contains "arg" "${in_array[@]}"))
  local expected=true
  shifu_assert_equal "${actual}" "${expected}"
}

test_shifu_infer_function_and_arguments() {
  local script_functions=(test_, test_sub_, test_sub_func)
  local fake_arguments=(test sub func arg1 arg2)

  local expected_function_to_call="test_sub_func"
  local expected_remaining_arguments=(arg1 arg2)

  shifu_infer_function_and_arguments "${fake_arguments[@]}"; local status=$?

  local error_count=0
  shifu_assert_zero $status
  error_count=$(($error_count + $?))
  shifu_assert_equal "${function_to_call}" "${expected_function_to_call}"
  error_count=$(($error_count + $?))
  shifu_assert_arrays_equal "${remaining_arguments[@]}" "${expected_remaining_arguments[@]}"
  error_count=$(($error_count + $?))
  return $error_count
}

test_shifu_infer_function_and_arguments_only_subcommand() {
  local script_functions=(test_, test_sub_, test_sub_func)
  local fake_arguments=(test sub arg1 arg2)

  local expected_function_to_call=""

  shifu_infer_function_and_arguments "${fake_arguments[@]}"; local status=$?

  local error_count=0
  shifu_assert_non_zero $status
  error_count=$(($error_count + $?))
  shifu_assert_equal "${function_to_call}" "${expected_function_to_call}"
  error_count=$(($error_count + $?))
  return $error_count
}

shifu_run_test() {
  local test_function=$1; shift
  message=$("${test_function}" "$@")
  local test_result=$?
  if [ "${test_result}" -eq 0 ]; then
    shifu_report_success "${test_function}"
  else
    shifu_report_failure "${test_function}"
    echo "${message}"
  fi
  return ${test_result}
}

shifu_run_test_suite() {
  [ $# -gt 0 ] && [ $1 = "-v" ] && verbose=true
  shifu_read_test_functions "$(realpath $(basename $0))"
  failures=0
  for test_function in "${test_functions[@]}"; do
    shifu_run_test "${test_function}"
    failures+=$(($failures + $?))
  done
  exit "${failures}"
}

shifu_run_test_suite $@
