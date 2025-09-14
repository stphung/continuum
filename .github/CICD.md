# CI/CD Pipeline Documentation

## Overview

This repository uses GitHub Actions for comprehensive Continuous Integration and Continuous Deployment (CI/CD) automation. The pipeline provides automated testing, multi-platform builds, and release management for the Continuum shmup game.

## Pipeline Architecture

### Workflow Triggers
- **Push to main/develop**: Full CI/CD pipeline with builds and deployments
- **Pull Requests to main**: Testing and validation only
- **Git Tags (v*)**: Creates GitHub releases with all platform builds
- **Manual Dispatch**: Can be triggered manually when needed

### Pipeline Stages

#### 1. Test Stage
- **Platform**: Ubuntu Latest with Godot CI container
- **Actions**:
  - Checkout code with Git LFS support
  - Install SCons build system
  - Install project dependencies via gd-plug
  - Import Godot project assets
  - Run comprehensive test suite (`scons test`)
  - Run project validation (`scons validate`)
  - Upload test reports as artifacts

#### 2. Desktop Build Stage
- **Platforms**: Linux, Windows, macOS
- **Strategy**: Matrix build for all platforms in parallel
- **Actions**:
  - Export platform-specific binaries using Godot export presets
  - Upload build artifacts with 14-day retention
  - Validates builds work across all desktop platforms

#### 3. Android Build Stage
- **Platform**: Ubuntu Latest with Android SDK
- **Features**:
  - Sets up Android SDK (API 33)
  - Configures Android keystore (production or debug)
  - Builds debug APK for PRs, release APK for main branch
  - Supports signed releases with production keystore

#### 4. Release Stage
- **Trigger**: Git tags starting with 'v' (e.g., v1.0.0)
- **Actions**:
  - Downloads all build artifacts
  - Creates platform-specific archive files
  - Generates comprehensive GitHub release
  - Attaches all platform builds to release

#### 5. Web Deployment Stage
- **Platform**: GitHub Pages
- **Actions**:
  - Builds web version using Godot Web export
  - Configures proper COOP/COEP headers for SharedArrayBuffer
  - Deploys to GitHub Pages for browser gameplay

## Build Outputs

### Desktop Builds
- **Linux**: `continuum-linux` (native executable)
- **Windows**: `continuum-windows.exe` (Windows executable)
- **macOS**: `continuum-macos.zip` (Universal binary for Intel/Apple Silicon)

### Mobile Builds
- **Android**: `continuum-android.apk` (ARM64 APK for Android devices)

### Web Build
- **Browser**: Deployed to GitHub Pages for instant browser play

## Configuration Requirements

### Repository Secrets
For production builds, configure these GitHub repository secrets:

```
ANDROID_KEYSTORE_BASE64     # Base64-encoded Android keystore file
ANDROID_KEYSTORE_PASSWORD   # Password for the Android keystore
```

### Branch Protection
Recommended branch protection rules for `main`:
- Require pull request reviews
- Require status checks to pass (CI pipeline)
- Require branches to be up to date
- Restrict pushes to branches

### Repository Settings
- Enable GitHub Pages with GitHub Actions source
- Configure LFS for large asset files
- Enable Issues and Discussions for community engagement

## Development Workflow

### Feature Development
1. Create feature branch from `main`
2. Develop feature with comprehensive tests
3. Push branch - triggers validation pipeline
4. Create PR to `main` - triggers full testing
5. Merge after review and successful CI checks

### Release Process
1. Update version numbers in project files
2. Create and push git tag: `git tag v1.0.0 && git push origin v1.0.0`
3. CI automatically creates GitHub release with all builds
4. Release artifacts are available for download immediately

### Hotfix Process
1. Create hotfix branch from `main`
2. Apply fix with updated tests
3. Follow normal PR process for validation
4. Create patch release tag (e.g., v1.0.1)

## Quality Assurance

### Automated Testing
- **Unit Tests**: Individual component testing via gdUnit4
- **Integration Tests**: System interaction testing
- **Build Validation**: Ensures all platforms build successfully
- **Asset Validation**: Verifies game assets are properly configured

### Code Quality Gates
- All tests must pass before merge
- SCons validation must succeed
- No build failures allowed on main branch
- Pre-commit hooks enforce code standards

### Performance Monitoring
- Build time tracking across pipeline stages
- Artifact size monitoring for deployment efficiency
- Test execution time analysis for optimization opportunities

## Platform-Specific Notes

### Android Builds
- Uses ARM64 architecture for modern device compatibility
- Requires Android SDK API 33+ for latest Android features
- Supports both debug (unsigned) and release (signed) builds
- Configures appropriate Android permissions for game functionality

### Web Builds
- Configured for modern browsers with SharedArrayBuffer support
- Sets proper COOP/COEP headers for advanced web features
- Optimized for responsive gameplay across desktop and mobile browsers
- Automatic deployment to GitHub Pages on main branch updates

### Desktop Builds
- Cross-platform compilation without platform-specific runners
- Universal macOS binaries support both Intel and Apple Silicon
- Windows builds include all necessary runtime dependencies
- Linux builds target standard distributions with broad compatibility

## Monitoring and Troubleshooting

### Pipeline Status
Monitor pipeline health via:
- GitHub Actions tab in repository
- Status badges in README.md
- Email notifications on failures
- Slack/Discord integration (if configured)

### Common Issues
1. **Test Failures**: Check test logs in Actions for specific failures
2. **Build Failures**: Verify export preset configurations
3. **Android Issues**: Check Android SDK and keystore setup
4. **Asset Problems**: Ensure all assets are committed and LFS-tracked

### Performance Optimization
- Parallel job execution reduces total pipeline time
- Artifact caching for dependencies where possible
- Strategic use of build matrices for multi-platform efficiency
- Optimized container usage for consistent environments

## Future Enhancements

### Planned Features
- Steam build integration for distribution
- iOS build support for Apple App Store
- Automated screenshot and video generation
- Performance regression testing
- Multi-language build support

### Monitoring Additions
- Build performance metrics dashboard
- Automated security scanning integration
- Dependency vulnerability monitoring
- Code coverage reporting and trends

This CI/CD pipeline ensures that Continuum maintains high quality across all platforms while enabling rapid, confident deployment of new features and releases.