{ pkgs, ... }:

let
  pythonEvdev = pkgs.python3.withPackages (ps: [ ps.evdev ]);

  kbm2padPy = pkgs.writeText "kbm2pad.py" ''
    #!/usr/bin/env python3
    import argparse
    import math
    import selectors
    import signal
    import sys
    import time
    from evdev import AbsInfo, InputDevice, UInput, ecodes as e, list_devices

    KEY_TO_BTN = {
        e.KEY_SPACE: e.BTN_SOUTH,       # Cross (Jump)
        e.KEY_C: e.BTN_EAST,            # Circle (Crouch/Slide)
        e.KEY_LEFTCTRL: e.BTN_EAST,
        e.KEY_R: e.BTN_WEST,            # Square (Reload/Use)
        e.KEY_1: e.BTN_NORTH,           # Triangle (Swap Weapon)
        e.KEY_TAB: e.BTN_NORTH,
        e.KEY_Q: e.BTN_TL,              # L1 (Tactical)
        e.KEY_E: e.BTN_TR,              # R1 (Lethal)
        e.KEY_V: e.BTN_THUMBR,          # R3 (Melee)
        e.KEY_F: e.BTN_THUMBR,
        e.KEY_ESC: e.BTN_START,         # Options
        e.KEY_M: e.BTN_SELECT,          # Share / Touchpad (remap in Control4Free if needed)
    }

    CAPABILITIES = {
        e.EV_KEY: [
            e.BTN_SOUTH, e.BTN_EAST, e.BTN_NORTH, e.BTN_WEST,
            e.BTN_TL, e.BTN_TR, e.BTN_SELECT, e.BTN_START,
            e.BTN_MODE, e.BTN_THUMBL, e.BTN_THUMBR,
        ],
        e.EV_ABS: [
            (e.ABS_X, AbsInfo(0, -32768, 32767, 16, 128, 0)),
            (e.ABS_Y, AbsInfo(0, -32768, 32767, 16, 128, 0)),
            (e.ABS_RX, AbsInfo(0, -32768, 32767, 16, 128, 0)),
            (e.ABS_RY, AbsInfo(0, -32768, 32767, 16, 128, 0)),
            (e.ABS_Z, AbsInfo(0, 0, 255, 0, 0, 0)),
            (e.ABS_RZ, AbsInfo(0, 0, 255, 0, 0, 0)),
            (e.ABS_HAT0X, AbsInfo(0, -1, 1, 0, 0, 0)),
            (e.ABS_HAT0Y, AbsInfo(0, -1, 1, 0, 0, 0)),
        ],
    }

    def find_input_devices():
        devs = []
        for path in list_devices():
            try:
                dev = InputDevice(path)
                if "X-Box 360" in dev.name:
                    continue
                caps = dev.capabilities()
                has_rel_mouse = e.EV_REL in caps and e.REL_X in caps[e.EV_REL] and e.REL_Y in caps[e.EV_REL]
                has_kbd = e.EV_KEY in caps and e.KEY_W in caps[e.EV_KEY] and e.KEY_F8 in caps[e.EV_KEY]
                if has_rel_mouse or has_kbd:
                    devs.append(dev)
            except Exception:
                pass
        return devs

    def main():
        parser = argparse.ArgumentParser(description="Mouse+Keyboard to Virtual Xbox 360 Controller")
        parser.add_argument("--sens", type=float, default=1.35, help="Mouse sensitivity (default: 1.35)")
        parser.add_argument("--deadzone", type=float, default=0.18, help="Inner stick deadzone jump 0.0-0.4 (default: 0.18)")
        parser.add_argument("--no-autosprint", action="store_true", help="Disable W auto-sprint")
        args = parser.parse_args()

        devices = find_input_devices()
        if not devices:
            print("No keyboard/mouse devices found under /dev/input/event*.")
            sys.exit(1)

        ui = UInput(CAPABILITIES, name="Microsoft X-Box 360 pad", vendor=0x045E, product=0x028E, version=0x0110)
        sel = selectors.DefaultSelector()
        for d in devices:
            sel.register(d, selectors.EVENT_READ)
            print(f"Listening: {d.path} ({d.name})")

        grabbed = False
        held = set()
        dx_acc = 0.0
        dy_acc = 0.0
        vx = 0.0
        vy = 0.0
        last_rx = 0
        last_ry = 0
        last_l3 = 0

        def set_grab(state: bool):
            nonlocal grabbed, held, dx_acc, dy_acc, vx, vy
            if state == grabbed:
                return
            for d in devices:
                try:
                    d.grab() if state else d.ungrab()
                except Exception as exc:
                    print(f"Grab error on {d.name}: {exc}")
            grabbed = state
            held.clear()
            dx_acc = dy_acc = vx = vy = 0.0
            # Reset sticks & triggers to neutral
            for code in (e.ABS_X, e.ABS_Y, e.ABS_RX, e.ABS_RY, e.ABS_Z, e.ABS_RZ, e.ABS_HAT0X, e.ABS_HAT0Y):
                ui.write(e.EV_ABS, code, 0)
            for btn in CAPABILITIES[e.EV_KEY]:
                ui.write(e.EV_KEY, btn, 0)
            ui.syn()
            print(f"[{'LOCKED to Gamepad' if grabbed else 'RELEASED to Desktop'}] (Press F8 to toggle)")

        def cleanup(*_):
            set_grab(False)
            ui.close()
            sys.exit(0)

        signal.signal(signal.SIGINT, cleanup)
        signal.signal(signal.SIGTERM, cleanup)

        print("Ready! Currently RELEASED. Open Control4Free/chiaki, then press F8 to lock controls.")

        tick = 1.0 / 120.0
        next_t = time.monotonic()

        try:
            while True:
                now = time.monotonic()
                timeout = max(0.0, next_t - now)
                for key, _ in sel.select(timeout=timeout):
                    dev = key.fileobj
                    try:
                        for ev in dev.read():
                            if ev.type == e.EV_KEY and ev.code == e.KEY_F8 and ev.value == 0:
                                set_grab(not grabbed)
                                continue

                            if not grabbed:
                                continue

                            if ev.type == e.EV_REL:
                                if ev.code == e.REL_X:
                                    dx_acc += ev.value
                                elif ev.code == e.REL_Y:
                                    dy_acc += ev.value

                            elif ev.type == e.EV_KEY and ev.value in (0, 1):
                                down = ev.value == 1
                                if down:
                                    held.add(ev.code)
                                else:
                                    held.discard(ev.code)

                                if ev.code == e.BTN_LEFT:
                                    ui.write(e.EV_ABS, e.ABS_RZ, 255 if down else 0)
                                elif ev.code == e.BTN_RIGHT:
                                    ui.write(e.EV_ABS, e.ABS_Z, 255 if down else 0)
                                elif ev.code in KEY_TO_BTN:
                                    ui.write(e.EV_KEY, KEY_TO_BTN[ev.code], 1 if down else 0)
                                elif ev.code == e.KEY_UP:
                                    ui.write(e.EV_ABS, e.ABS_HAT0Y, -1 if down else 0)
                                elif ev.code == e.KEY_DOWN:
                                    ui.write(e.EV_ABS, e.ABS_HAT0Y, 1 if down else 0)
                                elif ev.code == e.KEY_LEFT:
                                    ui.write(e.EV_ABS, e.ABS_HAT0X, -1 if down else 0)
                                elif ev.code == e.KEY_RIGHT:
                                    ui.write(e.EV_ABS, e.ABS_HAT0X, 1 if down else 0)
                                elif ev.code in (e.KEY_W, e.KEY_S, e.KEY_A, e.KEY_D):
                                    lx = (32767 if e.KEY_D in held else 0) - (32768 if e.KEY_A in held else 0)
                                    ly = (32767 if e.KEY_S in held else 0) - (32768 if e.KEY_W in held else 0)
                                    ui.write(e.EV_ABS, e.ABS_X, lx)
                                    ui.write(e.EV_ABS, e.ABS_Y, ly)
                    except BlockingIOError:
                        pass

                now = time.monotonic()
                if now >= next_t:
                    next_t = now + tick
                    if grabbed:
                        # Smooth mouse velocity with fast decay so stopping feels crisp
                        vx = vx * 0.40 + (dx_acc * args.sens * 0.045)
                        vy = vy * 0.40 + (dy_acc * args.sens * 0.045)
                        dx_acc = 0.0
                        dy_acc = 0.0

                        mag = math.hypot(vx, vy)
                        if mag < 0.015:
                            rx = ry = 0
                            vx = vy = 0.0
                        else:
                            # Jump past console inner deadzone + mild non-linear curve
                            clamped = min(1.0, mag)
                            curved = args.deadzone + (1.0 - args.deadzone) * (clamped ** 0.85)
                            scale = curved / mag
                            rx = max(-32768, min(32767, int(vx * scale * 32767)))
                            ry = max(-32768, min(32767, int(vy * scale * 32767)))

                        # Auto-sprint when W is held, unless walking (Shift), aiming, firing, reloading, or crouching
                        want_l3 = 0
                        if not args.no_autosprint:
                            blocking = {e.KEY_LEFTSHIFT, e.BTN_RIGHT, e.BTN_LEFT, e.KEY_R, e.KEY_C, e.KEY_LEFTCTRL}
                            if e.KEY_W in held and not (held & blocking):
                                want_l3 = 1
                        elif e.KEY_LEFTSHIFT in held:
                            want_l3 = 1

                        changed = (rx != last_rx) or (ry != last_ry) or (want_l3 != last_l3)
                        if rx != last_rx:
                            ui.write(e.EV_ABS, e.ABS_RX, rx)
                            last_rx = rx
                        if ry != last_ry:
                            ui.write(e.EV_ABS, e.ABS_RY, ry)
                            last_ry = ry
                        if want_l3 != last_l3:
                            ui.write(e.EV_KEY, e.BTN_THUMBL, want_l3)
                            last_l3 = want_l3
                        if changed:
                            ui.syn()
        finally:
            cleanup()

    if __name__ == "__main__":
        main()
  '';

  kbm2pad = pkgs.writeShellScriptBin "kbm2pad" ''
    exec ${pythonEvdev}/bin/python3 ${kbm2padPy} "$@"
  '';
in
{
  home.packages = [
    kbm2pad
  ];
}
