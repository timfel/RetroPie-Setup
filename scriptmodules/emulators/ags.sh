#!/usr/bin/env bash

# This file is part of The RetroPie Project
# 
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
# 
# See the LICENSE.md file at the top-level directory of this distribution and 
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="ags"
rp_module_desc="Adventure Game Studio - Adventure game engine"
rp_module_menus="4+"
rp_module_flags="!x86 !mali"

function depends_ags() {
    local depends=(pkg-config  libaldmb1-dev libfreetype6-dev libtheora-dev libvorbis-dev libogg-dev)
    if [[ "$__raspbian_ver" -lt 8 ]]; then
        depends+=(liballegro4.2-dev)
    else
        depends+=(liballegro4-dev)
    fi
    getDepends ${depends[@]}
}

function sources_ags() {
    gitPullOrClone "$md_build" https://github.com/adventuregamestudio/ags.git
}

function build_ags() {
    make -C Engine clean
    make -C Engine
}

function install_ags() {
    make -C Engine PREFIX="$md_inst" install
}

function configure_ags() {
    mkRomDir "ags"
    
    addSystem 1 "$md_id" "ags" "xinit $md_inst/bin/ags --fullscreen %ROM%" "Adventure Game Studio" ".exe"
}
