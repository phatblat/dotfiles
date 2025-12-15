# Embedded Toolchain

Execute embedded systems development operations including compilation, flashing, serial monitoring, and debugging for microcontrollers and single-board computers.

## Capability

This skill executes embedded toolchain operations for Arduino, ESP32/ESP8266, ARM Cortex-M, AVR, RISC-V, and other embedded platforms. It returns structured results with build output, flash status, serial data, and debugging information.

## Supported Platforms

### Microcontrollers
- **Arduino** (AVR, ARM, ESP32) - Arduino IDE, Arduino CLI
- **ESP32/ESP8266** - ESP-IDF, Arduino, PlatformIO
- **STM32** (ARM Cortex-M) - STM32CubeIDE, OpenOCD, GCC ARM
- **Nordic nRF** (ARM Cortex-M) - nRF SDK, Segger
- **Raspberry Pi Pico** (RP2040) - Pico SDK, MicroPython
- **Atmel AVR** - avr-gcc, avrdude
- **RISC-V** - RISC-V GCC toolchain

### Single-Board Computers
- **Raspberry Pi** - Raspbian, Linux GPIO
- **BeagleBone** - Debian, PRU, Device Tree
- **Jetson Nano** - Ubuntu, CUDA

## Supported Operations

### Build Operations
- **compile** - Compile source code to firmware
- **build** - Full build including linking
- **clean** - Clean build artifacts

### Flash Operations
- **flash** - Flash firmware to device
- **erase** - Erase device flash memory
- **verify** - Verify flashed firmware

### Debug Operations
- **debug** - Start GDB debugging session
- **attach** - Attach debugger to running device
- **breakpoint** - Set/remove breakpoints

### Monitor Operations
- **serial-monitor** - Open serial port monitor
- **serial-write** - Write data to serial port
- **serial-read** - Read data from serial port

### Utility Operations
- **list-devices** - List connected devices
- **device-info** - Get device information
- **upload-filesystem** - Upload filesystem (SPIFFS, LittleFS)

## Usage Protocol

Agents invoke this skill by specifying operation parameters:

```json
{
  "action": "compile",
  "platform": "esp32",
  "toolchain": "esp-idf",
  "projectPath": "my-project/",
  "board": "esp32dev",
  "config": {
    "optimization": "O2",
    "defines": ["DEBUG=1", "LOG_LEVEL=INFO"]
  }
}
```

### Parameters

- **action** (required): Operation to execute
- **platform** (required): Target platform (arduino, esp32, stm32, etc.)
- **toolchain** (required): Build toolchain (arduino-cli, esp-idf, platformio, etc.)
- **projectPath** (required): Path to project directory
- **board** (optional): Target board identifier
- **port** (optional): Serial port for flash/monitor operations
- **config** (optional): Build configuration options
- **timeout** (optional): Timeout in seconds (default: 300s)

## Build Configurations

### Arduino (Arduino CLI)

```json
{
  "action": "compile",
  "platform": "arduino",
  "toolchain": "arduino-cli",
  "projectPath": "arduino-project/",
  "board": "arduino:avr:uno",
  "config": {
    "sketchFile": "main.ino",
    "libraries": ["DHT sensor library", "Adafruit Unified Sensor"],
    "buildProperties": {
      "compiler.cpp.extra_flags": "-DDEBUG"
    }
  }
}
```

### ESP32 (ESP-IDF)

```json
{
  "action": "build",
  "platform": "esp32",
  "toolchain": "esp-idf",
  "projectPath": "esp32-project/",
  "board": "esp32",
  "config": {
    "sdkconfig": {
      "CONFIG_ESPTOOLPY_FLASHSIZE_4MB": true,
      "CONFIG_FREERTOS_HZ": 1000,
      "CONFIG_ESP_WIFI_STATIC_RX_BUFFER_NUM": 10
    },
    "target": "esp32"
  }
}
```

### STM32 (ARM GCC + OpenOCD)

```json
{
  "action": "compile",
  "platform": "stm32",
  "toolchain": "arm-none-eabi-gcc",
  "projectPath": "stm32-project/",
  "board": "stm32f407",
  "config": {
    "mcuFlags": "-mcpu=cortex-m4 -mthumb -mfpu=fpv4-sp-d16 -mfloat-abi=hard",
    "defines": ["STM32F407xx", "USE_HAL_DRIVER"],
    "optimization": "Os",
    "linkerScript": "STM32F407VGTx_FLASH.ld"
  }
}
```

