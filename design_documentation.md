# NeuralKB Mobile UI Design Specifications

This document contains the design specifications, reference images, and starter code for the NeuralKB Mobile App UI, generated using the **Gemini 3.1 Pro** model via StitchMCP. 

The aesthetic strictly mimics the **official Google Gemini mobile app**:
- Minimalist and extremely clean structure.
- Heavy use of white space.
- Floating, pill-shaped inputs and fully rounded buttons (`StadiumBorder`).
- No heavy purple/magenta AI accents; relies purely on typography and a soft palette (light grays, midnight blues, deep charcoal for dark mode).

---

## Screen References & Specifications

### 1. Login Screen
The login screen features a clean, airy layout with pill-shaped inputs and a solid primary button.

#### Light Mode
![Light Mode Login](C:/Users/satwi/.gemini/antigravity/brain/194c9a93-305f-475a-b501-64c324bce377/gemini_login_light.png)
- **Background**: Pure white (`#FFFFFF`)
- **Logo**: Soft, muted slate blue geometric 'N'.
- **Title**: Clean sans-serif (Google Sans style).
- **Inputs**: Pill-shaped with light gray border (`#E0E0E0`).
- **Primary Button**: Solid midnight blue pill.

#### Dark Mode
![Dark Mode Login](C:/Users/satwi/.gemini/antigravity/brain/194c9a93-305f-475a-b501-64c324bce377/gemini_login_dark.png)
- **Background**: Deep flat charcoal (`#131314`).
- **Logo**: Simple glowing white spark.
- **Primary Button**: Soft pale blue-to-white subtle gradient with dark text.

#### Implementation Guide (Login)
```dart
// Example widget structure for the Gemini-style Login
TextField(
  decoration: InputDecoration(
    hintText: 'Email',
    filled: true,
    fillColor: Theme.of(context).colorScheme.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(50.0), // Pill shape
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(50.0),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  ),
);

ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF131314), // Dark mode primary
    shape: StadiumBorder(), // Pill shape
    padding: EdgeInsets.symmetric(vertical: 16),
  ),
  onPressed: () {},
  child: Text('Sign In', style: TextStyle(color: Colors.white)),
)
```

---

### 2. Main Chat Dashboard
The chat interface features high whitespace, borderless AI messages, and a floating pill-shaped input area.

#### Light Mode
![Light Mode Chat](C:/Users/satwi/.gemini/antigravity/brain/194c9a93-305f-475a-b501-64c324bce377/gemini_chat_light.png)
- **Top Bar**: Minimal, borderless with a hamburger menu.
- **User Messages**: Soft light gray (`#F1F3F4`) pill-shaped bubbles, right-aligned.
- **AI Messages**: Borderless, flush left, clean precise typography.
- **Input Area**: Floating, elevated pill-shaped bar with a soft drop shadow, containing the attachment `+` and Send icon.

#### Dark Mode
![Dark Mode Chat](C:/Users/satwi/.gemini/antigravity/brain/194c9a93-305f-475a-b501-64c324bce377/gemini_chat_dark.png)
- **Background**: Deep charcoal (`#131314`).
- **User Messages**: Dark gray (`#303134`) pill bubbles.
- **AI Messages**: Borderless, white text, flush left.
- **Input Area**: Floating elevated pill in slightly lighter charcoal (`#202124`).

#### Implementation Guide (Chat)
```dart
// Example widget structure for the Gemini-style floating input
Container(
  margin: EdgeInsets.all(16.0),
  decoration: BoxDecoration(
    color: Theme.of(context).colorScheme.surfaceVariant, // e.g., #F1F3F4 or #202124
    borderRadius: BorderRadius.circular(30.0), // Floating Pill
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: Offset(0, 4),
      ),
    ],
  ),
  child: Row(
    children: [
      IconButton(
        icon: Icon(Icons.add_circle_outline, color: Colors.grey),
        onPressed: () {},
      ),
      Expanded(
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Message NeuralKB',
            border: InputBorder.none,
          ),
        ),
      ),
      IconButton(
        icon: Icon(Icons.send, color: AppTheme.accentBlue),
        onPressed: () {},
      ),
    ],
  ),
)

// Example AI Message Bubble (Borderless)
Container(
  padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
  alignment: Alignment.centerLeft,
  child: Text(
    "Here is the AI response...",
    style: TextStyle(height: 1.5, fontSize: 16),
  ),
)

// Example User Message Bubble (Pill)
Container(
  padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
  margin: EdgeInsets.only(left: 40.0, bottom: 8.0),
  decoration: BoxDecoration(
    color: const Color(0xFFF1F3F4), // Light mode
    borderRadius: BorderRadius.circular(24.0),
  ),
  child: Text("User query goes here"),
)
```

---

## Instructions for Claude
> *"Please refer to the screenshots and starter code snippets above. Update [lib/screens/login_screen.dart](file:///c:/Users/satwi/Downloads/Personal-project/Emmedding_project/lib/screens/login_screen.dart), [lib/screens/chat_screen.dart](file:///c:/Users/satwi/Downloads/Personal-project/Emmedding_project/lib/screens/chat_screen.dart), and [lib/theme/app_theme.dart](file:///c:/Users/satwi/Downloads/Personal-project/Emmedding_project/lib/theme/app_theme.dart) to exactly reproduce this structural layout and color palette. Ensure you utilize Flutter's `StadiumBorder` shapes, apply high whitespace padding, and completely remove any container borders or distinct background colors behind AI chat responses, matching the official Gemini mobile app."*
