-- Fox Den desktop service
-- These are launched once whenever a new Hyprland session starts

hl.on("hyprland.start",
function()
	hl.exec_cmd("waybar")
	hl.exec_cmd("swaync")
	hl.exec_cmd("hyprpaper")
	hl.exec_cmd("fcitx5 -d")
	hl.exec_cmd("systemctl --user start hyprpolkitagent.service")
	hl.exec_cmd('mpvpaper --fork --auto-stop --auto-mode FULL -o "no-audio --loop-file=inf" eDP-1 "$HOME/Pictures/Wallpapers/FoxDen/foxden_max_animation_wallpaper"')
end)
