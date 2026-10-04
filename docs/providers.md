# Providers

## Environment

Manages process-scoped `HTTP_PROXY`, `HTTPS_PROXY`, `ALL_PROXY`, and `NO_PROXY`.

## Git

Manages global `http.proxy` and `https.proxy`. Original values are stored in:

```text
%LOCALAPPDATA%\WinProxySync\providers\git.json
```

The provider checks for manual changes before restoring.

## Future

Additional providers can implement the same general lifecycle:

- Apply
- Restore/Disable
- Status
