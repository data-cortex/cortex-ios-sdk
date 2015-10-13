
# Data Cortex Example

Make sure you pods install after you clone.

```
pods install
```

The Pods directly is specifically not checked in because it is confusing.

Make sure you include the following key in your Info.plist

```
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSExceptionDomains</key>
  <dict>
   <key>api.data-cortex.com</key>
   <dict>
    <key>NSTemporaryThirdPartyExceptionRequiresForwardSecrecy</key>
    <false/>
   </dict>
  </dict>
</dict>
```
