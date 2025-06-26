# OpenRent v3.1 - Settings Reference

## Complete Settings Documentation

All settings are configured in the `_Settings` notecard. Lines starting with `#` are comments and are ignored.

### Basic Rental Settings

| Setting | Description | Example | Required |
|---------|-------------|---------|----------|
| `Spot Name` | Display name for your rental space | `My Awesome Rental` | ✅ |
| `Rental Cost` | Weekly rental price in L$ | `1000` | ✅ |
| `Prim Count` | Maximum prims allowed for renters | `175` | ✅ |
| `Rental Size` | Size of rental space in square meters | `512` | ✅ |
| `Discount Percent` | Discount for 4-week payments (0-100) | `10` | ❌ |

### Notification Settings

| Setting | Description | Example | Required |
|---------|-------------|---------|----------|
| `Email for Notifications` | Email address for owner notifications | `owner@example.com` | ❌ |
| `Info Notecard Name` | Notecard given to visitors | `Rental Info` | ✅ |
| `Welcome Notecard` | Notecard given to new renters | `Welcome Notecard` | ✅ |
| `Floating Text Enabled` | Show floating text above rental box | `1` (enabled) or `0` (disabled) | ❌ |

### Payment & Refund Settings

| Setting | Description | Example | Required |
|---------|-------------|---------|----------|
| `Refunds Enabled` | Allow renters to request refunds | `1` (enabled) or `0` (disabled) | ❌ |
| `Refund Fee` | Fee deducted from refunds in L$ | `50` | ❌ |
| `Allow Owner Payment` | Allow owner to pay rental box | `1` (enabled) or `0` (disabled) | ❌ |
| `Allow Group Payment` | Allow group members to pay | `1` (enabled) or `0` (disabled) | ❌ |

### Grace Period Settings

| Setting | Description | Example | Required |
|---------|-------------|---------|----------|
| `Grace Period` | Hours of grace period after lease expires | `24` | ❌ |

**Note:** Grace period allows renters additional time to pay after lease expiration before the space becomes available to others.

### Group Integration

| Setting | Description | Example | Required |
|---------|-------------|---------|----------|
| `Group Name` | Name of your land group | `My Rental Group` | ❌ |
| `Group UUID` | UUID of your land group | `12345678-1234-1234-1234-123456789012` | ❌ |

### Mesh Appearance Settings

| Setting | Description | Example | Required |
|---------|-------------|---------|----------|
| `For Rent Texture` | Texture when space is available | `for_rent_mesh` | ❌ |
| `Rented Texture` | Texture when space is rented (blank = transparent) | `` | ❌ |
| `Overdue Texture` | Texture when rent is overdue | `overdue_mesh` | ❌ |
| `Locked Texture` | Texture when box is locked | `locked_mesh` | ❌ |
| `Unavailable Texture` | Texture when marked unavailable | `tempunavailable_mesh` | ❌ |
| `Reserved Texture` | Texture when reserved for specific renter | `reserved_mesh` | ❌ |
| `Mesh Alpha` | Transparency level (0.0-1.0) | `0.8` | ❌ |
| `Mesh Glow` | Glow intensity (0.0-1.0) | `0.05` | ❌ |

### Advanced Integration Settings

The OpenRent system supports integration with third-party systems through custom modules. Integration settings depend on the specific modules you're using.

**Common Integration Patterns:**
- **Communication Channels**: Use negative channel numbers to avoid conflicts
- **Passwords/Keys**: Use secure passwords for system-to-system communication  
- **Auto-Actions**: Enable/disable automatic actions on rental events
- **Notifications**: Control what events trigger notifications

**Module-Specific Settings:**
- Module settings are typically stored in separate notecards (e.g., `_PrimCounterSettings`)
- See individual module documentation for specific configuration options

## Setting Value Guidelines

### Rental Cost
- Minimum: 1 L$ (though not practical)
- Maximum: 2,147,483,647 L$ (LSL integer limit)
- Recommended: 100-5000 L$ for most rentals

### Discount Percent
- Range: 0-100
- 0 = No discount
- 25 = 25% off 4-week package
- 100 = Free 4-week package (not recommended, you silly goose)

### Grace Period
- 0 = No grace period
- 12 = half a day
- 24 = 1 day grace period
- You can set longer but not recommended. Keep it to under a couple days for your own sanity

### Mesh Alpha
- Range: 0.0-1.0
- 0.0 = Completely transparent
- 1.0 = Completely opaque
- 0.8 = Recommended for visibility

### Mesh Glow
- Range: 0.0-1.0
- 0.0 = No glow
- 1.0 = Maximum glow
- 0.05 = Subtle glow (recommended)

## Common Configuration Examples

### Basic Rental (Minimal Settings)
```
Spot Name: Basic Rental 01
Rental Cost: 500
Prim Count: 100
Rental Size: 256
Info Notecard Name: Rental Info
Welcome Notecard: Welcome Notecard
```

### Premium Rental (Full Features)
```
Spot Name: Premium Skybox Rental 25
Rental Cost: 2000
Discount Percent: 15
Prim Count: 500
Rental Size: 1024
Refunds Enabled: 1
Refund Fee: 100
Grace Period: 48
Email for Notifications: owner@example.com
Floating Text Enabled: 1
Group Name: Skybox Renters
Group UUID: 12345678-1234-1234-1234-123456789012
```

### Commercial Rental (No Refunds, Group Payments)
```
Spot Name: Commercial Space 105
Rental Cost: 5000
Prim Count: 1000
Rental Size: 2048
Refunds Enabled: 0
Allow Group Payment: 1
Grace Period: 0
Email for Notifications: business@example.com
```

## Important Notes

1. **Email Notifications**: Emails cause a 20-second delay after sending. System will 'sleep' while sending emails. This is a limitation of Second Life

2. **Refunds vs Group Payments**: Don't enable both `Refunds Enabled` and `Allow Group Payment` simultaneously. Refunds are disabled automatically if owner or group payments are enabled to prevent fraud. Enable at your own risk.

3. **Texture Names**: Texture names are case-sensitive and must match textures in the rental box inventory.

4. **Group UUID**: You can get your group's UUID from the group information panel in the SL viewer.

5. **Channel Numbers**: Use negative numbers for integration channels to avoid conflicts with other systems.

6. **Backup Settings**: Always keep a backup copy of your `_Settings` notecard before making changes. 