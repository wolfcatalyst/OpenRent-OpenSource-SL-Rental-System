# OpenRent v3.1 - Open Source Second Life Rental System

**Professional-grade rental management system for Second Life with modular architecture and offline resilience.**

## 🚀 Quick Start

**Need it running NOW?** See [QUICK_START_GUIDE.md](QUICK_START_GUIDE.md)

**Upgrading from older version?** See the "GET IT UPDATED NOW" section in the Quick Start Guide.

## 📋 System Overview

OpenRent v3.1 is a comprehensive rental management system designed for Second Life land rentals. It features:

- **Hybrid Architecture**: Combines local reliability with modern notification features
- **Offline Resilience**: Automatically handles time passage when rental boxes are in inventory
- **Modular Design**: Expandable plugin system for custom features
- **Professional Notifications**: Dual IM/Email notifications for all events
- **Adaptive Performance**: Smart timer intervals based on lease urgency
- **Zero Dependencies**: No external servers or API keys required

## ✨ Core Features

### 💰 Payment & Billing
- Multiple payment options (1 week, 2 weeks, 3 weeks, 4 weeks, Custom payments after initial week)
- Configurable 4-week package discounts
- Automatic refund system with configurable fees
- Owner and group payment support
- Grace period management

### 📱 Smart Notifications
- **Dual delivery**: Both instant message and email notifications
- **Smart reminders**: 48-hour, 24-hour, 6-hour, and 1-hour lease expiration warnings
- **Owner alerts**: Real-time notifications for all rental activities
- **Offline corrections**: Automatic time adjustments with owner notifications

### 🎛️ Management Features
- Touch-based menu system for owners and renters
- Lock/unlock functionality - Owner only
- Reserve spaces for specific renters
- Floating text display (configurable)
- Mesh texture state management
- Real-time prim counting and monitoring

### 🔧 Advanced Features
- **Offline Time Tracking**: Handles rental boxes taken to inventory
- **Adaptive Timers**: Performance optimization based on lease urgency
- **Memory Optimized**: Efficient script architecture
- **State Persistence**: Maintains data through script resets
- **Integration Ready**: Built-in support for security and teleport systems

## 🧩 Included Modules

### Prim Counter Module ✅ (Pre-installed)
- Real-time parcel prim monitoring
- Configurable access levels (owner-only, renter access, public access)
- Aggressive mode for limit enforcement
- Detailed reporting with multiple display options
- Automatic texture changes when limits exceeded
- 24-hour violation notifications

### Hello World Module 📚 (Example)
- Demonstration module for developers
- Shows proper channel communication
- Template for creating custom modules
- Not installed by default (development reference)

## 🔮 Module System

The OpenRent system features a powerful modular architecture that allows developers to extend functionality through custom modules. The system includes:

- **Channel-based Communication**: Secure inter-module messaging
- **Auto-registration**: OpenRent Modules automatically register with the system
- **Role-based Access**: Proper permission handling for different user types - Owner, Renter, Stranger
- **Template System**: Use Hello World module as a starting point to create your own modules

Create your own modules to add custom features like web integration, security systems, teleport management, or any other functionality your rental business needs.

## 📦 Installation Requirements

### Required Notecards
- `_Settings` - Main configuration file
- `Rental Info` - Information given to potential renters  
- `Welcome Notecard` - Given to new renters after payment

### Required Scripts
- `Rental Core.lsl` - Main rental logic
- `Module Manager.lsl` - Module system management
- `UI Manager.lsl` - User interface handling
- `mesh script.lsl` - Mesh texture management
- `Prim Counter.lsl` - Prim monitoring (in modules folder)

### Optional Components
- Mesh models (`.dae` files in models/ directory)
- Texture files (`.tga` files in textures/ directory)
- Additional module scripts

## ⚙️ Configuration

### Basic Setup
See [SETTINGS_REFERENCE.md](/docs/SETTINGS_REFERENCE.md) for complete configuration documentation.

**Minimum Required Settings:**
```
Spot Name: Your Rental Name
Rental Cost: 1000
Prim Count: 175
Rental Size: 512
Info Notecard Name: Rental Info
Welcome Notecard: Welcome Notecard
```

