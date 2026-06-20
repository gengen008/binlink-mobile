import os
import re

def main():
    lib_dir = 'lib'
    color_count = 0
    edge_insets_count = 0
    border_radius_count = 0
    text_style_count = 0
    
    violations = []
    
    for root, dirs, files in os.walk(lib_dir):
        # Exclude design system definition files themselves
        if 'design_system' in root:
            continue
            
        for f in files:
            if f.endswith('.dart'):
                path = os.path.join(root, f)
                with open(path, 'r') as fp:
                    lines = fp.readlines()
                    
                for i, line in enumerate(lines):
                    line_num = i + 1
                    
                    if 'Color(' in line:
                        color_count += line.count('Color(')
                        violations.append(f"- {path}:{line_num} | Color(...)")
                        
                    if 'EdgeInsets.' in line:
                        edge_insets_count += line.count('EdgeInsets.')
                        violations.append(f"- {path}:{line_num} | EdgeInsets(...)")
                        
                    if 'BorderRadius.' in line:
                        border_radius_count += line.count('BorderRadius.')
                        violations.append(f"- {path}:{line_num} | BorderRadius(...)")
                        
                    # Find TextStyle( that is not inside a comment
                    if 'TextStyle(' in line and not line.strip().startswith('//'):
                        text_style_count += line.count('TextStyle(')
                        violations.append(f"- {path}:{line_num} | TextStyle(...)")
                        
    print(f"Color: {color_count}")
    print(f"EdgeInsets: {edge_insets_count}")
    print(f"BorderRadius: {border_radius_count}")
    print(f"TextStyle: {text_style_count}")
    
    with open('design_debt_report.md', 'w') as f:
        f.write("# BinLink V3 — Design Debt Report\n\n")
        f.write("## Remaining Violations\n")
        f.write(f"* Remaining Color(...) count: {color_count}\n")
        f.write(f"* Remaining EdgeInsets(...) count: {edge_insets_count}\n")
        f.write(f"* Remaining BorderRadius(...) count: {border_radius_count}\n")
        f.write(f"* Remaining TextStyle(...) count: {text_style_count}\n\n")
        
        f.write("## Violation Details\n")
        for v in violations:
            f.write(f"{v}\n")
            
if __name__ == "__main__":
    main()
