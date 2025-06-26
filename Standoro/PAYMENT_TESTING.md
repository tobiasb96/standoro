# Payment Testing Guide for Standoro

## A) Testing Without Paying

### 1. StoreKit Testing Framework (Recommended)

**Setup:**
1. Open Xcode
2. Go to **Product > Scheme > Edit Scheme**
3. Select **Run** on the left
4. Go to **Options** tab
5. Under **StoreKit Configuration**, select `Configuration.storekit`
6. Run the app

**How it works:**
- The app will use the local StoreKit configuration instead of the App Store
- You can make test purchases without real money
- All transactions are simulated locally
- Debug logs will show in the console

**Testing scenarios:**
- Purchase success/failure
- Restore purchases
- Network errors
- Verification failures

### 2. Debug Controls (Development Only)

In debug builds, you'll see additional buttons in the Pro upgrade view:
- **Simulate Purchase**: Instantly unlocks Pro features
- **Reset Purchase**: Locks Pro features again

### 3. Sandbox Testing

For more realistic testing:
1. Create a sandbox tester account in App Store Connect
2. Sign out of your real Apple ID on the device
3. Sign in with the sandbox account
4. Test purchases (they won't charge real money)

## B) Providing Free Access to Users

### 1. Promotional Codes (Recommended)

**Setup in App Store Connect:**
1. Go to **Users and Access > Promotional Codes**
2. Create a new promotional code
3. Set the code to provide free access to your Pro product
4. Set expiration date and usage limits
5. Share the code with users

**User redemption:**
- Users enter the code in the App Store
- The purchase is applied to their account
- Your app will detect the purchase via `Transaction.currentEntitlements`

### 2. TestFlight Promotional Codes

**For TestFlight users:**
1. In App Store Connect, go to **TestFlight**
2. Create promotional codes specifically for TestFlight builds
3. These codes work only in TestFlight versions
4. Perfect for beta testing with real users

### 3. Developer Gift Codes

**For specific users:**
1. In App Store Connect, go to **Users and Access > Promotional Codes**
2. Create single-use codes
3. Send directly to specific users
4. Track usage and redemption

### 4. Free Product Variant

**Alternative approach:**
1. Create a separate "Pro Free" product in App Store Connect
2. Set price to $0.00
3. Use this for testing and giveaways
4. Your app can check for either product

## Implementation Notes

### Current Setup
- Product ID: `com.standoro.pro`
- Type: Non-consumable (one-time purchase)
- Price: $9.99

### Debug Logging
The app now includes comprehensive debug logging:
- Product fetching status
- Purchase attempts and results
- Restore operations
- Transaction verification

### StoreKit Configuration
The `Configuration.storekit` file includes:
- Test product definition
- Error simulation options
- Localization support

## Testing Checklist

### Local Testing
- [ ] StoreKit configuration loads correctly
- [ ] Product information displays properly
- [ ] Purchase flow works end-to-end
- [ ] Restore purchases works
- [ ] Pro features unlock after purchase
- [ ] Debug controls work in debug builds

### Sandbox Testing
- [ ] Create sandbox tester account
- [ ] Test with sandbox Apple ID
- [ ] Verify purchase flow
- [ ] Test restore functionality
- [ ] Check receipt validation

### Promotional Code Testing
- [ ] Create promotional code in App Store Connect
- [ ] Test code redemption
- [ ] Verify Pro features unlock
- [ ] Test code expiration
- [ ] Test usage limits

## Troubleshooting

### Common Issues

**"No product found"**
- Check product ID matches App Store Connect
- Verify StoreKit configuration is selected in scheme
- Check network connectivity

**"Purchase failed"**
- Check sandbox account is signed in
- Verify product is approved in App Store Connect
- Check for any pending transactions

**"Restore not working"**
- Ensure user is signed in with correct Apple ID
- Check for network issues
- Verify transaction verification

### Debug Commands

In the console, you can monitor:
```
PurchaseManager: Product fetched successfully - Standoro Pro ($9.99)
PurchaseManager: Attempting to purchase product: com.standoro.pro
PurchaseManager: Purchase successful and verified
PurchaseManager: Transaction update - Pro unlocked
```

## Next Steps

1. **Set up App Store Connect:**
   - Create the Pro product
   - Set pricing and description
   - Submit for review

2. **Test thoroughly:**
   - Use StoreKit testing framework
   - Test with sandbox accounts
   - Verify all edge cases

3. **Prepare for launch:**
   - Create promotional codes for early users
   - Set up TestFlight distribution
   - Plan marketing strategy

4. **Monitor after launch:**
   - Track purchase analytics
   - Monitor for issues
   - Gather user feedback 