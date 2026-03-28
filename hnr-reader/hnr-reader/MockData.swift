//
//  MockData.swift
//  hnr-reader
//

import Foundation

struct MockData {
    static let topStories: [HNStory] = [
        HNStory(id: 1, title: "Llama 4 is here: Meta's open-source frontier model beats GPT-4o on most benchmarks", url: "https://ai.meta.com", domain: "ai.meta.com", score: 2847, author: "throwaway_ml", timeAgo: "2h ago", commentsCount: 634, feed: .top),
        HNStory(id: 2, title: "I spent 6 months rewriting my app in Rust and here's what I learned", url: "https://blog.example.com", domain: "blog.example.com", score: 1923, author: "rscoder42", timeAgo: "4h ago", commentsCount: 412, feed: .top),
        HNStory(id: 3, title: "Apple announces SwiftUI redesign for iOS 27 with new reactive paradigm", url: "https://developer.apple.com", domain: "developer.apple.com", score: 1456, author: "swiftnerd", timeAgo: "5h ago", commentsCount: 287, feed: .top),
        HNStory(id: 4, title: "The death of the junior developer: How AI is reshaping entry-level engineering jobs", url: "https://techcrunch.com", domain: "techcrunch.com", score: 1201, author: "hiringsage", timeAgo: "6h ago", commentsCount: 891, feed: .top),
        HNStory(id: 5, title: "Postgres 18 released with native vector search and columnar storage", url: "https://postgresql.org", domain: "postgresql.org", score: 987, author: "dbarchitect", timeAgo: "7h ago", commentsCount: 203, feed: .top),
        HNStory(id: 6, title: "How we scaled our startup to $10M ARR without a sales team", url: "https://medium.com", domain: "medium.com", score: 876, author: "foundermode", timeAgo: "8h ago", commentsCount: 178, feed: .top),
        HNStory(id: 7, title: "Git 3.0 ships with native conflict resolution AI and rebase improvements", url: "https://git-scm.com", domain: "git-scm.com", score: 754, author: "vcsgeek", timeAgo: "9h ago", commentsCount: 145, feed: .top),
        HNStory(id: 8, title: "New study: Remote work is 23% more productive than office work for software engineers", url: "https://stanford.edu", domain: "stanford.edu", score: 643, author: "wfhadvocate", timeAgo: "10h ago", commentsCount: 532, feed: .top),
        HNStory(id: 9, title: "WebAssembly Component Model hits 1.0 — what this means for the web platform", url: "https://webassembly.org", domain: "webassembly.org", score: 589, author: "wasmwatcher", timeAgo: "11h ago", commentsCount: 94, feed: .top),
        HNStory(id: 10, title: "The unreasonable effectiveness of just writing things down", url: "https://notes.andymatuschak.org", domain: "notes.andymatuschak.org", score: 512, author: "pkm_fan", timeAgo: "12h ago", commentsCount: 76, feed: .top),
        HNStory(id: 11, title: "Bun 2.0 launches with full Node.js compatibility and 10x faster cold starts", url: "https://bun.sh", domain: "bun.sh", score: 478, author: "jarredbuild", timeAgo: "13h ago", commentsCount: 217, feed: .top),
        HNStory(id: 12, title: "How Firefox regained 15% market share in 18 months", url: "https://hacks.mozilla.org", domain: "hacks.mozilla.org", score: 445, author: "openwebfan", timeAgo: "14h ago", commentsCount: 312, feed: .top),
        HNStory(id: 13, title: "I built a personal CRM in SQLite that runs entirely in the browser", url: "https://github.com", domain: "github.com", score: 398, author: "sqliteeverywhere", timeAgo: "15h ago", commentsCount: 89, feed: .top),
        HNStory(id: 14, title: "The case for boring technology in 2026", url: "https://mcfunley.com", domain: "mcfunley.com", score: 367, author: "boringtechbro", timeAgo: "16h ago", commentsCount: 204, feed: .top),
        HNStory(id: 15, title: "Figma acquires Linear for $1.2B, merging design and project management", url: "https://figma.com", domain: "figma.com", score: 2341, author: "designops", timeAgo: "17h ago", commentsCount: 723, feed: .top),
    ]

