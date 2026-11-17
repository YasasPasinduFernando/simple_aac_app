# Windows Window Management

> 22 nodes · cohesion 0.16

## Key Concepts

- **win32_window.cpp** (24 connections) — `windows/runner/win32_window.cpp`
- **.MessageHandler()** (12 connections) — `windows/runner/win32_window.h`
- **.WndProc()** (10 connections) — `windows/runner/win32_window.h`
- **.Create()** (9 connections) — `windows/runner/win32_window.h`
- **HWND** (7 connections)
- **.UpdateTheme()** (5 connections) — `windows/runner/win32_window.h`
- **.Destroy()** (4 connections) — `windows/runner/win32_window.h`
- **.GetThisFromHandle()** (4 connections) — `windows/runner/win32_window.h`
- **Win32Window::GetHandle()** (3 connections) — `windows/runner/win32_window.cpp`
- **EnableFullDpiSupportIfAvailable()** (3 connections) — `windows/runner/win32_window.cpp`
- **LPARAM** (2 connections)
- **LRESULT** (2 connections)
- **UINT** (2 connections)
- **Win32Window::Show()** (2 connections) — `windows/runner/win32_window.cpp`
- **WPARAM** (2 connections)
- **Scale()** (2 connections) — `windows/runner/win32_window.cpp`
- **.SetQuitOnClose()** (2 connections) — `windows/runner/win32_window.h`
- **Win32Window::Win32Window()** (2 connections) — `windows/runner/win32_window.cpp`
- **dwmapi** (1 connections)
- **resource.h** (1 connections) — `windows/runner/resource.h`
- **EnableNonClientDpiScaling** (1 connections) — `windows/runner/win32_window.cpp`
- **wstring** (1 connections)

## Relationships

- [Win32 Window Lifecycle](Win32_Window_Lifecycle.md) (16 shared connections)
- [Windows Class Registrar](Windows_Class_Registrar.md) (3 shared connections)
- [Windows C++ Runtime](Windows_C++_Runtime.md) (2 shared connections)
- [Windows Flutter Controller](Windows_Flutter_Controller.md) (2 shared connections)
- [Geometry Utility Classes](Geometry_Utility_Classes.md) (2 shared connections)

## Source Files

- `windows/runner/resource.h`
- `windows/runner/win32_window.cpp`
- `windows/runner/win32_window.h`

## Audit Trail

- EXTRACTED: 55 (87%)
- INFERRED: 8 (13%)
- AMBIGUOUS: 0 (0%)

---

*Part of the graphify knowledge wiki. See [index](index.md) to navigate.*