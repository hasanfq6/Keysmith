#!/bin/bash

# Mobile Development Environment Setup Script
# This script installs all necessary tools for mobile app development
# Supports: Android, iOS (macOS only), React Native, Flutter, Cordova/PhoneGap, Ionic

set -e  # Exit on any error

# Default installation flags (Android is always installed)
INSTALL_ANDROID=true
INSTALL_IOS=false
INSTALL_REACT_NATIVE=false
INSTALL_FLUTTER=false
INSTALL_CORDOVA=false
INSTALL_IONIC=false
INSTALL_EXPO=false
INSTALL_ANDROID_STUDIO=false
INSTALL_ADDITIONAL_TOOLS=false
INSTALL_VSCODE_EXTENSIONS=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Error handling function
handle_error() {
    log_error "An error occurred on line $1"
    log_error "Command that failed: $2"
    log_warning "Continuing with next installation step..."
}

# Set up error trap
trap 'handle_error ${LINENO} "$BASH_COMMAND"' ERR

# Show help
show_help() {
    echo "Mobile Development Environment Setup Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "OPTIONS:"
    echo "  --help, -h              Show this help message"
    echo "  --all                   Install all available tools and frameworks"
    echo "  --react-native, -rn     Install React Native development tools"
    echo "  --flutter, -f           Install Flutter development tools"
    echo "  --ionic, -i             Install Ionic development tools"
    echo "  --cordova, -c           Install Cordova/PhoneGap development tools"
    echo "  --expo, -e              Install Expo CLI and EAS CLI"
    echo "  --ios                   Install iOS development tools (macOS only)"
    echo "  --android-studio, -as   Install Android Studio"
    echo "  --additional-tools, -at Install additional tools (Fastlane, Scrcpy, etc.)"
    echo "  --vscode-ext, -vs       Install VS Code extensions for mobile development"
    echo ""
    echo "EXAMPLES:"
    echo "  $0                      # Install basic Android development tools only"
    echo "  $0 --react-native       # Install Android + React Native"
    echo "  $0 --flutter --ios      # Install Android + Flutter + iOS tools"
    echo "  $0 --all                # Install everything"
    echo "  $0 -rn -f -i            # Install Android + React Native + Flutter + Ionic"
    echo ""
    echo "NOTE: Android development tools are always installed as they are required"
    echo "      for most mobile development frameworks."
    echo ""
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                exit 0
                ;;
            --all)
                INSTALL_REACT_NATIVE=true
                INSTALL_FLUTTER=true
                INSTALL_CORDOVA=true
                INSTALL_IONIC=true
                INSTALL_EXPO=true
                INSTALL_IOS=true
                INSTALL_ANDROID_STUDIO=true
                INSTALL_ADDITIONAL_TOOLS=true
                INSTALL_VSCODE_EXTENSIONS=true
                shift
                ;;
            --react-native|-rn)
                INSTALL_REACT_NATIVE=true
                shift
                ;;
            --flutter|-f)
                INSTALL_FLUTTER=true
                shift
                ;;
            --ionic|-i)
                INSTALL_IONIC=true
                shift
                ;;
            --cordova|-c)
                INSTALL_CORDOVA=true
                shift
                ;;
            --expo|-e)
                INSTALL_EXPO=true
                shift
                ;;
            --ios)
                INSTALL_IOS=true
                shift
                ;;
            --android-studio|-as)
                INSTALL_ANDROID_STUDIO=true
                shift
                ;;
            --additional-tools|-at)
                INSTALL_ADDITIONAL_TOOLS=true
                shift
                ;;
            --vscode-ext|-vs)
                INSTALL_VSCODE_EXTENSIONS=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Show installation plan