    static let newStories: [HNStory] = [
        HNStory(id: 101, title: "Show HN: I built a terminal-based Pomodoro timer in 50 lines of Go", url: "https://github.com", domain: "github.com", score: 12, author: "gopher_dev", timeAgo: "4m ago", commentsCount: 3, feed: .new),
        HNStory(id: 102, title: "TypeScript 6.0 beta: Full type narrowing for discriminated unions", url: "https://devblogs.microsoft.com", domain: "devblogs.microsoft.com", score: 8, author: "ts_addict", timeAgo: "7m ago", commentsCount: 1, feed: .new),
        HNStory(id: 103, title: "Anthropic releases Claude 4 Opus with 200k context and tool use improvements", url: "https://anthropic.com", domain: "anthropic.com", score: 156, author: "aiwatch", timeAgo: "12m ago", commentsCount: 47, feed: .new),
        HNStory(id: 104, title: "A gentle introduction to category theory for programmers", url: "https://bartoszmilewski.com", domain: "bartoszmilewski.com", score: 34, author: "mathprog", timeAgo: "18m ago", commentsCount: 8, feed: .new),
        HNStory(id: 105, title: "Supabase announces edge functions with persistent storage", url: "https://supabase.com", domain: "supabase.com", score: 67, author: "pgpower", timeAgo: "23m ago", commentsCount: 19, feed: .new),
        HNStory(id: 106, title: "Why I switched from VS Code to Zed after 8 years", url: "https://zed.dev/superuberlong/superuberlong/superuberlong/superuberlong/", domain: "https://zed.dev/superuberlong/superuberlong/superuberlong/superuberlong/", score: 89, author: "editorhopper", timeAgo: "31m ago", commentsCount: 42, feed: .new),
        HNStory(id: 107, title: "A tiny ray tracer written in portable C99 under 1000 lines", url: "https://github.com", domain: "github.com", score: 45, author: "rayrayray", timeAgo: "38m ago", commentsCount: 11, feed: .new),
        HNStory(id: 108, title: "Introducing Rune: A new systems language with Rust semantics and Go simplicity", url: "https://rune-lang.org", domain: "rune-lang.org", score: 23, author: "langdev", timeAgo: "45m ago", commentsCount: 6, feed: .new),
        HNStory(id: 109, title: "The hidden costs of microservices that nobody talks about", url: "https://architecturenotes.co", domain: "architecturenotes.co", score: 112, author: "monolithfan", timeAgo: "52m ago", commentsCount: 63, feed: .new),
        HNStory(id: 110, title: "Open source alternative to Vercel is now production-ready", url: "https://github.com", domain: "github.com", score: 78, author: "selfhostpride", timeAgo: "1h ago", commentsCount: 29, feed: .new),
    ]

    static let askStories: [HNStory] = [
        HNStory(id: 201, title: "Ask HN: What's your workflow for staying focused in 2026?", score: 423, author: "deepworker", timeAgo: "3h ago", commentsCount: 312, feed: .ask, isAskHN: true, bodyText: "With AI tools, Slack, and endless notifications, deep work feels harder than ever. What systems, tools, or habits have actually worked for you?"),
        HNStory(id: 202, title: "Ask HN: Has anyone successfully migrated a large Rails monolith to microservices?", score: 287, author: "railsdev", timeAgo: "5h ago", commentsCount: 241, feed: .ask, isAskHN: true, bodyText: "We have a 10-year-old Rails app with ~500k LOC. Looking for real war stories — what worked, what didn't, and whether you'd do it again."),
        HNStory(id: 203, title: "Ask HN: What technical books have changed how you think about software?", score: 891, author: "bookwormdev", timeAgo: "8h ago", commentsCount: 643, feed: .ask, isAskHN: true),
        HNStory(id: 204, title: "Ask HN: Is Kubernetes still worth it for small teams?", score: 345, author: "k8skeptic", timeAgo: "12h ago", commentsCount: 289, feed: .ask, isAskHN: true, bodyText: "We're a team of 5 engineers running about 12 services. Every time I revisit K8s I wonder if Fly.io or Railway would just be simpler."),
        HNStory(id: 205, title: "Ask HN: How do you handle technical debt at your company?", score: 267, author: "debtcollector", timeAgo: "1d ago", commentsCount: 198, feed: .ask, isAskHN: true),
        HNStory(id: 206, title: "Ask HN: What was your biggest career mistake as an engineer?", score: 1204, author: "careeradvice", timeAgo: "2d ago", commentsCount: 891, feed: .ask, isAskHN: true),
        HNStory(id: 207, title: "Ask HN: Recommendations for learning about compilers in 2026?", score: 178, author: "compilernewbie", timeAgo: "2d ago", commentsCount: 134, feed: .ask, isAskHN: true),
        HNStory(id: 208, title: "Ask HN: What do you actually use AI coding tools for day-to-day?", score: 567, author: "aiuser2026", timeAgo: "3d ago", commentsCount: 432, feed: .ask, isAskHN: true, bodyText: "Not looking for hype — curious what tasks you've genuinely offloaded to Copilot, Cursor, Claude, etc. and what you still do by hand."),
    ]

