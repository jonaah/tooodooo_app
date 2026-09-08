<div align="center">
  <img src="assets/icon/toodoo_logo_new.png" alt="Tooodooo Logo" width="120" />
  <h1>Tooodooo</h1>
  <p><strong>A feature-rich task management & calendar app built with Flutter</strong></p>

  <p>
    <img src="https://img.shields.io/badge/Flutter-3.7+-02569B?logo=flutter&logoColor=white" alt="Flutter 3.7+" />
    <img src="https://img.shields.io/badge/Dart-3.7+-0175C2?logo=dart&logoColor=white" alt="Dart 3.7+" />
    <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-lightgrey" alt="Platforms" />
    <img src="https://img.shields.io/badge/Tests-151%20passing-brightgreen" alt="Tests" />
  </p>
</div>

---

## About

**Tooodooo** is a cross-platform productivity app that combines task management with calendar scheduling and Google Calendar integration. Built as a personal project to deepen my Flutter expertise and explore real-world mobile architecture patterns — from state management and local persistence to third-party API integration.

## Features

### Task Management
- Create, edit, and delete tasks with **priority levels** (1–5) and visual color-coding
- **Subtask groups** — organize related items as collapsible sub-lists with auto-completion tracking
- Assign custom **icons**, **colors**, and **estimated durations** to tasks
- Swipe gestures (slide-to-edit, slide-to-delete) for fast task management
- Tasks auto-sort by priority for at-a-glance focus

### Calendar Integration
- Full **day-view calendar** powered by Syncfusion, with pinch-to-zoom for time intervals
- Schedule tasks directly onto the calendar via double-tap or the task picker dialog
- **Google Calendar two-way sync** — sign in with Google to automatically pull and push events
- Mark calendar appointments as completed with visual distinction (greyed-out, strikethrough)
- Configurable calendar time range and initial display time

### Today View
- Smart categorization of daily tasks: **Happening Now**, **Upcoming**, **Pending**, **Completed**
- Date navigation with contextual labels ("TODAY", "TOMORROW", "IN 3 DAYS", etc.)
- Live progress tracking for currently active tasks
- Quick actions to mark tasks complete or navigate to the calendar

### Settings & Customization
- Configure calendar start/end times and default view
- Google Account login/logout for Calendar sync
- Centralized design system (`AppTheme`) for consistent styling across the app

## Architecture

```
lib/
├── models/              # Data models (Task, SubTask)
├── calendar/            # Calendar feature module
│   ├── appointment_service.dart       # CRUD + Google Calendar sync
│   ├── calendar_appointment.dart      # Immutable appointment model
│   ├── appointment_data_source.dart   # Syncfusion data source adapter
│   ├── calendar_edit_dialog.dart      # Appointment create/edit UI
│   ├── calendar_zoom_controller.dart  # Pinch-to-zoom logic
│   └── google_calendar_client.dart    # Google Sign-In & API client
├── today/               # Today-view feature module
│   ├── today_tasks_service.dart       # Task categorization logic
│   ├── task_card.dart                 # Task card widget
│   └── task_section_header.dart       # Section header widget
├── pages/               # App screens
│   ├── main.dart                      # Navigation shell (IndexedStack)
│   ├── home_page.dart                 # Task list + CRUD
│   ├── today_tasks_page.dart          # Today view
│   ├── calendar_page.dart             # Calendar view
│   ├── settings_page.dart             # App settings
│   └── emoji_picker_page.dart         # Icon selection
└── util/                # Shared UI components & utilities
    ├── app_theme.dart                 # Design system & theming
    ├── dialog_box.dart                # Task creation dialog
    ├── todo_tile.dart                 # Task list item widget
    ├── app_icons.dart                 # Icon registry
    ├── icon_manager.dart              # Recent icons persistence
    └── ...
```

**Key architectural decisions:**
- **Feature-based modules** (`calendar/`, `today/`) with dedicated services, models, and widgets
- **Separation of concerns** — business logic lives in service classes (`AppointmentService`, `TodayTasksService`), not in widget state
- **Immutable models** — `CalendarAppointment` uses `copyWith()` for safe state updates
- **Local persistence** via `SharedPreferences` with JSON serialization
- **Google Calendar sync** as an opt-in layer that gracefully degrades when offline or not authenticated

## Testing

The project follows a **3-tier testing strategy** with 151 tests:

```
test/
├── unit/          # Pure logic — models, services, controllers, utilities
├── widget/        # UI component tests with mocked dependencies
└── integration/   # Full app smoke tests
```

```bash
flutter test     
```

| Layer | Coverage |
|-------|----------|
| **Unit** | Task/SubTask models, CalendarAppointment, TodayTasksService categorization, CalendarZoomController, AppIcons, AppTheme, IconManager |
| **Widget** | HomePage (empty state, task display, scroll behavior), navigation bar, appointment data source, TodayTasksPage |
| **Integration** | App startup, tab navigation, state preservation across tabs |

## Tech Stack

| Category | Technology |
|----------|-----------|
| Framework | Flutter 3.7+ / Dart |
| Calendar | Syncfusion Flutter Calendar |
| Persistence | SharedPreferences (JSON) |
| Google Integration | Google Sign-In, Google Calendar API (googleapis) |
| UI Components | flutter_slidable, flutter_iconpicker |
| Testing | flutter_test (manual mocks, no code generation) |

## Getting Started

### Prerequisites
- Flutter SDK ≥ 3.7.0
- Dart SDK ≥ 3.7.0

### Installation

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/tooodooo_app.git
cd tooodooo_app

# Install dependencies
flutter pub get

# Run the app
flutter run

# Run tests
flutter test
```

> **Note:** Google Calendar sync requires a valid OAuth 2.0 client configuration. The app works fully offline without Google Sign-In.

## License

This is a private project. All rights reserved.
