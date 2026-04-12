# FarmerChat — Test Tag Specification

**For:** Android Developer  
**From:** QA Automation (Shaik Mohamed Imran)  
**Purpose:** Every Composable element listed below **must** have a `Modifier.testTag("...")` applied so that the Maestro automation suite can find and interact with it.  
**App Package:** `org.digitalgreen.farmer.chatbot`

---

## How to Add Test Tags in Jetpack Compose

```kotlin
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag

// On any Composable:
Button(
    onClick = { ... },
    modifier = Modifier.testTag("home_type_button")
) { ... }

// On a screen root:
Box(modifier = Modifier.testTag("home_screen")) { ... }

// On an input field:
TextField(
    value = name,
    onValueChange = { ... },
    modifier = Modifier.testTag("name_input")
)
```

**Rule:** The `testTag` string must match **exactly** as listed below. Case-sensitive, underscores, no spaces.

---

## 1. Onboarding / Language Selection Screen

| testTag | Element Type | Description |
|---------|-------------|-------------|
| `language_screen` | Screen root / Container | The language selection screen that appears on first launch |
| `language_start_button` | Button | "Start" or "Continue" button after selecting a language |
| `language_item_${code}` | List item | Individual language option (e.g., `language_item_en` for English). If dynamic IDs aren't possible, use text-based selection (already handled in flows) |
| `language_terms_link` | Clickable text / Link | "Terms of Use" link on the language screen |
| `language_privacy_link` | Clickable text / Link | "Privacy Policy" link on the language screen |

**Compose example:**
```kotlin
@Composable
fun LanguageScreen() {
    Column(modifier = Modifier.testTag("language_screen")) {
        // Language list
        LazyColumn {
            items(languages) { lang ->
                LanguageItem(
                    language = lang,
                    modifier = Modifier.testTag("language_item_${lang.code}")
                )
            }
        }
        
        Button(
            onClick = { onStart() },
            modifier = Modifier.testTag("language_start_button")
        ) { Text("Start") }
        
        Row {
            ClickableText(
                text = "Terms of Use",
                modifier = Modifier.testTag("language_terms_link")
            )
            ClickableText(
                text = "Privacy Policy",
                modifier = Modifier.testTag("language_privacy_link")
            )
        }
    }
}
```

---

## 2. Name Entry Screen

| testTag | Element Type | Description |
|---------|-------------|-------------|
| `name_screen` | Screen root / Container | The "Enter your name" screen during onboarding |
| `name_input` | TextField | Text input field for the user's name |
| `name_save_button` | Button | "Save" or "Continue" button to submit the name |

---

## 3. Location Interstitial Screen

| testTag | Element Type | Description |
|---------|-------------|-------------|
| `location_interstitial_skip` | Button | "Skip" button on the location permission interstitial |
| `location_share_button` | Button | "Share Location" button on the weather/location screen |

---

## 4. Home Screen

| testTag | Element Type | Description |
|---------|-------------|-------------|
| `home_screen` | Screen root / Container | The main home screen (must be visible when app is on home) |
| `home_hamburger_button` | IconButton | Hamburger menu icon (top-left) that opens the navigation drawer |
| `home_type_button` | Button / Card | "Type your question" entry point on home screen |
| `home_speak_button` | Button / FAB | Microphone / voice input button |
| `home_photo_button` | Button / Icon | Camera / photo query button |
| `home_weather_button` | Button / Card | Weather widget or "Check weather" button |
| `home_feed_list` | LazyColumn / List | The scrollable feed/advice list on home screen |

**Compose example:**
```kotlin
@Composable
fun HomeScreen() {
    Scaffold(
        modifier = Modifier.testTag("home_screen"),
        topBar = {
            TopAppBar(
                navigationIcon = {
                    IconButton(
                        onClick = { openDrawer() },
                        modifier = Modifier.testTag("home_hamburger_button")
                    ) { Icon(Icons.Default.Menu, "Menu") }
                }
            )
        }
    ) {
        LazyColumn(modifier = Modifier.testTag("home_feed_list")) {
            // Feed items
        }
        
        Button(
            onClick = { navigateToChat() },
            modifier = Modifier.testTag("home_type_button")
        ) { Text("Type your question") }
        
        IconButton(
            onClick = { startVoice() },
            modifier = Modifier.testTag("home_speak_button")
        ) { Icon(Icons.Default.Mic, "Speak") }
        
        IconButton(
            onClick = { openCamera() },
            modifier = Modifier.testTag("home_photo_button")
        ) { Icon(Icons.Default.CameraAlt, "Photo") }
    }
}
```

