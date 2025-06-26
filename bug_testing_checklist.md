🧪 OpenRent v3.1 Bug Testing Checklist
Core System Testing
Initial Setup
[X] Fresh rental box rezzed and initialized
[X] Settings notecard loads correctly
[X] Owner permissions granted
[X] Mesh textures apply correctly
[X] Floating text displays properly
Payment System
[X] Correct payment amounts accepted (1, 2, 3, 4 weeks)
[X] Underpayment rejected and refunded
[X] Overpayment accepted and time calculated correctly
[X] Discount pricing works (if configured)
- if discount is 100, payment won't work.. which is fine. Explore fixing the math someday.
[X] Group payment works (if enabled)
[X] Owner payment works (if enabled)
Rental States
[X] Idle → Payment → Rented transition
[X] Rented → Time expires → Grace (if enabled)
[X] Grace → Time expires → Idle
[X] Rented → Locked (owner action)
[X] Locked → Unlock → Rented (if time remaining)
[X] Locked → Unlock → Idle (if no time)
[X] Idle → Reserved (specific renter)
[X] Reserved → Payment → Rented
Owner Menu Testing
Idle State
[X] "Info" gives notecard and displays data
[X] "Reset" resets the rental box
[?] "Specify Renter" sets specific renter
-Renter is specified but rental isnt properly restricted to specified person.
[X] "Lock" locks the box
[X] "Unavailable" marks as unavailable
[?] "Modules" shows module menu
- only tested 2 modules so far.. need to add more test modules.
Rented State
[X] "Info" gives notecard and displays data
[X] "Release" terminates lease (no refund)
[X] "Reset" resets the rental box
[X] "Lock" locks the box
[X] "Unavailable" marks as unavailable
[X] "Modules" shows module menu
[X] "Refund" option appears (if enabled)
Specific Renter State
[X] Only specified renter can pay
[X] Other users get "reserved" message
[X] Owner can cancel specific renter
Renter Menu Testing
Rented State
[X] "Info" gives notecard and displays data
[X] "Refund" option works (if enabled)
[X] Refund confirmation dialog appears
[?] Refund calculation is correct
[X] Refund fee is applied correctly
Module System Testing
Module Registration
[X] Prim Counter registers with channel
[X] Hello World registers with channel
[X] Other modules register correctly
[X] Module Manager tracks channels
[X] Channel assignments are unique
Module Communication
[X] Modules only respond on their channels
[?] Channel 0 (broadcast) still works
[?] Module routing uses correct channels
[X] User role checks work via channels
-seems to be fine, renter roles vs owner roles for prim counter module check out
[X] No message conflicts between modules
Module Menus
[X] Owner sees owner module options
[X] Renter sees renter module options
[X] Module pagination works (if >9 modules)
[X] "Back" button returns to main menu
[X] Module-specific features work
Prim Counter Module Testing
Configuration
[X] _PrimCounterSettings.txt loads correctly
[X] MODULE_CHANNEL: 0 auto-assigns random channel
- I'm going to assume this works because Hello World and Prim Counter are both set to 0 and do not clobber each other anymore
[X] MODULE_CHANNEL: 1234 uses specific channel
[X] All other settings load properly
Access Control
[X] ACCESS_MODE: available - both owner and renter can access
[X] ACCESS_MODE: owner_only - only owner can access
[X] ACCESS_MODE: renter_only - only renter can access
[X] ACCESS_MODE: disabled - no one can access
Reports
[X] Owner gets detailed prim report
[X] Renter gets their prim usage
[X] Quick count works
[X] Per-avatar breakdown shows correctly
Aggressive Mode
[X] AGGRESSIVE_MODE: enabled activates monitoring
[X] AGGRESSIVE_MODE: disabled skips monitoring
[X] Texture changes when limit exceeded
[X] Notifications sent to owner/renter
[X] Mode deactivates when under limit
[X] Only checks when rented
Hello World Module Testing
Basic Functionality
[X] Registers with random channel
[X] Owner menu shows full options
[-] Renter menu shows limited options
Hello world doesnt have a renter only menu?
[X] Click counter increments
[X] Reset counter works
[X] "Say Hello" works
Time and Expiration Testing
Rental Duration
[X] 1 week payment = 1 week time
[X] 2 week payment = 2 weeks time
[X] 3 week payment = 3 weeks time
[X] 4 week payment = 4 weeks time
[X] Discount pricing calculates correctly
Expiration Handling
[X] Time counts down correctly
[X] 48-hour reminder sent
[X] 24-hour reminder sent
[X] 6-hour reminder sent
[X] 1-hour reminder sent
[X] Grace period starts (if enabled)
[X] Grace period expires correctly
Data Persistence Testing
Script Resets
[X] Rental data survives script reset
[X] Renter info preserved
[X] Time remaining preserved
[X] State preserved correctly
Object Rezzing
[X] Data survives object rez
[X] Settings reload correctly
[X] Module registration happens
Edge Cases
Payment Edge Cases
[X] Multiple payments during rental
[X] Payment during grace period
[X] Payment after expiration
    - after expiration, it goes to grace. if not, then it goes back to rented state.
[X] Zero payment amount
    - does not allow
[X] Very large payment amounts
State Edge Cases
[X] Rapid state changes
[X] Multiple users clicking simultaneously
[X] Script resets during operations
[X] Inventory changes during operation
Module Edge Cases
[?] Module removed during operation
    - doesnt unregister.. requires reset to reload. 
[?] Multiple modules with same name
    - doesnt prevent. will cause issues. "dont do this"
[X] Channel conflicts (very rare)
    - Considering this resolved because of how rare it is. Set specific channels if needed.
[?] Module script errors
    - there were none to test. That's per module anyway.
Performance Testing
Memory Usage
[X] No memory leaks during operation
[X] Module list doesn't grow indefinitely
[X] Listeners cleaned up properly
[X] Timers managed correctly
Response Time
[X] Menu responses are quick
    - Quick enough.
[X] Module loading is fast
    - fast enough
[X] Payment processing is immediate
[X] No lag during normal operation
Documentation Testing
User Experience
[ ] Error messages are clear
[ ] Instructions are helpful
[ ] Notecards provide good guidance
[X] Menu options are intuitive
Release Readiness Checklist
[X] All core functionality tested
[X] Module system working
[X] Channel communication stable
[X] No critical bugs found
[ ] Documentation updated
[ ] Configuration examples provided
[X] Backward compatibility maintained
    - Generally speaking it would require dropping a new box down.
[ ] Remove Debug messages from any scripts