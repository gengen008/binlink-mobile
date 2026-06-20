import os
import glob
import re

def main():
    dart_files = glob.glob('lib/**/*.dart', recursive=True)
    
    # 1. Update Imports
    # We will replace all references to 'core/theme' with 'core/design_system'
    # and 'shared/widgets' with 'shared/components'
    for filepath in dart_files:
        with open(filepath, 'r') as f:
            content = f.read()
            
        new_content = content.replace('core/theme/', 'core/design_system/')
        new_content = new_content.replace('shared/widgets/', 'shared/components/')
        # Also handle relative imports if needed
        new_content = new_content.replace('../theme/app_colors.dart', '../design_system/binlink_colors.dart')
        
        # Icon Consolidation
        new_content = new_content.replace('import \'package:lucide_icons_flutter/lucide_icons.dart\';', 'import \'package:phosphor_flutter/phosphor_flutter.dart\';')
        # Replace LucideIcons.xyz with PhosphorIcons.xyz
        new_content = re.sub(r'LucideIcons\.([a-zA-Z0-9_]+)', r'PhosphorIcons.\1', new_content)
        
        if content != new_content:
            with open(filepath, 'w') as f:
                f.write(new_content)
            print(f'Updated imports/icons in {filepath}')

if __name__ == '__main__':
    main()
