# HomeView Architecture

This document explains the structure and mechanism of the HomeView in the Bodima app after refactoring for better maintainability and modularity.

## Overview

The HomeView is the main screen of the Bodima app that displays habitation listings, user stories, and provides search/filter functionality. It has been refactored from a single large file into multiple focused components for better code organization.

## File Structure

```
Views/Home/
├── HomeView.swift              # Main view controller and state management
├── HomeHeaderSection.swift     # Header components (search, filters, notifications)
├── HomeStoriesSection.swift    # Stories display and interaction
├── HomeFeedSection.swift       # Habitation feed and cards
├── HomeStoryOverlay.swift      # Full-screen story viewing
└── README.md                   # This documentation
```

## Architecture Components

### 1. HomeView.swift (Main Controller)
**Purpose**: Central state management and view orchestration

**Key Responsibilities**:
- Manages all view models (`HabitationViewModel`, `ProfileViewModel`, `UserStoriesViewModel`)
- Handles state for search, filters, overlays, and data loading
- Coordinates data fetching and caching for locations and features
- Orchestrates the layout of header, content, and overlay sections

**Key State Variables**:
- `searchText`: Current search query
- `selectedHabitationType`: Active filter selection
- `showStoryOverlay`/`selectedStory`: Story viewing state
- `locationDataCache`/`featureDataCache`: Performance optimization caches

### 2. HomeHeaderSection.swift
**Purpose**: Top navigation and search functionality

**Components**:
- `HeaderView`: Main header container
- `TopBarView`: App title and notifications
- `SearchBarView`: Search input with icon
- `FilterBarView`: Habitation type filter chips
- `NotificationButton`: Notification icon with unread count badge

**Features**:
- Real-time search with debouncing
- Filter selection with visual feedback
- Notification count display
- Responsive layout for different screen sizes

### 3. HomeStoriesSection.swift
**Purpose**: User stories display and creation

**Components**:
- `StoriesSection`: Main stories container
- `StoriesHeader`: Section title and controls
- `StoriesScrollView`: Horizontal scrolling story list
- `UserStoriesView`: Individual user story display with segments
- `StorySegmentsIndicator`: Visual progress indicator for multiple stories
- `CreateStoryButton`: Story creation entry point

**Features**:
- 24-hour story expiration logic
- Story grouping by user
- Visual indicators for viewed/unviewed stories
- Loading states and empty state handling
- Story creation workflow integration

### 4. HomeFeedSection.swift
**Purpose**: Habitation listings and cards

**Components**:
- `MainContentView`: Content area coordinator
- `FeedSection`: Habitation list container
- `HabitationCardView`: Individual habitation display
- `HabitationHeader`: User info and follow button
- `HabitationImage`: Property image display
- `HabitationActions`: Like, share, bookmark buttons
- `HabitationContent`: Property details and availability

**Features**:
- Lazy loading for performance
- Image caching and placeholder handling
- Interactive actions (like, bookmark, follow)
- Navigation to detail views
- Loading and empty states
- Real-time availability checking

### 5. HomeStoryOverlay.swift
**Purpose**: Full-screen story viewing experience

**Components**:
- `StoryOverlayView`: Main overlay container
- `StoryProgressBar`: Progress indicators for story duration
- `StoryHeader`: User info and close button
- `StoryImageView`: Full-screen story image
- `StoryDescriptionView`: Story text content

**Features**:
- Auto-advancing story playback
- Manual navigation (tap left/right)
- Progress tracking across multiple stories from same user
- Story expiration handling
- Gesture-based dismissal

## Data Flow

### 1. Initialization
```
HomeView loads → ViewModels initialize → Data fetching begins
```

### 2. Search & Filter
```
User input → State update → ViewModel filtering → UI refresh
```

### 3. Story Interaction
```
Story tap → Overlay presentation → Timer start → Auto-advance or manual navigation
```

### 4. Habitation Interaction
```
Card tap → Navigation to DetailView → Reservation flow
```

## State Management

### View Models Used
- `HabitationViewModel`: Manages habitation data and filtering
- `ProfileViewModel`: Handles user profile and authentication
- `UserStoriesViewModel`: Manages story data and interactions

### Caching Strategy
- `locationDataCache`: Stores location data by habitation ID
- `featureDataCache`: Stores feature data by habitation ID
- Prevents redundant API calls and improves performance

## Performance Optimizations

1. **Lazy Loading**: Feed uses `LazyVStack` for efficient scrolling
2. **Image Caching**: `CachedImage` component prevents re-downloads
3. **Data Caching**: Location and feature data cached to reduce API calls
4. **State Optimization**: Minimal state updates to prevent unnecessary re-renders

## Integration Points

### Navigation
- Uses `NavigationView` for iOS navigation stack
- `NavigationLink` for habitation detail navigation
- Modal presentation for story creation

### External Dependencies
- `CachedImage`: Custom image caching component
- `AppColors`: Centralized color system
- Various model types: `EnhancedHabitationData`, `UserStoryData`, etc.

## Maintenance Guidelines

### Adding New Features
1. Determine which section the feature belongs to
2. Add components to the appropriate section file
3. Update state management in `HomeView.swift` if needed
4. Update this README with new functionality

### Modifying Existing Components
1. Locate the component in the appropriate section file
2. Make changes while maintaining the existing interface
3. Test integration with `HomeView.swift`
4. Update documentation if the interface changes

### Performance Considerations
- Keep section files focused on UI components
- Maintain state management in the main `HomeView`
- Use caching for expensive operations
- Consider lazy loading for large data sets

## Testing Strategy

### Unit Testing
- Test individual components in isolation
- Mock view models for predictable testing
- Test state transitions and data flow

### Integration Testing
- Test navigation between sections
- Verify data passing between components
- Test overlay presentations and dismissals

### UI Testing
- Test user interactions (tap, scroll, search)
- Verify visual states (loading, empty, error)
- Test accessibility features

## Future Improvements

### Potential Enhancements
1. **Further Modularization**: Extract common UI components
2. **State Management**: Consider using Combine or async/await patterns
3. **Performance**: Implement virtual scrolling for very large feeds
4. **Accessibility**: Enhanced VoiceOver support
5. **Animations**: Smoother transitions between states

### Architecture Evolution
- Consider moving to MVVM-C pattern for complex navigation
- Implement dependency injection for better testability
- Add analytics tracking for user interactions
- Consider SwiftUI 4.0+ features for improved performance

---

This architecture provides a clean separation of concerns while maintaining the cohesive user experience of the original HomeView. Each section can be developed and maintained independently while contributing to the overall functionality of the home screen.
