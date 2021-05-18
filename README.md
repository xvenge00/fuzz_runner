# ESP TEST RUNNER
A convenient script to build and flash test programs to the ESP32, run monitor and fuzzer at the same time.

## Usage
To build and flash test programs user must have the ESP-IDF installed.

The options can be passed by the command line arguments or by environment variables.

### Example

```shell
./run.sh \
    --monitor-python-env ~/dev/dp/py_esp_monitor/venv/bin/activate \
    --monitor ../bin/monitor.py \
    --monitor-out ../monitor_out \
    --esp-python-env ~/esp/esp-idf/venv/bin/activate \
    --esp-idf-export ~/esp/esp-idf/export.sh \
    --port /dev/ttyUSB0 \
    ../bin/wifuzz++ ./test/prb_resp
```

### Monitor
Monitor probe doesn't have to be run.
If you want to run the probe, the fuzzer configuration must be set to grpc probe.

#### Environment
The monitor can run in its own virtual environment.
To load it either set the environment variable:
```shell
export MONITOR_PYTHON_ENV=~/monitor/venv/bin/activate
```
or set the program argument:
```shell
--monitor-python-env ~/monitor/venv/bin/activate
```

#### Monitor path
The monitor path can be set by:
```shell
export MONITOR=../bin/monitor/monitor.py
```
or by program argument:
```shell
--monitor ../bin/monitor/monitor.py
```

### Monitor output
When monitor is running the ESP serial output is saved into specified output file.
```shell
export MONITOR_OUT=../monitor_out
```
or
```shell
--monitor-out ../monitor_out
```

The output can be monitored by the command:
```shell
tail -f ../monitor_out
```

### ESP builder

#### Skipping
The build and flash of the test programs can be skipped by specifying `--no-flash`

#### Environment
The ESP-IDF requires environment to run.
It is usually installed in `~/esp/esp-idf`
It uses python virtualenv and its own environment script `export.sh`

To set the paths through environment variables:
```shell
export ESP_PYTHON_ENV=~/esp/esp-idf/venv/bin/activate
export ESP_IDF_EXPORT=~/esp/esp-idf/export.sh
```

or they can be set by program arguments

```shell
--esp-python-env ~/esp/esp-idf/venv/bin/activate --esp-idf-export ~/esp/esp-idf/export.sh
```

### Fuzzer
The last two parameters are the path to the fuzzer and the test folder.

## Folder structure
The expected folder structure for each test is:
```
├── conf.yaml
└── esp/
    ├── CMakeLists.txt
    ├── main/
    └── sdkconfig
```
