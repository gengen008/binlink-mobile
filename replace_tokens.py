import re
import os

def migrate_file(path):
    with open(path, 'r') as f:
        content = f.read()

    # Need to add imports if not present
    if "import '../../../core/design_system/app_spacing.dart';" not in content:
        content = content.replace("import '../../../core/design_system/app_colors.dart';", 
                                  "import '../../../core/design_system/app_colors.dart';\nimport '../../../core/design_system/app_spacing.dart';")
    
    # Replace Colors
    content = content.replace('Color(0xFFE60000)', 'AppColors.danger')
    content = content.replace('Color(0xFFFFCC00)', 'AppColors.warning')
    content = content.replace('Color(0xFF005A9C)', 'AppColors.info')
    content = content.replace('Color(0xFF1A1A2E)', 'AppColors.premiumBlack')
    
    # Replace Padding
    content = re.sub(r'EdgeInsets\.all\(16(?:\.0)?\)', 'AppSpacing.edge16', content)
    content = re.sub(r'EdgeInsets\.all\(24(?:\.0)?\)', 'AppSpacing.edge24', content)
    content = re.sub(r'EdgeInsets\.all\(12(?:\.0)?\)', 'AppSpacing.edge12', content)
    content = re.sub(r'EdgeInsets\.all\(8(?:\.0)?\)', 'AppSpacing.edge8', content)
    content = re.sub(r'EdgeInsets\.all\(4(?:\.0)?\)', 'AppSpacing.edge4', content)
    content = re.sub(r'EdgeInsets\.all\(2(?:\.0)?\)', 'AppSpacing.edge4', content) # closest
    content = re.sub(r'EdgeInsets\.all\(10(?:\.0)?\)', 'AppSpacing.edge8', content) # closest
    content = re.sub(r'EdgeInsets\.all\(6(?:\.0)?\)', 'AppSpacing.edge4', content) # closest
    
    # Replace Radii
    content = re.sub(r'BorderRadius\.circular\(16(?:\.0)?\)', 'AppRadius.r16BR', content)
    content = re.sub(r'BorderRadius\.circular\(12(?:\.0)?\)', 'AppRadius.r12BR', content)
    content = re.sub(r'BorderRadius\.circular\(8(?:\.0)?\)', 'AppRadius.r8BR', content)
    content = re.sub(r'BorderRadius\.circular\(24(?:\.0)?\)', 'AppRadius.r24BR', content)
    content = re.sub(r'BorderRadius\.circular\(32(?:\.0)?\)', 'AppRadius.r32BR', content)
    
    with open(path, 'w') as f:
        f.write(content)
    print(f"Migrated {path}")

def main():
    screens = [
        'lib/features/collector/screens/active_pickup_screen.dart',
        'lib/features/collector/screens/map_screen.dart',
        'lib/features/collector/screens/pickups_screen.dart',
        'lib/features/collector/components/collector_map_tab.dart',
        'lib/shared/components/binlink_map.dart'
    ]
    for s in screens:
        if os.path.exists(s):
            migrate_file(s)

if __name__ == '__main__':
    main()
