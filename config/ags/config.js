import App from 'resource:///com/github/Aylur/ags/app.js';
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import Variable from 'resource:///com/github/Aylur/ags/variable.js';
import Audio from 'resource:///com/github/Aylur/ags/service/audio.js';

// Poll the time
const date = Variable('', {
    poll: [1000, 'date "+%H:%M"'],
});

// Global state variable that Hyprland will toggle via CLI
const showNotch = Variable(false);
globalThis.toggleNotch = () => {
    showNotch.value = !showNotch.value;
};

function SysInfo() {
    return Widget.Box({
        class_name: 'sys-info',
        hpack: 'center',
        spacing: 16,
        children: [
            Widget.Label({
                class_name: 'clock',
                label: date.bind(),
            }),
            Widget.Label({
                class_name: 'volume',
                label: Audio.speaker.bind('volume').as(v => `  ${Math.round(v * 100)}%`),
            }),
        ],
    });
}

function Notch() {
    const revealer = Widget.Revealer({
        reveal_child: showNotch.bind(), // Binds the animation to our variable
        transition_duration: 250,
        transition: 'slide_down',
        child: Widget.Box({
            class_name: 'notch-content',
            children: [SysInfo()],
        }),
    });

    return Widget.Window({
        name: 'notch',
        anchor: ['top'],
        layer: 'overlay',
        exclusivity: 'ignore', 
        margins: [0, 0, 0, 0],
        child: revealer, // Stripped out all EventBoxes and invisible hitboxes!
    });
}

App.config({
    style: App.configDir + '/style.css',
    windows: [Notch()],
});
