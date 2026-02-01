# Widget Visual States

## Medium Widget - With Data
```
┌─────────────────────────────────────┐
│ Statistics          Last 30 Days    │
│                                     │
│ 📱 DVG Valley Guide         1,234   │
│ 🌐 Website                    567   │
│ 📱 Mobile App                 890   │
│ 🌐 Web Portal                 345   │
│ 📱 Test App                   123   │
└─────────────────────────────────────┘
```

## Large Widget - With More Data
```
┌─────────────────────────────────────┐
│ Statistics              Today       │
│                                     │
│ 📱 DVG Valley Guide         1,234   │
│ 🌐 Website                    567   │
│ 📱 Mobile App                 890   │
│ 🌐 Web Portal                 345   │
│ 📱 Test App                   123   │
│ 📱 Another App                678   │
│ 📱 Demo App                   234   │
│ 🌐 Landing Page               456   │
│ 📱 Beta App                   789   │
│ 📱 Staging App                321   │
│ 🌐 Documentation              543   │
│ 📱 Internal Tool              987   │
│ + 2 more                            │
└─────────────────────────────────────┘
```

## Medium Widget - Empty State
```
┌─────────────────────────────────────┐
│                                     │
│             📊                      │
│                                     │
│        No Data Available            │
│                                     │
│   Open the app to sync your         │
│         statistics                  │
│                                     │
└─────────────────────────────────────┘
```

## Medium Widget - Error State
```
┌─────────────────────────────────────┐
│                                     │
│             ⚠️                      │
│                                     │
│      Failed to load data            │
│                                     │
└─────────────────────────────────────┘
```

## Configuration Options

### Time Period (App & Widget)
- Today (shows visitors for today only)
- Last 30 Days (shows total visitors over 30 days)

### Hidden Apps (Widget Only)
Edit Widget → Hidden Apps → Enter app IDs

Example: If you have apps with IDs "abc123, def456", the widget will hide those apps from the display.

## Features
- 🔄 Auto-refresh every 2 hours
- 📊 Up to 5 apps in medium, 12 in large widget
- 🎨 Native iOS design with SF Symbols
- 🔒 Secure data sharing via App Group
- ⚙️ Configurable via iOS widget settings
- 📱 Differentiates mobile apps vs websites
- 🔢 Shows visitor counts with proper formatting
