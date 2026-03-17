# B2C App Redesign — Route Map

> Master reference for all pages, routes, and their status.
> Built from Figma designs, screen by screen.

---

## Layout

All event sub-pages share a **persistent sidebar layout**:
- **Desktop**: Left sidebar (company logo, Quick Actions, navigation) + main content area
- **Mobile**: Hamburger menu replaces sidebar, content goes full-width
- **Top bar**: Event logo + event name (dark blue header), notification bell + profile icon (right)

---

## Auth Flow

| Route | Page | Status | Notes |
|-------|------|--------|-------|
| `/login` | Login | EXISTS | After login → redirect to `/events/:id/menu` |
| `/signup` | Registration | EXISTS | After register → redirect to `/events/:id/menu` |
| `/verify-code` | Verification Code | EXISTS | |
| `/verify-email` | Verify Email | EXISTS | |
| `/forgot-password` | Forgot Password | EXISTS | |
| `/forgot-password/verify` | Forgot Password Verify Code | EXISTS | |
| `/reset-password` | Reset Password | EXISTS | |
| `/legal/:docType` | Legal Document | EXISTS | |
| `/create-password` | Create Password | **NEW** | Public page (no auth). Token-based link sent to team members. One-time use token that never expires until consumed. Fields: New Password, Confirm Password. On submit → redirect to `/login`. Uses AuthPageLayout style (OGUZ logo, event image left). |

---

## Public Pages (no auth required)

| Route | Page | Status | Notes |
|-------|------|--------|-------|
| `/` | Event List (Home) | EXISTS | List of all events. Profile icon click → `/login` if not logged in |
| `/events/:id` | Event Details | RESTYLE | Two-column: scrollable description card (left) + event image + "Open" button (right). Company logo on top bar, event logo + name in header. Image carousel at bottom. "Open" → login if not auth'd, else → menu |

---

## Event Pages (auth required, sidebar layout)

### Core / Dashboard

| Route | Page | Status | Notes |
|-------|------|--------|-------|
| `/events/:id/menu` | Event Menu / Dashboard | RESTYLE | **Two states:** Pre-approval = Event Services shop. Post-approval = Dashboard with sponsor carousel, progress bar (Registration ✓, Payment ✓, Company Info %, Team Members %, Visa %), 4 summary cards (My Company, Team Members, Visa Status, Services & Orders) |

### Quick Actions

| Route | Page | Status | Notes |
|-------|------|--------|-------|
| `/events/:id/company-profile` | Complete Company Profile | **NEW** | Tabs for multiple companies (up to 5 per registrant, "+ Add 1/5"). Sections: **Basic Info** (name, category dropdown, website, About rich text editor max 2000 chars), **Contact & Address** (country, city, email, mobile, social medias + Add New), **Branding** (Brand Icon 512x512, Full Logo 1200x400, Cover Image 1200x400), **Gallery** (up to 4 images). Cancel/Continue buttons. |
| `/events/:id/company-profile/:companyId/preview` | Company Profile Preview | **NEW** | Public view: company name + logo, about text, gallery (4 images), "Participants list from this company" (team member cards with photo/name/title/flag/"View Profile"), social media icons, contacts, email. **Note: missing from Figma, needs button on profile form.** |
| `/events/:id/team` | Team Members (Manage) | **NEW** | List of team members per company, role management, status changes. Replaces old "participants" concept. |
| `/events/:id/team/add` | Add Team Member | **NEW** | **2-step wizard:** Step 1 "Personal Info" — tabs for each member + "+ Add (1/5)", hint box (ID badge info), form: profile picture upload/remove, Name, Surname, Email, Mobile (country flag), Country, City, Choose Company dropdown, Position, "Follow Me" social links (+ Add New). Step 2 "Role in Event" — table: avatar + name, email, Role dropdown (User = "view/edit own info", Administrator = "view/edit all users"), delete button with confirmation dialog. Back/Cancel/Continue buttons. |
| `/events/:id/services` | Event Services (Shop) | **NEW** | Category filter (checkboxes: All, Expo, Forum, Sponsors, Promotional, Print, Transfer, Tickets, Flight, Catering), filter dropdowns (Price, Discount, Service Type, Currency), product grid with cards (image, name, price, discount tag, add-to-cart/quantity controls), cart icon with badge + dual currency total (TMT/$) |
| `/events/:id/services/:serviceId` | Service Detail | **NEW** | Breadcrumb, product image, name, subtitle, description, price, minimum order, Included/Not Included lists, add-to-cart button |
| `/events/:id/services/cart` | Shopping Cart | **NEW** | Product cards with delete icon + quantity controls, Cart summary (price, discount, total), Promocode input + "Send" button, "Delete all" link |

