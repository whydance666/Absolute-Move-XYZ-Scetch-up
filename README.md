# 🧩 Absolute Move XYZ — SketchUp Plugin by whydance&Mike_iLeech feat GKL0SS

> Precise object positioning using absolute or relative XYZ coordinates with per-axis anchor point control.

---

<div align="center">

**[🇬🇧 English](#english) · [🇷🇺 Русский](#русский)**

</div>

---

<a name="english"></a>

## 🇬🇧 English

### 📋 Table of Contents

- [Features](#features)
- [How It Works](#how-it-works)
- [Project Architecture](#project-architecture)
- [Installation](#installation)
- [Technical Notes](#technical-notes)
- [Version History](#version-history)

---

### ✨ Features

- 🎯 Set **absolute** or **relative** coordinates independently for each axis (X, Y, Z)
- ⚓ **Per-axis anchor points** for precise placement:
  - **X** → `Left` / `Center` / `Right`
  - **Y** → `Front` / `Center` / `Rear`
  - **Z** → `Bottom` / `Center` / `Top`
- 📐 Supports all SketchUp unit types: `inches`, `feet`, `mm`, `cm`, `meters`
- 🔒 Safely skips locked objects and raw geometry (faces / edges)
- 🧱 Correct multi-selection: nested objects are never moved twice
- ↩️ Full undo support via SketchUp's native operation system

---

### ⚙️ How It Works

#### Coordinate Input

Each axis has two controls:

| Control | Description |
|---------|-------------|
| **Value** | Numeric coordinate to move to |
| **Abs** | Move to an exact world coordinate |
| **Rel** | Offset from the object's current position |

#### Anchor Points

The anchor point defines **which part of the object** aligns to the given coordinate.

> **Example:** Z = `0`, anchor = `Bottom` → the bottom face lands exactly on the ground plane.
> Z = `0`, anchor = `Center` → the geometric center lands at Z = 0.

| Axis | Anchor | Meaning |
|------|--------|---------|
| X | Left | Left side of bounding box → X |
| X | Center | Center of bounding box → X |
| X | Right | Right side of bounding box → X |
| Y | Front | Front side of bounding box → Y |
| Y | Center | Center of bounding box → Y |
| Y | Rear | Rear side of bounding box → Y |
| Z | Bottom | Bottom of bounding box → Z |
| Z | Center | Center of bounding box → Z |
| Z | Top | Top of bounding box → Z |

> ⚠️ All anchor calculations are based on the object's **bounding box**, not the transformation origin — ensuring consistent, predictable behavior regardless of how the object was created or rotated.

#### Apply vs OK

| Button | Behavior |
|--------|----------|
| **Apply** | Moves the selection — dialog stays open |
| **OK** | Moves the selection — dialog closes |

---

### 🏗️ Project Architecture

> ⚠️ **Correct file structure is required for the extension to load properly.**
> Violating this structure causes duplicate toolbars, broken enable/disable, and unpredictable behavior.

```
Plugins/
├── AbsoluteMoveXYZ.rb          ← Entry point (loader)
└── AbsoluteMoveXYZ/
    ├── core.rb                 ← All plugin logic, UI & toolbar
    └── icons/
        ├── icon_16.png         ← Toolbar icon (16×16 px)
        └── icon_24.png         ← Toolbar icon (24×24 px)
```

#### `AbsoluteMoveXYZ.rb` — Loader (Entry Point)

This is the **only** file SketchUp loads directly from the `Plugins/` root.
Its sole job is to register the extension and point to `core.rb`:

```ruby
loader = File.join(File.dirname(__FILE__), 'AbsoluteMoveXYZ', 'core.rb')
extension = SketchupExtension.new(EXTENSION_NAME, loader)
Sketchup.register_extension(extension, true)
```

> 🚫 **Never put toolbar, menu, or UI code here.**
> This file runs before the user enables the extension. Any UI registered here
> will be created on every SketchUp launch regardless of extension state,
> resulting in duplicate toolbar buttons that accumulate over time.

#### `AbsoluteMoveXYZ/core.rb` — Plugin Logic

Loaded **only when the extension is active**. Contains everything:

- Dialog creation and HTML UI
- Toolbar and menu registration (protected by `file_loaded?` guard)
- Move calculation and transformation
- Anchor point resolution
- Unit conversion

The `file_loaded?` guard ensures toolbar and menu are registered **exactly once**:

```ruby
unless file_loaded?(__FILE__)
  UI.menu("Extensions").add_item(PLUGIN_NAME) { AbsoluteMoveXYZ.run }
  toolbar = UI::Toolbar.new(PLUGIN_NAME)
  # ...
  file_loaded(__FILE__)
end
```

#### ❌ Common Mistakes

| Mistake | Consequence |
|---------|-------------|
| Toolbar registration in the root loader | Duplicate toolbar buttons on every restart |
| All code in a single root `.rb` file | Extension Manager cannot enable/disable the plugin |
| Missing `file_loaded?` guard in `core.rb` | Toolbar and menu items multiply on each reload |
| Icons missing or wrong path | SketchUp raises an error, toolbar fails to display |

---

### 📦 Installation

1. Download or clone this repository
2. Copy **both** `AbsoluteMoveXYZ.rb` and the `AbsoluteMoveXYZ/` folder into your SketchUp Plugins directory:

| OS | Path |
|----|------|
| **Windows** | `%APPDATA%\SketchUp\SketchUp 20XX\SketchUp\Plugins` |
| **macOS** | `~/Library/Application Support/SketchUp 20XX/SketchUp/Plugins` |

3. Restart SketchUp
4. Enable via **Window → Extension Manager** (if not auto-enabled)
5. Access via **Extensions → Absolute Move XYZ** or the toolbar button

---

### 🔬 Technical Notes

#### Unit Conversion

SketchUp stores all coordinates internally in **inches**. The plugin reads the active model's unit settings and converts input values before applying any transformation:

| Unit | Multiplier |
|------|-----------|
| Inches | × 1.0 |
| Feet | × 12.0 |
| Millimeters | ÷ 25.4 |
| Centimeters | ÷ 2.54 |
| Meters | × 39.3701 |

#### Multi-Selection Safety

When multiple objects are selected, the plugin filters out **nested entities** before processing. If a group and an object inside it are both in the selection — only the group is moved. This prevents any object from being displaced twice.

#### Bounding Box Axis Orientation

SketchUp's bounding box follows the **world coordinate system**, which may seem counterintuitive:

| Property | Visual Direction |
|----------|-----------------|
| `bb.min.x` | Right side |
| `bb.max.x` | Left side |
| `bb.min.y` | Rear side |
| `bb.max.y` | Front side |
| `bb.min.z` | Bottom |
| `bb.max.z` | Top |

The anchor point mapping accounts for this inversion so that `Left`, `Right`, `Front`, and `Rear` always match what the user sees in the default SketchUp camera view.

---

### 📜 Version History

| Version | Changes |
|---------|---------|
| **2.1.0** | Per-axis anchor points: Left/Right for X, Front/Rear for Y, Bottom/Top for Z |
| **2.0.0** | Full rewrite: unit conversion, anchor system, multi-selection fix, Abs/Rel per axis |
| **1.0.0** | Initial release |

---
---

<a name="русский"></a>

## 🇷🇺 Русский

### 📋 Содержание

- [Возможности](#возможности)
- [Как это работает](#как-это-работает)
- [Архитектура проекта](#архитектура-проекта)
- [Установка](#установка)
- [Технические детали](#технические-детали)
- [История версий](#история-версий)

---

### ✨ Возможности

- 🎯 Задание **абсолютных** или **относительных** координат независимо для каждой оси (X, Y, Z)
- ⚓ **Индивидуальные точки привязки** для каждой оси:
  - **X** → `Left` (лево) / `Center` (центр) / `Right` (право)
  - **Y** → `Front` (перед) / `Center` (центр) / `Rear` (зад)
  - **Z** → `Bottom` (низ) / `Center` (центр) / `Top` (верх)
- 📐 Поддержка всех единиц измерения SketchUp: `дюймы`, `футы`, `мм`, `см`, `метры`
- 🔒 Пропускает заблокированные объекты и голую геометрию (грани / рёбра)
- 🧱 Безопасная работа с мульти-селекцией: вложенные объекты не перемещаются дважды
- ↩️ Полная поддержка отмены через нативную систему операций SketchUp

---

### ⚙️ Как это работает

#### Ввод координат

Каждая ось имеет два элемента управления:

| Элемент | Описание |
|---------|----------|
| **Значение** | Числовая координата для перемещения |
| **Abs** | Переместить в точную мировую координату |
| **Rel** | Смещение относительно текущей позиции объекта |

#### Точки привязки (Anchor Points)

Точка привязки определяет **какая часть объекта** выравнивается по заданной координате.

> **Пример:** Z = `0`, привязка = `Bottom` → нижняя грань объекта окажется ровно на нулевой плоскости.
> Z = `0`, привязка = `Center` → геометрический центр объекта окажется на Z = 0.

| Ось | Привязка | Значение |
|-----|----------|----------|
| X | Left | Левая сторона bounding box → X |
| X | Center | Центр bounding box → X |
| X | Right | Правая сторона bounding box → X |
| Y | Front | Передняя сторона bounding box → Y |
| Y | Center | Центр bounding box → Y |
| Y | Rear | Задняя сторона bounding box → Y |
| Z | Bottom | Низ bounding box → Z |
| Z | Center | Центр bounding box → Z |
| Z | Top | Верх bounding box → Z |

> ⚠️ Все вычисления привязок основаны на **bounding box** объекта, а не на origin трансформации — это обеспечивает предсказуемое поведение независимо от того, как объект был создан или повёрнут.

#### Apply vs OK

| Кнопка | Поведение |
|--------|-----------|
| **Apply** | Перемещает объекты — диалог остаётся открытым |
| **OK** | Перемещает объекты — диалог закрывается |

---

### 🏗️ Архитектура проекта

> ⚠️ **Правильная структура файлов обязательна для корректной загрузки расширения.**
> Нарушение структуры приводит к дублированию тулбаров, невозможности включить/выключить плагин и непредсказуемому поведению.

```
Plugins/
├── AbsoluteMoveXYZ.rb          ← Точка входа (загрузчик)
└── AbsoluteMoveXYZ/
    ├── core.rb                 ← Вся логика, UI и тулбар
    └── icons/
        ├── icon_16.png         ← Иконка тулбара (16×16 пикс.)
        └── icon_24.png         ← Иконка тулбара (24×24 пикс.)
```

#### `AbsoluteMoveXYZ.rb` — Загрузчик (точка входа)

Это **единственный** файл, который SketchUp загружает напрямую из корня `Plugins/`.
Его единственная задача — зарегистрировать расширение и указать путь к `core.rb`:

```ruby
loader = File.join(File.dirname(__FILE__), 'AbsoluteMoveXYZ', 'core.rb')
extension = SketchupExtension.new(EXTENSION_NAME, loader)
Sketchup.register_extension(extension, true)
```

> 🚫 **Никогда не размещайте здесь тулбар, меню или UI-код.**
> Этот файл выполняется до того, как пользователь активирует расширение. Любой UI,
> зарегистрированный здесь, будет создаваться при каждом запуске SketchUp вне зависимости
> от состояния расширения — это приводит к накоплению дублирующихся кнопок тулбара.

#### `AbsoluteMoveXYZ/core.rb` — Логика плагина

Загружается **только когда расширение активно**. Содержит всё:

- Создание диалога и HTML-интерфейс
- Регистрация тулбара и меню (защищена guard-блоком `file_loaded?`)
- Вычисление перемещения и применение трансформации
- Определение точек привязки
- Конвертация единиц измерения

Guard-блок `file_loaded?` гарантирует, что тулбар и меню регистрируются **ровно один раз**:

```ruby
unless file_loaded?(__FILE__)
  UI.menu("Extensions").add_item(PLUGIN_NAME) { AbsoluteMoveXYZ.run }
  toolbar = UI::Toolbar.new(PLUGIN_NAME)
  # ...
  file_loaded(__FILE__)
end
```

#### ❌ Типичные ошибки

| Ошибка | Последствие |
|--------|-------------|
| Регистрация тулбара в корневом загрузчике | Дублирующиеся кнопки тулбара при каждом перезапуске |
| Весь код в одном корневом `.rb` файле | Extension Manager не может включить/выключить плагин |
| Отсутствие guard-блока `file_loaded?` в `core.rb` | Тулбар и пункты меню множатся при каждой перезагрузке |
| Отсутствующие иконки или неверный путь | SketchUp выдаёт ошибку, тулбар не отображается |

---

### 📦 Установка

1. Скачайте или клонируйте репозиторий
2. Скопируйте **оба** файла — `AbsoluteMoveXYZ.rb` и папку `AbsoluteMoveXYZ/` — в директорию плагинов SketchUp:

| ОС | Путь |
|----|------|
| **Windows** | `%APPDATA%\SketchUp\SketchUp 20XX\SketchUp\Plugins` |
| **macOS** | `~/Library/Application Support/SketchUp 20XX/SketchUp/Plugins` |

3. Перезапустите SketchUp
4. Активируйте через **Window → Extension Manager** (если не активировалось автоматически)
5. Запустите через **Extensions → Absolute Move XYZ** или кнопку в тулбаре

---

### 🔬 Технические детали

#### Конвертация единиц

SketchUp хранит все координаты внутри в **дюймах**. Плагин читает настройки единиц активной модели и конвертирует введённые значения перед применением трансформации:

| Единица | Множитель |
|---------|-----------|
| Дюймы | × 1.0 |
| Футы | × 12.0 |
| Миллиметры | ÷ 25.4 |
| Сантиметры | ÷ 2.54 |
| Метры | × 39.3701 |

#### Безопасность при мульти-селекции

При выборе нескольких объектов плагин **фильтрует вложенные сущности** перед обработкой. Если в selection попали и группа, и объект внутри неё — перемещается только группа. Это исключает двойное смещение вложенных объектов.

#### Ориентация осей bounding box

Bounding box в SketchUp следует **мировой системе координат**, что может показаться неочевидным:

| Свойство | Визуальное направление |
|----------|----------------------|
| `bb.min.x` | Правая сторона |
| `bb.max.x` | Левая сторона |
| `bb.min.y` | Задняя сторона |
| `bb.max.y` | Передняя сторона |
| `bb.min.z` | Низ |
| `bb.max.z` | Верх |

Маппинг точек привязки в плагине учитывает эту инверсию, поэтому `Left`, `Right`, `Front` и `Rear` всегда соответствуют тому, что пользователь видит в стандартном виде камеры SketchUp.

---

### 📜 История версий

| Версия | Изменения |
|--------|-----------|
| **2.1.0** | Индивидуальные точки привязки для каждой оси: Left/Right для X, Front/Rear для Y, Bottom/Top для Z |
| **2.0.0** | Полная переработка: конвертация единиц, система привязок, исправление мульти-селекции, Abs/Rel для каждой оси |
| **1.0.0** | Первый релиз |

---

<div align="center">
  <sub>Built with ❤️ by whydance&Mike_iLeech featuring GKL0SS for SketchUp</sub>
</div>
