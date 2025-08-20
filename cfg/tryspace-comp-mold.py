#!/usr/bin/env python3
"""
TrySpace Component Mold Generator

Generate a new component by:
- Copy all files from ./comp/demo to ./comp/<component_name>
- Change file contents from "demo" to the provided component name
- Rename files that contain "demo" in their names
"""

import os
import sys
import shutil
import re
import argparse
from pathlib import Path


def validate_component_name(name):
    """Validate the component name follows naming conventions."""
    if not name:
        raise ValueError("Component name cannot be empty")
    
    # Check for valid characters (alphanumeric and underscore)
    if not re.match(r'^[a-zA-Z][a-zA-Z0-9_]*$', name):
        raise ValueError("Component name must start with a letter and contain only letters, numbers, and underscores")
    
    # Convert to lowercase for consistency
    return name.lower()


def get_name_variants(component_name):
    """Generate different case variants of the component name."""
    name_lower = component_name.lower()
    name_first = name_lower.capitalize()
    name_upper = name_lower.upper()
    
    return {
        'lower': name_lower,
        'first': name_first,
        'upper': name_upper
    }


def ignore_patterns(dir, files):
    """Define patterns to ignore during copy."""
    ignored = []
    for file in files:
        # Ignore git files and directories
        if file == '.git' or file == '.gitmodules':
            ignored.append(file)
        # Ignore build directories
        elif file == 'build':
            ignored.append(file)
        # Ignore device configuration
        elif file == 'device_cfg.h':
            ignored.append(file)
        # Ignore common temporary/cache files
        elif file.startswith('.') and file.endswith(('.swp', '.tmp', '.cache')):
            ignored.append(file)
    return ignored


def copy_demo_component(source_dir, target_dir):
    """Copy the demo component directory to the new component directory."""
    if target_dir.exists():
        response = input(f"Component '{target_dir.name}' already exists. Overwrite? (y/N): ")
        if response.lower() != 'y':
            print("Aborting component creation.")
            sys.exit(0)
        shutil.rmtree(target_dir)
    
    print(f"Copying demo component from {source_dir} to {target_dir}")
    shutil.copytree(source_dir, target_dir, ignore=ignore_patterns)
    
    print("Skipped git files, build directories, and temporary files during copy")


def replace_content_in_files(target_dir, name_variants):
    """Replace 'demo' with component name variants in file contents."""
    print("Updating file contents...")
    
    # Define replacement patterns
    replacements = [
        # Component name variants
        ('DEMO', name_variants['upper']),
        ('Demo', name_variants['first']),
        ('demo', name_variants['lower']),
        # Change USART device from 5 to 9 in device config
        ('/dev/usart_5', '/dev/usart_9'),
        ('handle: 5', 'handle: 9'),
        # Change message IDs to avoid conflicts (A to C, B to D)
        ('0x18FA', '0x18FC'),
        ('0x18FB', '0x18FD'),
        ('0x08FA', '0x08FC'),
        ('0x08FB', '0x08FD')
    ]
    
    # Find all text files (exclude binary files)
    text_extensions = {'.c', '.h', '.cmake', '.cli', '.txt', '.md', '.yml', '.yaml', '.xtce', '.scr', '.j2'}
    
    for file_path in target_dir.rglob('*'):
        if file_path.is_file() and (file_path.suffix.lower() in text_extensions or file_path.name in ['CMakeLists.txt', 'Makefile']):
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                modified = False
                for old_pattern, new_pattern in replacements:
                    if old_pattern in content:
                        content = content.replace(old_pattern, new_pattern)
                        modified = True
                
                if modified:
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write(content)
                    print(f"  Updated: {file_path.relative_to(target_dir)}")
                        
            except (UnicodeDecodeError, PermissionError) as e:
                print(f"  Skipped: {file_path.relative_to(target_dir)} ({e})")


def rename_files_and_dirs(target_dir, name_variants):
    """Rename files and directories that contain 'demo' in their names."""
    print("Renaming files and directories...")
    
    # Define rename patterns (order matters - do DEMO first, then Demo, then demo)
    rename_patterns = [
        ('DEMO', name_variants['upper']),
        ('Demo', name_variants['first']),
        ('demo', name_variants['lower'])
    ]
    
    # Collect all paths that need renaming (files and directories)
    paths_to_rename = []
    for item in target_dir.rglob('*'):
        for old_pattern, new_pattern in rename_patterns:
            if old_pattern in item.name:
                new_name = item.name.replace(old_pattern, new_pattern)
                new_path = item.parent / new_name
                paths_to_rename.append((item, new_path))
                break  # Only apply the first matching pattern
    
    # Sort by depth (deepest first) to avoid path conflicts
    paths_to_rename.sort(key=lambda x: len(x[0].parts), reverse=True)
    
    # Perform renames
    for old_path, new_path in paths_to_rename:
        if old_path.exists() and old_path != new_path:
            print(f"  Renaming: {old_path.relative_to(target_dir)} -> {new_path.relative_to(target_dir)}")
            old_path.rename(new_path)


def main():
    parser = argparse.ArgumentParser(description="Generate a new TrySpace component from the demo template")
    parser.add_argument('component_name', help='Name of the new component')
    parser.add_argument('--source', default='demo', help='Source component to copy from (default: demo)')
    
    args = parser.parse_args()
    
    try:
        # Validate and normalize component name
        component_name = validate_component_name(args.component_name)
        name_variants = get_name_variants(component_name)
        
        print(f"Creating new component: {component_name}")
        print(f"  Lower case: {name_variants['lower']}")
        print(f"  First cap:  {name_variants['first']}")
        print(f"  Upper case: {name_variants['upper']}")
        print()
        
        # Determine paths
        script_dir = Path(__file__).parent
        workspace_dir = script_dir.parent
        comp_dir = workspace_dir / 'comp'
        source_dir = comp_dir / args.source
        target_dir = comp_dir / component_name
        
        # Validate source directory exists
        if not source_dir.exists():
            raise FileNotFoundError(f"Source component '{args.source}' not found at {source_dir}")
        
        # Create the new component
        copy_demo_component(source_dir, target_dir)
        replace_content_in_files(target_dir, name_variants)
        rename_files_and_dirs(target_dir, name_variants)
        
        print()
        print(f"Component mold creation complete!")
        print(f"New component created at: {target_dir}")
        print()
        print("Next steps:")
        print(f"  1. Review the generated component in ./comp/{component_name}")
        print(f"  2. Add the component to your active mission, default is ./cfg/drm/drm.yaml")
        print(f"  3. Add the component to the FSW definitions:")
        print(f"       ./fsw/tryspace_defs/cpu1_cfe_es_startup.scr")
        print(f"       ./fsw/tryspace_defs/tables/sch_def_msgtbl.c")
        print(f"       ./fsw/tryspace_defs/tables/sch_def_schtbl.c")
        print(f"       ./fsw/tryspace_defs/tables/to_lab_sub.c")
        print(f"       ./fsw/tryspace_defs/targets.cmake")
        print(f"  4. Add the component to the GSW definitions:")
        print(f"       ./gsw/src/main/yamcs/etc/etc/yamcs.nos3.yaml")
        print(f"  5. Build like you would normally and confirm new component runs")
        print(f"  6. Customize the component for your specific needs")
        print()
        
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
