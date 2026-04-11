import pathlib, re
screen_root = pathlib.Path('lib/screens')
count = 0
for screen_path in sorted(screen_root.glob('*.dart')):
    text = screen_path.read_text(encoding='utf-8')
    m = re.search(r'class\s+([A-Za-z0-9_]+Page)\s+extends\s+([A-Za-z0-9_]+)', text)
    if not m:
        continue
    className = m.group(1)
    # if already a wrapper that references View, skip
    if re.search(r'class\s+' + re.escape(className) + r'\s+extends\s+StatelessWidget', text) and 'View' in text and 'class ' + className + 'View' not in text:
        # not already a pure wrapper, continue refactor
        pass
    # if already wrapper with classNameView usage, skip to avoid rewriting
    if 'class ' + className + 'View' in text and 'return const ' + className + 'View' in text and 'class ' + className + ' extends' in text:
        continue

    baseName = className[:-4] if className.endswith('Page') else className
    widgets_module = baseName.lower().replace('page','')
    widget_dir = pathlib.Path('lib/widgets') / widgets_module
    widget_dir.mkdir(parents=True, exist_ok=True)
    widget_file = widget_dir / f'{screen_path.stem.lower()}_page_widgets.dart'

    new_content = text
    # rename main class to View (only top-level class)
    new_content = re.sub(r'class\s+' + re.escape(className) + r'\s+extends', 'class ' + className + 'View extends', new_content, count=1)

    # rename private view class and uses
    private_view = '_' + baseName + 'PageView'
    new_content = re.sub(r'class\s+' + re.escape(private_view) + r'\s+extends', 'class ' + className + 'View extends', new_content)
    new_content = new_content.replace('const ' + private_view + '(', 'const ' + className + 'View(')
    new_content = new_content.replace('child: const ' + private_view + '()', 'child: const ' + className + 'View()')

    # if this instead uses _XxxPageView id directly as child
    new_content = new_content.replace('const _' + baseName + 'PageView()', 'const ' + className + 'View()')

    # write widget file
    widget_file.write_text(new_content, encoding='utf-8')

    # create simple wrapper in screen
    wrapper = f"""import 'package:flutter/material.dart';
import 'package:project_granith/widgets/{widgets_module}/{widget_file.name}';

class {className} extends StatelessWidget {{
  const {className}({{super.key}});

  @override
  Widget build(BuildContext context) {{
    return const {className}View();
  }}
}}
"""
    screen_path.write_text(wrapper, encoding='utf-8')

    count += 1
    print('refactored', screen_path.name, '->', widget_file)

print('total', count)
