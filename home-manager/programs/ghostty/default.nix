{ pkgs }:
{
  programs.ghostty = {
    enable = true;
    package = pkgs.ghostty-bin;
    enableFishIntegration = true;
    clearDefaultKeybinds = true;
    settings = {
      font-family = "HackGen Console NF";
      font-size = 14;
      cursor-style = "block";
      cursor-style-blink = false;
      window-padding-x = 8;
      window-padding-y = 8;
      background-opacity = 0.85;
      theme = "tokyonight";
      macos-option-as-alt = true;
      window-save-state = "always";
      macos-titlebar-style = "tabs";

      keybind = [
        # general
        "super+w=close_surface"
        "super+q=quit"
        "super+z=undo"
        "super+shift+z=redo"
        "super+shift+i=inspector:toggle"
        "super+shift+comma=reload_config"

        # font size
        "super+equal=increase_font_size:1"
        "super+minus=decrease_font_size:1"
        "super+0=reset_font_size"

        # copy & paste
        "super+c=copy_to_clipboard"
        "copy=copy_to_clipboard"
        "super+v=paste_from_clipboard"
        "paste=paste_from_clipboard"

        # split
        "ctrl+j>minus=new_split:down"
        "ctrl+j>backslash=new_split:right"
        "ctrl+j>h=goto_split:left"
        "ctrl+j>j=goto_split:down"
        "ctrl+j>k=goto_split:up"
        "ctrl+j>l=goto_split:right"
        "ctrl+j>shift+period=resize_split:up,10"
        "ctrl+j>shift+comma=resize_split:down,10"

        # tab
        "super+t=new_tab"
        "ctrl+tab=next_tab"
      ];
    };
  };
}
