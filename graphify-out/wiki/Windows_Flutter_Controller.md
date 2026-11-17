# Windows Flutter Controller

> 20 nodes · cohesion 0.11

## Key Concepts

- **FlutterWindow** (12 connections) — `windows/runner/flutter_window.h`
- **.MessageHandler()** (8 connections) — `windows/runner/flutter_window.h`
- **flutter_window.cpp** (7 connections) — `windows/runner/flutter_window.cpp`
- **FlutterWindow::OnDestroy()** (3 connections) — `windows/runner/flutter_window.cpp`
- **Win32Window::OnDestroy()** (3 connections) — `windows/runner/win32_window.cpp`
- **FlutterWindow::FlutterWindow()** (2 connections) — `windows/runner/flutter_window.cpp`
- **FlutterViewController** (1 connections)
- **optional** (1 connections)
- **unique_ptr** (1 connections)
- **DartProject** (1 connections)
- **HWND** (1 connections)
- **LPARAM** (1 connections)
- **LRESULT** (1 connections)
- **UINT** (1 connections)
- **WPARAM** (1 connections)
- **flutter_controller_** (1 connections) — `windows/runner/flutter_window.h`
- **project_** (1 connections) — `windows/runner/flutter_window.h`
- **DartProject** (1 connections)
- **.OnCreate()** (1 connections) — `windows/runner/flutter_window.h`
- **.OnDestroy()** (1 connections) — `windows/runner/flutter_window.h`

## Relationships

- [Win32 Window Lifecycle](Win32_Window_Lifecycle.md) (4 shared connections)
- [Windows C++ Runtime](Windows_C++_Runtime.md) (2 shared connections)
- [Windows Window Management](Windows_Window_Management.md) (2 shared connections)
- [Windows Plugin Registry](Windows_Plugin_Registry.md) (1 shared connections)

## Source Files

- `windows/runner/flutter_window.cpp`
- `windows/runner/flutter_window.h`
- `windows/runner/win32_window.cpp`

## Audit Trail

- EXTRACTED: 29 (100%)
- INFERRED: 0 (0%)
- AMBIGUOUS: 0 (0%)

---

*Part of the graphify knowledge wiki. See [index](index.md) to navigate.*