import os
import re
import subprocess
import sys

def get_esv_key():
    key = os.environ.get('ESV_API_KEY')
    if key and key != 'REDACTED':
        return key
    zshrc_path = os.path.expanduser('~/.zshrc')
    if os.path.exists(zshrc_path):
        with open(zshrc_path, 'r', encoding='utf-8', errors='ignore') as f:
            for line in f:
                if 'ESV_API_KEY=' in line:
                    m = re.search(r'ESV_API_KEY=["\x27]?([A-Za-z0-9_\-]+)["\x27]?', line)
                    if m:
                        return m.group(1)
    return ''

def main():
    key = get_esv_key()
    if not key:
        print('❌ ESV_API_KEY not found!')
        sys.exit(1)
    print(f'🔑 Loaded ESV_API_KEY ({key[:4]}...{key[-4:]})')
    
    project_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    print(f'Building APK in {project_dir}...')
    
    cmd = [
        'flutter', 'build', 'apk', '--debug',
        f'--dart-define=ESV_API_KEY={key}'
    ]
    res = subprocess.run(cmd, cwd=project_dir)
    if res.returncode != 0:
        print(f'❌ Build failed with code {res.returncode}')
        sys.exit(res.returncode)
    
    apk_path = os.path.join(project_dir, 'build', 'app', 'outputs', 'flutter-apk', 'app-debug.apk')
    print(f'Installing {apk_path} on 58221JEBF20835...')
    install_res = subprocess.run(['adb', '-s', '58221JEBF20835', 'install', '-r', apk_path])
    if install_res.returncode != 0:
        print(f'❌ Install failed with code {install_res.returncode}')
        sys.exit(install_res.returncode)
        
    print('✅ Build & Install Succeeded!')

if __name__ == '__main__':
    main()