show_installation_plan() {
    log_info "Installation Plan:"
    echo "===================="
    echo "✅ Android SDK & Tools (always installed)"
    echo "✅ Java (OpenJDK 17)"
    echo "✅ Node.js & npm"
    echo "✅ Basic development tools"
    
    if [[ "$INSTALL_REACT_NATIVE" == true ]]; then
        echo "✅ React Native CLI & Watchman"
    fi
    
    if [[ "$INSTALL_FLUTTER" == true ]]; then
        echo "✅ Flutter SDK & Dart"
    fi
    
    if [[ "$INSTALL_IONIC" == true ]]; then
        echo "✅ Ionic CLI"
    fi
    
    if [[ "$INSTALL_CORDOVA" == true ]]; then
        echo "✅ Cordova/PhoneGap CLI"
    fi
    
    if [[ "$INSTALL_EXPO" == true ]]; then
        echo "✅ Expo CLI & EAS CLI"
    fi
    
    if [[ "$INSTALL_IOS" == true ]]; then
        if [[ "$OS" == "macos" ]]; then
            echo "✅ iOS development tools (CocoaPods, iOS Deploy)"
        else
            echo "⚠️  iOS development tools (skipped - not on macOS)"
        fi
    fi
    
    if [[ "$INSTALL_ANDROID_STUDIO" == true ]]; then
        echo "✅ Android Studio"
    fi
    
    if [[ "$INSTALL_ADDITIONAL_TOOLS" == true ]]; then
        echo "✅ Additional tools (Fastlane, Scrcpy, etc.)"
    fi
    
    if [[ "$INSTALL_VSCODE_EXTENSIONS" == true ]]; then
        echo "✅ VS Code extensions"
    fi
    
    echo "===================="
    echo ""
}

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        if command -v apt-get &> /dev/null; then
            DISTRO="ubuntu"
        elif command -v yum &> /dev/null; then
            DISTRO="centos"
        elif command -v pacman &> /dev/null; then
            DISTRO="arch"
        else
            DISTRO="unknown"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        OS="windows"
    else
        OS="unknown"
    fi
    
    log_info "Detected OS: $OS ($DISTRO)"
}

# Update system packages
update_system() {
    log_info "Updating system packages..."
    
    case $OS in
        "linux")
            case $DISTRO in
                "ubuntu")
                    sudo apt-get update -y || true
                    sudo apt-get upgrade -y || true
                    ;;
                "centos")
                    sudo yum update -y || true
                    ;;
                "arch")
                    sudo pacman -Syu --noconfirm || true
                    ;;
            esac
            ;;
        "macos")
            # Update Homebrew if installed, install if not
            if command -v brew &> /dev/null; then
                brew update || true
                brew upgrade || true
            else
                log_info "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || true
                echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc || true
                echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.bash_profile || true
                eval "$(/opt/homebrew/bin/brew shellenv)" || true
            fi
            ;;
    esac
    
    log_success "System packages updated"
}

# Install basic development tools
install_basic_tools() {
    log_info "Installing basic development tools..."
    
    case $OS in
        "linux")
            case $DISTRO in
                "ubuntu")
                    sudo apt-get install -y curl wget git unzip zip build-essential \
                        software-properties-common apt-transport-https ca-certificates \
                        gnupg lsb-release python3 python3-pip || true
                    ;;
                "centos")
                    sudo yum groupinstall -y "Development Tools" || true
                    sudo yum install -y curl wget git unzip zip python3 python3-pip || true
                    ;;
                "arch")
                    sudo pacman -S --noconfirm curl wget git unzip zip base-devel python python-pip || true
                    ;;
            esac
            ;;
        "macos")
            # Install Xcode Command Line Tools
            xcode-select --install || true
            
            # Install basic tools via Homebrew
            brew install curl wget git unzip zip python3 || true
            ;;
    esac
    
    log_success "Basic development tools installed"
}

