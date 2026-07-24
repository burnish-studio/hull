{ config, pkgs, lib, ... }:
{
  # WSL2 cannot set up cgroup namespace delegation for user session managers;
  # systemd's executor fails with EBUSY when Delegate=yes is in effect.
  # Override to Delegate=no — safe because we run no user-level services in WSL.
  systemd.packages = [
    (pkgs.writeTextDir "lib/systemd/system/user@.service.d/wsl.conf" ''
      [Service]
      Delegate=no
    '')
  ];
}
