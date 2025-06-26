# Module Channel Communication System

## Overview

The OpenRent system now includes a configurable channel-based communication system for modules. This eliminates message conflicts between modules and provides more reliable communication.

## How It Works

### Module Channels

Each module can now operate on its own communication channel:

- **Channel 0**: Broadcast channel - all scripts listen here
- **Module Channels**: Specific channels (1000-4294967294) for individual modules
- **Auto-Assignment**: If no channel is specified, a random channel is automatically assigned

### Communication Flow

1. **Module Registration**: Modules register with their channel information
2. **Request Routing**: Main scripts route requests to specific module channels  
3. **Response Handling**: Responses are sent back on the same channel
4. **Message Filtering**: Modules only process messages on their assigned channel

## Configuration

### For Module Developers

Add these variables to your module:

```lsl
// Module communication channel (configurable)
integer moduleChannel = 0; // 0 = auto-assign random channel
integer assignedChannel = 0; // The actual channel we're using

// Module channel management
assignModuleChannel() {
    if (moduleChannel == 0) {
        // Generate random channel between 1000 and 4294967294
        assignedChannel = 1000 + (integer)(llFrand(4294966294.0));
    } else {
        assignedChannel = moduleChannel;
    }
    
    llOwnerSay("Module: Using channel " + (string)assignedChannel);
}
```

### For End Users

In your module configuration notecard (e.g., `_PrimCounterSettings.txt`):

```
# Module Communication Channel (0 = auto-assign random channel)
# Set to a specific number to use that channel, or leave at 0 for automatic assignment
# Valid range: 0 (auto) or 1000-4294967294
MODULE_CHANNEL: 0
```

## Implementation Guide

### 1. Module Registration

```lsl
// Register with channel information
llMessageLinked(LINK_SET, 0, "Module:Register^" + MODULE_NAME + "^" + llDumpList2String(MODULE_CAPABILITIES, ",") + "^" + (string)assignedChannel, NULL_KEY);
```

### 2. Message Filtering

```lsl
link_message(integer sender_num, integer num, string message, key id) {
    // Only process messages on our assigned channel or channel 0 (broadcast)
    if (num != 0 && num != assignedChannel) return;
    
    // Process message...
}
```

### 3. Requesting Services

```lsl
// Request user role check on our channel for response
llMessageLinked(LINK_SET, assignedChannel, "Core:Action^CheckUserRole^" + (string)id, NULL_KEY);
```

## Benefits

### For Developers
- **No Message Conflicts**: Each module gets its own communication space
- **Configurable Channels**: Users can set specific channels if needed
- **Automatic Assignment**: Zero configuration required for basic use
- **Reliable Communication**: Messages go exactly where they should

### For End Users
- **Better Performance**: Modules only process relevant messages
- **Conflict Resolution**: No more issues with multiple modules interfering
- **Configurable**: Advanced users can set specific channels
- **Transparent**: Most users won't need to change anything

## Backward Compatibility

- Existing modules without channel support will continue to work
- Channel 0 (broadcast) is still monitored by all modules
- Main scripts listen on all channels for maximum compatibility

## Updated Scripts

The following scripts have been updated to support the channel system:

1. **Prim Counter.lsl** - Full channel support with configuration
2. **Hello World.lsl** - Channel support example
3. **Module Manager.lsl** - Channel tracking and routing
4. **Rental Core.lsl** - Channel-aware response handling

## Configuration Examples

### Prim Counter Module
```
MODULE_CHANNEL: 1001
ACCESS_MODE: available
AGGRESSIVE_MODE: enabled
```

### Multiple Modules
If you have multiple rental boxes, you can assign different channel ranges:

- **Box 1**: Channels 1000-1099
- **Box 2**: Channels 1100-1199  
- **Box 3**: Channels 1200-1299

This prevents any cross-interference between rental systems.

## Troubleshooting

### Module Not Responding
1. Check if the module is registered: Look for registration messages in chat
2. Verify channel assignment: Module should report its channel on startup
3. Check configuration: Ensure MODULE_CHANNEL setting is valid

### Channel Conflicts
- Very rare with random assignment (4+ billion possible channels)
- If it happens, set specific channels manually
- Different rental boxes should use different channel ranges

### Debug Information
Enable update notifications in your module config to see channel assignments:
```
UPDATE_NOTIFICATIONS: yes
```

## Future Enhancements

- **Channel Groups**: Group related modules on similar channels
- **Dynamic Channels**: Automatic channel reassignment on conflicts
- **Channel Registry**: Central tracking of all assigned channels
- **Performance Monitoring**: Track message efficiency per channel

---

*This system maintains full backward compatibility while providing improved reliability and performance for modular rental systems.* 