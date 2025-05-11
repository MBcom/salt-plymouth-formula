{%- from tpldir ~ "/map.jinja" import plymouth with context %}

# State to configure Plymouth with a custom logo and progress bar splash

# Define theme name and path variables
{% set theme_name = plymouth.theme %}
{% set theme_path = '/usr/share/plymouth/themes/' + theme_name %}


# 2. Create the directory for the custom theme
create_custom_theme_directory:
  file.directory:
    - name: {{ theme_path }}
    - user: root
    - group: root
    - mode: '0755'
    - makedirs: True
    - require:
      - pkg: install_plymouth_packages

# 3. Copy the custom logo image
plymouth_copy_theme:
  file.recurse:
    - name: {{ theme_path }}
    - source: salt://plymouth/files/{{ theme_name }}
    - user: root
    - group: root
    - file_mode: '0644'
    - require:
      - file: create_custom_theme_directory

# 8. Configure GRUB settings in /etc/default/grub (Same as before)
configure_grub_for_plymouth:
  cmd.run:
    - name: |
        changed=0
        # Ensure GRUB_GFXMODE is set (auto usually works)
        if ! grep -q '^GRUB_GFXMODE=' /etc/default/grub; then
          echo 'GRUB_GFXMODE=auto' >> /etc/default/grub && changed=1
        elif ! grep -q '^GRUB_GFXMODE=auto' /etc/default/grub; then
          sed -i -E 's/^#?(GRUB_GFXMODE=.*)/GRUB_GFXMODE=auto/' /etc/default/grub && changed=1
        fi

        # Process GRUB_CMDLINE_LINUX_DEFAULT
        current_cmdline=$(grep '^GRUB_CMDLINE_LINUX_DEFAULT=' /etc/default/grub | cut -d= -f2-)
        current_cmdline_nq=$(echo "$current_cmdline" | sed -e 's/^"//' -e 's/"$//')
        new_cmdline=$(echo "$current_cmdline_nq" | sed -E 's/\bnomodeset\b//g' | sed 's/  */ /g' | sed 's/^ //; s/ $//')
        if ! echo "$new_cmdline" | grep -q '\bquiet\b'; then new_cmdline="quiet $new_cmdline"; fi
        if ! echo "$new_cmdline" | grep -q '\bsplash\b'; then new_cmdline="$new_cmdline splash"; fi
        new_cmdline=$(echo "$new_cmdline" | sed 's/  */ /g' | sed 's/^ //; s/ $//')

        if [ "$current_cmdline" != "\"$new_cmdline\"" ]; then
          sed -i -E "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"$new_cmdline\"|" /etc/default/grub && changed=1
        fi

        if [ "$changed" -eq 1 ]; then exit 0; else exit 1; fi
    - onlyif: test -f /etc/default/grub
    - unless: 
       - |
            grep -q '^GRUB_GFXMODE=auto' /etc/default/grub && \
            grep -q '^GRUB_CMDLINE_LINUX_DEFAULT=".*quiet.*splash.*"' /etc/default/grub
    - require:
      - pkg: install_plymouth_packages

# 9. Set the new theme as default and update initramfs
set_plymouth_default_theme:
  cmd.run:
    # Using -R updates the initramfs automatically
    - name: plymouth-set-default-theme {{ theme_name }} -R
    - require:
      - file: plymouth_copy_theme
    - watch:
      - file: plymouth_copy_theme

# 10. Update GRUB configuration (only if /etc/default/grub was changed)
update_grub_config:
  cmd.wait:
    - name: update-grub
    - watch:
      - cmd: configure_grub_for_plymouth

# 11. Ensure initramfs is updated if plymouth packages change (redundant if -R used above, but safe)
watch_plymouth_packages_for_initramfs:
  cmd.wait:
    - name: update-initramfs -u
    - watch:
      - pkg: install_plymouth_packages