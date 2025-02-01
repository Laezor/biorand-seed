# Changelog

## [2.0.0] - 2025-02-01

### Added
- Support for Resident Evil 2 Remake (Early Access)
- Game selection menu to choose between RE4R and RE2R
- Automatic game-specific installation path handling
- Game-specific profile listing and selection
- Game-specific website links in completion message

### Changed
- Updated configuration to store both RE4R and RE2R paths
- Improved log file cleanup with wildcard support (`*.log`)
- Made API endpoints game-aware for proper profile and seed handling
- Updated README to reflect multi-game support
- Made error messages more descriptive with API failure reasons

### Fixed
- Corrected profile endpoint usage with game ID
- Fixed seed generation status polling
- Improved error handling for failed generations
- Updated asset download URL handling

### Technical
- Refactored code to be game-agnostic where possible
- Updated API integration to use correct game IDs
- Improved configuration file structure
- Enhanced logging and error reporting

## [1.5.0] - 2024-12-23
- Initial release with RE4R support
- Basic profile selection
- Seed generation and installation
- Configuration management
