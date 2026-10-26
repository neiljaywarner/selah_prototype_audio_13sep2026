#!/usr/bin/env python3
"""
Unified helper script for Selah Android Release APK + Web Hosting Deployment.
Safely loads ESV_API_KEY, API_BIBLE_KEY, and APTABASE_KEY from ~/.zshrc
without echoing secrets to terminal stdout.

Usage:
  python3 scripts/release_and_deploy.py build-apk-dry-run
  python3 scripts/release_and_deploy.py distribute-apk
  python3 scripts/release_and_deploy.py build-web
  python3 scripts/release_and_deploy.py deploy-web
"""
import os
import re
import subprocess
import sys

def load_env_with_keys():
    env = os.environ.copy()
    zshrc_path = os.path.expanduser('~/.zshrc')
    if os.path.exists(zshrc_path):
        content = open(zshrc_path, 'r', encoding='utf-8', errors='ignore').read()
        for key_name in ['ESV_API_KEY', 'API_BIBLE_KEY', 'APTABASE_KEY', 'POSTHOG_KEY']:
            if not env.get(key_name) or env.get(key_name) == 'REDACTED':
                m = re.search(rf'{key_name}=["\x27]?([A-Za-z0-9_\-]+)["\x27]?', content)
                if m:
                    env[key_name] = m.group(1)
    return env

def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else 'build-apk-dry-run'
    project_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    env = load_env_with_keys()

    notes = (
        "ESV 1.0 Soft Launch: Crossway David Cochran Heath human narrator audio "
        "for passages (1 Cor 13:4-7, 1 Peter 5:7-9), zero TTS for ESV, and "
        "clean ESV-only soft launch UI."
    )

    if cmd == 'build-apk-dry-run':
        res = subprocess.run(
            ['./scripts/distribute_android_release.sh', '--dry-run', '--notes', notes],
            cwd=project_dir,
            env=env,
        )
        sys.exit(res.returncode)

    elif cmd == 'distribute-apk':
        res = subprocess.run(
            ['./scripts/distribute_android_release.sh', '--notes', notes],
            cwd=project_dir,
            env=env,
        )
        sys.exit(res.returncode)

    elif cmd == 'test':
        extra_args = sys.argv[2:]
        res = subprocess.run(
            ['flutter', 'test', *extra_args],
            cwd=project_dir,
            env=env,
        )
        sys.exit(res.returncode)

    elif cmd == 'build-web':
        defines = []
        for k in ['ESV_API_KEY', 'API_BIBLE_KEY', 'APTABASE_KEY', 'POSTHOG_KEY']:
            if env.get(k):
                defines.append(f'--dart-define={k}={env[k]}')
        res = subprocess.run(
            ['flutter', 'build', 'web', '--release', *defines],
            cwd=project_dir,
            env=env,
        )
        if res.returncode != 0:
            sys.exit(res.returncode)
        # Verify compiled bundle has clean ESV key without shell quotes or REDACTED
        js_path = os.path.join(project_dir, 'build', 'web', 'main.dart.js')
        js = open(js_path, 'r', encoding='utf-8', errors='ignore').read()
        if re.search(r'Token\s+[\x27\x22][0-9a-fA-F]', js):
            print("FATAL: Quoted literal Token found in build/web/main.dart.js!", file=sys.stderr)
            sys.exit(2)
        if not env.get('ESV_API_KEY'):
            print("FATAL: ESV_API_KEY missing during build-web!", file=sys.stderr)
            sys.exit(2)
        print("Verified build/web/main.dart.js: clean ESV token compiled without quotes.")
        sys.exit(0)

    elif cmd == 'deploy-web':
        js_path = os.path.join(project_dir, 'build', 'web', 'main.dart.js')
        if not os.path.exists(js_path):
            print("FATAL: build/web/main.dart.js missing. Run build-web first.", file=sys.stderr)
            sys.exit(2)
        js = open(js_path, 'r', encoding='utf-8', errors='ignore').read()
        if re.search(r'Token\s+[\x27\x22][0-9a-fA-F]', js):
            print("FATAL: Refusing to deploy build/web with quoted Token!", file=sys.stderr)
            sys.exit(2)
        p1 = subprocess.run(
            ['firebase', 'hosting:channel:deploy', 'esv-soft-launch', '--project', 'selahwordapp', '--expires', '7d'],
            cwd=project_dir,
            env=env,
        )
        if p1.returncode != 0:
            sys.exit(p1.returncode)
        res = subprocess.run(
            ['firebase', 'deploy', '--only', 'hosting', '--project', 'selahwordapp'],
            cwd=project_dir,
            env=env,
        )
        sys.exit(res.returncode)

    else:
        print(f"Unknown command: {cmd}")
        sys.exit(1)

if __name__ == '__main__':
    main()
