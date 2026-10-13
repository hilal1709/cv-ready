# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Stack

Flutter (Android target). Database: Neon PostgreSQL, connected directly from the app via the `postgres` Dart package. Credentials are injected at build time (`--dart-define-from-file=.env`), never committed. Confirmed by the user as a personal-use APK, not distributed. AI writing assistance via the Claude API (key injected the same way).

User-requested libraries: shadcn_ui (Flutter port), Lottie for illustration animation, Hugeicons for icons. GSAP is web-only; its role (timeline-style, eased motion) is filled by `flutter_animate`.

## Users

The owner (an Indonesian job seeker) applying to jobs, including international roles, who wants to produce ATS-safe CVs quickly and raise the chance of passing automated screening. Uses the app on an Android phone, often in short sessions.

## Product Purpose

Build, score, tailor and export ATS-friendly CVs in an international format. Success: a clean single-column PDF that parses correctly in ATS systems, with content that is specific, quantified and matched to the target job posting.

## Positioning

A phone-first CV workshop that treats ATS readability as the hard constraint: every template is a real-text, single-column PDF; the app scores the CV, matches it against a pasted job description, and rewrites weak bullets with AI.

## Capabilities and Constraints

- Accounts (email + password) with multiple CVs per account; duplicate CVs per target role.
- Sections: contact, summary, experience, education, skills, projects, certifications, languages.
- Export ATS-friendly PDF (real text, standard fonts, no tables/columns/images in the CV body).
- ATS score + checklist (completeness, action verbs, metrics, length, contact info).
- Job-description keyword match (matched / missing keywords).
- AI: draft a summary, improve a bullet sentence, generate bullets from a rough description.
- App UI language: Bahasa Indonesia. CV content and templates: international (English-ready).

## Brand Commitments

- Name: **CV Ready**.
- Binding palette (all five must be used): Scarlet Rush #DA2C38, Turf Green #226F54, Willow Green #87C38F, Lemon Chiffon #F4F0BB, Dark Coffee #43291F.
- Binding visual language: claymorphism. Illustrations preferred over icon overuse. Custom loading animation, modal, toast and banner in the app's theme.

## Evidence on Hand

No testimonials, user counts or hiring-rate statistics exist. Do not claim acceptance-rate improvements as numbers.

## Product Principles

1. ATS readability beats decoration in the exported CV; the app can be playful, the PDF must be plain.
2. Every suggestion is actionable: tell the user what to change, not just a score.
3. Fast on a phone: short forms, autosave, no dead ends.
4. The user owns their data; nothing is sent to AI without an explicit tap.
