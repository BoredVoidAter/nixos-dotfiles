{ pkgs, lib, config, ... }:

{
  # ========================================================================
  # SECURITY HARDENING - Reasonable Desktop Hardening
  # ========================================================================

  # -------------------------------------------------------------------------
  # Firewall - Restrict incoming connections
  # -------------------------------------------------------------------------
  networking.firewall = {
    enable = true;
    # Only allow explicitly defined ports
    allowedTCPPorts = [ 22 53317 8080 9090 ]; # SSH + your custom ports
    allowedUDPPorts = [ 53317 ];
    # Log rejected packets for debugging
    logRefusedPackets = true;
    logRefusedConnections = true;
  };

  # -------------------------------------------------------------------------
  # SSH Hardening
  # -------------------------------------------------------------------------
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;           # Keys only
      KbdInteractiveAuthentication = false;     # No keyboard-interactive
      PermitRootLogin = "no";                   # No root login
      # SFTP is controlled via Subsystem directive in extraConfig if needed
    };
    extraConfig = ''
      # Crypto hardening
      Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
      MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,umac-128-etm@openssh.com
      KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512
      # Security features
      AuthenticationMethods publickey
      MaxAuthTries 3
      LoginGraceTime 30
      ClientAliveInterval 300
      ClientAliveCountMax 2
      X11Forwarding no
      AllowAgentForwarding no
      AllowStreamLocalForwarding no
      AllowTcpForwarding no
      PermitEmptyPasswords no
      PermitUserEnvironment no
      PrintMotd no
      # Debanner no  # Not a valid option
    '';
  };

  # -------------------------------------------------------------------------
  # Nix Access Control - Limit who can use nix
  # -------------------------------------------------------------------------
  nix.settings = {
    # Only wheel group can use nix (sudo users)
    allowed-users = [ "@wheel" ];
    # Require signatures on binary cache
    require-sigs = true;
    # Don't automatically trust new substituters
    trusted-substituters = [
      "https://cache.nixos.org"
      "https://nixos.cachix.org"
      "https://cuda-maintainers.cachix.org"
      "https://vicinae.cachix.org"
      "https://boredvoidater-dotfiles.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nixos.cachix.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5U="
      "vicinae.cachix.org-1:b67slZMcPnvEtL5mB5g7pSmD898Wmsr0pIgb78a/Xlg="
      "boredvoidater-dotfiles.cachix.org-1:Lw1knkMWYS0Zdc/xpPT+98s0nNio12ziYASKjps5790="
    ];
  };

  # -------------------------------------------------------------------------
  # Kernel Hardening via sysctl
  # -------------------------------------------------------------------------
  boot.kernel.sysctl = {
    # Network hardening
    "net.ipv4.tcp_syncookies" = 1;
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.default.accept_source_route" = 0;
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    # Kernel hardening
    "kernel.dmesg_restrict" = 1;
    "kernel.kptr_restrict" = 2;
    "kernel.yama.ptrace_scope" = 1;
    "kernel.unprivileged_bpf_disabled" = 1;
    "kernel.perf_event_paranoid" = 3;
    # Filesystem hardening
    "fs.protected_hardlinks" = 1;
    "fs.protected_symlinks" = 1;
    "fs.protected_fifos" = 2;
    "fs.protected_regular" = 2;
    # ASLR
    "vm.mmap_rnd_bits" = 32;
    "vm.mmap_rnd_compat_bits" = 16;
  };

  # -------------------------------------------------------------------------
  # Sudo Hardening
  # -------------------------------------------------------------------------
  security.sudo = {
    enable = true;
    # Only wheel group can use sudo
    wheelNeedsPassword = true;
  };

  # -------------------------------------------------------------------------
  # Remove unnecessary default packages
  # -------------------------------------------------------------------------
  environment.defaultPackages = lib.mkForce [ ];

  # -------------------------------------------------------------------------
  # Audit Logging - Track important events
  # -------------------------------------------------------------------------
  security.audit = {
    enable = true;
    rules = [
      # Track execve (program execution)
      "-a exit,always -F arch=b64 -S execve -F key=exec"
      # Track file modifications in sensitive areas
      "-w /etc/passwd -p wa -k passwd_changes"
      "-w /etc/shadow -p wa -k shadow_changes"
      "-w /etc/sudoers -p wa -k sudoers_changes"
      "-w /etc/ssh/sshd_config -p wa -k sshd_config_changes"
      # Track mount/unmount
      "-a exit,always -F arch=b64 -S mount -S umount2 -k mount"
      # Track privilege escalation
      "-a exit,always -F arch=b64 -S setuid -S setgid -S setreuid -S setregid -k priv_esc"
      # Track kernel module loading (NixOS paths)
      "-w /run/current-system/sw/bin/insmod -p x -k modules"
      "-w /run/current-system/sw/bin/rmmod -p x -k modules"
      "-w /run/current-system/sw/bin/modprobe -p x -k modules"
    ];
  };

  # -------------------------------------------------------------------------
  # Core Dump Handling - Hardened: collect but restrict access
  # -------------------------------------------------------------------------
  systemd.coredump.enable = true;
  systemd.coredump.settings.Coredump = {
    Storage = "external";           # Store in /var/lib/systemd/coredump
    Compress = "zstd";              # Compress dumps
    ProcessSizeMax = "2G";          # Max dump size
    ExternalSizeMax = "10G";        # Max total storage
    MaxUse = "5G";                  # Disk quota
    KeepSize = "1G";                # Keep at least this much free
  };
  # Restrict access to root only (default is root:systemd-coredump 0640)
  systemd.tmpfiles.rules = [
    "d /var/lib/systemd/coredump 0700 root root -"
  ];

  # -------------------------------------------------------------------------
  # AppArmor - Mandatory Access Control (optional, enable if desired)
  # -------------------------------------------------------------------------

  # -------------------------------------------------------------------------
  # AppArmor - Mandatory Access Control (optional, enable if desired)
  # -------------------------------------------------------------------------
  # security.apparmor = {
  #   enable = true;
  #   profiles = [ ];
  # };

  # -------------------------------------------------------------------------
  # Automatic Security Updates
  # -------------------------------------------------------------------------
  system.autoUpgrade = {
    enable = true;
    # Run daily at 3 AM
    flags = [ "--keep-going" ];
    # Only install security updates automatically
    # (you'll still need to run nixos-rebuild switch manually for major updates)
  };

  # -------------------------------------------------------------------------
  # Disable unused filesystems
  # -------------------------------------------------------------------------
  # Blacklist uncommon filesystems
  boot.blacklistedKernelModules = [
    "cramfs"
    "freevxfs"
    "jffs2"
    "hfs"
    "hfsplus"
    "squashfs"
    "udf"
    "affs"
    "ecryptfs"
    "befs"
    "sysv"
    "ufs"
  ];

  # -------------------------------------------------------------------------
  # USBGuard - Control USB device access (optional)
  # -------------------------------------------------------------------------
  # services.usbguard = {
  #   enable = true;
  #   # Generate initial policy with: usbguard generate-policy
  # };

  # -------------------------------------------------------------------------
  # Hardened malloc (optional - can break some apps)
  # -------------------------------------------------------------------------
  # environment.memoryAllocator = {
  #   provider = pkgs.hardened_malloc;
  # };
}
