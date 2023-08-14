# File              : main.do
# Description       : QuestaSim shell script, launched by run.sh. It
#                     orchestrates: source files collection, dependency
#                     resolution, simulation run, coverage report generation
#                     and the post-processing of the applied stimulus.
# Author            : Fabio Scatozza <s315216@studenti.polito.it>
# Date              : 02.06.2023
# Last Modified Date: 14.08.2023
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

# batch customization
onerror  {exit -code 20}
onfinish stop

# get arguments from launcher
set proj_dir        $::env(LAUNCHER_PROJ_DIR)
set out_dir         $::env(LAUNCHER_PROJ_OUT_DIR)

set top_module      $::env(LAUNCHER_TOP_MODULE)
set top_module_dir  [regsub {_top} $top_module {}]
set copt            $::env(LAUNCHER_COPT)
set plusargs        $::env(LAUNCHER_PLUSARGS)

# load the directory tree
set src_dir         $proj_dir/src
set script_dir      $proj_dir/scripts

set artifacts_dir   $proj_dir/workspace
file mkdir $artifacts_dir 

# create the work library
vlib $artifacts_dir/work
vmap work $artifacts_dir/work

# recursive glob
source $script_dir/findFiles.tcl

# compilation with dependency resolution
source $script_dir/autocompile.tcl

# compile vhdl sources 
set vhdl_compile_command "vcom -explicit -stats=none"

if { [autocompile $vhdl_compile_command [findFiles $src_dir/rtl/$top_module_dir "*.vhd"]] } {
  echo "main.do: compilation of vhdl sources failed"
  abort all
}

# then systemverilog
set sv_compile_command "vlog -sv $copt -stats=none"

if { [autocompile $sv_compile_command [findFiles $src_dir/tb/$top_module_dir "*.sv"]] } {
  echo "main.do: compilation of systemverilog sources failed"
  abort all
}

vsim -sv_seed random $top_module {*}$plusargs +printer_file=$out_dir/printer.log +scoreboard_file=$out_dir/scoreboard.log
run -all

# report coverage

# -all
# When reporting toggles, creates a report that lists both toggled
# and untoggled signals. Reports counts of all enumeration values.
# Not a valid option when reporting on a functional coverage database.

# -cvg 
# Adds covergroup coverage data to the report.

# -details
# Includes details associated with each coverage item in the output (FEC).
# By default, details are not provided. You cannot use this argument with -recursive.

# -directive
# Reports only cover directive coverage data.

# -srcfile=<filename>[+<filename>]
# Reports the coverage data for the specified source files. By default, all source
# information is included. You can use wildcards (*).

coverage report -all -cvg -details -directive -output $out_dir/func_cover.rpt

# extract the stimulus vectors prepending Sv_Seed for repeatability
source $script_dir/log2csv.tcl
log2csv $out_dir/printer.log $out_dir/scoreboard.log $Sv_Seed $out_dir/extract.csv

exit

