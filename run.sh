#!/usr/bin/env bash

# More safety, by turning some bugs into errors.
# Without `errexit` you don’t need ! and can replace
# PIPESTATUS with a simple $?, but I don’t do that.
set -o errexit -o pipefail -o noclobber -o nounset

# -allow a command to fail with !’s side effect on errexit
# -use return value from ${PIPESTATUS[0]}, because ! hosed $?
! getopt --test > /dev/null 
if [[ ${PIPESTATUS[0]} -ne 4 ]]; then
    echo 'I’m sorry, `getopt --test` failed in this environment.'
    exit 1
fi

ESP_PYTHON_ENV="/home/adam/esp/esp-idf/venv/bin/activate"
PORT="/dev/ttyUSB0"
MONITOR="/home/adam/dev/dp/py_esp_monitor/main.py"
MONITOR_PYTHON_ENV="/home/adam/dev/dp/py_esp_monitor/venv/bin/activate"
FUZZER="/home/adam/dev/dp/cpp/build/src/wi_fuzz"
FUZZER_CONFIG_FILE="/home/adam/dev/dp/cpp/conf/wifuzz.yaml"
ESP_IDF_EXPORT="/home/adam/esp/esp-idf/export.sh"

CURR_DIR=$(pwd)
ESP_PROJ_DIR="/home/adam/dev/dp/test_runner/test/station"



OPTIONS=
# LONGOPTS=debug,force,output:,verbose
LONGOPTS=esp-python-env:,port:,monitor:,monitor-python-env:,fuzzer-config-file:,esp-idf-export:

# -regarding ! and PIPESTATUS see above
# -temporarily store output to be able to check for errors
# -activate quoting/enhanced mode (e.g. by writing out “--options”)
# -pass arguments only via   -- "$@"   to separate them correctly
! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    # e.g. return value is 1
    #  then getopt has complained about wrong arguments to stdout
    exit 2
fi
# read getopt’s output this way to handle the quoting right:
eval set -- "$PARSED"

d=n
# now enjoy the options in order and nicely split until we see --
while true; do
    case "$1" in
        --esp-python-env)
            ESP_PYTHON_ENV="$2"
            shift 2
            ;;
        --port)
            PORT="$2"
            shift 2
            ;;
        --monitor)
            MONITOR="$2"
            shift 2
            ;;
        --monitor-python-env)
            MONITOR_PYTHON_ENV="$2"
            shift 2
            ;;
        --fuzzer-config-file)
            FUZZER_CONFIG_FILE="$2"
            shift 2
            ;;
        --esp-idf-export)
            ESP_IDF_EXPORT="$2"
            shift 2
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Programming error"
            exit 3
            ;;
    esac
done

# handle non-option arguments
if [[ $# -ne 2 ]]; then
    echo $#
    echo "$0: TODO print usage"
    exit 4
fi

FUZZER=${1}
ESP_PROJ_DIR=${2}

# set -e

# TODO
# source correct env
# if python env is added as parameter

# TODO check for root priviledges

echo "ESP_PYTHON_ENV" ${ESP_PYTHON_ENV}
echo PORT ${PORT}
echo MONITOR ${MONITOR}
echo MONITOR_PYTHON_ENV ${MONITOR_PYTHON_ENV}
echo FUZZER ${FUZZER}
echo FUZZER_CONFIG_FILE ${FUZZER_CONFIG_FILE}
echo ESP_IDF_EXPORT ${ESP_IDF_EXPORT}
echo ESP_PROJ_DIR ${ESP_PROJ_DIR}

# ################ SETTING UP ESP-IDF ##################

# # check if venv exists
# if [ -f "${ESP_PYTHON_ENV}" ]; then
#     echo "Using virtualenv: " ${ESP_PYTHON_ENV}
#     # shellcheck source=/dev/null
#     source "${ESP_PYTHON_ENV}"
# else 
#     echo "$FILE does not exist."
#     exit 1
# fi

# echo ${PORT}


# # TODO check esp_proj_dir, port, python_env, esp-idf/export.sh

# # shellcheck source=/dev/null
# source ${ESP_IDF_EXPORT}


# ################ BUILDING AND FLASHING PROBE ##################

# cd ${ESP_PROJ_DIR}
# idf.py build
# idf.py -p ${PORT} flash
# cd "${CURR_DIR}"


# # kill monitor when fuzzing ends
# trap 'kill $(jobs -p)' EXIT

# monitor() {
#     # shellcheck source=/dev/null
#     source ${MONITOR_PYTHON_ENV}

#     # run monitor
#     ${MONITOR}
# }

# ############## RUNNING FUZZER WITH MONITOR #####################

# # run monitor in background
# monitor &

# # run fuzzer as sudo
# sudo ${FUZZER} ${FUZZER_CONFIG_FILE}
