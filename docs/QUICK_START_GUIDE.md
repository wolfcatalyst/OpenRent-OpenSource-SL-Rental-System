# OpenRent v3.1 - Quick Start Guide

## GET IT UP NOW - Minimal Setup Instructions

### Step 1: Rez the Rental Box
1. Rez your OpenRent rental box in-world
2. Make sure it's positioned where you want your rental space

### Step 2: Configure Basic Settings
Edit the `_Settings` notecard with these MINIMUM required settings:

```
# Basic Configuration - Change these values!
Spot Name: My Rental Space
Rental Cost: 1000
Prim Count: 100
Rental Size: 256
Info Notecard Name: Rental Info
Welcome Notecard: Welcome Notecard

# Optional but recommended
Email for Notifications: your.email@example.com
Refunds Enabled: 1
Refund Fee: 50
Grace Period: 24
Floating Text Enabled: 1
```

### Step 3: Add Required Notecards
Make sure these notecards are in the rental box:
- `Rental Info` - Information given to potential renters
- `Welcome Notecard` - Given to renters after payment
- `_Settings` - Your configuration (created in Step 2)

### Step 4: Reset and Test
1. Touch the rental box
2. Select "Reset" from owner menu
3. Wait for "Initialized" message
4. Test by touching the box - should show rental information

**You're live!** The rental box is now accepting payments.

---

## GET IT UPDATED NOW - Upgrade Instructions

### Upgrading from Previous Versions

**Manual Upgrade Process:**
1. **Deploy new rental box** with updated v3.1 scripts
2. **Copy object description** from old rental box to new rental box
3. **Reset the new rental box** (touch menu → Reset, or llResetScript)
4. **Verify data transfer** - check that renter info, time remaining, and all settings are correct
5. **Delete old rental box** once confirmation is complete

**What Gets Preserved:**
- Renter information (name, ID, remaining time)
- All rental settings and configurations
- Module states and data

**Important Notes:**
- The new system includes offline time correction - if the old box was in inventory, time will be automatically adjusted on first rez
- All owner notifications are now enhanced with both IM and email
- Reminder system has been improved with proper time ranges
- Grace period status is NOT preserved (renters already didn't pay on time)

**Verification Checklist:**
- [ ] Renter name displays correctly
- [ ] Time remaining is accurate
- [ ] Floating text shows correct information
- [ ] Touch menu functions properly
- [ ] Payment system works

---

## Troubleshooting

**"Settings notecard not found!"**
- Make sure `_Settings` notecard is in the rental box
- Check spelling and capitalization

**"Waiting for debit permissions..."**
- This is normal - Second Life is asking for payment permissions
- Grant permissions when prompted

**Rental time doesn't match after update**
- The system automatically corrects for offline time
- Check chat for "Offline Time Correction" messages

**Need help?**
- Check the full documentation in README.md
- Support available only for official purchasers from Wolf Catalyst in Second Life 