### PlatformIO (Universal)

```json
{
  "action": "build",
  "platform": "platformio",
  "toolchain": "platformio",
  "projectPath": "pio-project/",
  "board": "esp32dev",
  "config": {
    "environment": "esp32dev",
    "buildFlags": ["-DDEBUG_SERIAL", "-O2"]
  }
}
```

## Flash Configurations

### Flash to Arduino

```json
{
  "action": "flash",
  "platform": "arduino",
  "toolchain": "arduino-cli",
  "projectPath": "arduino-project/",
  "board": "arduino:avr:uno",
  "port": "/dev/ttyUSB0",
  "config": {
    "baudRate": 115200,
    "verify": true
  }
}
```

### Flash to ESP32

```json
{
  "action": "flash",
  "platform": "esp32",
  "toolchain": "esptool",
  "firmwarePath": "build/firmware.bin",
  "port": "/dev/ttyUSB0",
  "config": {
    "baudRate": 921600,
    "flashMode": "dio",
    "flashFreq": "40m",
    "flashSize": "4MB",
    "offset": "0x10000",
    "eraseFlash": false
  }
}
```

### Flash to STM32 (OpenOCD)

```json
{
  "action": "flash",
  "platform": "stm32",
  "toolchain": "openocd",
  "firmwarePath": "build/firmware.elf",
  "config": {
    "interface": "stlink-v2",
    "target": "stm32f4x",
    "resetAfterFlash": true,
    "verify": true
  }
}
```

### Flash via J-Link

```json
{
  "action": "flash",
  "platform": "nrf52",
  "toolchain": "jlink",
  "firmwarePath": "build/firmware.hex",
  "config": {
    "device": "nRF52832_xxAA",
    "interface": "SWD",
    "speed": 4000,
    "eraseChip": false
  }
}
```

## Serial Monitor Configurations

### Open Serial Monitor

```json
{
  "action": "serial-monitor",
  "port": "/dev/ttyUSB0",
  "config": {
    "baudRate": 115200,
    "dataBits": 8,
    "parity": "none",
    "stopBits": 1,
    "outputFormat": "text",
    "timestampLines": true
  }
}
```

### Write to Serial Port

```json
{
  "action": "serial-write",
  "port": "/dev/ttyUSB0",
  "config": {
    "baudRate": 115200,
    "data": "Hello Device\n",
    "encoding": "ascii"
  }
}
```

## Output Format

Returns structured JSON execution report:

```json
{
  "executionReport": {
    "timestamp": "2025-12-14T14:30:00Z",
    "action": "compile",
    "platform": "esp32",
    "toolchain": "esp-idf",
    "exitCode": 0,
    "duration": "45.3s",
    "status": "success",
    "artifacts": {
      "firmware": "build/firmware.bin",
      "bootloader": "build/bootloader.bin",
      "partitionTable": "build/partition-table.bin",
      "elf": "build/firmware.elf"
    },
    "metadata": {
      "firmwareSize": "512KB",
      "ramUsage": "45KB",
      "flashUsage": "38%",
      "ramUsagePercent": "14%",
      "compiledFiles": 157,
      "warnings": 2,
      "errors": 0
    }
  }
}
```

### Successful Compilation (ESP32)

```json
{
  "executionReport": {
    "timestamp": "2025-12-14T14:30:00Z",
    "action": "compile",
    "platform": "esp32",
    "toolchain": "esp-idf",
    "projectPath": "my-esp32-project/",
    "board": "esp32dev",
    "exitCode": 0,
    "duration": "45.3s",
    "status": "success",
    "stdout": "Executing action: all (aliases: build)\n...",
    "artifacts": {
      "firmware": "build/firmware.bin",
      "bootloader": "build/bootloader/bootloader.bin",
      "partitionTable": "build/partition_table/partition-table.bin",
      "elf": "build/firmware.elf",
      "map": "build/firmware.map"
    },
    "metadata": {
      "firmwareSize": "524288 bytes",
      "flashUsage": "38%",
      "ramUsage": "45312 bytes",
      "ramUsagePercent": "14%",
      "compiledFiles": 157,
      "linkedLibraries": 23,
      "warnings": 2,
      "errors": 0,
      "espIdfVersion": "v5.1.2"
    }
  }
}
```

