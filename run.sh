#!/usr/bin/env bash

# More safety, by turning some bugs into errors.
# Without `errexit` you don’t need ! and can replace
# PIPESTATUS with a simple $?, but I don’t do that.
# set -o errexit -o pipefail -o noclobber -o nounset

# -allow a command to fail with !’s side effect on errexit
# -use return value from ${PIPESTATUS[0]}, because ! hosed $?
# ! getopt --test > /dev/null 
# if [[ ${PIPESTATUS[0]} -ne 4 ]]; then
#     echo 'I’m sorry, `getopt --test` failed in this environment.'
#     exit 1
# fi

# ESP_PYTHON_ENV="/home/adam/esp/esp-idf/venv/bin/activate"
# PORT="/dev/ttyUSB0"
# MONITOR="/home/adam/dev/dp/py_esp_monitor/main.py"
# MONITOR_PYTHON_ENV="/home/adam/dev/dp/py_esp_monitor/venv/bin/activate"
# FUZZER="/home/adam/dev/dp/cpp/build/src/wi_fuzz"
# FUZZER_CONFIG_FILE="/home/adam/dev/dp/cpp/conf/wifuzz.yaml"
# ESP_IDF_EXPORT="/home/adam/esp/esp-idf/export.sh"

# CURR_DIR=$(pwd)
# ESP_PROJ_DIR="/home/adam/dev/dp/test_runner/test/station"

set -e

PORT="/dev/ttyUSB0"
# MONITOR=
# MONITOR_PYTHON_ENV=
# FUZZER_CONFIG_FILE=
ESP_IDF_EXPORT="$HOME/esp/esp-idf/export.sh"
FLASH_ESP_APP=1

CURR_DIR=$(pwd)
# ESP_PROJ_DIR=



OPTIONS=
LONGOPTS=esp-python-env:,port:,monitor:,monitor-python-env:,fuzzer-config-file:,esp-idf-export,no-flash,--esp-proj-dir:

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
        --esp-proj-dir)
            ESP_PROJ_DIR="$2"
            shift 2
            ;;
        --no-flash)
            FLASH_ESP_APP=0
            shift
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
TEST_DIR=${2}


################# check for correct config ##############################
if [ ! -f "${FUZZER}" ]; then
    echo "Specified fuzzer executable doesn't exist ${FUZZER}"
    exit 1
fi

if [ ! -d "${TEST_DIR}" ]; then
    echo "Specified test directory doesn't exist: ${TEST_DIR}"
    exit 1
fi

if [ ! -c "${PORT}" ]; then
    echo "specified device port doesn't exist: ${PORT}"
    exit 1
fi

if [ -z "${FUZZER_CONFIG_FILE}" ]; then
    FUZZER_CONFIG_FILE=${TEST_DIR}/conf.yaml
fi
if [ ! -f "${FUZZER_CONFIG_FILE}" ]; then
    echo "specified fuzzer config file doesn't exist: ${FUZZER_CONFIG_FILE}"
    exit 1
fi

if [ ! -f "${ESP_IDF_EXPORT}" ]; then
    echo "Specified esp export file doesn't exist ${ESP_IDF_EXPORT}"
    exit 1
fi

if [ -n "${ESP_PYTHON_ENV}" ] && [ ! -f "${ESP_PYTHON_ENV}" ]; then
    echo "Specified python env for ESP doesn't exist ${ESP_PYTHON_ENV}"
    exit 1
fi

if [ -n "${MONITOR_PYTHON_ENV}" ] && [ ! -f "${MONITOR_PYTHON_ENV}" ]; then
    echo "Specified python env for monitor doesn't exist ${MONITOR_PYTHON_ENV}"
    exit 1
fi

if [ -z "${ESP_PROJ_DIR}" ]; then
    ESP_PROJ_DIR="${TEST_DIR}/esp"
fi
if [ ! -d "${ESP_PROJ_DIR}" ]; then
    echo "Specified project dir doesn't exist ${ESP_PROJ_DIR}"
    exit 1
fi


################## building and flashing esp app ########################

if [ "$FLASH_ESP_APP" -eq 1 ]; then
    echo "Flashing the app through the port: ${PORT}"

    # load python venv for esp-idf
    if [ -n "${ESP_PYTHON_ENV}" ]; then
        # shellcheck source=/dev/null
        source "${ESP_PYTHON_ENV}"
    fi

    # export esp-idf
    if [ -f "${ESP_IDF_EXPORT}" ]; then
        # shellcheck source=/dev/null
        source "${ESP_IDF_EXPORT}"
    else
        echo "ESP-IDF export file doesn't exists: ${ESP_IDF_EXPORT}"
        exit 5
    fi

    # build and flash
    cd "${ESP_PROJ_DIR}"
    idf.py build
    idf.py -p "${PORT}" flash
    cd "${CURR_DIR}"

    # deactivate python venv
    if [ -n "${ESP_PYTHON_ENV}" ]; then
        deactivate
    fi
fi

######################## running monitor ################################
if [ -n "${MONITOR}" ]; then
    # should run monitor
    echo "running monitor"

    if [ -n "${MONITOR_PYTHON_ENV}" ]; then
        # shellcheck source=/dev/null
        source "${MONITOR_PYTHON_ENV}"
    fi

    monitor() {
        # shellcheck source=/dev/null
        source ${MONITOR_PYTHON_ENV}

        # run monitor
        ${MONITOR}
    }

    # kill monitor when fuzzing ends
    trap 'kill $(jobs -p)' EXIT

    # run monitor in background
    monitor &

    if [ -n "${MONITOR_PYTHON_ENV}" ]; then
        deactivate
    fi
fi


######################## running fuzzer ###################################
sudo "${FUZZER}" "${FUZZER_CONFIG_FILE}"

# TODO check for root priviledges
