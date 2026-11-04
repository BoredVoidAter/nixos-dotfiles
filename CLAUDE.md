# Repository Guidelines for Claude Code

This repository contains a modular, flake-based **NixOS** configuration with integrated **Home Manager**, **sops-nix** for secrets, and out-of-store symlinked dotfiles for instant reloading.

---

## 1. System Overview & Key Metadata

- **Flake Target**: `.#nixos-btw` (System: `x86_64-linux`)
- **Primary User**: `boredvoidater` (Home: `/home/boredvoidater`)
- **Desktop Environment**: Hyprland (Wayland) with Waybar, Mako, and Vicinae launcher
- **Hardware**: Hybrid Intel iGPU + Nvidia dGPU (Prime offload enabled)
- **State Version**: `25.05`

---

## 2. Directory Structure & Architecture