### Main Navigation

| Route | Page | Status | Notes |
|-------|------|--------|-------|
| `/events/:id/visa-travel` | Visa & Travel Center | RESTYLE | Was `visa-apply`. Warning banner (incomplete form disclaimer). **VISA APPLICATION FORM**: Name, Surname, 2x photo uploads (passport photo 5x6 + document scan), Gender dropdown, Date of birth (date picker), **Surname at birth** (hidden until gender selected, replaces old unnamed field), Citizenship dropdown, Country of birth dropdown, Place of birth (City) dropdown, Type of passport (optional), Passport number, Passport date issue, Passport validity period, Place of issue (country) dropdown, Personal Address, Email, Education, Speciality, Place of work (Company name), Personal mobile number, **Position** (LinkedIn-style global list, multi-select), Place of education, Planned residential address, Marital status (Yes/No toggle), Confirmation checkbox, Cancel/Submit. |
| `/events/:id/services-addons` | Services & Add-Ons | ALIAS | Same page as Event Services (`/events/:id/services`) |
| `/events/:id/schedule` | Schedule & Meetings | RENAMED | Was `meetings`. Details TBD |
| `/events/:id/financial` | Financial Section | **COMING SOON** | Payment history table: date, method (PayPal), amount (US$). Placeholder page for now. |
| `/events/:id/analytics` | Analytics | **COMING SOON** | Placeholder page for now. |
| `/events/:id/hotels` | Hotels | **COMING SOON** | Placeholder page for now. |
| `/events/:id/speakers` | Speakers List | RESTYLE | Search bar, Sort by A-Z dropdown, speaker cards (photo, name, title/company, country flag + name, "View Profile" button) |
| `/events/:id/speakers/:speakerId` | Speaker Detail | RESTYLE | Breadcrumb (Speakers > Name), "Meeting request" button (top right), photo, name, company logo + title, bio, social icons (Facebook, Instagram, LinkedIn), contacts (phone) |
| `/events/:id/agenda` | Event Agenda | RESTYLE | Program/Favourite toggle tabs, search bar, Sort by dropdown, Day tabs (Day 1/2/3), time slots, agenda items (date, location chip, title, description, "Read more", sponsor logo + badge, favourite star icon). |
| `/events/:id/participants` | Participants of Event | RESTYLE | List of companies/participants. Clicking a participant → Company Profile Preview page (`/events/:id/company-profile/:companyId/preview`). No longer individual person view — shows companies. |
| `/events/:id/news` | News | EXISTS | Details TBD |
| `/events/:id/news/:newsId` | News Detail | EXISTS | Details TBD |
| `/events/:id/hotline` | Hotline | EXISTS | Details TBD |
| `/events/:id/feedback` | Feedback | EXISTS | Details TBD |
| `/events/:id/faq` | FAQ | RESTYLE | Search bar, accordion expand/collapse items, expanded shows answer with numbered steps |

---

## Other Pages

| Route | Page | Status | Notes |
|-------|------|--------|-------|
| `/profile` | Profile | RESTYLE | Back arrow + "Profile" title. Photo with "Upload Photo (5:6)". Fields: Name, Surname, Email, Mobile (country flag), **Country** (dropdown), **City** (dropdown, depends on selected country), Company Name, Company Website, **Company category** (multi-select, 200+ LinkedIn-standard categories, shows count badge), Position. **Follow Me**: 5 options (LinkedIn, Instagram, Facebook, WeChat, Twitter) — validate/format URLs correctly. Save button. |
| `/events/:id/transfer` | Transfer | EXISTS | Separate sidebar item |
| `/events/:id/flights` | Flights | EXISTS | Separate sidebar item |

---

## Summary Stats

| Category | Count |
|----------|-------|
| **NEW pages** | 12 (incl. Create Password) |
| **RESTYLE pages** | 7 (incl. Participants of Event) |
| **COMING SOON** | 3 (Financial, Analytics, Hotels) |
| **EXISTS (unchanged)** | 15+ |
| **TO REMOVE** | 5+ old participant pages/routes |
| **Total routes** | 38+ |

---

## New Shared Components Needed

