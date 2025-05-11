# Plymouth Formula

**Do you want to create a custom boot experience? Do you want to show your companies logo oder your own logo during startup of your Ubuntu oder Debian based PC?** This formula will configure anything for you.

A SaltStack formula to configure Plymouth boot splash screen with custom themes.

## Features

- Installs Plymouth and required firmware packages
- Configures GRUB for Plymouth compatibility
- Sets up custom boot splash themes
- Includes example theme "mbcom" with:
  - @MBcom logo
  - Progress bar
  - Message display support
  - Configurable background colors

## Configuration

The formula can be configured through pillar data. Default settings are:

```yaml
plymouth:
  theme: mbcom  # Default theme name
```

## Usage

1. Include the formula in your state:
```sls
include:
  - plymouth
```

2. Optionally override the default theme in your pillar:
```yaml
plymouth:
  theme: mytheme
```

## Creating Custom Themes

To create a custom theme:

1. Create a new directory under `plymouth/files/mytheme/`
2. Add required theme files:
   - `mytheme.plymouth` - Theme configuration
   - `custom-splash.script` - Theme script
   - Image assets (logo, progress bar, etc.)

Example theme structure:
```
plymouth/files/mytheme/
├── custom-splash.script
├── logo.png
├── progress-bar.png
├── progress-box.png
└── mytheme.plymouth
```

## Testing

Test the theme after installation:
```bash
plymouth-set-default-theme -l    # List available themes
plymouth-set-default-theme mytheme -R  # Set and test new theme
```

## License

Apache-2.0

## Contributing

1. Fork the repository
2. Create a feature branch
3. Submit a Pull Request