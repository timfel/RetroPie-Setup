#!/usr/bin/env bash

# This file is part of The RetroPie Project
# 
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
# 
# See the LICENSE.md file at the top-level directory of this distribution and 
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="lr-fceumm"
rp_module_desc="NES emu - FCEUmm port for libretro"
rp_module_menus="2+"

function sources_lr-fceumm() {
    gitPullOrClone "$md_build" https://github.com/libretro/libretro-fceumm.git
}

function build_lr-fceumm() {
    make -f Makefile.libretro clean
    make -f Makefile.libretro
    md_ret_require="$md_build/fceumm_libretro.so"
}

function install_lr-fceumm() {
    md_ret_files=(
        'Authors'
        'changelog.txt'
        'Copying'
        'fceumm_libretro.so'
        'whatsnew.txt'
        'zzz_todo.txt'
    )
}

function configure_lr-fceumm() {
    # remove old install folders
    rm -rf "$rootdir/$md_type/neslibretro"
    rm -rf "$rootdir/$md_type/lr-fceu-next"

    mkRomDir "nes"
    ensureSystemretroconfig "nes"

    delSystem "lr-fceu-next" "nes"
    addSystem 1 "$md_id" "nes" "$md_inst/fceumm_libretro.so"
}
