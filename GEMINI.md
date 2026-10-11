# Workspace Rules: Selah Scripture Audio Meditation

## Rule: Zero Plaintext API Keys & Secrets in Repository
Under NO circumstances may any API keys, access tokens, secret credentials, private keys, or passwords be written to files tracked by git, nor hardcoded as default fallback values in configuration files (such as `codemagic.yaml`, workflow files, `.env` files, or Dart sources).

### Strict Requirements
1. **No Plaintext Fallbacks**: In YAML or workflow files, NEVER use syntax like `${VAR:-plaintext_secret}` that embeds a fallback secret.
2. **Environment & Secrets**: Use only environment variables supplied at build time or via secure CI/CD groups (`groups: [selah_secrets]`).
3. **Dart Code Constants**: Always load sensitive keys via `String.fromEnvironment('KEY_NAME', defaultValue: 'REDACTED')`. Never embed actual tokens in source code or unit test mocks.
4. **Ignored Files**: Ensure files containing credentials (e.g., `google-services.json`, `GoogleService-Info.plist`, `.env*`, `*.keystore`, `*.jks`) are strictly included in `.gitignore`.
5. **Pre-Commit Verification**: Before executing `git commit`, inspect `git diff --staged` to verify no secret or credential was introduced.
