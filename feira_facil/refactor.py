import os
import re

replacements = {
    r'AppColors\.orangeDark': r'context.colors.colorOrangeDark',
    r'AppColors\.orangeLight': r'context.colors.colorOrangeLight',
    r'AppColors\.orangeLT': r'context.colors.colorOrangeLight',
    r'AppColors\.orangeMedium': r'context.colors.colorOrangeMedium',
    r'AppColors\.orangeUltraLight': r'context.colors.colorOrangeUltraLight',
    r'AppColors\.orange': r'context.colors.colorOrange',
    
    r'AppColors\.greenDark': r'context.colors.colorGreenDark',
    r'AppColors\.greenLight': r'context.colors.colorGreenLight',
    r'AppColors\.greenLT': r'context.colors.colorGreenLight',
    r'AppColors\.greenMedium': r'context.colors.colorGreenMedium',
    r'AppColors\.green': r'context.colors.colorGreen',
    
    r'AppColors\.redLight': r'context.colors.colorRedLight',
    r'AppColors\.red': r'context.colors.colorRed',
    
    r'AppColors\.cream2': r'context.colors.colorBorder',
    r'AppColors\.cream': r'context.colors.colorBackground',
    r'AppColors\.white': r'context.colors.colorCard',
    
    r'AppColors\.textBody': r'context.colors.colorTextBody',
    r'AppColors\.textSecondary': r'context.colors.colorTextSecondary',
    r'AppColors\.textTertiary': r'context.colors.colorTextTertiary',
    
    r'const\s*\[\s*AppColors\.shadow1\s*\]': r'context.colors.shadow1',
    r'const\s*\[\s*AppColors\.shadow2\s*\]': r'context.colors.shadow2',
    r'\[\s*AppColors\.shadow1\s*\]': r'context.colors.shadow1',
    r'\[\s*AppColors\.shadow2\s*\]': r'context.colors.shadow2',
}

def process_file(filepath):
    # Do not process app_theme.dart and app_colors.dart, theme_ext.dart
    if 'app_theme.dart' in filepath or 'app_colors.dart' in filepath or 'theme_ext.dart' in filepath:
        return

    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
        
    orig = content
    for pattern, repl in replacements.items():
        content = re.sub(pattern, repl, content)
        
    if content != orig:
        # Avoid duplicate imports
        if 'theme_ext.dart' not in content:
            # We must use package import assuming project name is feira_facil
            import_statement = "import 'package:feira_facil/core/theme/theme_ext.dart';"
            imports = list(re.finditer(r'^import .*?;', content, re.MULTILINE))
            if imports:
                last_import = imports[-1]
                content = content[:last_import.end()] + '\n' + import_statement + content[last_import.end():]
                
        # Also replace context.colors with context.color... Wait, my replacements above map to context.colors.colorX, but my extension is `context.colorX`!
        # Let's fix that in content string:
        content = content.replace('context.colors.color', 'context.color')
        content = content.replace('context.colors.shadow', 'context.shadow')
                
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
            print(f"Refactored {filepath}")

for root, _, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))