    static let showStories: [HNStory] = [
        HNStory(id: 301, title: "Show HN: Papermark – open-source DocSend alternative with analytics", url: "https://papermark.io", domain: "papermark.io", score: 634, author: "mfts0", timeAgo: "6h ago", commentsCount: 187, feed: .show, isShowHN: true, bodyText: "Share documents with custom domains, track views per page, require email to access, and get notified when someone opens your link."),
        HNStory(id: 302, title: "Show HN: I made a free, open-source Duolingo alternative that works offline", url: "https://github.com/langlearner/polyglot", domain: "github.com", score: 1245, author: "langlearner", timeAgo: "1d ago", commentsCount: 342, feed: .show, isShowHN: true, bodyText: "No streaks, no gamification, no dark patterns — just spaced repetition with offline-first sync. Built with SwiftUI + SQLite."),
        HNStory(id: 303, title: "Show HN: Gradient descent visualized in pure CSS", url: "https://gradientdescent.css.art", domain: "gradientdescent.css.art", score: 423, author: "cssartist", timeAgo: "1d ago", commentsCount: 89, feed: .show, isShowHN: true),
        HNStory(id: 304, title: "Show HN: A minimal, keyboard-driven note-taking app built with SwiftUI", url: "https://github.com/swiftuinotes/notes", domain: "github.com", score: 287, author: "swiftuinotes", timeAgo: "2d ago", commentsCount: 76, feed: .show, isShowHN: true),
        HNStory(id: 305, title: "Show HN: SQLiteStudio – A web-based SQLite explorer that runs client-side", url: "https://sqlitestudio.app", domain: "sqlitestudio.app", score: 567, author: "sqlfan", timeAgo: "2d ago", commentsCount: 123, feed: .show, isShowHN: true, bodyText: "Open any .sqlite file directly in the browser. No server, no uploads — everything runs in a WASM SQLite instance. Supports export, queries, and schema view."),
        HNStory(id: 306, title: "Show HN: Real-time collaborative whiteboard built on WebRTC and CRDTs", url: "https://github.com/crdtbuilder/collab-board", domain: "github.com", score: 389, author: "crdtbuilder", timeAgo: "3d ago", commentsCount: 94, feed: .show, isShowHN: true),
        HNStory(id: 307, title: "Show HN: Terminal dashboard for monitoring all your cloud costs in one place", url: "https://cloudcost.sh", domain: "cloudcost.sh", score: 312, author: "cloudwatcher", timeAgo: "3d ago", commentsCount: 67, feed: .show, isShowHN: true),
        HNStory(id: 308, title: "Show HN: I trained a 1B parameter model on my own writing and it sounds like me", url: "https://blog.personallm.com/one-billion", domain: "blog.personallm.com", score: 891, author: "personallm", timeAgo: "4d ago", commentsCount: 412, feed: .show, isShowHN: true, bodyText: "Dataset: 8 years of journal entries, emails, and notes. Fine-tuned Llama 3 on a single A100 for 3 hours. The results are unsettling."),
    ]

    static func stories(for feed: StoryFeed) -> [HNStory] {
        switch feed {
        case .top: return topStories
        case .new: return newStories
        case .ask: return askStories
        case .show: return showStories
        }
    }
}