### Successful Flash (Arduino)

```json
{
  "executionReport": {
    "timestamp": "2025-12-14T14:31:00Z",
    "action": "flash",
    "platform": "arduino",
    "toolchain": "arduino-cli",
    "board": "arduino:avr:uno",
    "port": "/dev/ttyUSB0",
    "exitCode": 0,
    "duration": "8.2s",
    "status": "success",
    "stdout": "avrdude: AVR device initialized...",
    "metadata": {
      "bytesFlashed": 15234,
      "flashSpeed": "115200 baud",
      "verified": true,
      "programmer": "arduino",
      "chipSignature": "0x1e950f"
    }
  }
}
```

### Serial Monitor Output

```json
{
  "executionReport": {
    "timestamp": "2025-12-14T14:32:00Z",
    "action": "serial-monitor",
    "port": "/dev/ttyUSB0",
    "baudRate": 115200,
    "status": "running",
    "data": [
      {"timestamp": "14:32:01.123", "line": "Device started"},
      {"timestamp": "14:32:02.456", "line": "WiFi connected: 192.168.1.100"},
      {"timestamp": "14:32:03.789", "line": "Temperature: 23.5C"}
    ],
    "metadata": {
      "linesReceived": 3,
      "bytesReceived": 87,
      "duration": "3.5s"
    }
  }
}
```

### Debug Session Started

```json
{
  "executionReport": {
    "timestamp": "2025-12-14T14:33:00Z",
    "action": "debug",
    "platform": "stm32",
    "toolchain": "openocd",
    "exitCode": 0,
    "duration": "2.1s",
    "status": "success",
    "metadata": {
      "debugger": "gdb",
      "gdbPort": 3333,
      "telnetPort": 4444,
      "targetHalted": true,
      "breakpointsSet": 2,
      "debugAdapter": "stlink-v2"
    }
  }
}
```

## Compilation Errors

### Build Error

```json
{
  "executionReport": {
    "timestamp": "2025-12-14T14:34:00Z",
    "action": "compile",
    "platform": "esp32",
    "toolchain": "esp-idf",
    "exitCode": 1,
    "duration": "12.3s",
    "status": "failed",
    "errors": [
      {
        "file": "main/main.c",
        "line": 45,
        "column": 12,
        "severity": "error",
        "message": "implicit declaration of function 'gpio_set_level'",
        "code": "[-Wimplicit-function-declaration]"
      },
      {
        "file": "main/main.c",
        "line": 67,
        "column": 5,
        "severity": "error",
        "message": "unknown type name 'gpio_num_t'",
        "code": null
      }
    ],
    "metadata": {
      "compiledFiles": 89,
      "failedFile": "main/main.c",
      "totalErrors": 2,
      "totalWarnings": 5
    }
  }
}
```

## Error Handling

Returns structured error information for:

- **Compilation errors**: Syntax errors, missing includes, type errors
- **Linker errors**: Undefined references, memory overflow
- **Flash errors**: Device not found, connection failed, verification failed
- **Serial errors**: Port not found, permission denied, timeout
- **Toolchain errors**: Compiler not found, missing dependencies
- **Device errors**: Device not responding, wrong firmware, incompatible board

Example error response:

```json
{
  "error": {
    "type": "flash-failed",
    "platform": "esp32",
    "message": "Failed to connect to device",
    "port": "/dev/ttyUSB0",
    "exitCode": 1,
    "stderr": "esptool.py: Serial port /dev/ttyUSB0 - Device not found",
    "solution": "Check USB connection, ensure device is in bootloader mode, verify port: ls /dev/tty*"
  }
}
```

### Device Not Found

```json
{
  "error": {
    "type": "device-not-found",
    "port": "/dev/ttyUSB0",
    "message": "No device found on specified port",
    "availablePorts": ["/dev/ttyUSB1", "/dev/ttyACM0"],
    "solution": "Verify device connection. Available ports: /dev/ttyUSB1, /dev/ttyACM0"
  }
}
```

### Memory Overflow

```json
{
  "error": {
    "type": "linker-error",
    "platform": "arduino",
    "message": "Sketch too big for device memory",
    "details": {
      "programSize": 34816,
      "maxProgramSize": 32256,
      "overflow": 2560,
      "dataSize": 1234,
      "maxDataSize": 2048
    },
    "solution": "Reduce code size: disable debug logging, optimize libraries, use PROGMEM for constants"
  }
}
```

