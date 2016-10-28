#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="bluetooth"
rp_module_desc="Configure Bluetooth Devices"
rp_module_menus="3+"
rp_module_flags="nobin !x86"

function depends_bluetooth() {
    getDepends bluetooth python-dbus python-gobject
}

function get_script_bluetooth() {
    name="$1"
    if ! which "$name"; then
        [[ "$name" == "bluez-test-input" ]] && name="bluez-test-device"
        name="$scriptdir/scriptmodules/supplementary/$md_id/$name"
    fi
    echo "$name"
}

function list_available_bluetooth() {
    local mac_address
    local device_name
    if hasPackage bluez 5; then
        # create a named pipe & fd for input for bluetoothctl
        local fifo="$(mktemp -u)"
        mkfifo "$fifo"
        exec 3<>"$fifo"
        local line
        while read -r -n12 line; do
            if [[ "$line" == *"[bluetooth]"* ]]; then
                echo "scan on" >&3
                read -r line
                sleep 5
                break
            fi
        # read from bluetoothctl buffered line by line
        done < <(stdbuf -oL bluetoothctl <&3)
        exec 3>&-
        rm -f "$fifo"

        while read mac_address; read device_name; do
            echo "$mac_address"
            echo "$device_name"
        done < <(echo "devices" | bluetoothctl 2>/dev/null | grep "^Device " | cut -d" " -f2,3- | sed 's/ /\n/')

    else
        while read; read mac_address; read device_name; do
            echo "$mac_address"
            echo "$device_name"
        done < <(hcitool scan --flush | tail -n +2 | sed 's/\t/\n/g')
    fi
}

function list_registered_bluetooth() {
    local line
    local mac_address
    local device_name
    while read line; do
        mac_address=$(echo $line | sed 's/ /,/g' | cut -d, -f1)
        device_name=$(echo $line | sed -e 's/'"$mac_address"' //g')
        echo -e "$mac_address\n$device_name"
    done < <($(get_script_bluetooth bluez-test-device) list)
}

function display_active_and_registered_bluetooth() {
    local registered
    local active

    registered="$($(get_script_bluetooth bluez-test-device) list 2>&1)"
    [[ -z "$registered" ]] && registered="There are no registered devices"

    if [[ "$(hcitool con)" != "Connections:" ]]; then
        active="$(hcitool con 2>&1 | sed -e 1d)"
    else
        active="There are no active connections"
    fi

    printMsgs "dialog" "Registered Devices:\n\n$registered\n\n\nActive Connections:\n\n$active"
}

function remove_bluetooth() {
    local mac_addresses=()
    local mac_address
    local device_names=()
    local device_name
    local options=()
    while read mac_address; read device_name; do
        mac_addresses+=("$mac_address")
        device_names+=("$device_name")
        options+=("$mac_address" "$device_name")
    done < <(list_registered_bluetooth)

    if [[ ${#mac_addresses[@]} -eq 0 ]] ; then
        printMsgs "dialog" "There are no devices to remove."
    else
        local cmd=(dialog --backtitle "$__backtitle" --menu "Please choose the bluetooth device you would like to remove" 22 76 16)
        choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        [[ -z "$choice" ]] && return

        remove_bluetooth_device=$($(get_script_bluetooth bluez-test-device) remove $choice)
        if [[ -z "$remove_bluetooth_device" ]] ; then
            printMsgs "dialog" "Device removed"
        else
            printMsgs "dialog" "An error occurred removing the bluetooth device. Please ensure you typed the mac address correctly"
        fi
    fi
}

function connect_bluetooth() {
    local mac_addresses=()
    local mac_address
    local device_names=()
    local device_name
    local options=()

    while read mac_address; read device_name; do
        mac_addresses+=("$mac_address")
        device_names+=("$device_name")
        options+=("$mac_address" "$device_name")
    done < <(list_available_bluetooth)

    if [[ ${#mac_addresses[@]} -eq 0 ]] ; then
        printMsgs "dialog" "No devices were found. Ensure device is on and try again"
        return
    fi

    local cmd=(dialog --backtitle "$__backtitle" --menu "Please choose the bluetooth device you would like to connect to" 22 76 16)
    choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    [[ -z "$choice" ]] && return

    mac_address="$choice"

    local cmd=(dialog --backtitle "$__backtitle" --menu "Please choose the security mode - Try the first one, then second if that fails" 22 76 16)
    options=(
        1 "DisplayYesNo"
        2 "KeyboardDisplay"
    )
    choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    [[ -z "$choice" ]] && return

    local opts=""
    [[ "$choice" == "1" ]] && opts="-c DisplayYesNo"

    # create a named pipe & fd for input for bluez-simple-agent
    local fifo="$(mktemp -u)"
    mkfifo "$fifo"
    exec 3<>"$fifo"
    local line
    local pin
    local error=""
    while read -r line; do
        case "$line" in
            "RequestPinCode"*)
                cmd=(dialog --nocancel --backtitle "$__backtitle" --menu "Please choose a pin" 22 76 16)
                options=(
                    1 "Pin 0000"
                    2 "Enter own Pin"
                )
                choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
                pin="0000"
                if [[ "$choice" == "2" ]]; then
                    pin=$(dialog --backtitle "$__backtitle" --inputbox "Please enter a pin" 10 60 2>&1 >/dev/tty)
                fi
                dialog --backtitle "$__backtitle" --infobox "Please enter pin $pin on your bluetooth device" 10 60
                echo "$pin" >&3
                # read "Enter PIN Code:"
                read -n 15 line
                ;;
            "DisplayPasskey"*|"DisplayPinCode"*)
                # extract key from end of line
                # DisplayPasskey (/org/bluez/1284/hci0/dev_01_02_03_04_05_06, 123456)
                [[ "$line" =~ ,\ (.+)\) ]] && pin=${BASH_REMATCH[1]}
                dialog --backtitle "$__backtitle" --infobox "Please enter pin $pin on your bluetooth device" 10 60
                ;;
            "Release")
                success=1
                ;;
            "Creating device failed"*)
                error="$line"
                ;;
        esac
    # read from bluez-simple-agent buffered line by line
    done < <(stdbuf -oL $(get_script_bluetooth bluez-simple-agent) $opts hci0 "$mac_address" <&3)
    exec 3>&-
    rm -f "$fifo"

    if [[ -z "$error" ]]; then
        error=$($(get_script_bluetooth bluez-test-device) trusted "$mac_address" yes 2>&1)
        if [[ -z "$error" ]] ; then
            error=$($(get_script_bluetooth bluez-test-input) connect "$mac_address" 2>&1)
            if [[ -z "$error" ]]; then
                printMsgs "dialog" "Successfully registered and connected to $mac_address"
                return 0
            fi
        fi
    fi

    printMsgs "dialog" "An error occurred connecting to the bluetooth device ($error)"
    return 1
}

function configure_bluetooth() {
    while true; do
        local cmd=(dialog --backtitle "$__backtitle" --menu "Configure Bluetooth Devices" 22 76 16)
        local options=(
            1 "Register and Connect to Bluetooth Device"
            2 "Unregister and Remove Bluetooth Device"
            3 "Display Registered & Connected Bluetooth Devices"
        )
        local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        if [[ -n "$choice" ]]; then
            case $choice in
                1)
                    connect_bluetooth
                    ;;
                2)
                    remove_bluetooth
                    ;;
                3)
                    display_active_and_registered_bluetooth
                    ;;
            esac
        else
            break
        fi
    done
}
