{ pkgs, ... }:

{
  home.packages = with pkgs; [
    todoist          # Phenomenal open-source CLI
    todoist-electron # Official Desktop GUI
  ];
}
