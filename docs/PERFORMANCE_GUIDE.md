# Performance Profiling Guide

## Overview

This guide provides instructions for profiling and optimizing the Chatterbox iOS app using Xcode Instruments and other performance tools.

## When to Profile

Profile the app when:
- Adding new features with complex UI
- After major refactoring
- Users report slowness or battery drain
- Before major releases
- Investigating specific performance issues

## Tools

### 1. Instruments (Primary Tool)

#### Time Profiler
**Purpose**: Find CPU-intensive code paths

**How to Use**:
1. Open Xcode
2. Product → Profile (⌘I)
3. Select "Time Profiler" template
4. Click Record
5. Use the app, focusing on slow areas
6. Stop recording
7. Analyze call tree for hot paths

**What to Look For**:
- Functions taking >100ms
- Unexpected expensive operations on main thread
- View body recomputation
- JSON parsing bottlenecks

**Common Culprits**:
- Large view hierarchies in SwiftUI
- Inefficient ForEach loops
- Heavy computations in view body
- Unoptimized date formatting

#### Allocations
**Purpose**: Track memory usage and leaks

**How to Use**:
1. Product → Profile
2. Select "Allocations" template
3. Record while using app
4. Look for:
   - Growing memory without release
   - Repeated allocations in loops
   - Large object graphs

**What to Look For**:
- Memory leaks (zombie objects)
- Excessive allocations
- Large persistent memory usage
- Retain cycles

#### SwiftUI View Body Profiler
**Purpose**: Measure view update performance

**How to Use**:
1. Product → Profile
2. Select "SwiftUI" template
3. Record interaction
4. Check view update counts
5. Find views that update unnecessarily

**What to Look For**:
- Views updating when data hasn't changed
- Cascading updates
- Expensive computed properties in body

### 2. Xcode Debugger

#### Debug View Hierarchy
**How to Use**:
1. Run app in simulator
2. Debug → View Debugging → Capture View Hierarchy
3. Inspect view layers
4. Look for unnecessary nesting

**What to Look For**:
- Excessive view nesting (>10 levels)
- Hidden views still in hierarchy
- Overlapping views

#### Memory Graph
**How to Use**:
1. Run app
2. Debug → Debug Memory Graph
3. Look for leak warnings
4. Inspect retain cycles

**What to Look For**:
- Purple warnings (leaks)
- Strong reference cycles
- Unexpected object retention

### 3. SwiftUI Performance Tips

#### Observation Scope
```swift
// ❌ Bad: Observes entire viewModel
@State private var viewModel: HomeViewModel

var body: some View {
    VStack {
        Text(viewModel.title)        // Observes viewModel
        if viewModel.isLoading { }   // Observes viewModel
    }
}

// ✅ Better: Extract to separate views
var body: some View {
    VStack {
        TitleView(title: viewModel.title)
        LoadingView(isLoading: viewModel.isLoading)
    }
}
```

#### Lazy Containers
```swift
// ❌ Bad: Creates all views upfront
ScrollView {
    VStack {
        ForEach(items) { item in
            ItemView(item: item)
        }
    }
}

// ✅ Better: Lazy loading
ScrollView {
    LazyVStack {
        ForEach(items) { item in
            ItemView(item: item)
        }
    }
}
```

#### Expensive Computations
```swift
// ❌ Bad: Recomputes on every update
var body: some View {
    Text(heavyComputation())
}

// ✅ Better: Compute once
@State private var result: String = ""

var body: some View {
    Text(result)
        .task {
            result = heavyComputation()
        }
}
```

## Performance Baselines

### App Launch
- **Target**: < 2 seconds to interactive
- **Measure**: Time from tap to first frame
- **Current**: ~1.5s (good)

### Network Requests
- **Target**: < 500ms for cached, < 2s for remote
- **Measure**: Time from request to response
- **Current**: Varies by endpoint

### View Rendering
- **Target**: 60fps (16.67ms per frame)
- **Measure**: Frame rate in Time Profiler
- **Current**: Mostly 60fps

### Memory Usage
- **Target**: < 100MB for typical session
- **Measure**: Memory report in Instruments
- **Current**: ~60-80MB (good)

## Optimization Checklist

### Before Optimizing
- [ ] Profile first - identify actual bottlenecks
- [ ] Set performance baseline
- [ ] Identify user-facing slow paths
- [ ] Prioritize by impact

### Common Optimizations

#### 1. View Performance
```swift
// Use .id() to force view identity
ForEach(items) { item in
    ItemView(item: item)
        .id(item.id)  // Prevents unnecessary recreations
}

// Use equatable to prevent updates
struct ItemView: View, Equatable {
    let item: Item
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.item.id == rhs.item.id
    }
}
```

