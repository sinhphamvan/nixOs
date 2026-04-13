# File cấu hình NixOS Server - Metta OS
# Dành cho việc quản lý hệ thống, Internet và chia sẻ tài nguyên xuyên nền tảng

{ config, pkgs, ... }:

{
  imports =
    [ # Bao gồm kết quả quét phần cứng mặc định
      ./hardware-configuration.nix
    ];

  # --- 1. HỆ THỐNG & BOOT ---
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  networking.hostName = "metta-server"; # Tên máy chủ

  # --- 2. QUẢN LÝ NGƯỜI DÙNG ---
  users.users.dongthan = {
    isNormalUser = true;
    description = "Thân Văn Đông";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    intialPassword = "admin123";
    packages = with pkgs; [
      # Các app dòng lệnh thiết yếu
      vim git wget curl htop btop tmux tree nix-index nh direnv
    ];
  };

  # --- 3. DỊCH VỤ QUẢN TRỊ (SSH & DOCKER) ---
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "no";
    };
  };

  virtualisation.docker.enable = true;

  # --- 4. QUẢN LÝ INTERNET (ADGUARD HOME) ---
  # Chặn quảng cáo, theo dõi truy cập và quản lý DNS nội bộ
  services.adguardhome = {
    enable = true;
    openFirewall = true; # Tự động mở port 3000 (UI) và 53 (DNS)
  };

  # --- 5. CHIA SẺ FILE (SAMBA) ---
  # Tối ưu cho cả Windows và macOS (hỗ trợ Time Machine và icon Mac)
  services.samba = {
    enable = true;
    securityType = "user";
    openFirewall = true;
    extraConfig = ''
      workgroup = WORKGROUP
      server string = MettaServer
      netbios name = MettaServer
      
      # Tối ưu cho macOS (Giao thức Fruit)
      vfs objects = catia fruit streams_xattr
      fruit:metadata = stream
      fruit:model = MacSamba
      fruit:posix_rename = yes
      fruit:veto_appledouble = no
      fruit:wipe_empty_files = yes
      fruit:nfs_aces = no
    '';
    shares = {
      "MettaStorage" = {
        path = "/srv/samba/storage";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "fruit:time machine" = "yes"; # Cho phép làm ổ backup Time Machine
      };
    };
  };

  # Tạo thư mục lưu trữ nếu chưa có
  systemd.tmpfiles.rules = [
    "d /srv/samba/storage 0775 dong users -"
  ];

  # --- 6. GIÁM SÁT HỆ THỐNG (NETDATA) ---
  # Theo dõi CPU, RAM, Network realtime tại port 19999
  services.netdata.enable = true;

  # --- 7. FIREWALL (TỔNG HỢP) ---
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 
      22    # SSH
      80 443 # HTTP/HTTPS
      3000  # AdGuard Home Web UI
      19999 # Netdata UI
      445   # Samba
    ];
    allowedUDPPorts = [ 
      53    # DNS
      67 68 # DHCP (nếu dùng AdGuard làm DHCP)
      137 138 # Samba NetBIOS
    ];
  };

  # --- 8. TỐI ƯU HÓA NIX ---
  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # --- 9. PHIÊN BẢN HỆ THỐNG ---
  # Tuyệt đối không thay đổi số này sau khi cài đặt
  system.stateVersion = "23.11"; 
}
