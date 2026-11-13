
with open(r'C:\regional-mobility\mobile\driver_app\pubspec.yaml', 'r', encoding='utf-8') as f:
    content = f.read()

# Add new dependencies after cupertino_icons line
old_deps = '  cupertino_icons: ^1.0.8\n\ndev_dependencies:'
new_deps = '  cupertino_icons: ^1.0.8\n  http: ^1.2.2\n  flutter_secure_storage: ^9.2.4\n  shared_preferences: ^2.3.3\n\ndev_dependencies:'

# Fix assets section - replace commented-out assets block with actual assets
old_assets = '  # assets:\n  #   - images/a_dot_burr.jpeg\n  #   - images/a_dot_ham.jpeg\n\n  # An image asset can refer to one or more resolution-specific "variants", see\n  # https://flutter.dev/to/resolution-aware-images'
new_assets = '  assets:\n    - assets/images/\n\n  # An image asset can refer to one or more resolution-specific "variants", see\n  # https://flutter.dev/to/resolution-aware-images'

if old_deps in content:
    content = content.replace(old_deps, new_deps, 1)
    print("Dependencies added")
else:
    print("WARN: deps marker not found")
    print(repr(content[800:1000]))

if old_assets in content:
    content = content.replace(old_assets, new_assets, 1)
    print("Assets section added")
else:
    print("WARN: assets marker not found - trying CRLF version")
    old_assets_crlf = old_assets.replace('\n', '\r\n')
    new_assets_crlf = new_assets.replace('\n', '\r\n')
    if old_assets_crlf in content:
        content = content.replace(old_assets_crlf, new_assets_crlf, 1)
        print("Assets section added (CRLF)")
    else:
        idx = content.find('# assets:')
        print(f"'# assets:' at index: {idx}")
        if idx >= 0:
            print(repr(content[idx:idx+200]))

with open(r'C:\regional-mobility\mobile\driver_app\pubspec.yaml', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done")
