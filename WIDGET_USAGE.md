# Widget Usage Guide

## Overview

The TelemetryDeck Stats widget displays your app statistics directly on your home screen. It supports customization through widget configuration options.

## Features

### 1. Time Period Selection

The widget supports two time periods:
- **Today**: Shows visitor statistics for the current day (last 1 day)
- **Last 30 Days**: Shows visitor statistics for the past 30 days (default)

You can change the time period:
- In the app: Use the segmented picker at the top of the InsightsView
- In the widget: Edit the widget and select your preferred time period

### 2. Hide Specific Apps

You can hide specific apps from appearing in the widget through the widget configuration:
1. Long-press on the widget
2. Select "Edit Widget"
3. In the "Hidden Apps" field, enter app IDs you want to hide (comma-separated)

### 3. Widget Sizes

Two widget sizes are supported:
- **Medium**: Displays up to 5 apps
- **Large**: Displays up to 12 apps

If you have more apps than can fit, a "+ X more" indicator will appear at the bottom.

## How It Works

### Data Synchronization

1. **In the App**: When you open an app's insights page, the app:
   - Fetches the latest statistics from TelemetryDeck API
   - Calculates total visitors for the selected time period
   - Saves the data to a shared App Group container
   - Triggers a widget refresh

2. **In the Widget**: The widget:
   - Reads data from the shared App Group container
   - Applies your configuration (filters hidden apps, shows selected time period)
   - Updates every 2 hours automatically
   - Shows empty state if no data is available

### Widget States

- **Empty State**: Shown when no data is available. The message prompts you to open the app.
- **Error State**: Shown if there's an error loading data.
- **Data State**: Shows app statistics with icons and visitor counts.

## Technical Details

### App Group

The app and widget share data through an App Group:
- **Suite Name**: `group.nl.wesleydegroot.TelemetryDeckStats`
- **Storage Key**: `widgetData`

### Data Structure

The widget stores:
- App ID, name, and display mode (app/website icon)
- Total visitor count for the configured time period
- Time period configuration
- List of hidden app IDs

### Refresh Policy

- Manual: When you open the app and view insights
- Automatic: Every 2 hours (iOS system-managed)
- On-demand: When you force-refresh in the app

## Troubleshooting

### Widget Not Updating

1. Open the app and navigate to any app's insights
2. Pull down to refresh the data
3. Wait a few moments for the widget to update

### No Data Showing

1. Ensure you're logged in to the app
2. Open at least one app's insights page
3. Check that the app has data available in TelemetryDeck

### Widget Configuration Not Saved

1. Ensure you tap "Done" after editing widget configuration
2. Try removing and re-adding the widget