---

## 5. Navigation Drawer

| testTag | Element Type | Description |
|---------|-------------|-------------|
| `drawer_content` | Drawer container | The navigation drawer content area |
| `drawer_signup_button` | Button / Item | "Sign Up" item in the drawer |
| `drawer_settings_button` | Button / Item | "Settings" item in the drawer |
| `drawer_help_button` | Button / Item | "Help" or "Help & Support" item |
| `drawer_language_button` | Button / Item | "Change Language" item |
| `drawer_see_all_button` | Button / Item | "See All" or "Chat History" link |
| `drawer_home_button` | Button / Item | "Home" navigation item |

**Compose example:**
```kotlin
@Composable
fun AppDrawer() {
    Column(modifier = Modifier.testTag("drawer_content")) {
        DrawerItem(
            label = "Home",
            modifier = Modifier.testTag("drawer_home_button")
        )
        DrawerItem(
            label = "Sign Up",
            modifier = Modifier.testTag("drawer_signup_button")
        )
        DrawerItem(
            label = "Settings",
            modifier = Modifier.testTag("drawer_settings_button")
        )
        DrawerItem(
            label = "Help & Support",
            modifier = Modifier.testTag("drawer_help_button")
        )
        DrawerItem(
            label = "Change Language",
            modifier = Modifier.testTag("drawer_language_button")
        )
        TextButton(
            onClick = { navigateToChatHistory() },
            modifier = Modifier.testTag("drawer_see_all_button")
        ) { Text("See All") }
    }
}
```

---

## 6. Chat Screen

| testTag | Element Type | Description |
|---------|-------------|-------------|
| `chat_thread_list` | LazyColumn / List | The scrollable chat message list |
| `chat_read_full_advice_button` | Button / Link | "Read Full Advice" or "Learn More" button on a chat card |
| `chat_listen_button` | IconButton | TTS / listen button on an AI response |
| `chat_save_button` | IconButton | Save / bookmark button on an AI response |
| `chat_share_button` | IconButton | Share button on an AI response |
| `chat_close_button` | IconButton | Close / back button to exit chat and return to home |
| `chat_inline_error` | Container / Text | Error message shown inline in chat when network fails |
| `chat_inline_retry_button` | Button | Inline retry button shown with chat error |

**Compose example:**
```kotlin
@Composable
fun ChatScreen() {
    Column {
        LazyColumn(modifier = Modifier.testTag("chat_thread_list")) {
            items(messages) { msg ->
                ChatMessage(msg)
            }
        }
        
        // On each AI response bubble:
        Row {
            IconButton(
                onClick = { listen(msg) },
                modifier = Modifier.testTag("chat_listen_button")
            ) { Icon(Icons.Default.VolumeUp, "Listen") }
            
            IconButton(
                onClick = { save(msg) },
                modifier = Modifier.testTag("chat_save_button")
            ) { Icon(Icons.Default.Bookmark, "Save") }
            
            IconButton(
                onClick = { share(msg) },
                modifier = Modifier.testTag("chat_share_button")
            ) { Icon(Icons.Default.Share, "Share") }
        }
        
        // Close button (top bar)
        IconButton(
            onClick = { navigateBack() },
            modifier = Modifier.testTag("chat_close_button")
        ) { Icon(Icons.Default.Close, "Close") }
    }
}

// Error state (shown when network fails mid-chat):
@Composable
fun ChatInlineError() {
    Column(modifier = Modifier.testTag("chat_inline_error")) {
        Text("Something went wrong")
        Button(
            onClick = { retry() },
            modifier = Modifier.testTag("chat_inline_retry_button")
        ) { Text("Retry") }
    }
}
```