### Permission Denied (Serial Port)

```json
{
  "error": {
    "type": "permission-denied",
    "port": "/dev/ttyUSB0",
    "message": "Permission denied accessing serial port",
    "solution": "Add user to dialout group: sudo usermod -a -G dialout $USER (logout required)"
  }
}
```

### Toolchain Not Found

```json
{
  "error": {
    "type": "toolchain-not-found",
    "toolchain": "esp-idf",
    "message": "ESP-IDF toolchain not found in PATH",
    "requiredTools": ["idf.py", "xtensa-esp32-elf-gcc"],
    "solution": "Install ESP-IDF: https://docs.espressif.com/projects/esp-idf/en/latest/get-started/"
  }
}
```

## Platform-Specific Tools

### Arduino
- **arduino-cli** - Arduino command-line interface
- **avrdude** - AVR programmer
- **avr-gcc** - AVR compiler

### ESP32/ESP8266
- **esp-idf** - Espressif IoT Development Framework
- **esptool.py** - ESP32/ESP8266 flash tool
- **xtensa-esp32-elf-gcc** - Xtensa compiler

### STM32
- **arm-none-eabi-gcc** - ARM compiler
- **openocd** - On-chip debugger
- **st-link** - STM32 programmer
- **stm32cubemx** - Configuration tool

### General
- **platformio** - Universal embedded development platform
- **gdb** - GNU debugger
- **jlink** - Segger J-Link tools

## Tool Requirements

### Core Tools (install as needed)
- **Arduino CLI**: `curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh`
- **ESP-IDF**: `https://docs.espressif.com/projects/esp-idf/en/latest/get-started/`
- **PlatformIO**: `pip install platformio`
- **ARM GCC**: `brew install arm-none-eabi-gcc` or `apt install gcc-arm-none-eabi`
- **OpenOCD**: `brew install openocd` or `apt install openocd`

## Constraints

This skill does NOT:
- Select hardware platforms or components
- Design circuit schematics or PCB layouts
- Write firmware code or implement algorithms
- Debug application logic beyond toolchain errors
- Recommend platform selection criteria
- Optimize code for performance or power
- Configure communication protocols
- Design interrupt handlers or real-time systems
- Provide hardware troubleshooting beyond device detection
- Make architectural decisions

## Performance Considerations

### Build Times
- Arduino (AVR): 5-15 seconds
- ESP32 (ESP-IDF): 30-90 seconds (first build), 5-20 seconds (incremental)
- STM32 (ARM GCC): 10-60 seconds
- PlatformIO: Similar to native toolchains

### Flash Times
- Arduino (AVR): 5-10 seconds
- ESP32: 10-30 seconds (depending on firmware size)
- STM32 (OpenOCD): 5-15 seconds
- STM32 (J-Link): 2-8 seconds (faster)

## Common Embedded Workflows

### Compile and Flash Arduino

```json
{
  "action": "compile",
  "platform": "arduino",
  "toolchain": "arduino-cli",
  "projectPath": "blink-project/",
  "board": "arduino:avr:uno"
}
```

Then:

```json
{
  "action": "flash",
  "platform": "arduino",
  "toolchain": "arduino-cli",
  "projectPath": "blink-project/",
  "board": "arduino:avr:uno",
  "port": "/dev/ttyUSB0"
}
```

### Build and Flash ESP32

```json
{
  "action": "build",
  "platform": "esp32",
  "toolchain": "esp-idf",
  "projectPath": "wifi-project/"
}
```

Then:

```json
{
  "action": "flash",
  "platform": "esp32",
  "toolchain": "esp-idf",
  "projectPath": "wifi-project/",
  "port": "/dev/ttyUSB0"
}
```

### Monitor Serial Output

```json
{
  "action": "serial-monitor",
  "port": "/dev/ttyUSB0",
  "config": {
    "baudRate": 115200,
    "timestampLines": true
  }
}
```

### Debug STM32 with OpenOCD

```json
{
  "action": "debug",
  "platform": "stm32",
  "toolchain": "openocd",
  "firmwarePath": "build/firmware.elf",
  "config": {
    "interface": "stlink-v2",
    "target": "stm32f4x",
    "gdbPort": 3333
  }
}
```
