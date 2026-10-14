Issue: https://github.com/omacom/omarchy/issues/15364
Branch: fix/edge-webapp-dock-15364
Commit: 2f1858e623f9d8a7b6949fd996de52fe90e1d4f8

The patch retries an unmatched Edge web-app class (`msedge-x.com__-Default`) as the shipped Chromium class (`chrome-x.com__-Default`) in the dock. Exact entries win. Only the observed Edge prefix and web-app-shaped IDs are eligible. Browser prefixes that have not been measured are not mapped, and the URL/profile suffix is preserved.

The actual QML lookup method is exercised in Node with desktop-entry stand-ins. Old code fails the new Edge lookup regression; fixed dock-test.sh passes 52 checks, including grouping a running window with a pinned X entry, exact-match precedence, regular Edge windows, unsupported prefixes, missing entries, profile suffixes and terminal fallback. These are headless checks, not real QML/DesktopEntries or visual verification.

No Hyprland, Quickshell or Edge is installed in the configured Debian cloud. The repository's agents/skills/visual-verification.md requires verification in the running UI. Do not submit this branch as ready until these checks are performed on a real Omarchy desktop:

1. With Edge as the default browser, launch X through the normal launcher while X is unpinned. Confirm its dock icon appears and resolves to X's entry.
2. Pin X, close it, then launch it again. Confirm the pinned icon gains a running window and the normal running appearance; clicking it focuses that window.
3. Confirm an ordinary Edge window still resolves as Edge, an exact browser-specific web-app entry wins when present, and Chromium web apps retain their matching behavior.
4. Exercise an alternate profile if available. The fallback preserves the suffix; it must not force a Profile_1 app onto the shipped Default entry.
5. Capture and inspect before/after screenshots as required by the guide. Verify no duplicate icon, incorrect grouping, clipping or stale running state.

This is a preserved work-in-progress patch. It does not resolve unmeasured Brave/Opera/Vivaldi/Helium prefixes. No upstream PR has been created for it.