# Install Java (OpenJDK)
install_java() {
    log_info "Installing Java (OpenJDK)..."
    
    case $OS in
        "linux")
            case $DISTRO in
                "ubuntu")
                    sudo apt-get install -y openjdk-17-jdk || true
                    ;;
                "centos")
                    sudo yum install -y java-17-openjdk-devel || true
                    ;;
                "arch")
                    sudo pacman -S --noconfirm jdk17-openjdk || true
                    ;;
            esac
            ;;
        "macos")
            brew install openjdk@17 || true
            # Link it for system Java wrappers
            sudo ln -sfn /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-17.jdk || true
            ;;
    esac
    
    # Set JAVA_HOME
    if [[ "$OS" == "macos" ]]; then
        export JAVA_HOME="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
        echo 'export JAVA_HOME="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"' >> ~/.zshrc || true
        echo 'export JAVA_HOME="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"' >> ~/.bash_profile || true
    else
        export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
        echo 'export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"' >> ~/.bashrc || true
    fi
    
    log_success "Java installed"
}

# Install Node.js and npm
install_nodejs() {
    log_info "Installing Node.js and npm..."
    
    # Install Node Version Manager (nvm)
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash || true
    
    # Source nvm
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" || true
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" || true
    
    # Install latest LTS Node.js
    nvm install --lts || true
    nvm use --lts || true
    nvm alias default node || true
    
    # Update npm to latest
    npm install -g npm@latest || true
    
    # Install Yarn
    npm install -g yarn || true
    
    log_success "Node.js and npm installed"
}

