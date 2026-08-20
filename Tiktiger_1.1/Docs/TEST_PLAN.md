# Test Plan

## Build tests
- Clean Debug build
- Clean Release build
- Build from Xcode UI
- Build from script

## Binary tests
- file
- lipo -info
- otool -hv
- otool -L

## API smoke tests
- version returns non-null
- enable/disable roundtrip
- counter increments
- counter reset
- uppercase handles normal input
- uppercase rejects undersized buffer
- checksum deterministic

## Host-app tests, when integration is available
- app launch
- foreground/background
- permission denial
- Photos permission allowed/denied
- LocalAuthentication unavailable/failure/success
- audio extraction cancellation
- invalid URL
- network failure
- provider failure
- disk-full / file-write error
- share sheet
- dark/light appearance
- Arabic/English translation paths
