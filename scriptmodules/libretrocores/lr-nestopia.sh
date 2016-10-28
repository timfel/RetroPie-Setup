#!/usr/bin/env bash

# This file is part of The RetroPie Project
# 
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
# 
# See the LICENSE.md file at the top-level directory of this distribution and 
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="lr-nestopia"
rp_module_desc="NES emu - Nestopia (enhanced) port for libretro"
rp_module_menus="2+"

function sources_lr-nestopia() {
    gitPullOrClone "$md_build" https://github.com/libretro/nestopia.git
}

function build_lr-nestopia() {
    cd libretro
    rpSwap on 512
    make clean
    make
    rpSwap off
    md_ret_require="$md_build/libretro/nestopia_libretro.so"
}

function install_lr-nestopia() {
    md_ret_files=(
        'libretro/nestopia_libretro.so'
        'NstDatabase.xml'
        'README.md'
        'README.unix'
        'changelog.txt'
        'readme.html'
        'COPYING'
        'AUTHORS'
    )
}

function configure_lr-nestopia() {
    # remove old install folder
    rm -rf "$rootdir/$md_type/nestopia"

    mkRomDir "nes"
    mkRomDir "fds"
    ensureSystemretroconfig "nes"
    ensureSystemretroconfig "fds"

    delSystem "$md_id" "nes-nestopia"
    addSystem 0 "$md_id" "nes" "$md_inst/nestopia_libretro.so"
    addSystem 1 "$md_id" "fds" "$md_inst/nestopia_libretro.so"
}
