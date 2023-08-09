#!/usr/bin/env bash
#
# File              : run.sh
# Author            : Fabio Scatozza <s315216@studenti.polito.it>
# Date              : 09.08.2023
# Last Modified Date: 09.08.2023
#
# Copyright (c) 2023
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

script_name="./${0##*/}"

# top modules
top_modules=('p4_adder_top' 'windowed_rf_top')

# tests
tests=('Test' 'BaseTest')

# workspace cleanup
cleanup() {
    rm -rf workspace
}

trap cleanup EXIT

check_questasim() {
  if ! vsim -help 2>&1 | grep -q "Questa"; then
    echo "$script_name: QuestaSim is not installed or not in your PATH."
    exit 1
  fi
}

show_help() {

  echo "\"Step 2 - Introduction to the UVM\" launcher

System requirements:
  QuestaSim must be installed and available in your PATH.

Usage:
  $script_name -k <key> [-c <compile-options>] [plusargs]

Keys:
  choose top module and test

  1    top module     : p4 adder
       test           : src/tb/p4_adder/Test.svh
                        customized stimulus
                        coverage collection for testcases
       compile-options: nbit, nbit_per_block
                        default: 32,4


  2    top module     : p4 adder
       test           : src/tb/p4_adder/BaseTest.svh
                        default environment (no coverage collection)
                        no randomization constraints
       compile-options: nbit, nbit_per_block
                        default: 32,4

Compile Options Format:
  in a list of numeric values, the separator can't include whitespaces.

Plusargs: forwarded to the vsim call

  +n_txn=<txn number>             number of transactions
                                  default: 100

  +quiet                          suppress printer messages to screen

  +UVM_VERBOSITY=UVM_FULL         enable debugging messages
                                    - uvm report summaries
                                    - uvm testbench topology
                                    - uvm config db dump
                                    - factory configuration
                                    - info messages by components
Examples:
  $script_name -k 1
  $script_name -k 1 -c 32,8 +n_txn=10 +UVM_VERBOSITY=UVM_FULL
"
}

parse_cmdline() {

# -k and -c require values
local short_options=k:,c:,h
local long_options=help

if ! opts=$(getopt -a -n "$script_name" --longoptions "$long_options" --options "$short_options" -- "$@")
then
  return 1
fi

# replace input arguments
eval set -- "$opts"
unset opts

while true; do
  case "$1" in
    -k )
      key="$2"
      shift 2
      ;;
    -c )
      copt="$2"
      shift 2
      ;;
    -h | --help )
      show_help
      exit 0
      ;;
    -- )
      shift
      break
      ;;
    * )
      echo "Internal error!"
      exit 1
      ;;
  esac
done

# parse the remaining args
plusargs="$@"

# key is mandatory
if [ -z "$key" ]; then
  echo "Missing 'key'"
  return 1
fi

# key is a number
if ! [[ "$key" =~ ^[0-9]+$ ]]; then
  echo "Invalid 'key'"
  return 1
fi

if (( key < 1 || key > 2)); then
  echo "Out of range 'key'"
  return 1
fi

# pick top module
if (( key <= 2 )); then
  top_module="${top_modules[0]}"

  # compile options ?
  local copt_pattern='^([0-9]+)[^0-9 ]([0-9]+)$'

  if [[ "$copt" =~ $copt_pattern ]]; then
    copt="+define+NBIT=${BASH_REMATCH[1]} +define+NBIT_PER_BLOCK=${BASH_REMATCH[2]}"
  elif [[ -z "$copt" ]]; then
    copt="+define+NBIT=32 +define+NBIT_PER_BLOCK=4"
  elif [[ -n "$copt" ]]; then
    echo "Invalid 'compile-options'"
    return 1
  fi

else
  top_module="${top_modules[1]}"

  #TODO compile options

fi

# validate plusargs
local plusargs_pattern='^(\+[a-zA-Z_]+(=[^ ]+)?( \+[a-zA-Z_]+(=[^ ]+)?)*)?$'

if ! [[ "$plusargs" =~ $plusargs_pattern ]]; then
  echo "Invalid 'plusargs'"
  return 1
fi

# test selection
plusargs="+UVM_TESTNAME=${tests[$((key-1))]} $plusargs"

return 0

}

make_out_dir() {

# top_module ends with '_top'
out_dir="out/${top_module/_top//}"

# Iterate through matches and update
local copt_pattern='\+define\+(\w+)=([^ ]+)'
local copt_="$copt"

while [[ "$copt_" =~ $copt_pattern ]]; do

  out_dir="${out_dir}-${BASH_REMATCH[1]}${BASH_REMATCH[2]}"

  # Remove the processed match from $copt
  copt_="${copt_/${BASH_REMATCH[0]}/}"

done

# remove initial /-
out_dir="${out_dir/\/-//}"

# if the directory already exists, clean it
rm -rf "$out_dir"
mkdir -p "$out_dir"

}

if ! parse_cmdline "$@"; then
  echo "Try '$script_name -h' for more information."
  exit 1
fi

check_questasim

make_out_dir

# pass arguments to 'main.do'
export LAUNCHER_PROJ_DIR="$(pwd)"
export LAUNCHER_PROJ_OUT_DIR="$out_dir"
export LAUNCHER_TOP_MODULE="$top_module"
export LAUNCHER_COPT="$copt"
export LAUNCHER_PLUSARGS="$plusargs"

# run QuestaSim logging to file
if ! vsim -batch -do "do ./scripts/main.do" &> "${out_dir}/vsim.log"; then
  echo "$script_name: vsim error."
  echo "The log is in '${out_dir}/vsim.log'"
  exit 1
fi

echo "Outputs written in '$out_dir'"
exit 0
