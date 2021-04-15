#!/usr/bin/env bash

set -e



# TODO
# source correct env
# if python env is added as parameter

# TODO check for root priviledges


ESP_PYTHON_ENV="/home/adam/esp/esp-idf/venv/bin/activate"
PORT="/dev/ttyUSB0"
MONITOR="/home/adam/dev/dp/py_esp_monitor/main.py"
MONITOR_PYTHON_ENV="/home/adam/dev/dp/py_esp_monitor/venv/bin/activate"
FUZZER="/home/adam/dev/dp/cpp/build/src/wi_fuzz"
FUZZER_CONFIG_FILE="/home/adam/dev/dp/cpp/conf/wifuzz.yaml"
ESP_IDF_EXPORT="/home/adam/esp/esp-idf/export.sh"

CURR_DIR=$(pwd)
ESP_PROJ_DIR="/home/adam/dev/dp/test_runner/test/station"

################ SETTING UP ESP-IDF ##################

# check if venv exists
if [ -f "${ESP_PYTHON_ENV}" ]; then
    echo "Using virtualenv: " ${ESP_PYTHON_ENV}
    # shellcheck source=/dev/null
    source "${ESP_PYTHON_ENV}"
else 
    echo "$FILE does not exist."
    exit 1
fi

echo ${PORT}


# TODO check esp_proj_dir, port, python_env, esp-idf/export.sh

# shellcheck source=/dev/null
source ${ESP_IDF_EXPORT}


################ BUILDING AND FLASHING PROBE ##################

cd ${ESP_PROJ_DIR}
idf.py build
idf.py -p ${PORT} flash
cd "${CURR_DIR}"


# kill monitor when fuzzing ends
trap 'kill $(jobs -p)' EXIT

monitor() {
    # shellcheck source=/dev/null
    source ${MONITOR_PYTHON_ENV}

    # run monitor
    ${MONITOR}
}

############## RUNNING FUZZER WITH MONITOR #####################

# run monitor in background
monitor &

# run fuzzer as sudo
sudo ${FUZZER} ${FUZZER_CONFIG_FILE}
