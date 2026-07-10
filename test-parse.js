const { parse } = require("./modules/pill/lib/binds.js");

const testInput = [
  'bind = $mod, space, exec, qs ipc call pill launcher eDP-1',
  'bind = $mod, Q, killactive',
  'bind = $mod SHIFT, Left, movewindow, l',
  'binde = $mod CTRL, Left, resizeactive, -20 0',
  'bindm = $mod, mouse:272, movewindow',
  'bind = , Print, exec, grim ~/screenshots/$(date +%Y-%m-%d_%H-%M-%S).png && notify-send "Screenshot Saved"',
  'bind = SUPER, F12, exec, hyprctl activeworkspace -j >> /tmp/fs-debug.log 2>&1',
].join("\n");

const result = parse(testInput);
console.log(JSON.stringify(result, null, 2));