| Component | Used By |
|-----------|---------|
| `EventSidebarLayout` | All event sub-pages (wraps sidebar + content) |
| `SponsorCarousel` | Dashboard (post-approval) |
| `ProgressBar` | Dashboard |
| `SummaryCard` | Dashboard (My Company, Team, Visa, Services) |
| `ProductCard` | Event Services grid |
| `CategoryFilter` | Event Services sidebar |
| `CartSummary` | Shopping Cart, cart icon badge |
| `ServiceDetailCard` | Service Detail page |
| `SpeakerCard` | Speakers list (redesigned) |
| `FAQAccordion` | FAQ page (redesigned) |
| `BreadcrumbNav` | All sub-pages (e.g. "Speakers > Dr. Mitchell") |
| `StepWizard` | Add Team Member (2-step), possibly others |
| `TeamMemberCard` | Team manage page, company preview |
| `RoleDropdown` | Add Team Member step 2 (User/Administrator) |
| `CompanyProfileForm` | Company Profile (multi-section form with tabs) |
| `RichTextEditor` | Company Profile "About" field (max 2000 chars) |
| `ImageUploader` | Company branding (icon, logo, cover), gallery, team member photo |
| `CompanyPreviewCard` | Company Profile Preview page |
| `DeleteConfirmDialog` | Team member removal confirmation |

---

## Key Business Logic

- **Participants → Team Members**: Old "participants" are now "team members" belonging to companies
- **One registrant = multiple companies** (up to 5), each with its own team members (up to 5 per company)
- **Registrant = Team Administrator**: Can assign roles (User/Administrator) and change statuses for all team members
- **Administrator role**: "can view and edit information for all users"
- **User role**: "can view and edit only their own information"
- **Company Profile** has a public preview page showing gallery, team members, social media, contacts
- **Choose Company** dropdown on Add Team Member links member to one of registrant's companies
- **Create Password flow**: Admin creates team member → system generates one-time token link → team member opens `/create-password?token=xxx` → creates password → redirected to `/login` → logs in with email + new password. Token never expires until consumed. Once used, link dies.
- **Sidebar lock icons** unlock after admin approval
- **"Participants of Event"** now shows company list, clicking opens Company Profile Preview
- **"Services & Add-Ons"** = same as "Event Services" (alias route)

---

## Old Code to Remove

These files/features are replaced by the new structure and should be deleted:

| Old Path | Reason |
|----------|--------|
| `features/participants/ui/my_participants_page.dart` | Replaced by `team/ui/team_members_page.dart` |
| `features/participants/ui/add_participant_form_page.dart` | Replaced by `team/ui/add_team_member_page.dart` |
| `features/participants/ui/add_participant_select_event_page.dart` | No longer needed — team members added from within event |
| `features/participants/ui/edit_participant_page.dart` | Replaced by team member edit (within add_team_member flow) |
| Old `/participants/select-event` route | Remove from router |
| Old `/participants/add` route | Remove from router |
| Old `/events/:id/my-participants` route | Remove from router (replaced by `/events/:id/team`) |
| Old `/events/:id/visa-apply` route | Remove from router (replaced by `/events/:id/visa-travel`) |
| Old `/events/:id/participants/edit/:participantId` route | Remove from router |
| `features/events/ui/event_registration_page.dart` | REMOVE — registration is now handled by Event Services (buy package = register) |
| Old `/events/:id/registration` route | Remove from router |
| `features/networking/ui/meeting_not_registered_page.dart` | TBD — may not be needed with new approval flow |
| `features/contact/` (entire feature) | REMOVE — contact page removed from redesign |
| Old `/events/:id/contact` route | Remove from router |
| `features/events/ui/event_registration_page.dart` route | Remove — registration handled by Event Services |

---

## Development Rules

- **Icons**: Use any placeholder icon (e.g. `Icons.circle`) when building pages. User will replace with correct Figma-exported icons later.
- **Registration = buying a package** through Event Services. Old `event_registration_page.dart` is obsolete.
- **Transfer & Flights** remain separate sidebar items (not categories within Event Services).
- **City depends on Country**: Everywhere Country/City dropdowns appear (Profile, Visa, Company Profile, Add Team Member), City list must filter based on selected Country.
- **Company categories**: Use LinkedIn-standard list (200+ categories), multi-selectable with count badge.
- **Follow Me** social links: 5 options — LinkedIn, Instagram, Facebook, WeChat, Twitter. Validate and format URLs correctly (e.g. auto-prefix `https://linkedin.com/in/` if user just types username).
- **Notifications**: Trigger notifications on user actions (team member added, status changed, approval, etc.). More conditions TBD.
- **Agenda**: Now in sidebar. Has Program/Favourite tabs, day tabs, search, sort, sponsor badges, favourite star.

---

## Design Notes

- **Lock icons** on sidebar items = requires approval/registration first
- **Cart** persists across pages with badge count + dual currency (TMT / $)
- **Sponsor carousel** horizontal scrollable, shown on dashboard
- **Responsive**: Desktop = sidebar + content. Mobile = hamburger + full-width stacked content
- **Color scheme**: Dark blue header (#3C4494), white cards, light gray background (#F1F1F6), green buttons for actions
