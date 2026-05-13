import re
from collections import defaultdict

def process_analyze_output(filepath):
    with open(filepath, 'r', encoding='utf-16') as f:
        lines = f.readlines()
        
    errors = []
    for line in lines:
        if 'invalid_constant' in line or 'const_with_non_constant_argument' in line or 'const_eval_method_invocation' in line or 'non_constant_list_element' in line or 'const_initialized_with_non_constant_value' in line:
            parts = line.split(' - ')
            if len(parts) >= 3:
                location = parts[-2].strip()
                loc_parts = location.split(':')
                if len(loc_parts) == 3:
                    file, l, col = loc_parts
                    errors.append((file, int(l)))

    file_to_lines = defaultdict(set)
    for f, l in errors:
        file_to_lines[f].add(l)
        
    for file, err_lines in file_to_lines.items():
        try:
            with open(file, 'r', encoding='utf-8') as f:
                content_lines = f.readlines()
                
            for l in sorted(list(err_lines), reverse=True):
                idx = l - 1
                if idx < len(content_lines):
                    for offset in range(15):
                        target_idx = idx - offset
                        if target_idx >= 0:
                            if 'const ' in content_lines[target_idx]:
                                content_lines[target_idx] = re.sub(r'\bconst\s+', '', content_lines[target_idx])
                                break
                            if 'const[' in content_lines[target_idx] or 'const [' in content_lines[target_idx]:
                                content_lines[target_idx] = re.sub(r'\bconst\s*\[', '[', content_lines[target_idx])
                                break
                                
            with open(file, 'w', encoding='utf-8') as f:
                f.writelines(content_lines)
            print(f"Fixed consts in {file}")
        except Exception as e:
            print(f"Error processing {file}: {e}")

process_analyze_output('analyze_output.txt')