---

## 7. Text Input Bar

| testTag | Element Type | Description |
|---------|-------------|-------------|
| `text_input_send_button` | IconButton | The send button in the chat input bar |

```kotlin
@Composable
fun ChatInputBar() {
    Row {
        TextField(value = query, onValueChange = { ... })
        IconButton(
            onClick = { sendMessage() },
            modifier = Modifier.testTag("text_input_send_button")
        ) { Icon(Icons.Default.Send, "Send") }
    }
}
```

---

## 8. Chat History Screen

| testTag | Element Type | Description |
|---------|-------------|-------------|
| `chat_history_screen` | Screen root / Container | The chat history / past conversations screen |
| `chat_history_list` | LazyColumn / List | Scrollable list of past chat sessions |

---

## 9. Authentication Screens

| testTag | Element Type | Description |
|---------|-------------|-------------|
| `auth_screen` | Screen root / Container | The sign-up / login screen |
| `auth_phone_input` | TextField | Phone number input field |
| `auth_otp_input` | TextField / OTP fields | OTP code input field(s) |
| `auth_submit_button` | Button | "Submit" or "Verify" button to submit OTP |
| `account_success_screen` | Screen root / Container | The "Account created successfully" screen |
| `account_success_continue` | Button | "Continue" button on the success screen |

**Compose example:**
```kotlin
@Composable
fun AuthScreen() {
    Column(modifier = Modifier.testTag("auth_screen")) {
        TextField(
            value = phone,
            onValueChange = { ... },
            modifier = Modifier.testTag("auth_phone_input"),
            placeholder = { Text("Phone number") }
        )
        
        // After OTP is sent:
        TextField(
            value = otp,
            onValueChange = { ... },
            modifier = Modifier.testTag("auth_otp_input")
        )
        
        Button(
            onClick = { verifyOtp() },
            modifier = Modifier.testTag("auth_submit_button")
        ) { Text("Verify") }
    }
}

@Composable
fun AccountSuccessScreen() {
    Column(modifier = Modifier.testTag("account_success_screen")) {
        Text("Account created!")
        Button(
            onClick = { goHome() },
            modifier = Modifier.testTag("account_success_continue")
        ) { Text("Continue") }
    }
}
```

---

## 10. Settings Screen

| testTag | Element Type | Description |
|---------|-------------|-------------|
| `settings_screen` | Screen root / Container | The settings screen |
| `settings_appearance_day` | Button / Toggle | "Day" mode option |
| `settings_appearance_night` | Button / Toggle | "Night" mode option |
| `settings_appearance_auto` | Button / Toggle | "Auto" mode option |
| `settings_name_item` | Clickable row / Item | Tappable row showing current name (opens edit) |
| `settings_name_screen` | Screen / Dialog | The name editing screen or dialog |
| `settings_name_input` | TextField | Name input field in the edit screen |
| `settings_name_save_button` | Button | "Save" button for name update |
| `settings_signup_button` | Button | "Sign Up" button in settings (for anonymous users) |
| `settings_logout_button` | Button | "Logout" button in settings (for logged-in users) |

---

## 11. Language Chooser (In-app language change)

| testTag | Element Type | Description |
|---------|-------------|-------------|
| `language_chooser_screen` | Screen root / Container | The language change screen (accessed from drawer) |
| `language_chooser_save_button` | Button | "Save" button to confirm language change |

---

## 12. Help & Support Screen

| testTag | Element Type | Description |
|---------|-------------|-------------|
| `help_screen` | Screen root / Container | The Help & Support screen |
| `help_hamburger_button` | IconButton | Hamburger menu button on the Help screen's top bar |
| `help_terms_of_use` | Clickable item / Link | "Terms of Use" link in Help screen |
| `help_privacy_policy` | Clickable item / Link | "Privacy Policy" link in Help screen |
| `faqs-en` | Container / Section | The FAQ section for English (or current language) |
| `faq-01` | Expandable item | First FAQ accordion item |

---

## 13. Error Screen (Full-screen error)

