# Architecture

```text
WinProxySync
├── Core
│   ├── ProxyReader
│   ├── StateManager
│   └── SyncEngine
└── Providers
    ├── Environment
    └── Git
```

Core reads Windows WinINET settings and dispatches a normalized proxy model to providers.

Providers own their integrations. This keeps Git/environment logic out of Core and makes future providers possible.
