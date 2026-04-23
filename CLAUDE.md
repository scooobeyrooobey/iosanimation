# hikeapp — iOS Shader Demo

iOS 26 SwiftUI app. Two screens (Home, Card Screen) — архитектура вторична, цель — полировка шейдерных анимаций и Liquid Glass эффектов.

## Стек
- SwiftUI + iOS 26 deployment target
- Нативный Liquid Glass API (`.glassEffect`, `GlassEffectContainer`)
- Metal `.metal` шейдеры через `ShaderLibrary` + `.colorEffect/.layerEffect/.distortionEffect`
- `matchedGeometryEffect` для hero-переходов
- `KeyframeAnimator` для физики капли

## Структура
```
hikeapp/
├── Theme/          # Colors, Typography, Metrics (дизайн-токены)
├── Models/         # Expedition
├── Components/     # ExpeditionCard, ImageTrio, LiquidGlassButton, TabBarView, DifficultyDots, BookmarkDrop
├── Screens/        # HomeView, CardScreenView
├── Shaders/        # CardGlow.metal, DropRefraction.metal, ContactMerge.metal + Swift wrappers
├── Animations/     # HeroTransition, DropPhysics
└── Assets.xcassets # card1/card2/card3, DropPic
```

Xcode project использует `PBXFileSystemSynchronizedRootGroup` — новые файлы в `hikeapp/` подхватываются автоматически, править `project.pbxproj` вручную не нужно.

## Дизайн-система (основные токены)
- Фон Home: `#152716 → #060C06`
- Фон карточки/экрана: `#233D20 → #0A1208`
- Белый текст: `#F4E1D3`
- Зелёный accent: `#5FF453`
- Glow шейдера карточки: `#18DE9B`, `#1DB6D5`
- Нижняя панель Card Screen: `#0C0C0C`, topRadius 32
- Титулы: `EightiesComeback-ExtraCondensed` (32/34 на Home, 44/46 на Card Screen)
- Body/meta: `SF Pro`

Источник: `0G8BaRoNKkFB6FESr0eREh` (Figma file key). Ключевые узлы: `11:2418` (Home), `13:2656` (Card Screen), `11:2187` (Components & Icons), `14:3134` (Bookmarkstoryboard).

## Ключевые анимации
1. **Card hero transition** — `matchedGeometryEffect` поверх ID `home-<uuid>-img1/img2/img3` и фона `card-<uuid>-bg`. Бейс `spring(duration: 0.55, bounce: 0.18)`. Controls (Book now, bookmark, bottom panel, back) выезжают c задержкой 0.05/0.1/0.15s.
2. **Card shader border glow** — `CardGlow.metal` (SDF + fbm-flow), цвета teal↔cyan, пульсация толщины. Время через `TimelineView(.animation)`.
3. **Bookmark drop** — `DropPic` с `DropRefraction.metal` (displacement + linza), отделяется от bookmark-кнопки через `ContactMerge.metal` (metaball). `KeyframeAnimator` по S-дуге (см. `images for app/Drop_traektory.png`) с stretch-by-velocity. Приземление в Profile-таб — морфинг + squash&stretch bounce.

## Работа с Figma
Пользователь работает через MCP. Ключевые инструменты:
- `mcp__d83d9763-5ace-4e3d-8d81-c5f202cb5ed0__get_metadata` — структура узлов
- `mcp__d83d9763-5ace-4e3d-8d81-c5f202cb5ed0__get_design_context` — React+Tailwind код, конвертируется в SwiftUI
- `mcp__d83d9763-5ace-4e3d-8d81-c5f202cb5ed0__get_screenshot` — для визуального diff

## Референсные изображения
`images for app/` (не в таргете, только для справки):
- `Экраны_приложения.png` — оба экрана в финальном виде
- `Card_light_shaders.png` — референс подсветки карточки (flow, выпуклый блик)
- `Drop_ref.png` — базовая рефракция капли (нам нужно сильнее)
- `Drop_pic.png` — картинка внутри капли
- `drop_contact_effect.jpeg` — metaball merge
- `Drop_traektory.png` — траектория полёта (стрелки показывают наклон)
- `card_open/1..6.png` — покадровка hero-transition

## Правила проекта
- Верстка строго 1 в 1 с Figma. Размеры/цвета/шрифты из `Theme/`, не хардкодим.
- Не менять signing & capabilities без подтверждения.
- Не править `Info.plist` и `project.pbxproj` без подтверждения.
- Для кастомного шрифта — ждать TTF/OTF от пользователя.
- Shader-time подаём через `TimelineView(.animation)` + uniform.

## Build
- Xcode 26.4+, iOS 26 simulator (iPhone 16 Pro предпочтительно для ProMotion).
- Сборка: `xcodebuild -project hikeapp.xcodeproj -scheme hikeapp -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`.