#### 2. Image Loading
```swift
// Async loading with placeholder
AsyncImage(url: imageURL) { phase in
    switch phase {
    case .success(let image):
        image.resizable()
    case .failure:
        placeholderImage
    case .empty:
        ProgressView()
    @unknown default:
        EmptyView()
    }
}
```

#### 3. List Performance
```swift
// Use LazyVStack/LazyHStack
// Set explicit IDs
// Minimize state in list items
```

#### 4. Debouncing User Input
```swift
@Observable
final class SearchViewModel {
    var searchText = "" {
        didSet {
            debounceSearch()
        }
    }
    
    private func debounceSearch() {
        // Cancel previous task
        searchTask?.cancel()
        
        searchTask = Task {
            try await Task.sleep(for: .milliseconds(300))
            await performSearch(searchText)
        }
    }
}
```

## Critical Paths to Profile

### 1. App Launch
- ChatterboxApp initialization
- SessionController bootstrap
- Initial view render

### 2. Cue Loading
- API request
- JSON parsing
- View rendering

### 3. Recording
- AVAudioRecorder initialization
- Timer updates
- State changes

### 4. Upload
- File reading
- Network upload
- Background task handling

## Performance Monitoring in Production

### Add Strategic Timers

```swift
import OSLog

func loadCues() async {
    let start = Date()
    defer {
        let duration = Date().timeIntervalSince(start)
        Log.app.info("loadCues took \(duration)s")
    }
    
    // ... loading code
}
```

### Track Key Metrics

```swift
// In appropriate places
Log.app.info("View appeared: \(viewName)")
Log.app.info("API call: \(endpoint) took \(duration)ms")
Log.app.info("Memory usage: \(memoryUsage)MB")
```

## Known Performance Considerations

### CueDetailView
- **Size**: Large view (~380 lines)
- **Complexity**: Multiple nested VStacks, ScrollView
- **Recommendation**: Monitor with SwiftUI View Body Profiler
- **Potential Split**: Could separate recording controls into child view

### RootTabView
- **Complexity**: Multiple navigation stacks, debug tools
- **Recommendation**: Profile tab switching performance
- **Current**: No known issues

### AudioPlayerView
- **Consideration**: Slider updates during playback
- **Recommendation**: Ensure smooth 60fps during scrubbing
- **Current**: Uses GeometryReader efficiently

## Optimization Priorities

### High Priority (Do First)
1. App launch time
2. List scrolling performance
3. View transition smoothness
4. Network request latency

### Medium Priority (Do If Needed)
1. Memory usage optimization
2. Battery usage reduction
3. Background task efficiency

### Low Priority (Nice to Have)
1. Micro-optimizations
2. Premature optimization
3. Theoretical improvements

## Testing Performance

### Automated Performance Tests

```swift
func testLaunchPerformance() {
    measure(metrics: [XCTApplicationLaunchMetric()]) {
        XCUIApplication().launch()
    }
}

func testScrollPerformance() {
    let app = XCUIApplication()
    app.launch()
    
    measure(metrics: [XCTOSSignpostMetric.scrollDecelerationMetric]) {
        app.scrollViews.firstMatch.swipeUp(velocity: .fast)
    }
}
```

### Manual Performance Tests

1. **Cold Launch**: Force quit → launch
2. **Warm Launch**: Background → foreground
3. **Heavy Load**: Load 100+ cues
4. **Long Session**: Use app for 10+ minutes
5. **Network Issues**: Test on slow connection

## Red Flags

Watch for:
- Frame drops during scrolling
- Delayed UI responses (>100ms)
- Memory growth without bound
- Battery drain reports
- Crash reports from memory pressure

## Optimization Strategy

1. **Measure**: Profile to find bottleneck
2. **Hypothesize**: Why is it slow?
3. **Fix**: Implement optimization
4. **Verify**: Profile again to confirm improvement
5. **Document**: Note what was changed and why

## Resources

- [Apple Performance Best Practices](https://developer.apple.com/documentation/xcode/improving-your-app-s-performance)
- [SwiftUI Performance](https://developer.apple.com/documentation/swiftui/optimizing-swiftui-performance)
- [Instruments Help](https://help.apple.com/instruments/mac/)

## Notes

- Profile on real devices when possible (simulators can misrepresent performance)
- Test on oldest supported device (iPhone with iOS 17)
- Use Release build for accurate profiling
- Profile both cold and warm launches
- Check performance after major iOS updates

## Revision History
- 2025-12-13: Initial version

