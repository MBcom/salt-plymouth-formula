# 1. Install Plymouth and KMS-related firmware
install_plymouth_packages:
  pkg.installed:
    - pkgs:
      - plymouth
      - plymouth-themes
      - firmware-linux
      # - firmware-misc-nonfree # Example: uncomment if needed for specific hardware
    - refresh: False