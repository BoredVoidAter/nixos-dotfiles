# modules/unity.nix
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    unityhub
    dotnet-sdk_8        # Unity 2023+ generally uses .NET 8
    mono                # Still required by some Unity legacy tooling
    omnisharp-roslyn    # Language Server for Neovim
    netcoredbg          # For debugging C# in Neovim
  ];

  # Force Unity/Dotnet to respect your Wayland/Dark theme preferences where possible
  home.sessionVariables = {
    DOTNET_ROOT = "${pkgs.dotnet-sdk_8}";
  };
}
