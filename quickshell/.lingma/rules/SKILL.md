---
name: Qt-and-QuickShell-Development
description: >-
  Comprehensive Qt/QML development skill covering C++ documentation, code review, QML best practices,
  performance profiling, unit testing, UI design, and project-specific QuickShell desktop shell development.
  Handles Qt6 C++ and QML code generation, review, documentation, testing, profiling, and UI/UX design
  for desktop, embedded, and web targets. Includes project-specific rules for the Yemi QuickShell desktop
  environment with Hyprland/Niri compositor support.
license: LicenseRef-Qt-Commercial OR BSD-3-Clause
compatibility: >-
  Designed for Claude Code, GitHub Copilot, and similar agents.
metadata:
  author: qt-ai-skills + Yemi
  version: "1.0"
  qt-version: "6.x"
  category: development
---

# Qt & QuickShell Development Skill

This unified skill combines multiple Qt development sub-skills into a single comprehensive reference. It covers:

1. **Qt C++ Documentation** — Markdown reference docs for .h/.cpp files
2. **Qt C++ Code Review** — 60+ lint rules, 6 parallel deep-analysis agents
3. **Qt Deprecated Classes Reference** — Modern replacements for deprecated APIs
4. **Qt Framework Development Checklist** — FW-* rules for module/ framework code
5. **QML Documentation** — Markdown reference docs for .qml components
6. **QML Profiling** — Performance analysis with qmlprofiler
7. **QML Code Review** — 47+ lint rules, 6 analysis agents
8. **QML Test Running** — Build, run, and report Qt Quick tests
9. **QML Test Generation** — Write tst_*.qml unit tests
10. **QML Coding Best Practices** — Rules for writing QML code
11. **CMake Test Wiring** — Test infrastructure setup
12. **Test Report Format** — Markdown report specification
13. **C++ Review Checklist** — 80+ review rules
14. **UI/UX Design** — Design principles, accessibility, embedded/MCU
15. **Project Working Rules** — Yemi's QuickShell development rules

---

# Table of Contents

