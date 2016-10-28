#!/usr/bin/env bash

# This file is part of The RetroPie Project
# 
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
# 
# See the LICENSE.md file at the top-level directory of this distribution and 
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="lr-stella"
rp_module_desc="Atari 2600 emulator - Stella port for libretro"
rp_module_menus="2+"

function sources_lr-stella() {
    gitPullOrClone "$md_build" https://github.com/libretro/stella-libretro.git
}

function build_lr-stella() {
    make clean
    make
    md_ret_require="$md_build/stella_libretro.so"
}

function install_lr-stella() {
    md_ret_files=(
        'README.md'
        'stella_libretro.so'
    )
}

function configure_lr-stella() {
    # remove old install folder
    rm -rf "$rootdir/$md_type/stellalibretro"

    mkRomDir "atari2600"
    ensureSystemretroconfig "atari2600"

    delSystem "$md_id" "atari2600-libretro"
    addSystem 1 "$md_id" "atari2600" "$md_inst/stella_libretro.so"
}