| testTag | Element Type | Description |
|---------|-------------|-------------|
| `error_screen` | Screen root / Container | Full-screen error state (e.g., no internet on launch) |
| `error_retry_button` | Button | "Try Again" / "Retry" button on the error screen |

**Compose example:**
```kotlin
@Composable
fun ErrorScreen(onRetry: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .testTag("error_screen"),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text("Something went wrong")
        Button(
            onClick = onRetry,
            modifier = Modifier.testTag("error_retry_button")
        ) { Text("Try Again") }
    }
}
```

---

## Complete Tag Checklist (61 tags)

Use this as a checklist. Check off each tag as you add it:

### Onboarding (5 tags)
- [ ] `language_screen`
- [ ] `language_start_button`
- [ ] `language_terms_link`
- [ ] `language_privacy_link`
- [ ] `language_item_${code}` (dynamic, optional — flows use text fallback)

### Name Entry (3 tags)
- [ ] `name_screen`
- [ ] `name_input`
- [ ] `name_save_button`

### Location (2 tags)
- [ ] `location_interstitial_skip`
- [ ] `location_share_button`

### Home Screen (7 tags)
- [ ] `home_screen`
- [ ] `home_hamburger_button`
- [ ] `home_type_button`
- [ ] `home_speak_button`
- [ ] `home_photo_button`
- [ ] `home_weather_button`
- [ ] `home_feed_list`

### Navigation Drawer (7 tags)
- [ ] `drawer_content`
- [ ] `drawer_signup_button`
- [ ] `drawer_settings_button`
- [ ] `drawer_help_button`
- [ ] `drawer_language_button`
- [ ] `drawer_see_all_button`
- [ ] `drawer_home_button`

### Chat (9 tags)
- [ ] `chat_thread_list`
- [ ] `chat_read_full_advice_button`
- [ ] `chat_listen_button`
- [ ] `chat_save_button`
- [ ] `chat_share_button`
- [ ] `chat_close_button`
- [ ] `chat_inline_error`
- [ ] `chat_inline_retry_button`
- [ ] `text_input_send_button`

### Chat History (2 tags)
- [ ] `chat_history_screen`
- [ ] `chat_history_list`

### Authentication (6 tags)
- [ ] `auth_screen`
- [ ] `auth_phone_input`
- [ ] `auth_otp_input`
- [ ] `auth_submit_button`
- [ ] `account_success_screen`
- [ ] `account_success_continue`

### Settings (10 tags)
- [ ] `settings_screen`
- [ ] `settings_appearance_day`
- [ ] `settings_appearance_night`
- [ ] `settings_appearance_auto`
- [ ] `settings_name_item`
- [ ] `settings_name_screen`
- [ ] `settings_name_input`
- [ ] `settings_name_save_button`
- [ ] `settings_signup_button`
- [ ] `settings_logout_button`

### Language Chooser (2 tags)
- [ ] `language_chooser_screen`
- [ ] `language_chooser_save_button`

### Help & Support (6 tags)
- [ ] `help_screen`
- [ ] `help_hamburger_button`
- [ ] `help_terms_of_use`
- [ ] `help_privacy_policy`
- [ ] `faqs-en`
- [ ] `faq-01`

### Error Screen (2 tags)
- [ ] `error_screen`
- [ ] `error_retry_button`

---

## Important Notes for Developer

1. **testTag is for automation only** — it has zero impact on the user experience, performance, or app size. It's stripped from release builds by default.

2. **Don't rename existing tags** — the Maestro test flows depend on these exact strings. If you need to rename a UI element, coordinate with QA (Imran) first.

3. **New screens need tags too** — if you add a new screen or feature, add testTags and notify QA so we can write corresponding test flows.

4. **testTag vs contentDescription** — `testTag` is for test automation. `contentDescription` is for accessibility (screen readers). Use both where appropriate, but they serve different purposes.

5. **Compose Navigation** — screen-level tags (`home_screen`, `settings_screen`, etc.) should be on the outermost container of each screen composable, not on the NavHost.

---

*Document maintained by: Shaik Mohamed Imran (QA Automation)*  
*Last updated: April 2026*  
*Maestro flows repo: https://github.com/Mohamedimran5307/FarmerChat-Maestro-Tests*
