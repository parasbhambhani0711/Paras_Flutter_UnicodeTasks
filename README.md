# ⚡ Study Brahmastra (स्टडी ब्रह्मास्त्र)

<p align="center">
  <b>An AI-Powered, Modular Autonomous Study Workspace Built with Flutter & Gemini AI</b>
  <br />
  <i>Organize tasks, manage notes with Cloudinary attachments, render complex math LaTeX equations, and interact with an autonomous app agent.</i>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase" />
  <img src="https://img.shields.io/badge/Google_Gemini_AI-8E75B2?style=for-the-badge&logo=googlegemini&logoColor=white" alt="Gemini AI" />
  <img src="https://img.shields.io/badge/State_Management-BLoC-blue?style=for-the-badge" alt="BLoC" />
  <img src="https://img.shields.io/badge/Cloudinary-3448C5?style=for-the-badge&logo=cloudinary&logoColor=white" alt="Cloudinary" />
</p>

---

## 📌 Table of Contents
- [Overview](#-overview)
- [Advanced Key Features](#-advanced-key-features)
- [Project Architecture](#-project-architecture)
- [Getting Started](#-getting-started)
- [Environment Configuration](#-environment-configuration)
- [Tech Stack](#-tech-stack)
- [Contributing](#-contributing)
- [License](#-license)

---

## 📖 Overview

**Study Brahmastra** is a feature-rich, modular mobile study productivity application developed in Flutter. Designed specifically for students and engineering scholars, it merges automated task scheduling, custom notes management with Cloudinary cloud storage, advanced LaTeX math rendering, and a context-aware **Astra AI Agent** powered by Google's Gemini API that can autonomously manage your tasks, notes, and subjects inside the app.

---

## 🌟 Advanced Key Features

### 🤖 Autonomous Astra AI Agent
- **Context-Aware AI Tutor:** Interacts with Google's Gemini API using an automated multi-model fallback chain (`gemini-3.8-flash`, `gemini-3.6-flash`, `gemini-3.5-flash-lite`, `gemini-flash-latest`).
- **Autonomous App Execution:** Receives real-time app state snapshots and executes user commands by outputting structured JSON actions to automatically:
  - Add, toggle completion, or delete study tasks.
  - Create, rename, or remove subjects.
  - Create, edit, or delete notes.
- **Multimodal Visual Analysis:** Allows students to upload or snap photos of textbook problems, diagrams, or handwritten notes for instant AI analysis and explanation.

### 📐 Custom LaTeX & Markdown Engine
- **Regex Pre-Sanitizer:** Intelligent parsing pipeline (`sanitizeAiResponse` & `sanitizeMathText`) that prevents currency `$` symbol collisions and standardizes inline math `\(...\)` and display math `$$...$$`.
- **Safe LaTeX Builder:** `SafeLatexElementBuilder` gracefully recovers from invalid math syntax by displaying clear fallback text without crashing the UI.
- **Scrollable Table Builder:** `ScrollableTableBuilder` dynamically wraps Markdown data tables in horizontal scroll view containers to maintain UI layout integrity on mobile screens.

### 📁 Cloudinary Cloud Integration
- **File & Media Attachments:** Attach study notes, diagrams, and PDF files directly to Firestore notes via Cloudinary.
- **Dynamic PDF Thumbnails:** Automatically generates preview thumbnail images for PDF documents on the fly via Cloudinary image transformation URLs.
- **Full-Screen Interactive Viewer & PDF Launcher:** View attached high-resolution images in interactive zoom viewers or launch external PDF readers smoothly using `url_launcher`.

### ⚡ Clean BLoC Architecture
- **Reactive BLoC Pattern:** Strict separation of UI and business logic using `AuthBloc`, `TaskBloc`, `NoteBloc`, and `ChatBloc`.
- **Real-time Firestore Streams:** Live synchronization of custom subjects, tasks, and notes across devices.
- **24-Hour Auto-Vanish Tasks:** Completed tasks feature smooth animated fade transitions and auto-clear after 24 hours to keep the workspace clean.

### 🔔 Smart Local Notifications
- **Hourly Study Reminders:** Periodically scheduled local notifications via `flutter_local_notifications` alerting students of pending study tasks.
- **Notification Verification:** Instant notification test triggers directly from the user profile settings.

---

## 🏗️ Project Architecture

```text
lib/
├── core/                        # Core configuration & utilities
│   ├── constants/               # App Themes & Colors
│   ├── enums/                   # Task & Note Sort/Filter Options
│   ├── services/                # Cloudinary Service & Notification Service
│   ├── utils/                   # Math Sanitizer & Regex Engines
│   └── setup.dart               # App Bootstrap & BLoC Initialization
├── data/                        # Data Layer
│   ├── models/                  # TaskModel, NoteModel, ChatMessage
│   └── repositories/            # FirestoreRepository & GeminiRepository
├── logic/                       # Business Logic Layer (BLoC)
│   ├── auth/                    # AuthBloc
│   ├── task/                    # TaskBloc
│   ├── note/                    # NoteBloc
│   └── chat/                    # ChatBloc
└── presentation/                # UI & Presentation Layer
    ├── screens/                 # Splash, Auth, Home, Tasks, Notes, AI Chat, Profile
    └── widgets/                 # SafeLatexElementBuilder, ScrollableTableBuilder
