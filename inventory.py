import re
import glob

def scan_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    colors = re.findall(r'Color\(0x[A-Fa-f0-9]+\)', content)
    spacing = re.findall(r'EdgeInsets\.(?:all|symmetric|only|fromLTRB)\([^)]+\)', content)
    radii = re.findall(r'(?:Radius|BorderRadius)\.(?:circular|vertical|horizontal)\([^)]+\)', content)

    # Inconsistent components might mean using standard flutter components instead of AppButton, etc.
    # Like ElevatedButton, Container without AppSpacing, etc.
    # But just identifying the colors/spacing/radii is the main requirement.
    
    return {
        'colors': list(set(colors)),
        'spacing': list(set(spacing)),
        'radii': list(set(radii))
    }

def main():
    screens = [
        'lib/features/collector/screens/active_pickup_screen.dart',
        'lib/features/collector/screens/map_screen.dart',
        'lib/features/collector/screens/pickups_screen.dart',
        'lib/features/collector/screens/earnings_screen.dart',
        'lib/features/collector/components/collector_map_tab.dart',
        'lib/shared/components/binlink_map.dart'
    ]

    print("=== UI INVENTORY ===")
    for screen in screens:
        print(f"\n--- Screen: {screen} ---")
        try:
            res = scan_file(screen)
            print(f"Hardcoded Colors ({len(res['colors'])} unique):")
            for c in res['colors']: print(f"  - {c}")
            
            print(f"Hardcoded Spacing ({len(res['spacing'])} unique):")
            for s in res['spacing']: print(f"  - {s}")
            
            print(f"Hardcoded Radii ({len(res['radii'])} unique):")
            for r in res['radii']: print(f"  - {r}")
        except FileNotFoundError:
            print("  File not found.")

if __name__ == '__main__':
    main()
