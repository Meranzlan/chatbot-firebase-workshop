# chatbot-firebase

A Flutter chat app connected to **Gemini** through **Firebase AI Logic**.

## Workshop setup

Do these once, in order. You'll connect the app to your own free Firebase
project.

### 1. Install the tools

- **Flutter 3.41 or newer** (check with `flutter --version`), plus an Android
  emulator, iOS simulator or phone.
- **Firebase CLI** (needs Node.js), then sign in:

  ```bash
  npm install -g firebase-tools
  ```

  ```bash
  firebase login
  ```

- **FlutterFire CLI:**

  ```bash
  dart pub global activate flutterfire_cli
  ```

### 2. Create your Firebase project

1. In the [Firebase console](https://console.firebase.google.com), create a
   project.
2. Open **AI Logic**, click **Get started**, and choose the **Gemini Developer
   API**. It's free, with no billing needed. The free tier has a daily
   request limit per project, so don't use it all up testing before the
   session.

### 3. Get the code and connect it to your project

```bash
git clone https://github.com/Meranzlan/chatbot-firebase-workshop.git
```

```bash
cd chatbot-firebase-workshop
```

```bash
flutterfire configure
```

Pick your project and the platforms you'll run on. When it asks to override
`lib/firebase_options.dart` (a placeholder in this repo), answer **yes**.
This writes your project's settings into the app (`lib/firebase_options.dart`,
`google-services.json`, `GoogleService-Info.plist`). The app won't build
until you've done this.

### 4. Get an App Check debug token

App Check proves requests really come from your app. During development,
it uses a debug token that you register:

1. In the Firebase console, open **App Check** → **Apps**.
2. On your app, open the **⋮** menu → **Manage debug tokens** →
   **Add debug token** → **Generate token** → **Save**.
3. Copy the token.

Or with the Firebase CLI, which creates and registers one for you
(`<APP_ID>` is the `appId` for your platform in `lib/firebase_options.dart`):

```bash
firebase appcheck:debugtokens:create --app <APP_ID>
```

Treat the token like a password: don't commit it or share it.

### 5. Run the app with your token

```bash
flutter run --dart-define=APP_CHECK_DEBUG_TOKEN=<your token>
```

Send a message. If Gemini answers, you're set up. In VS Code or Android
Studio, add the same `--dart-define=...` to your run configuration's
arguments.

## How it talks to Gemini

Two steps, both in `lib/repository/chatbot_repository.dart`:

| Step | Call | What it does |
|---|---|---|
| 1 | `startConversation()` | Forgets the old conversation (no network call) |
| 2 | `chat.sendMessage()` | Sends your message plus the conversation so far, waits for the whole reply |
| 2 (streaming) | `chat.sendMessageStream()` | Same, but the reply arrives in pieces while Gemini writes |

Firebase does the rest. `firebase_options.dart` says which Firebase project to
use (it isn't a secret), and **App Check** proves each request really comes
from this app. Enforce App Check for Firebase AI Logic in the Firebase console
(**App Check → APIs**) so other apps can't use your quota.

**Google Search (optional).** Give the model the `Tool.googleSearch()` tool and
Gemini may search the web before it answers. The answer then comes with its
sources, which the app shows as `[1]` markers in the text, numbered source
chips, and Google's search suggestions. Google's terms require the sources and
the search suggestions to be shown with every answer that used Google Search,
so keep them if you change the UI.

## Where things live

```
lib/
├── main.dart                        Starts Firebase + App Check, runs the app
├── firebase_options.dart            Written by `flutterfire configure`
├── config/
│   ├── app_config.dart              Bot name, Gemini model, system prompt
│   ├── app_colors.dart              Every colour in the app
│   └── demo_config.dart             On/off switches (streaming, Google Search…)
├── models/
│   ├── chat_message.dart            One chat bubble
│   ├── chat_citation.dart           One web page an answer came from
│   └── reply_piece.dart             One piece of Gemini's reply, as it arrives
├── repository/
│   └── chatbot_repository.dart      ★ The Gemini calls
├── controllers/
│   └── chat_controller.dart         ★ Chat state: messages, "thinking", errors
├── utils/
│   └── open_link.dart               Opens links in the browser
└── views/
    ├── screens/home_page.dart       ★ The chat screen
    └── widgets/                     The pieces of the screen
```

Start with the three ★ files. The rest is polish you can read later.

## Things to try

Every change below takes effect after saving and pressing `r` (hot reload).

- **Turn on streaming:** set `useStreaming = true` in
  `lib/config/demo_config.dart`. Ask for something long, like *"Write a 250
  word story about a robot learning to paint"*. Short answers arrive almost
  all at once, so the effect is easiest to see on long ones.
- **Turn on Google Search** (needs the Blaze plan, see Troubleshooting): ask
  *"What's the latest iPhone?"*. Then set `useGoogleSearch = true` and ask
  again. The first answer only knows what Gemini learned in training; the
  second searches Google and shows its sources.
- Flip the other switches in `demo_config.dart` (suggested prompts, 👍/👎,
  disclaimer…).
- Change a colour in `lib/config/app_colors.dart`.
- Give the bot a new personality: edit `systemPrompt` in
  `lib/config/app_config.dart`.
- Run the tests: `flutter test`

## Troubleshooting

**"App Check blocked this device"** (the raw error says `403 … App
attestation failed`)
The token you ran with isn't registered for this app in your Firebase
project, or you ran without `--dart-define`. Register it (Workshop setup,
step 4) and run with it (step 5). Without a token, the app makes up its own
and prints it in the device logs, and you can register that one instead. On
Android:

```bash
adb logcat -d | grep "App Check debug token"
```

On iOS, look for "debug token" in the Xcode or `flutter run` console.

**"This Firebase project has no Gemini quota left for that"** (the raw error
says `You exceeded your current quota`)
One of two things:

- The free tier's **daily limit** is used up. Each Firebase project has its
  own, it resets at midnight Pacific time, and testing uses it up too.
- **Google Search** is on, and it isn't in the free tier at all.

For more, upgrade the project to the **Blaze** (pay-as-you-go) plan.

**`This model … is no longer available`**
Google retires older Gemini models. Pick a current one from the
[supported models list](https://firebase.google.com/docs/ai-logic/models),
put it in `AppConfig.model`, then hot reload (`r`). With Google Search on,
choose one that also supports
[grounding](https://firebase.google.com/docs/ai-logic/grounding-google-search).

**"Gemini is very busy right now"**
Google's servers are briefly overloaded (the raw error says "This model is
currently experiencing high demand"). The app already waits and asks again
twice on its own. If it still fails, send your message again in a few
seconds. During a live demo you can also switch `AppConfig.model` to another
model from the supported list, then hot reload (`r`).