### Advanced Configuration
The system supports extensive customization including:
- Email notifications with SMTP integration
- Group integration and auto-invites
- Custom mesh textures and appearance
- Flexible payment and refund policies
- Modular extensions for additional features

## 🏗️ System Architecture

### Core Components
- **Rental Core**: State management, timer handling, payment processing
- **Module Manager**: Plugin system, channel management, module communication
- **UI Manager**: Dialog system, menu handling, user interaction
- **Mesh Script**: Visual state management, texture handling

### Module System
- **Channel-based Communication**: Secure inter-module messaging
- **Auto-registration**: Modules automatically register capabilities
- **Strict Protocols**: Enforced communication standards
- **Resource Management**: Automatic cleanup and memory optimization

### Performance Features
- **Adaptive Timers**: 1-minute (urgent), 15-minute (moderate), 1-hour (relaxed) intervals
- **Memory Optimization**: Efficient variable usage and data storage
- **Event-driven Updates**: Responsive to user interactions
- **Offline Resilience**: Handles inventory storage and time corrections

## 🔧 Development

### Creating Custom Modules
1. Use `Hello World.lsl` as a template
2. Implement required communication protocols
3. Follow channel management standards
4. Include proper cleanup functions
5. Test with the Module Manager system

### Integration Guidelines
- Use negative channel numbers for external system integration
- Implement proper error handling and timeouts
- Follow LSL best practices for memory management
- Include comprehensive logging for debugging

## 📄 License

This project is open source and provided under the included license terms. See [license.txt](license.txt) for full details.

**Commercial Use**: Permitted under license terms
**Modifications**: Encouraged for personal and commercial use
**Distribution**: Allowed with proper attribution

## 🆘 Support

**Official Support**: Available only for users who purchased the system directly from Wolf Catalyst in Second Life or from the SL Marketplace.

**Marketplace Link**: https://marketplace.secondlife.com/p/OpenRent-OS-Mesh-Rental-System/25754107

**Community Support**: 
- GitHub Issues for bug reports and feature requests
- Fork and contribute improvements
- Share modules and extensions

**No Support Policy**: Downloaded versions from GitHub or third parties are provided as-is without support. You're welcome to troubleshoot, fork, or collaborate, but please don't contact Wolf Catalyst for help unless you're using the official in-world product.

## 🎯 Competitive Advantages

### vs. CasperLet and Similar Systems
- **No External Dependencies**: Works entirely within Second Life
- **Instant Responsiveness**: No network latency or API delays
- **Offline Resilience**: Handles real-world SL scenarios
- **Modular Architecture**: Expandable without core system changes
- **Open Source**: Full customization and transparency
- **Professional Notifications**: Comprehensive owner communication
- **Performance Optimized**: Adaptive resource usage

### Technical Superiority
- **Hybrid Approach**: Local reliability with modern features
- **State Persistence**: Survives script resets and inventory storage
- **Memory Efficient**: Optimized for SL script limitations
- **Channel Management**: Secure inter-component communication
- **Error Recovery**: Graceful handling of edge cases

## 📊 System Specifications

- **Script Memory**: Optimized for SL 64KB limit per script
- **Timer Resolution**: 1-minute minimum, adaptive scaling
- **Module Capacity**: 20 modules maximum (configurable)
- **Channel Range**: -2147483648 to 2147483647
- **Data Persistence**: Object description + variable storage
- **Notification Delay**: 20 seconds for email, instant for IM

## 🔄 Version History

### v3.1 (Current)
- Offline time correction system
- Enhanced reminder notifications with owner alerts
- Improved timer system with adaptive intervals
- Bug fixes for reminder range checking
- Memory optimization improvements

### v3.0
- Modular architecture implementation
- Module Manager system
- Enhanced UI system
- Performance optimizations

## 🚀 Getting Started

1. **Download**: Get the system from official sources
2. **Quick Setup**: Follow [QUICK_START_GUIDE.md](/docs/QUICK_START_GUIDE.md)
3. **Configure**: Edit settings using [SETTINGS_REFERENCE.md](/docs/SETTINGS_REFERENCE.md)
4. **Deploy**: Rez and test your rental system
5. **Customize**: Add modules and integrate with existing systems

**Ready to revolutionize your Second Life rental business? Let's get started!** 🎉
