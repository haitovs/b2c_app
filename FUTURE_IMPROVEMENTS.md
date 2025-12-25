# Future Improvements

This document tracks planned improvements to be implemented later.

---

## 1. Image Caching

**Priority:** Medium  
**Effort:** ~2 hours

### Current Issue
- 40+ `Image.network` usages across the app
- Images re-download on every view (wastes bandwidth, slow)

### Solution
Add `cached_network_image` package:

```yaml
# pubspec.yaml
dependencies:
  cached_network_image: ^3.3.1
```

Replace pattern:
```dart
// Before
Image.network(url, ...)

// After  
CachedNetworkImage(
  imageUrl: url,
  placeholder: (c, url) => CircularProgressIndicator(),
  errorWidget: (c, url, e) => Icon(Icons.error),
)
```

### Files to Update
- `event_menu_page.dart`
- `agenda_page.dart`
- `participant_detail_page.dart`
- `speaker_detail_page.dart`
- `news_page.dart`, `news_detail_page.dart`
- `meetings_page.dart` and related
- `event_card.dart`

---

## 2. API Response Caching

**Priority:** Low  
**Effort:** ~3 hours

### Current Issue
- API responses fetched every time
- No offline support

### Solution
Add HTTP caching layer or local database cache (Hive/SQLite)

---

## 3. State Management Optimization

**Priority:** Low

Review Provider usage and consider:
- Lazy loading where possible
- Dispose unused data
- Use `Selector` instead of `Consumer` for granular rebuilds

---

## 4. Custom Styled Message Widget

**Priority:** Medium  
**Effort:** ~2 hours

### Current Issue
- Using default Flutter `SnackBar` for bottom messages
- Not matching app's white/premium design aesthetic

### Solution
Create custom `AppMessage` widget that:
- White background with subtle shadow
- App typography (Google Fonts)
- Optional icon (success/error/info)
- Smooth slide-in animation
- Auto-dismiss with progress indicator

### Usage Pattern
```dart
// Before
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Message')),
);

// After
AppMessage.show(
  context,
  message: 'Message',
  type: MessageType.success, // or .error, .info
);
```

### Files Using SnackBar
- `profile_page.dart`
- `event_menu_page.dart`
- `login_page.dart`
- `registration_page.dart`
- Various meeting pages

---

## 5. Custom Admin Panel for Registration Manager

**Priority:** High  
**Effort:** ~4-6 hours

### Current Issue
The sqladmin `BaseView` class has proven unreliable for custom admin pages:
- Sidebar menu link doesn't respect the `identity` attribute
- Routes defined with `@expose("/")` don't mount at expected paths
- Framework picks arbitrary routes as the "default" menu link

### Recommended Solution: Separate FastAPI Routes
Create standalone admin routes that bypass sqladmin:

```
/api/admin/registrations/          - Dashboard HTML
/api/admin/registrations/detail    - Detail modal data
/api/admin/registrations/approve   - Approve action
/api/admin/registrations/reject    - Reject action
```

**Pros:**
- Full control over routing
- No dependency on sqladmin internals
- Can use Jinja2 templates

**Cons:**
- Loses sidebar integration
- Needs separate authentication

### Implementation Steps
1. Create `/api/admin/registrations/` route in new file
2. Move HTML template to Jinja2
3. Add admin authentication middleware
4. Remove `AdminRegistrationsView` from sqladmin
5. Add link in sqladmin dashboard to custom page
