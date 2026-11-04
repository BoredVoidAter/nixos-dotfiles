#!/usr/bin/env bash
# DaVinci Resolve wrapper with optimized environment for memory/GPU
# Includes FHS environment variables from nixpkgs package wrapper

# Force use of NVIDIA GPU with proper offload
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export __VK_LAYER_NV_optimus=NVIDIA_only
export DRI_PRIME=1

# CUDA device selection (use first Nvidia GPU)
export CUDA_VISIBLE_DEVICES=0

# FHS environment variables from nixpkgs davinci-resolve package wrapper
# These are critical for the AppImage/FHS environment to work correctly
export QT_XKB_CONFIG_ROOT="/run/current-system/sw/share/X11/xkb"
export QT_PLUGIN_PATH="${QT_PLUGIN_PATH:-/run/current-system/sw/lib/qt6/plugins}"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-/run/current-system/sw/lib:/run/current-system/sw/lib32}"

# GPU memory settings for DaVinci Resolve
# Limit GPU memory usage to prevent "GPU memory full" errors
# RTX 2060 has 6GB VRAM - limit to ~4.5GB (4608 MB) leaving ~1.5GB for system/compositor
export RESOLVE_GPU_MEMORY_LIMIT=4608

# OpenCL/ICD configuration for Nvidia
export OCL_ICD_VENDORS="/run/current-system/sw/etc/OpenCL/vendors"
export OPENCL_VENDOR_PATH="/run/current-system/sw/etc/OpenCL/vendors"

# Qt/Wayland settings
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export QT_AUTO_SCREEN_SCALE_FACTOR=1

# GStreamer settings
export GST_GL_API=gles2
export GST_GL_PLATFORM=wayland

# VA-API settings
export GST_VAAPI_ALL_DRIVERS=1
export LIBVA_DRIVER_NAME=nvidia

# Memory management
export MALLOC_ARENA_MAX=2

# Disable problematic features that can cause memory issues
export MESA_LOADER_DRIVER_OVERRIDE=nvidia
export __GL_SYNC_TO_VBLANK=0

# Run DaVinci Resolve
exec davinci-resolve "$@"