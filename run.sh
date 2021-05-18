#!/usr/bin/env bash

set -e

PORT="/dev/ttyUSB0"
FLASH_ESP_APP=1

CURR_DIR=$(pwd)
# ESP_PROJ_DIR=

# getopts inspired by https://stackoverflow.com/a/29754866

OPTIONS=
LONGOPTS=esp-python-env:,port:,monitor:,monitor-python-env:,fuzzer-config-file:,esp-idf-export:,no-flash,esp-proj-dir:,monitor-out:

! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    exit 2
fi

# read getopt’s output this way to handle the quoting right:
eval set -- "$PARSED"

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
        --monitor-out)
            MONITOR_OUT="$2"
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

# TODO check monitor set and monitor env set

if [ -z "${MONITOR_OUT}" ]; then
    echo "Need to specify monitor output file"
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

    # kill monitor when fuzzing ends
    trap 'kill $(jobs -p)' EXIT

    # run monitor in background
    ${MONITOR} "${MONITOR_OUT}" &

    if [ -n "${MONITOR_PYTHON_ENV}" ]; then
        deactivate
    fi
fi


######################## running fuzzer ###################################
sudo "${FUZZER}" "${FUZZER_CONFIG_FILE}"

# TODO check for root priviledges