- [Qt C++ Documentation](#qt-c-documentation)
- [Qt C++ Code Review](#qt-c-code-review)
- [Qt Deprecated Classes](#qt-deprecated-classes)
- [Qt Framework Development Checklist](#qt-framework-development-checklist)
- [QML Documentation](#qml-documentation)
- [QML Profiling](#qml-profiling)
- [QML Code Review](#qml-code-review)
- [QML Test Running](#qml-test-running)
- [QML Test Generation](#qml-test-generation)
- [QML Coding Best Practices](#qml-coding-best-practices)
- [CMake Test Wiring](#cmake-test-wiring)
- [Test Report Format](#test-report-format)
- [C++ Review Checklist](#c-review-checklist)
- [UI/UX Design](#uiux-design)
- [Project Working Rules](#project-working-rules)

---

# Qt C++ Documentation

## Trigger
`qt-cpp-doc` — Use when generating Markdown docs for any .h or .cpp file in a Qt project.

## Core Requirements

- **No code fences anywhere except the Usage Example.** Method signatures, property types, and enum values all belong in prose and tables.
- **Header is truth, implementation provides context.** The `.h` file defines the public API surface. The `.cpp` provides implementation detail.
- **Context-aware.** Understand how each class fits into the project.
- **Tables for properties.** Always use Markdown tables for `Q_PROPERTY` declarations.
- **Access-level discipline.** Document `public` API in full. Document `protected` API separately. Silently skip `private` members.

## Document Structure for C++ Classes

Generate `<ClassName>.md` with these sections (omit empty sections):

### 1. Class Overview
Describe what the module does and where this class fits.

### 2. Project Structure and Dependencies
- What files `#include` or instantiate it
- Qt modules it depends on
- Build requirements

### 3. Class Hierarchy and Role
Describe inheritance chain. For every base class, explain what it contributes.

### 4. Q_PROPERTY Declarations
| Property | Type | READ | WRITE | NOTIFY | Description |

### 5. Enumerations (Q_ENUM / Q_FLAG)
| Value | Integer | Description |

### 6. Public Member Variables
| Variable | Type | Description |

### 7. Signals
Format: `#### signalName(paramType paramName)`

### 8. Public Slots and Q_INVOKABLE Methods
Format: `#### returnType methodName(paramType paramName)`

### 9. Public Methods

### 10. Protected Virtual Methods / Event Handlers

### 11. Ownership and Lifecycle
Parent ownership, RAII, caller responsibility, deleteLater() usage.

### 12. Thread Safety
GUI-thread only, thread-safe, or single-threaded.

### 13. QML Exposure (if applicable)

### 14. Inter-Class Interactions

### 15. External Communication (if applicable)
Network I/O, local sockets/IPC, D-Bus, serial/hardware, external processes.

### 16. Usage Example (reusable classes only)

## Document Structure for Application Entry Points (main.cpp)
A. Overview, B. Qt Application Setup, C. Command-Line Handling, D. Top-Level Object Creation, E. Wiring and Connections, F. Event Loop, G. Dependencies.

## Document Structure for Free-Function Headers
A. Overview, B. Namespaces, C. Types and Type Aliases, D. Constants, E. Functions, F. Dependencies, G. Usage Example.

## Pre-flight Check
Before reading source files, check if `doc/` directory and `.md` files already exist. If they do, ask user: update, skip, generate fresh, or cancel.

## Input Handling
- **Single file/pasted code:** Document just that file.
- **Folder/project:** Walk directory tree, document every meaningful .h/.cpp. If documenting >1 file, create `doc/index.md`.

## Parsing Qt C++ Accurately
- `Q_OBJECT` — meta-object system
- `Q_PROPERTY(type name READ getter WRITE setter NOTIFY signal ...)` — bindable property
- `Q_INVOKABLE` — callable from QML
- `Q_ENUM` / `Q_FLAG` — registered enums
- `Q_GADGET` — lightweight meta-object (no QObject)
- `Q_INTERFACES(...)` — plugin interfaces
- Members prefixed `m_` or `d_` are implementation details — skip them.

## Tone and Style
Write for a developer who knows Qt/C++ but hasn't seen this class. Be precise about types. Use present tense. Avoid filler. Describe behaviour, not implementation.

## Output Location
Generate docs in a `doc/` subdirectory next to source files. Only create `doc/index.md` if documenting >1 file.

## Quality Check (internal only)
- Every Q_PROPERTY, Q_ENUM, Q_FLAG, signal, public slot, Q_INVOKABLE, and public method is documented.
- Ownership/Lifecycle and Thread Safety sections are accurate.
- Correct document structure chosen for file type.

---

# Qt C++ Code Review

## Trigger
`qt-cpp-review` — Use when reviewing, auditing, or checking Qt6 C++ code quality before committing.

## When to Use
- User mentions: "review", "check", "audit", "look over", "code review", "sanity check"
- Suggest before committing code
- Validate Qt6 C++ code quality

## Arguments
- `/qt-cpp-review` — universal Qt6 C++ rules only
- `/qt-cpp-review framework` — also apply Qt framework/module development rules

## Framework Mode Detection
Auto-detect by scanning for framework signals. If ≥2 found, suggest framework mode:
- `QT_BEGIN_NAMESPACE` / `QT_END_NAMESPACE`
- `Q_*_EXPORT` macros
- `#include <QtModule/private/*_p.h>`
- `Q_DECLARE_PRIVATE`, `Q_D()`, `Q_Q()`
- `qt_internal_add_module` or `qt_add_module` in CMakeLists.txt

## Scope Detection
- **Diff/commit scope (narrow):** "this commit", "these changes", "the diff" → run `git diff`
- **Codebase scope (wide):** "review the codebase", "audit the project" → glob `*.cpp`, `*.h`, `*.hpp`

## Execution Order (3 Phases)

### Phase 1: Deterministic Linting
Run `python3 references/lint-scripts/qt_review_lint.py <files...>`

Rule categories (60+ checks):
- **INC** (Includes) — ordering, qglobal.h, duplication
- **DEP** (Deprecated) — obsolete class usage
- **PAT** (Patterns) — anti-patterns
- **MDL** (Model) — QAbstractItemModel contract
- **ERR** (Error Handling) — QFile::open, QJsonDocument::isNull, etc.
- **LCY** (Lifecycle) — deleteLater, Q_ASSERT side effects
- **API** (Naming) — get-prefix, enum hygiene
- **HDR/TMO/CND/VAL/TRN** — headers, timeouts, conditionals, value classes, ternary

### Phase 2: Agent-Driven Deep Analysis (6 parallel agents)

**Agent 1: Model Contracts**
- beginInsertRows/endInsertRows balance
- roleNames() returning roles data() doesn't handle
- dataChanged emitted with empty roles vector
- flags() returning inappropriate flags
- setData() returning true without emitting dataChanged
- Proxy models accessing source model internals

**Agent 2: Ownership & Lifecycle**
- Raw pointers with new but no delete/smart-pointer
- Missing deleteLater() on QNetworkReply
- Q_ASSERT with side effects or as sole null guard
- Missing Q_DISABLE_COPY_MOVE on polymorphic QObject subclasses
- Unbounded container growth
- Destructor not cleaning up owned children

**Agent 3: Thread Safety**
- QObject members written from worker threads without sync
- Signals emitted from workers with DirectConnection to main thread
- Model mutations from background threads
- Shared containers modified from multiple threads without sync
- Non-atomic counter increments

**Agent 4: API, Naming & C++ Correctness**
- get-prefix on mere getters
- Non-const getter methods (UB via meta-object system)
- return std::move(localVar) preventing NRVO
- noexcept on functions containing Q_ASSERT
- Unscoped enums without explicit underlying type
- Missing trailing comma on last enumerator
- Default: label in switch over enum
- QList<QString> instead of QStringList

**Agent 5: Error Handling & Validation**
- QFile::open() return value ignored
- QJsonDocument::fromJson() not checked for isNull()
- QNetworkReply::error() not checked before readAll()
- Hardcoded http:// instead of https://
- No SSL error handling
- Negative values accepted where only positive valid

**Agent 6: Performance & Code Quality**
- QRegularExpression constructed inside loop
- roleNames() rebuilding QHash on every call
- Non-const range-for over COW-shared containers
- operator[] on shared QHash (triggers detach)
- Magic numbers without named constants
- God classes violating SRP
- Stale member caches not invalidated

### Phase 3: Consolidation and Reporting
Merge lint + agent findings. Deduplicate. Apply confidence scoring. Format report.

## Confidence Scoring
| Confidence | Meaning | Action |
|------------|---------|--------|
| 90-100 | Certain | Report as finding |
| 80-89 | High | Report as finding |
| 60-79 | Medium | Investigation target |
| <60 | Low | Suppress |

## Output Format
```
## Qt Code Review Report

**Scope**: [diff/files]
**Files reviewed**: N
**Issues found**: N (M from lint, K from deep analysis)

### Lint findings
#### [L-NNN] <Short title>
- **File**: path/to/file.cpp:42
- **Rule**: <rule ID>
- **Finding**: <description>
- **Mitigation**: <what to do>

### Deep analysis findings
#### [D-NNN] <Short title>
- **File**: path/to/file.cpp:42
- **Category**: <agent name>
- **Confidence**: NN/100
- **Finding**: <description>
- **Trace**: <how confirmed>
- **Mitigation**: <what to do>

### Investigation targets
### Summary table
```

---

# Qt Deprecated Classes

## Trigger
`qt-deprecated-cl` — Reference list of deprecated Qt/std classes and their modern replacements.

## Qt Classes → Replacements
| Deprecated | Replacement | Rationale |
|------------|-------------|-----------|
| Java-style iterators | STL iterators | QT_NO_JAVA_STYLE_ITERATORS |
| Q_FOREACH | Range-based for | QT_NO_FOREACH |
| QScopedPointer | std::unique_ptr | Can't be moved |
| QSharedPointer / QWeakPointer | std::shared_ptr / std::weak_ptr | Removal planned for Qt 7 |
| QAtomic* | std::atomic | Exception: static QBasicAtomic* |
| QPair | std::pair | Type alias since Qt 6.0 |
| QSharedDataPointer | QExplicitlySharedDataPointer | Premature detach |
| q(v)nprintf() | std::(v)snprintf() | Platform-dependent |
| qMin/qMax/qBound | (std::min)() / (std::max)() / std::clamp() | Mixed-type args |
| QChar (as object) | char16_t | Language support |
| count() / length() | size() | Consistency |

## Anti-Patterns
| Pattern | Fix |
|---------|-----|
| std::optional::value() | Use *opt, opt->foo, if (opt) |
| std::optional{} default ctor | Use std::nullopt explicitly |
| p = realloc(p, ...) | tmp = realloc(...); check; p = tmp |
| value_or() with non-trivial arg | Ternary or if/else |
| QDateTime::currentDateTime() | currentDateTimeUtc() (100× faster) |
| QThreadPool::globalInstance() + blocking | Dedicated pool or releaseThread() |

---

# Qt Framework Development Checklist

## Trigger
`Qt-Dev-Checklist` — Use only when contributing to Qt framework/module code, not application code.

## API Design
- **FW-API-1**: Static factory members → `create()`. Non-static → `createFoo()`.
- **FW-API-2**: Don't default arguments of non-Trivial Type. Use out-of-line overloading.
- **FW-API-4**: Don't define symbols in a Qt library not referencing a type from that library.

## Public Headers
- **FW-HDR-1**: Don't move code around in public headers when changing them.
- **FW-HDR-2**: New virtual overrides must be designed for skipping.

## Includes (Framework)
- **FW-INC-1**: Include as `<QtModule/qheader.h>`, not `<QtModule/QHeader>`.
- **FW-INC-2**: Group: module → dep Qt modules → QtCore → C++ → C → platform.
- **FW-INC-5**: Prefer forward-declaring in headers. Use qcontainerfwd.h / qstringfwd.h.
- **FW-INC-6**: Don't include qglobal.h. Use fine-grained headers.

## Variables (Framework)
- **FW-VAR-1**: Static constexpr in exported classes: define in both .h and .cpp.
- **FW-VAR-2**: Use constexpr → Q_CONSTINIT const → Q_CONSTINIT → comment.

## Methods (Framework)
- **FW-MTH-2**: If inline must be out-of-class: `inline` on declaration, never on definition.
- **FW-MTH-3**: Const-ref getter → add lvalue-this and rvalue-this overloads.
- **FW-MTH-4**: Pass geometric types by value.

## Properties (Framework)
- **FW-PRP-2**: Don't add FINAL to existing QML-exposed class properties.

## Value Classes
- **FW-VAL-2**: Never QSharedPointer for d-pointers (2× size). Use QExplicitlySharedDataPointer.
- **FW-VAL-3**: Don't forget Q_DECLARE_SHARED.
- **FW-VAL-6**: Move SMFs: inline and noexcept.
- **FW-VAL-7**: Never export non-polymorphic class wholesale.

## Polymorphic Classes (Framework)
- **FW-PLY-1**: Dtor out-of-line (=default in .cpp) — required for stable ABI.

## QObject Subclasses (Framework)
- **FW-QOB-2**: Always override QObject::event(), even if just `return Base::event()`.

## Enums (Framework)
- **FW-ENM-6**: Scoped enums in QML-exposed classes: `Q_CLASSINFO("RegisterEnumClassesUnscoped", "false")`.

## QML Module Versioning
- **FW-QML-1**: New properties/methods/signals must be revisioned.
- **FW-QML-3**: Don't add new props/signals to QObject class itself.

## Commit Message
- **FW-CMT-1**: Demand rationale (not just Jira/task link).
- **FW-CMT-6**: Imperative mood, no passive voice.
- **FW-CMT-8**: Change-Id last; Pick-to/Task-number/Fixes before.

---

# QML Documentation

## Trigger
`qt-qml-docs` — Use when generating Markdown docs for any .qml file or QML component/module.

## Core Requirements
- **No code snippets (except Usage Example).** Describe code in prose and tables.
- **Context-aware.** Understand how each component fits into the project.
- **Tables for properties.** Always use Markdown tables.

## Document Structure for QML Components
Generate `<ComponentName>.md` with these sections (omit empty):

### 1. Component Overview
What the module does, where this component fits, its visual/logical role.

### 2. Project Structure and Dependencies
What imports/instantiates it, what it imports, build requirements.

### 3. Component Hierarchy and Role

### 4. Properties
| Property | Type | Default | Required | Description |

### 5. Signals
Format: `#### signalName(paramType paramName)`

### 6. Methods
Format: `#### methodName(paramType paramName) : returnType`

### 7. Inter-Component Interactions
Which properties are driven by external bindings, which signals consumed, shared state.

### 8. Usage Example (reusable components only)
Include only when root type is NOT Window/ApplicationWindow.

## Pre-flight Check
Check for existing docs. If found, ask user: update, skip, generate fresh, or cancel.

## Input Handling
- **Single file:** Document just that component.
- **Folder/project:** Walk tree, find all .qml files. Generate one .md per component. If >1, create doc/index.md.

## Parsing QML Accurately
- Root element is the base type
- `property`, `property alias`, `required property`, `signal`, `function`
- `readonly property` — document as read-only
- `component <Name> : BaseType { }` — document as separate component
- Internal helpers prefixed with `_` are usually private

## Tone and Style
Write for a developer who knows QML but hasn't seen this component. Be precise about types. Use present tense.

---

# QML Profiling

## Trigger
`qt-qml-profiler` — Use when the UI feels slow, laggy, or dropping frames.

## Scope
Targets 2D QML / Qt Quick applications only. Does NOT cover Qt Quick 3D.

## Arguments
- `[--profile <full|rendering|logic|memory>] -- <executable> [app-args...]`
- `<trace.qtd>` — analysis-only mode with existing trace

## Steps

### Step 1 — Locate tools
Find qmlprofiler binary. Detect OS (Linux/macOS/Windows) for compiler subdir and PATH lookup.

### Step 2 — Build with QML debugging
```bash
cmake -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo \
      -DCMAKE_CXX_FLAGS="-DQT_QML_DEBUG" \
      -DCMAKE_PREFIX_PATH="<qt-path>"
cmake --build build
```

### Step 3 — Run qmlprofiler
```bash
"<qt-path>/bin/qmlprofiler" [--include <features>] -o "<trace-file>" -- "<executable>" [app-args...]
```

### Step 4 — Parse the trace
```bash
python3 "<skill-path>/references/scripts/parse-qmlprofiler-trace.py" "<trace-file>"
```

### Step 5 — Analyze hotspots
Take top 5 hotspots. Map filenames to local source. Read source code. Analyze against anti-pattern reference.

### Step 6 — Write report
Write `profiler/reports/profile-report-<app>-YYYY-MM-DD-HHMMSS.md` containing:
1. Header (profiling metadata)
2. Event type summary table
3. Animation/frame-time summary
4. Memory summary
5. Pixmap cache summary
6. Top 30 hotspots table
7. Detailed analysis (top 5)
8. Next steps
9. AI-assistance footer

### Step 7 — Console summary
Display event summary, frame-time, memory, pixmap cache, top 5 hotspots, report path.

---

# QML Code Review

## Trigger
`qt-qml-review` — Use when reviewing, auditing, or checking QML code quality before committing.

## When to Use
- User mentions: "review", "check", "audit", "look over", "code review"
- Suggest before committing QML code

## Phase 1: Deterministic Linting (47+ checks)
```bash
python3 references/lint-scripts/qt_qml_lint.py <files...>
```

Rule categories: IMP (Imports), ORD (Ordering), BND (Bindings), LAY (Layout), LDR (Loader), DEL (Delegates), STA (States), IMG (Images), PRF (Performance), STY (Style), SIG (Signals), ERR (Error/Security), JS (JavaScript).

### Phase 1b: System qmllint (optional)
Run `qmllint --json` if available. Merge with Python linter findings.

## Phase 2: 6 Deep Analysis Agents

**Agent 1: Bindings & Properties**
Multi-cycle binding loops, property alias chains, unqualified access, missing `pragma ComponentBehavior: Bound`, missing `readonly`.

**Agent 2: Layout & Anchoring**
Anchoring to invisible items, cross-branch anchoring, items in Layouts using implicitWidth/Height feedback loops, missing Layout.fillWidth/fillHeight.

**Agent 3: Component Loading & Lifecycle**
createObject() return values not tracked, Loader source/sourceComponent switching, Image without status check, Connections with dynamic target, context properties in C++.

**Agent 4: ListView & Delegate Correctness**
Missing required property int index, delegate accessing undefined roles, complex delegates, currentIndex bugs, DelegateChooser patterns.

**Agent 5: States, Transitions & Structure**
PropertyChanges.restoreEntryValues surprises, Binding.restoreMode migration, deprecated Connections syntax, GraphicalEffects → MultiEffect migration.

**Agent 6: Performance & Code Quality**
Expensive expressions in bindings, missing Text.PlainText, font.preferShaping opportunity, signals communicating down (should be functions), unnecessary ids, singletons for data, reusable components with explicit width/height.

## Output Format
Same structure as C++ review report.

---

# QML Test Running

## Trigger
`qt-qml-test-run` — Use when building and running QML tests via qmltestrunner or CMake/CTest.

## Arguments
```
[--wire-up] [--no-build] [--no-report] [<path-or-dir>]
```

## Steps

### Step 1 — Locate Qt and qmltestrunner
Find Qt installation containing `bin/qmltestrunner`.

### Step 2 — Discover the test target
Scan for `tst_*.qml` files. Tests dir priority: `tests/` > any existing location.

### Step 3 — Harness mode
Three modes: No CMake → direct qmltestrunner; CMake with wiring → C++ harness; CMake without wiring → offer both.

### Step 4 — Detect existing CMake test wiring
Grep for `find_package(..QuickTest)`, `QUICK_TEST_MAIN`, or `QUICK_TEST_SOURCE_DIR`.

### Step 5 — Wire up if missing
Write `tests/CMakeLists.txt` + `tests/main.cpp`. Propose root CMakeLists.txt edits.

### Step 6 — Build
```bash
cmake -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_PREFIX_PATH="<qt-path>"
cmake --build build
```

### Step 7 — Run tests
```bash
"./build/tests/tst_qmltests" -o "<report.xml>,junitxml"
```

### Step 8 — Parse JUnit XML
Run `scripts/parse-qmltestrunner-output.py`.

### Step 9 — Write Markdown report
Write `build/tests/reports/test-report-YYYY-MM-DD-HHMMSS.md`.

### Step 10 — Console summary
Verdict, top 3 failures, report path.

---

# QML Test Generation

## Trigger
`qt-qml-test` — Use when writing Qt Quick unit tests with TestCase, SignalSpy, or tryCompare.

## Scope
- Authoring `tst_*.qml` files using TestCase, SignalSpy, tryCompare
- Testing properties, signals, Qt Quick Controls
- Single and multi-document generation

## Output Contract
- Write test file to `tests/tst_<ComponentName>.qml`
- Never emit test code as Markdown code block in chat
- Never silently overwrite existing files
- No skill-internal references in generated code

## Canonical Template
```qml
import QtQuick
import QtTest
import <source-import>

Item {
    id: root
    width: ...; height: ...

    Component {
        id: comp
        <ComponentType> { /* required properties */ }
    }

    TestCase {
        name: "test<ComponentType>"
        when: windowShown

        function test_properties() {
            const obj = createTemporaryObject(comp, root);
            verify(!!obj, "Component exists");
            compare(obj.someProperty, expectedValue);
        }
    }
}
```

## Testing Rules (47 rules)
Key rules:
1. QtQuick + QtTest without versions
2. Set Item width/height appropriately
3. Always parent createTemporaryObject on root, never on TestCase
6. Use `.background` accessor for background
7. Test only explicitly defined properties
8-11. Do NOT test size, anchors, currentIndex, cursorVisible
12. SignalSpy only for source-declared signals
21. One SignalSpy per target with descriptive IDs
23. Set focus = true before testing input components
26. Use mouseDoubleClickSequence, not mouseDoubleClick
27. Use tryCompare after any mouse event
30. No custom messages on compare/verify except 3 canonical forms
31. Lowercase hex colors
33. Use qsTr() for text values
40. Skip properties dependent on out-of-scope components
41. Window: use Qt.createComponent, not createTemporaryObject
42. Singleton: access by name, restore mutated state
43. Never invoke pointer handler signal as function
46. Offer to add objectName for testable inner items
47. Every test function must end with at least one compare/tryCompare

---

# QML Coding Best Practices

## Trigger
`qt-qml` — Use whenever writing, editing, reviewing, or debugging any .qml file.

## When Writing New QML Code
Produce minimum code. No illustrative snippets, placeholder comments, or scaffolding. Follow rules silently. Do not mention rules or violations in response.

## Imports
- No `QtQuick.Window` when `QtQuick` is imported (Qt 6)
- Use style-specific import when customizing controls (Qt 6)
- No version numbers on any import (Qt 6)
- Prefer Qt Quick Controls over building from atomic primitives

## Component Loading
- Use Loader for conditional UI
- `Loader.active: false` when unused frees memory
- Guard `Loader.item` access with `status === Loader.Ready`
- No `Qt.createComponent(url)` strings — use inline Component
- Loader.asynchronous: true for heavy components

## Property Bindings
- No circular dependencies. If A→B and B→A, one must break.
- Prefer declarative bindings (`prop: expr`) over imperative (`prop = value`)
- Imperative `=` destroys bindings. Use `Qt.binding(() => expr)` to restore.
- No function calls in hot bindings — cache in `readonly property`
- Use `Binding { when: ... }` to deactivate expensive bindings

## Layouts
- Never mix `anchors` + `Layout.*` on the same item
- Size items inside Layout with `Layout.*` properties only
- `anchors.fill: parent` over four separate edges
- Don't anchor to `visible: false` items
- Use Row/Column for uniform static arrangements
- Use RowLayout/ColumnLayout for resize-responsive UI

## ListView and Delegates
- Use `required property` for model roles (type-safe, faster)
- Access roles as `model.roleName` (prevents shadowing)
- Keep delegates minimal (complexity multiplies by item count)
- `ListView.reuseItems: true` for large lists (Qt 6.7+)
- No mutable JS variables in delegates — use QML properties
- Prefer Repeater + Column for static lists

## State Management
- `states` for discrete configurations only
- State names as enum-like strings
- `PropertyChanges` inside `states` only
- No `target` in `PropertyChanges` (Qt 6)
- Target transitions with `from`/`to`

## Animations
- Stop/pause animations when off-screen (bind `running` to visibility)
- Avoid animating width/height on complex subtrees (triggers full relayout)
- Use Behavior sparingly
- Set `alwaysRunToEnd` when interruption would leave broken state

## Images
- Always set `sourceSize` (prevents full-resolution decode)
- `asynchronous: true` for network/large files
- Check `Image.status` for error handling
- Prefer SVG for icons

## Accessibility
- Set `Accessible.role` and `Accessible.name` on custom controls
- `Accessible.ignored: true` for decorative items
- `activeFocusOnTab: true` on interactive custom items

## Performance and Rendering
- Avoid `clip: true` unless visually necessary (forces offscreen pass)
- Avoid `opacity` on complex components (composites subtree into FBO)
- Avoid unnecessary Item wrappers
- Use Item instead of transparent Rectangle
- Prefer Animator types over Animation for opacity, scale, rotation, x, y
- Avoid Canvas for animated content (use Shape, ShapePath, or QQuickPaintedItem)
- Minimize ShaderEffect/MultiEffect usage
- Prefer `layer.enabled` sparingly

## Internationalization
- Wrap every user-visible string in `qsTr()`
- Use `%1` placeholders, not concatenation
- Add disambiguation for identical strings
- `qsTr()` with literals only (cannot extract variables)

## Non-obvious Pitfalls
- `parent` in delegates is NOT the ListView — use `ListView.view`
- Dynamic scope is fragile — always use explicit `id` references
- Imperative `=` silently kills bindings
- `Timer.running` defaults to `false`
- `Connections` targets one object
- Z-ordering follows declaration order (last declared is on top)

## Pre-output Checklist (silent — never mention)
- No binding loops
- Delegates use `required property`
- Loader.item guarded with status check
- anchors and Layout.* not mixed
- Items in Layouts use Layout.* properties for sizing
- Every user-visible string in qsTr()

---

# CMake Test Wiring

## Trigger
`qt-quick-test-cm` — Use when wiring up test infrastructure (CMakeLists.txt, main.cpp) in a QML project.

## Two Variants

### GuiApplication Variant (default)
`tests/CMakeLists.txt`:
```cmake
qt_add_executable(tst_qmltests main.cpp)
target_compile_definitions(tst_qmltests PRIVATE
    QUICK_TEST_SOURCE_DIR="${CMAKE_CURRENT_SOURCE_DIR}"
)
target_link_libraries(tst_qmltests PRIVATE
    Qt6::Gui
    Qt6::QuickTest
    # <project library>
    # <project library>plugin
)
add_test(NAME tst_qmltests COMMAND tst_qmltests)
```

`tests/main.cpp`:
```cpp
#include <QtQuickTest>
#include <QCoreApplication>
#include <QObject>
class Setup : public QObject {
    Q_OBJECT
public slots:
    void applicationAvailable() {
        QCoreApplication::setOrganizationName("QtProject");
        QCoreApplication::setOrganizationDomain("qt.io");
        QCoreApplication::setApplicationName("qmltests");
    }
};
QUICK_TEST_MAIN_WITH_SETUP(qmltests, Setup)
#include "main.moc"
```

### Widgets Variant
Use when project links: Widgets, Charts, WebEngineWidgets, WebEngineQuick, Multimedia + widgets, PrintSupport, Pdf, PdfWidgets.

Links `Qt6::Widgets` and uses explicit `QApplication` in main.cpp.

## Root CMakeLists.txt Addition
```cmake
find_package(Qt6 REQUIRED COMPONENTS QuickTest)
enable_testing()
add_subdirectory(tests)
```

## Module-on-Executable Refactor
When `qt_add_qml_module(<exe> URI ...)` is called on a `qt_add_executable` target:
1. Create a STATIC library for the module
2. Link both the original executable and test binary against it
3. Remove `NO_RESOURCE_TARGET_PATH`
4. Link `<name>moduleplugin` in both targets

---

# Test Report Format

## Trigger
`qt-quick-test-re` — Defines the Markdown report format written after a Qt Quick test run.

## Report Sections
1. **Header** — project name, Qt version, run mode, timestamp, JUnit path
2. **Run setup** — exact command line, test root, skipped directories, extra -import paths
3. **Summary table** — total/passed/failed/skipped/duration
4. **Source changes since prior run** — list modified source files since last test run
5. **Failed tests** — name, failure_message, source, suggested next step
6. **Slowest tests** — top 10 by time_ms, flag >1000ms
7. **Skipped tests** — name + reason
8. **AI-assistance footer**

## Console Summary
Verdict line, first 3 failures, report path.

---

# C++ Review Checklist

## Trigger
`qt-review-checkl` — Rule reference for qt-cpp-review. Contains Qt6 C++ lint rules.

## API & Naming
- **API-3**: Naming consistency (timeout not timeOut, size() not count())
- **API-5**: get-prefix = user interaction or decomposition, not mere getters

## Variables
- **VAR-3**: Braced initializers: opening `{` on same line
- **VAR-4**: Use std::array/C arrays for statically-sized data, not containers

## Methods
- **MTH-1**: Inline methods: define in class body (skip `inline` keyword)

## Properties
- **PRP-1**: New classes: Q_PROPERTY FINAL unless intended for override
- **PRP-3**: Avoid properties with same name as meta-methods

## Timeouts
- **TMO-1**: Use QDeadlineTimer or std::chrono, not int/qint64

## Polymorphic Classes
- **PLY-2**: Q_DISABLE_COPY_MOVE on polymorphic classes
- **PLY-4**: Virtual functions marked by exactly ONE of virtual/override/final
- **PLY-6**: Virtual access: public if callable, private if reimpl shouldn't call base

## QObject Subclasses
- **QOB-1**: Always include Q_OBJECT macro
- **QOB-4**: Element order: Q_OBJECT, Q_PROPERTY, Q_CLASSINFO, public, public slots, signals, event handlers, protected, private

## Enums
- **ENM-1**: Trailing comma on last enumerator
- **ENM-2**: Scoped or explicit underlying type (binary compat)
- **ENM-7**: Switch over enum: no `default:` label, list all enumerators

## Model Contracts
- **MDL-1**: Structural changes must use begin/end signals, not layoutChanged
- **MDL-2**: dataChanged should pass specific changed roles
- **MDL-3**: setData() must emit dataChanged before returning true
- **MDL-7**: data() switch should list all role cases explicitly
- **MDL-10**: roleNames() should cache the QHash

## Error Handling
- **ERR-1**: Check QFile::open() return value
- **ERR-2**: Check QJsonDocument::fromJson() result
- **ERR-4**: Use https:// not http://
- **ERR-5**: Set QNetworkRequest::setTransferTimeout()
- **ERR-12**: Consistent error reporting pattern

## Resource Lifecycle
- **LCY-1**: deleteLater() on QNetworkReply in finished handlers
- **LCY-3**: No side-effectful expressions inside Q_ASSERT
- **LCY-5**: Cap unbounded container growth

## Thread Safety
- **THR-1**: Never write QObject members from QtConcurrent::run() without sync
- **THR-3**: Never mutate QAbstractItemModel from background threads
- **THR-5**: Use std::atomic or mutex for shared counters

## Performance
- **PRF-1**: Don't construct QRegularExpression inside loops
- **PRF-3**: Use const auto& in range-for over shared containers
- **PRF-4**: Use .value() not operator[] for reads on shared QHash/QMap
- **PRF-7**: Extract magic numbers to named constants

---

# UI/UX Design

## Trigger
`qt-ui-design` — Use when designing, auditing, or building Qt/QML screens, layouts, or UX for any platform.

## Context Check (7 items)
1. **Target platform** — Desktop, web, mobile, or embedded/MCU
2. **Screen shape** — Rectangle, Square, or Circle
3. **Resolution and DPI**
4. **Design system** — Follow existing or recommend: Basic, Fusion, Imagine, Material, Universal, iOS, FluentWinUI3
5. **Content priority** — Primary, secondary, tertiary
6. **Viewing distance** — Handheld ~30cm, desk ~60cm, panel ~1.5m, wall ~3m
7. **Locale and input** — Language, RTL support, input methods

## Design Principles
- Golden Ratio + Rule of Thirds
- Progressive Disclosure
- Hick's Law (limit choices)
- Miller's Law (~7 items in working memory)
- Recognition Over Recall
- Peak-End Rule
- Doherty Threshold (feedback within 400ms)

## Motion and Animation
- Enter: deceleration easing (fast start, slow end)
- Exit: acceleration easing (slow start, fast end)
- Duration: small 100-150ms, medium 200-300ms, full-screen 300-400ms (never >500ms)
- Animate only transform and opacity (GPU-composited)
- Honour prefers-reduced-motion

## Typography
Use modular scale. Base 16px for desktop. Ratios: Major second 1.125, Minor third 1.200, Major third 1.250, Perfect fourth 1.333, Golden section 1.618.

Max 3-4 type sizes per screen. Line height: 1.4-1.6× for body, 1.1-1.2× for headings. Line length: 45-75 characters.

## Accessibility (WCAG 2.2)
- Contrast ≥ 4.5:1 for text, ≥ 3:1 for large text and UI components
- Full keyboard navigation
- Never rely on color alone to communicate state
- Test with OS font size set to Large
- Test with colour-blindness simulation

## AI-Specific UX
- User Control: Start, stop, modify, undo/regenerate
- Transparency: Show why AI made a decision
- Graceful Failure: Clear manual fallback when AI fails
- Latency: Show skeleton screens for 1-15s operations
- Consent before action affecting user data

## Embedded and MCU Targets
- No GPU? No gradients, drop shadows, blur, or transparency layers
- Fixed pixel layout, no fluid grids
- No hover states, no drag/scroll inertia/multi-touch
- Touch minimum: 48px (60-72px for gloved hands)
- Max 2 levels of navigation depth
- Error states: three independent cues (color + shape + text)

## Audit Checklist
- [ ] Critical — violates WCAG or core UX law. Must fix.
- [ ] Warning — potential friction. Should fix.
- [ ] Opportunity — enhancement. Consider.

---

# Project Working Rules

## Trigger
`always-on` — These rules apply to ALL interactions with this project.

## Who You're Working With
- Computer engineering student (Uniben), beginner-intermediate level
- Building toward backend engineering, databases, networking
- Wants to **understand** what's happening, not just have working code

## Current Project Context
- **Shell by Yemi** — custom QuickShell desktop shell for Wayland
- Supports both **Hyprland** and **Niri** via compositor abstraction
- Migrating color theming from pywal → Matugen
- Modular folder structure
- Fixing keybinds pointing to missing `inir` binary → redirect to QuickShell services

## Rule #1: PLAN FIRST. Always.
> Do NOT write a single line of code until I've agreed on the plan/architecture.
- Lay out approach, files affected, trade-offs
- Wait for explicit go-ahead
- Architecture tasks = planning tasks, not quick fixes

## Rule #2: You do mechanical work. I do the thinking.
- I use agents for restructuring, boilerplate, repetitive edits
- Every change will be read and understood
- Don't bury logic in one-line cleverness
- Don't introduce new patterns/libraries without flagging
- Keep changes traceable

## Rule #3: Don't hand-hold. Don't dump tutorials.
- Point to source (docs, repo, YouTube search) with short summary
- Don't write full explainers unless I paste content and ask for breakdown
- Assume I want **direction**, not a lecture

## Rule #4: If my logic/code is weak, say so.
- Don't quietly "fix" lazy thinking — call it out
- Tell me: what's wrong, why it's wrong, what's better
- Humor is fine. Vague niceness is not.

## Rule #5: Ask when ambiguous.
- If a request could go two ways, ask which one
- Don't pick the bigger/riskier interpretation and execute

## Rule #6: No fluff.
- No padding, no "great question!", no restating request
- Explain jargon the first time
- Nigerian-relatable analogies welcome

## Standard Workflow
1. **Understand** — restate problem in one line, confirm scope
2. **Propose** — plan/architecture, files, trade-offs
3. **Wait** — for go-ahead. Do not skip.
4. **Execute** — mechanical changes only
5. **Hand back** — I review. Flag anything uncertain.

## Do NOT
- Refactor beyond scope of what was asked
- Auto-install or change tooling without flagging
- Write full working solutions to learning exercises
- Assume frontend polish > backend correctness in this project