// NIP-07 browser extension signer.
//
// On web platforms, this provides access to browser extensions like Alby,
// nos2x, etc. via the window.nostr JavaScript API.
//
// On non-web platforms, isAvailable always returns false and create
// always throws Nip07NotAvailableException.

export 'nip07_signer_stub.dart'
    if (dart.library.js_interop) 'nip07_signer_web.dart';