# Install Android SDK and tools
install_android_sdk() {
    log_info "Installing Android SDK and tools..."
    
    # Create Android directory
    mkdir -p ~/Android/Sdk || true
    cd ~/Android/Sdk || true
    
    # Download Android command line tools
    if [[ "$OS" == "macos" ]]; then
        wget -q https://dl.google.com/android/repository/commandlinetools-mac-9477386_latest.zip -O cmdline-tools.zip || true
    else
        wget -q https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip -O cmdline-tools.zip || true
    fi
    
    unzip -q cmdline-tools.zip || true
    rm cmdline-tools.zip || true
    
    # Create proper directory structure
    mkdir -p cmdline-tools/latest || true
    mv cmdline-tools/* cmdline-tools/latest/ 2>/dev/null || true
    
    # Set Android environment variables
    export ANDROID_HOME="$HOME/Android/Sdk"
    export ANDROID_SDK_ROOT="$HOME/Android/Sdk"
    export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator"
    
    # Add to shell profiles
    if [[ "$OS" == "macos" ]]; then
        echo 'export ANDROID_HOME="$HOME/Android/Sdk"' >> ~/.zshrc || true
        echo 'export ANDROID_SDK_ROOT="$HOME/Android/Sdk"' >> ~/.zshrc || true
        echo 'export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator"' >> ~/.zshrc || true
        echo 'export ANDROID_HOME="$HOME/Android/Sdk"' >> ~/.bash_profile || true
        echo 'export ANDROID_SDK_ROOT="$HOME/Android/Sdk"' >> ~/.bash_profile || true
        echo 'export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator"' >> ~/.bash_profile || true
    else
        echo 'export ANDROID_HOME="$HOME/Android/Sdk"' >> ~/.bashrc || true
        echo 'export ANDROID_SDK_ROOT="$HOME/Android/Sdk"' >> ~/.bashrc || true
        echo 'export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator"' >> ~/.bashrc || true
    fi
    
    # Accept all licenses automatically
    yes | sdkmanager --licenses || true
    
    # Install essential Android packages
    sdkmanager --install "platform-tools" || true
    sdkmanager --install "platforms;android-34" || true
    sdkmanager --install "platforms;android-33" || true
    sdkmanager --install "build-tools;34.0.0" || true
    sdkmanager --install "build-tools;33.0.1" || true
    sdkmanager --install "emulator" || true
    sdkmanager --install "system-images;android-34;google_apis;x86_64" || true
    sdkmanager --install "system-images;android-33;google_apis;x86_64" || true
    
    # Create AVD (Android Virtual Device)
    echo "no" | avdmanager create avd -n "Pixel_7_API_34" -k "system-images;android-34;google_apis;x86_64" --device "pixel_7" || true
    
    log_success "Android SDK installed"
}

# Install Android Studio
install_android_studio() {
    if [[ "$INSTALL_ANDROID_STUDIO" != true ]]; then
        return
    fi
    
    log_info "Installing Android Studio..."
    
    case $OS in
        "linux")
            case $DISTRO in
                "ubuntu")
                    # Add Android Studio repository
                    sudo add-apt-repository ppa:maarten-fonville/android-studio -y || true
                    sudo apt-get update || true
                    sudo apt-get install -y android-studio || true
                    ;;
                *)
                    log_warning "Android Studio auto-install not supported for this Linux distribution. Please install manually."
                    ;;
            esac
            ;;
        "macos")
            brew install --cask android-studio || true
            ;;
    esac
    
    log_success "Android Studio installation attempted"
}

# Install iOS development tools (macOS only)
install_ios_tools() {
    if [[ "$INSTALL_IOS" != true ]]; then
        return
    fi
    
    if [[ "$OS" != "macos" ]]; then
        log_warning "iOS development tools can only be installed on macOS"
        return
    fi
    
    log_info "Installing iOS development tools..."
    
    # Install Xcode (this will prompt user to install from App Store)
    log_info "Please install Xcode from the Mac App Store if not already installed"
    
    # Install iOS Simulator
    sudo xcode-select -s /Applications/Xcode.app/Contents/Developer || true
    
    # Install CocoaPods
    sudo gem install cocoapods || true
    pod setup || true
    
    # Install iOS Deploy
    npm install -g ios-deploy || true
    
    log_success "iOS development tools installed"
}

# Install React Native CLI
install_react_native() {
    if [[ "$INSTALL_REACT_NATIVE" != true ]]; then
        return
    fi
    
    log_info "Installing React Native CLI..."
    
    npm install -g @react-native-community/cli || true
    npm install -g react-native-cli || true
    
    # Install Watchman (for file watching)
    case $OS in
        "macos")
            brew install watchman || true
            ;;
        "linux")
            case $DISTRO in
                "ubuntu")
                    # Build Watchman from source
                    cd /tmp || true
                    git clone https://github.com/facebook/watchman.git || true
                    cd watchman || true
                    git checkout v2023.11.20.00 || true
                    sudo apt-get install -y autoconf automake build-essential libtool pkg-config libssl-dev || true
                    ./autogen.sh || true
                    ./configure --enable-lenient || true
                    make || true
                    sudo make install || true
                    ;;
            esac
            ;;
    esac
    
    log_success "React Native CLI installed"
}

# Install Flutter
install_flutter() {
    if [[ "$INSTALL_FLUTTER" != true ]]; then
        return
    fi
    
    log_info "Installing Flutter..."
    
    # Create Flutter directory
    mkdir -p ~/development || true
    cd ~/development || true
    
    # Download Flutter
    if [[ "$OS" == "macos" ]]; then
        if [[ $(uname -m) == "arm64" ]]; then
            wget -q https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_3.16.0-stable.zip -O flutter.zip || true
        else
            wget -q https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_3.16.0-stable.zip -O flutter.zip || true
        fi
    else
        wget -q https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.16.0-stable.tar.xz -O flutter.tar.xz || true
    fi
    
    # Extract Flutter
    if [[ "$OS" == "macos" ]]; then
        unzip -q flutter.zip || true
        rm flutter.zip || true
    else
        tar xf flutter.tar.xz || true
        rm flutter.tar.xz || true
    fi
    
    # Add Flutter to PATH
    export PATH="$PATH:$HOME/development/flutter/bin"
    
    if [[ "$OS" == "macos" ]]; then
        echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.zshrc || true
        echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.bash_profile || true
    else
        echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.bashrc || true
    fi
    
    # Run Flutter doctor to download Dart SDK and other dependencies
    flutter doctor --android-licenses || true
    flutter doctor || true
    
    log_success "Flutter installed"
}

# Install Cordova/PhoneGap
install_cordova() {
    if [[ "$INSTALL_CORDOVA" != true ]]; then
        return
    fi
    
    log_info "Installing Cordova..."
    
    npm install -g cordova || true
    npm install -g phonegap || true
    
    log_success "Cordova installed"
}

# Install Ionic
install_ionic() {
    if [[ "$INSTALL_IONIC" != true ]]; then
        return
    fi
    
    log_info "Installing Ionic..."
    
    npm install -g @ionic/cli || true
    
    log_success "Ionic installed"
}

# Install Expo CLI
install_expo() {
    if [[ "$INSTALL_EXPO" != true ]]; then
        return
    fi
    
    log_info "Installing Expo CLI..."
    
    npm install -g @expo/cli || true
    npm install -g eas-cli || true
    
    log_success "Expo CLI installed"
}

# Install additional useful tools
install_additional_tools() {
    if [[ "$INSTALL_ADDITIONAL_TOOLS" != true ]]; then
        return
    fi
    
    log_info "Installing additional mobile development tools..."
    
    # Install Fastlane (for iOS/Android deployment)
    case $OS in
        "macos")
            brew install fastlane || true
            ;;
        "linux")
            sudo gem install fastlane || true
            ;;
    esac
    
    # Install ADB (Android Debug Bridge) - usually comes with platform-tools
    # Install Scrcpy (Android screen mirroring)
    case $OS in
        "macos")
            brew install scrcpy || true
            ;;
        "linux")
            case $DISTRO in
                "ubuntu")
                    sudo apt-get install -y scrcpy || true
                    ;;
            esac
            ;;
    esac
    
    log_success "Additional tools installed"
}

# Install VS Code extensions (if VS Code is installed)
install_vscode_extensions() {
    if [[ "$INSTALL_VSCODE_EXTENSIONS" != true ]]; then
        return
    fi
    
    if command -v code &> /dev/null; then
        log_info "Installing VS Code extensions for mobile development..."
        
        code --install-extension ms-vscode.vscode-typescript-next || true
        code --install-extension bradlc.vscode-tailwindcss || true
        code --install-extension esbenp.prettier-vscode || true
        code --install-extension ms-vscode.vscode-eslint || true
        code --install-extension ms-vscode.vscode-react-native || true
        code --install-extension dart-code.dart-code || true
        code --install-extension dart-code.flutter || true
        code --install-extension vscjava.vscode-java-pack || true
        code --install-extension redhat.java || true
        code --install-extension ms-vscode.vscode-gradle || true
        
        log_success "VS Code extensions installed"
    else
        log_warning "VS Code not found, skipping extension installation"
    fi
}

# Verify installations
verify_installations() {
    log_info "Verifying installations..."
    
    echo "=== Installation Verification ==="
    
    # Java
    if command -v java &> /dev/null; then
        echo "✅ Java: $(java -version 2>&1 | head -n 1)"
    else
        echo "❌ Java: Not installed"
    fi
    
    # Node.js
    if command -v node &> /dev/null; then
        echo "✅ Node.js: $(node --version)"
    else
        echo "❌ Node.js: Not installed"
    fi
    
    # npm
    if command -v npm &> /dev/null; then
        echo "✅ npm: $(npm --version)"
    else
        echo "❌ npm: Not installed"
    fi
    
    # Android SDK
    if command -v adb &> /dev/null; then
        echo "✅ Android SDK: $(adb --version | head -n 1)"
    else
        echo "❌ Android SDK: Not installed"
    fi
    
    # React Native
    if command -v react-native &> /dev/null; then
        echo "✅ React Native: $(react-native --version | head -n 1)"
    else
        echo "❌ React Native: Not installed"
    fi
    
    # Flutter
    if command -v flutter &> /dev/null; then
        echo "✅ Flutter: $(flutter --version | head -n 1)"
    else
        echo "❌ Flutter: Not installed"
    fi
    
    # Cordova
    if command -v cordova &> /dev/null; then
        echo "✅ Cordova: $(cordova --version)"
    else
        echo "❌ Cordova: Not installed"
    fi
    
    # Ionic
    if command -v ionic &> /dev/null; then
        echo "✅ Ionic: $(ionic --version)"
    else
        echo "❌ Ionic: Not installed"
    fi
    
    # CocoaPods (macOS only)
    if [[ "$OS" == "macos" ]] && command -v pod &> /dev/null; then
        echo "✅ CocoaPods: $(pod --version)"
    elif [[ "$OS" == "macos" ]]; then
        echo "❌ CocoaPods: Not installed"
    fi
    
    echo "=== End Verification ==="
}

# Main installation function
main() {
    # Parse command line arguments
    parse_arguments "$@"
    
    log_info "Starting Mobile Development Environment Setup..."
    
    # Detect OS
    detect_os
    
    # Show installation plan
    show_installation_plan
    
    # Ask for confirmation
    read -p "Do you want to proceed with this installation? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Installation cancelled by user"
        exit 0
    fi
    
    # Update system
    update_system
    
    # Install basic tools
    install_basic_tools
    
    # Install Java
    install_java
    
    # Install Node.js
    install_nodejs
    
    # Install Android SDK (always installed)
    install_android_sdk
    
    # Install Android Studio
    install_android_studio
    
    # Install iOS tools
    install_ios_tools
    
    # Install React Native
    install_react_native
    
    # Install Flutter
    install_flutter
    
    # Install Cordova
    install_cordova
    
    # Install Ionic
    install_ionic
    
    # Install Expo
    install_expo
    
    # Install additional tools
    install_additional_tools
    
    # Install VS Code extensions
    install_vscode_extensions
    
    # Verify installations
    verify_installations
    
    log_success "Mobile Development Environment Setup Complete!"
    log_info "Please restart your terminal or run 'source ~/.bashrc' (Linux) or 'source ~/.zshrc' (macOS) to apply environment changes"
    log_info "You may also need to restart your IDE/editor to recognize the new tools"
    
    # Show next steps
    echo ""
    echo "=== Next Steps ==="
    echo "1. Restart your terminal or run: source ~/.bashrc (Linux) or source ~/.zshrc (macOS)"
    
    if [[ "$INSTALL_FLUTTER" == true ]]; then
        echo "2. Run 'flutter doctor' to check Flutter setup"
    fi
    
    if [[ "$INSTALL_REACT_NATIVE" == true ]]; then
        echo "3. Run 'react-native doctor' to check React Native setup"
    fi
    
    echo "4. For Android development, you may need to accept additional licenses: sdkmanager --licenses"
    
    if [[ "$INSTALL_IOS" == true && "$OS" == "macos" ]]; then
        echo "5. For iOS development, install Xcode from the Mac App Store if not already installed"
    fi
    
    echo "6. Create your first project:"
    echo "   - Android: Create new project in Android Studio"
    
    if [[ "$INSTALL_REACT_NATIVE" == true ]]; then
        echo "   - React Native: npx react-native init MyApp"
    fi
    
    if [[ "$INSTALL_FLUTTER" == true ]]; then
        echo "   - Flutter: flutter create my_app"
    fi
    
    if [[ "$INSTALL_IONIC" == true ]]; then
        echo "   - Ionic: ionic start myApp tabs"
    fi
    
    if [[ "$INSTALL_CORDOVA" == true ]]; then
        echo "   - Cordova: cordova create myApp"
    fi
    
    if [[ "$INSTALL_EXPO" == true ]]; then
        echo "   - Expo: npx create-expo-app MyApp"
    fi
}

# Run main function
main "$@"