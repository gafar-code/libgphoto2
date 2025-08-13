# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

libgphoto2 is a library for accessing digital cameras via USB, serial, and IP protocols. It supports over 2000 camera models and provides a uniform API for camera operations including file transfer, camera control, and remote capture.

The project consists of:
- Core library (`libgphoto2/`)
- Port drivers for communication protocols (`libgphoto2_port/`)  
- Camera-specific drivers (`camlibs/`)
- API headers (`gphoto2/`)

## Build System

The project supports two build systems:

### Autotools (Traditional)
```bash
autoreconf -is  # for git clones
./configure PKG_CONFIG_PATH="$HOME/.local/lib/pkgconfig${PKG_CONFIG_PATH+":${PKG_CONFIG_PATH}"}" --prefix="$HOME/.local"
make
make install
```

### Meson (Recommended)
```bash
meson setup builddir && cd builddir
meson compile
meson test
```

## Testing

Run tests with:
- Autotools: `make check`
- Meson: `meson test`

Individual camera driver tests are available in `camlibs/ptp2/test-*.sh` scripts.

## Code Architecture

### Core Components

1. **libgphoto2** (`libgphoto2/`): Main library providing camera abstraction
   - `gphoto2-camera.c`: Core camera operations
   - `gphoto2-filesys.c`: Virtual filesystem for cameras
   - `gphoto2-abilities-list.c`: Camera capability detection
   - `gphoto2-widget.c`: Camera configuration UI elements

2. **libgphoto2_port** (`libgphoto2_port/`): Communication abstraction layer
   - Port drivers: `usb/`, `serial/`, `ptpip/`, `libusb1/`
   - Core: `libgphoto2_port/gphoto2-port.c`

3. **Camera Libraries** (`camlibs/`): Device-specific implementations
   - `ptp2/`: PTP/MTP protocol (most modern cameras)
   - `canon/`, `nikon/`, etc.: Manufacturer-specific drivers
   - Each camlib has `library.c` (gphoto2 interface) and device-specific code

### Communication Flow

1. Application → libgphoto2 API
2. libgphoto2 → Camera library (camlib)
3. Camera library → libgphoto2_port
4. libgphoto2_port → Physical port driver (USB/serial/IP)

## Development Guidelines

### Coding Style
- Use existing file conventions
- TAB indentation, Linux kernel style braces
- Return value checking with `CHECK_RESULT` macros
- Prefix: `gp_` for public functions, `GP_` for constants

### Adding Camera Support
1. Copy `camlibs/template/` as starting point
2. Implement in `library.c` (gphoto2 interface) and device-specific files
3. Use `camera->port` for communication
4. Set up `camera->fs` filesystem callbacks for caching

### Portability Requirements
- C99 standard compliance
- Use fixed-width types (`uint8_t`, `uint32_t`) from `stdint.h`
- Use endian macros from `gphoto2-endian.h` for packet parsing
- No GCC-specific extensions

### Security Considerations
- Data from ports (USB/serial/IP) is untrusted
- Primary attack vector: malicious USB devices in kiosk scenarios
- Memory corruption and infinite loops are security issues
- Use proper bounds checking and input validation

## Key Files for Development

- `gphoto2/gphoto2.h`: Main API header
- `libgphoto2/gphoto2-camera.c`: Core camera operations  
- `camlibs/ptp2/ptp.c`: PTP protocol implementation (most cameras)
- `libgphoto2_port/libgphoto2_port/gphoto2-port.c`: Port abstraction
- `HACKING.md`: Detailed development guidelines

## Camera Driver Development

Most modern cameras use PTP/MTP protocol (`camlibs/ptp2/`). For new cameras:
1. Check if PTP driver already supports it (likely)
2. Add device IDs to `camlibs/ptp2/library.c`
3. For proprietary protocols, create new camlib in `camlibs/`

## Debug Commands

Enable debug output:
```bash
env LC_ALL=C gphoto2 --debug --debug-logfile=debug.log <command>
```

Test specific camera:
```bash
env CAMLIBS="./camlibs" gphoto2 --debug --auto-detect
```