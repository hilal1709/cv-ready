# Graph Report - aplikasi bikin cv  (2026-10-13)

## Corpus Check
- 41 files · ~24,695 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 18 file(s) not represented in the graph (top: .ttf 14, (none) 3, .lock 1)

## Summary
- 764 nodes · 1083 edges · 58 communities (35 shown, 23 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- splash_screen.dart
- StatelessWidget
- editor_screen.dart
- export_screen.dart
- score_screen.dart
- account_tab.dart
- migrate.dart
- clay_widgets.dart
- palette.dart
- sections.dart
- package:flutter/material.dart
- contextlib
- models.dart
- ResumeStore
- html
- brand.dart
- colorsys
- feedback.dart
- json
- os
- base64
- re
- pdf_builder.dart
- shutil
- struct
- subprocess
- sys
- tempfile
- time
- main.dart
- cv_list_tab.dart
- argparse
- resume_repository.dart
- ats_scorer.dart
- resume_store.dart
- unicodedata
- xml_etree_elementtree
- math
- Components
- State
- match_tab.dart
- ai_service.dart
- auth_screen.dart
- session.dart
- statistics
- auth_repository.dart
- keyword_matcher.dart
- random
- motion.dart
- Product
- core_test.dart
- collections
- format.dart
- ClayColors
- CV Ready
- ClayContext
- CLAUDE.md
- shot.sh

## God Nodes (most connected - your core abstractions)
1. `ResumeStore` - 48 edges
2. `Session` - 15 edges
3. `Components` - 11 edges
4. `Product` - 10 edges
5. `Design System: CV Ready` - 9 edges
6. `Colors` - 6 edges
7. `ClayColors` - 5 edges
8. `Resume` - 5 edges
9. `_AuthScreenState` - 5 edges
10. `build` - 5 edges

## Surprising Connections (you probably didn't know these)
- `build` --references--> `ResumeStore`  [EXTRACTED]
  lib/ui/screens/export_screen.dart → lib/state/resume_store.dart
- `_addSkill` --references--> `ResumeStore`  [EXTRACTED]
  lib/ui/screens/match_tab.dart → lib/state/resume_store.dart
- `build` --references--> `ResumeStore`  [EXTRACTED]
  lib/ui/screens/match_tab.dart → lib/state/resume_store.dart
- `build` --references--> `ResumeStore`  [EXTRACTED]
  lib/ui/screens/score_screen.dart → lib/state/resume_store.dart
- `_AuthScreenState` --references--> `ResumeStore`  [EXTRACTED]
  lib/ui/screens/auth_screen.dart → lib/state/resume_store.dart

## Import Cycles
- None detected.

## Communities (58 total, 23 thin omitted)

### Community 0 - "splash_screen.dart"
Cohesion: 0.25
Nodes (7): home_shell.dart, build, createState, initState, package:flutter_animate/flutter_animate.dart, ../routes.dart, ../../state/resume_store.dart

### Community 1 - "StatelessWidget"
Cohesion: 0.12
Nodes (17): ClayButton, ClayField, ClayIconButton, ClayLoader, Hi, SectionTitle, ClayBanner, _Header (+9 more)

### Community 2 - "editor_screen.dart"
Cohesion: 0.15
Nodes (12): export_screen.dart, Resume, info, report, resume, resumeId, SaveIndicator, _ScoreCard (+4 more)

### Community 3 - "export_screen.dart"
Cohesion: 0.17
Nodes (11): ../kit/feedback.dart, CvTemplate, build, createState, _fileName, _print, resumeId, _share (+3 more)

### Community 4 - "score_screen.dart"
Cohesion: 0.18
Nodes (10): ../kit/brand.dart, AtsCheck, build, check, _CheckCard, createState, resumeId, _showDone (+2 more)

### Community 5 - "account_tab.dart"
Cohesion: 0.16
Nodes (13): account_tab.dart, auth_screen.dart, ../../core/theme/clay.dart, ../../core/theme/palette.dart, cv_list_tab.dart, ../kit/clay_widgets.dart, _guide, _rename (+5 more)

### Community 6 - "migrate.dart"
Cohesion: 0.22
Nodes (8): dart:convert, package:postgres/postgres.dart, close, conn, env, execute, main, r

### Community 7 - "clay_widgets.dart"
Cohesion: 0.04
Nodes (49): EdgeInsetsGeometry, int?, Iterable, autofillHints, build, capitalization, child, ClayButtonTone (+41 more)

### Community 8 - "palette.dart"
Cohesion: 0.04
Nodes (46): ClayColors get, accent, clay, coffee, coffeeLine, coffeeMuted, copyWith, danger (+38 more)

### Community 9 - "sections.dart"
Cohesion: 0.04
Nodes (45): Key, actions, ai, bottom, bullets, children, company, _confirmDelete (+37 more)

### Community 10 - "package:flutter/material.dart"
Cohesion: 0.50
Nodes (3): ../../core/motion.dart, package:flutter/material.dart, T

### Community 12 - "models.dart"
Cohesion: 0.05
Nodes (39): DateTime, bullets, byId, Certification, certifications, clone, Contact, createdAt (+31 more)

### Community 13 - "ResumeStore"
Cohesion: 0.12
Nodes (23): ChangeNotifier, ResumeStore, Session, AccountTab, build, _submit, build, CvListTab (+15 more)

### Community 15 - "brand.dart"
Cohesion: 0.05
Nodes (37): Color?, CustomPainter, animate, build, color, colorFor, createState, _current (+29 more)

### Community 17 - "feedback.dart"
Cohesion: 0.05
Nodes (38): clay_widgets.dart, action, actionLabel, build, _c, close, colors, confirmClay (+30 more)

### Community 22 - "pdf_builder.dart"
Cohesion: 0.07
Nodes (28): dart:typed_data, accent, build, _bullet, centerName, _certifications, _education, _experience (+20 more)

### Community 29 - "main.dart"
Cohesion: 0.15
Nodes (12): core/theme/app_theme.dart, ../data/db.dart, ../data/resume_repository.dart, build, CvReadyApp, main, restore, session (+4 more)

### Community 30 - "cv_list_tab.dart"
Cohesion: 0.09
Nodes (21): editor_screen.dart, ../format.dart, busy, created, _CvSheet, _Empty, items, _MiniPage (+13 more)

### Community 32 - "resume_repository.dart"
Cohesion: 0.14
Nodes (13): db.dart, Db, _cols, create, _db, delete, duplicate, list (+5 more)

### Community 33 - "ats_scorer.dart"
Cohesion: 0.09
Nodes (21): actionVerbs, AtsReport, AtsScorer, checks, CheckStatus, _firstPerson, max, maxPoints (+13 more)

### Community 34 - "resume_store.dart"
Cohesion: 0.09
Nodes (21): bind, byId, create, _debounce, delete, dispose, duplicate, _error (+13 more)

### Community 38 - "Components"
Cohesion: 0.06
Nodes (30): Brand mark, Buttons, Cards / Containers, Colors, Components, Design System: CV Ready, Do:, Do's and Don'ts (+22 more)

### Community 39 - "State"
Cohesion: 0.13
Nodes (23): ClayPressable, _ClayPressableState, AuthScreen, _AuthScreenState, build, ExportScreen, _ExportScreenState, HomeShell (+15 more)

### Community 40 - "match_tab.dart"
Cohesion: 0.12
Nodes (15): _addSkill, build, createState, dispose, _job, _jobText, onAdd, _result (+7 more)

### Community 44 - "ai_service.dart"
Cohesion: 0.06
Nodes (31): Connection?, ../../core/env.dart, dart:async, ../../data/models.dart, Exception, Future, AuthException, _conn (+23 more)

### Community 45 - "auth_screen.dart"
Cohesion: 0.12
Nodes (16): build, _busy, createState, dispose, _email, _ModeSwitch, _name, onChanged (+8 more)

### Community 46 - "session.dart"
Cohesion: 0.11
Nodes (17): AppUser? get, bool get, ../data/auth_repository.dart, AuthRepository, AppUser, _auth, _key, login (+9 more)

### Community 51 - "auth_repository.dart"
Cohesion: 0.12
Nodes (16): dart:math, block, _db, _hash, hmac, _iterations, login, message (+8 more)

### Community 58 - "keyword_matcher.dart"
Cohesion: 0.14
Nodes (13): int get, extract, KeywordMatch, KeywordMatcher, match, matched, missing, percent (+5 more)

### Community 75 - "motion.dart"
Cohesion: 0.05
Nodes (38): anthropicKey, dbHost, dbName, dbPassword, dbUser, Env, hasAi, hasDatabase (+30 more)

### Community 76 - "Product"
Cohesion: 0.18
Nodes (10): Brand Commitments, Capabilities and Constraints, Evidence on Hand, Platform, Positioning, Product, Product Principles, Product Purpose (+2 more)

### Community 86 - "core_test.dart"
Cohesion: 0.22
Nodes (8): dart:io, package:flutter_test/flutter_test.dart, package:lamar/data/models.dart, package:lamar/services/ats_scorer.dart, package:lamar/services/keyword_matcher.dart, package:lamar/services/pdf_builder.dart, main, sample

### Community 110 - "format.dart"
Cohesion: 0.50
Nodes (3): d, m, relativeTime

### Community 112 - "ClayColors"
Cohesion: 0.67
Nodes (3): @immutable, ClayColors, ThemeExtension

### Community 113 - "CV Ready"
Cohesion: 0.33
Nodes (5): Catatan stack, CV Ready, Keamanan, Menjalankan, Struktur

## Knowledge Gaps
- **479 isolated node(s):** `Env`, `dbHost`, `dbName`, `dbUser`, `dbPassword` (+474 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 563 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **23 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `ResumeStore` connect `ResumeStore` to `splash_screen.dart`, `StatelessWidget`, `resume_store.dart`, `editor_screen.dart`, `export_screen.dart`, `account_tab.dart`, `score_screen.dart`, `State`, `match_tab.dart`, `sections.dart`, `auth_screen.dart`, `cv_list_tab.dart`?**
  _High betweenness centrality (0.044) - this node is a cross-community bridge._
- **Why does `Resume` connect `editor_screen.dart` to `match_tab.dart`, `sections.dart`, `models.dart`, `cv_list_tab.dart`?**
  _High betweenness centrality (0.022) - this node is a cross-community bridge._
- **Why does `Session` connect `ResumeStore` to `splash_screen.dart`, `account_tab.dart`, `State`, `auth_screen.dart`, `session.dart`, `cv_list_tab.dart`?**
  _High betweenness centrality (0.012) - this node is a cross-community bridge._
- **What connects `Env`, `dbHost`, `dbName` to the rest of the system?**
  _479 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `StatelessWidget` be split into smaller, more focused modules?**
  _Cohesion score 0.11764705882352941 - nodes in this community are weakly interconnected._
- **Should `clay_widgets.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.04 - nodes in this community are weakly interconnected._
- **Should `palette.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.0425531914893617 - nodes in this community are weakly interconnected._