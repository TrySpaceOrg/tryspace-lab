#!/usr/bin/env python3
"""
Orchestrator for tryspace-lab configuration.
Loads global, mission, and scenario YAMLs, merges them, and writes to active.yaml.
"""
import sys
import os
from jinja2 import Environment, FileSystemLoader
import yaml

CFG_DIR = os.path.dirname(os.path.abspath(__file__))
ACTIVE_PATH = os.path.join(CFG_DIR, "active.yaml")
BUILD_PATH = os.path.join(CFG_DIR, "build.yaml")
GLOBAL_CONFIG = os.path.join(CFG_DIR, "tryspace-config.yaml")


def fail(msg):
    print(f"[orchestrator] ERROR: {msg}", file=sys.stderr)
    sys.exit(1)


def load_yaml(path):
    if not os.path.exists(path):
        return None
    with open(path, "r") as f:
        return yaml.safe_load(f)


def main():
    # If active.yaml does not exist, create with defaults from global config
    active = load_yaml(ACTIVE_PATH)
    global_cfg = load_yaml(GLOBAL_CONFIG)
    if active is None:
        # Use first mission and scenario as defaults
        missions = global_cfg["build"]["missions"]
        if not missions:
            fail("No missions defined in global config.")
        mission = missions[0]["name"]
        mission_cfg_path = os.path.join(CFG_DIR, os.path.relpath(missions[0]["config_file"], CFG_DIR))
        mission_cfg = load_yaml(mission_cfg_path)
        scenarios = mission_cfg.get("scenarios", [])
        scenario = scenarios[0]["name"] if scenarios else "nominal"
        
        # Default spacecraft selection from global or mission config
        if "spacecraft" in global_cfg["build"] and global_cfg["build"]["spacecraft"]:
            spacecraft_list = global_cfg["build"]["spacecraft"]
        else:
            spacecraft_list = mission_cfg.get("spacecraft", [])
        spacecraft = spacecraft_list[0]["name"] if spacecraft_list else None
        
        active = {"mission": mission, "spacecraft": spacecraft, "scenario": scenario, "cli": "demo", "log_mode": "none"}
        with open(ACTIVE_PATH, "w") as f:
            yaml.safe_dump(active, f)
        print(f"[orchestrator] Created {ACTIVE_PATH} with defaults: mission={mission}, spacecraft={spacecraft}, scenario={scenario}")

    mission = active.get("mission", "drm")
    spacecraft = active.get("spacecraft", "sat-1")
    scenario = active.get("scenario", "nominal")
    cli_component = active.get("cli", "demo")
    log_mode = active.get("log", "none")

    # Find mission config file
    mission_entry = next((m for m in global_cfg["build"]["missions"] if m["name"] == mission), None)
    if not mission_entry:
        fail(f"Mission '{mission}' not found in global config.")
    mission_cfg_path = os.path.join(CFG_DIR, os.path.relpath(mission_entry["config_file"], CFG_DIR))
    mission_cfg = load_yaml(mission_cfg_path)

    # Find scenario config file
    scenario_entry = next((s for s in mission_cfg["scenarios"] if s["name"] == scenario), None)
    if not scenario_entry:
        fail(f"Scenario '{scenario}' not found in mission config.")
    scenario_cfg_path = os.path.join(CFG_DIR, os.path.relpath(scenario_entry["config_file"], CFG_DIR))
    scenario_cfg = load_yaml(scenario_cfg_path)

    # Load spacecraft config if specified
    spacecraft_cfg = {}
    if spacecraft:
        spacecraft_list = mission_cfg.get("spacecraft", [])
        spacecraft_entry = next((sc for sc in spacecraft_list if sc["name"] == spacecraft), None)
        if not spacecraft_entry:
            fail(f"Spacecraft '{spacecraft}' not found in mission config.")
        spacecraft_cfg_path = os.path.join(CFG_DIR, os.path.relpath(spacecraft_entry["config_file"], CFG_DIR))
        spacecraft_cfg = load_yaml(spacecraft_cfg_path)
        if not spacecraft_cfg:
            spacecraft_cfg = {}

    # Merge configs (minimal: just collect for now)
    merged = {
        "mission": mission,
        "spacecraft": spacecraft,
        "scenario": scenario,
        "global": global_cfg,
        "mission_cfg": mission_cfg,
        "spacecraft_cfg": spacecraft_cfg,
        "scenario_cfg": scenario_cfg,
    }

    # Write merged config to build.yaml
    with open(BUILD_PATH, "w") as f:
        yaml.safe_dump(merged, f)
    print(f"[orchestrator] Merged config written to {BUILD_PATH}")

    # Render config files for components
    # Determine which components to process based on spacecraft or fallback to mission components
    if spacecraft and merged["spacecraft_cfg"]:
        components = merged["spacecraft_cfg"].get("components", [])
    else:
        # Fallback to mission-level components for backward compatibility
        components = merged["mission_cfg"].get("components", [])
    
    for comp in components:
        comp_name = comp.get("name")
        if not comp_name:
            continue

        # Full cascading merge: fallback -> global -> mission -> spacecraft -> scenario -> scenario overrides
        # 1. Fallback config
        fallback_path = os.path.abspath(os.path.join(CFG_DIR, f'../comp/{comp_name}/support/device_config.yaml'))
        fallback_data = load_yaml(fallback_path)
        comp_cfg = dict(fallback_data.get(comp_name, {})) if fallback_data and fallback_data.get(comp_name) else {}

        # 2. Global config
        global_cfg_comp = merged["global"].get(comp_name, {})
        comp_cfg.update(global_cfg_comp)

        # 3. Mission config
        mission_cfg_comp = merged["mission_cfg"].get(comp_name, {})
        comp_cfg.update(mission_cfg_comp)

        # 4. Spacecraft config (NEW LAYER)
        if merged["spacecraft_cfg"]:
            spacecraft_cfg_comp = merged["spacecraft_cfg"].get(comp_name, {})
            comp_cfg.update(spacecraft_cfg_comp)

        # 5. Scenario config
        scenario_cfg_comp = merged["scenario_cfg"].get(comp_name, {})
        comp_cfg.update(scenario_cfg_comp)

        # 6. Scenario-level 'overrides' dict
        overrides = merged["scenario_cfg"].get("overrides", {})
        if overrides is None:
            overrides = {}
        comp_cfg.update(overrides)

        # Try to find a template for this component
        template_path = os.path.abspath(os.path.join(CFG_DIR, f'../comp/{comp_name}/support'))
        template_file = f'device_config.j2'
        template_full_path = os.path.join(template_path, template_file)
        if os.path.exists(template_full_path) and comp_cfg:
            env = Environment(loader=FileSystemLoader(template_path))
            template = env.get_template(template_file)
            output = template.render(config=comp_cfg)

            # Output path for the generated config (e.g., comp/<name>/shared/<name>_cfg.h)
            output_path = os.path.abspath(os.path.join(CFG_DIR, f'../comp/{comp_name}/shared/device_cfg.h'))
            os.makedirs(os.path.dirname(output_path), exist_ok=True)
            with open(output_path, 'w') as f:
                f.write(output)
            print(f"[orchestrator] device_cfg.h written to {output_path}")
        else:
            print(f"[orchestrator] No config or template found for component '{comp_name}', skipping.")

    # Render cli-compose.yaml from Jinja2 template using cli_component
    cli_template_path = os.path.abspath(os.path.join(CFG_DIR))
    cli_template_file = "cli-compose.j2"
    cli_template_full_path = os.path.join(cli_template_path, cli_template_file)
    cli_compose_output_path = os.path.join(CFG_DIR, "cli-compose.yaml")
    if os.path.exists(cli_template_full_path):
        env = Environment(loader=FileSystemLoader(cli_template_path))
        template = env.get_template(cli_template_file)
        output = template.render(cli_component=cli_component)
        with open(cli_compose_output_path, "w") as f:
            f.write(output)
        print(f"[orchestrator] cli-compose.yaml written to {cli_compose_output_path} (cli_component={cli_component})")
    else:
        print(f"[orchestrator] cli-compose.j2 template not found, skipping cli-compose.yaml generation.")

    # Render lab-compose.yaml from Jinja2 template using log_mode and spacecraft
    lab_template_path = os.path.abspath(os.path.join(CFG_DIR))
    lab_template_file = "lab-compose.j2"
    lab_template_full_path = os.path.join(lab_template_path, lab_template_file)
    lab_compose_output_path = os.path.join(CFG_DIR, "lab-compose.yaml")
    if os.path.exists(lab_template_full_path):
        env = Environment(loader=FileSystemLoader(lab_template_path))
        template = env.get_template(lab_template_file)
        output = template.render(log_mode=log_mode, spacecraft=spacecraft, mission=mission)
        with open(lab_compose_output_path, "w") as f:
            f.write(output)
        print(f"[orchestrator] lab-compose.yaml written to {lab_compose_output_path} (log_mode={log_mode}, spacecraft={spacecraft})")
    else:
        print(f"[orchestrator] lab-compose.j2 template not found, skipping lab-compose.yaml generation.")

    # Copy and manipulate spacecraft-specific FSW config files
    if spacecraft:
        build_cfg_dir = os.path.abspath(os.path.join(CFG_DIR, f'../build/{mission}/{spacecraft}/cfg'))
        baseline_cfg_dir = os.path.abspath(os.path.join(CFG_DIR, 'tryspace_defs'))
        os.makedirs(build_cfg_dir, exist_ok=True)

        # Copy all baseline config files to build/<mission>/<spacecraft>/cfg
        import shutil
        for item in os.listdir(baseline_cfg_dir):
            s = os.path.join(baseline_cfg_dir, item)
            d = os.path.join(build_cfg_dir, item)
            if os.path.isdir(s):
                if os.path.exists(d):
                    shutil.rmtree(d)
                shutil.copytree(s, d)
            else:
                shutil.copy2(s, d)
        print(f"[orchestrator] Baseline FSW config files copied to {build_cfg_dir}")

        # Manipulate cpu1_cfe_es_startup.scr to remove lines for components not enabled for the spacecraft
        startup_scr_path = os.path.join(build_cfg_dir, "cpu1_cfe_es_startup.scr")
        enabled_components = set()
        # Get enabled components from spacecraft_cfg (preferred) or mission_cfg
        if merged["spacecraft_cfg"] and "components" in merged["spacecraft_cfg"]:
            enabled_components = set(comp["name"] for comp in merged["spacecraft_cfg"]["components"] if "name" in comp)
        elif "components" in merged["mission_cfg"]:
            enabled_components = set(comp["name"] for comp in merged["mission_cfg"]["components"] if "name" in comp)

        if os.path.exists(startup_scr_path):
            with open(startup_scr_path, "r") as f:
                lines = f.readlines()
            new_lines = []
            # Only modify lines for spacecraft-specific components (adcs, demo, eps, radio)
            spacecraft_apps = {"adcs", "demo", "eps", "radio"}
            for line in lines:
                # Only process non-comment, non-blank lines before '!'
                if line.strip().startswith("!") or not line.strip():
                    new_lines.append(line)
                    continue
                # Check for CFE_APP lines for spacecraft-specific components
                if line.startswith("CFE_APP"):
                    parts = [p.strip() for p in line.split(",")]
                    if len(parts) > 1:
                        comp_name = parts[1]
                        if comp_name in spacecraft_apps:
                            # Only keep if enabled for this spacecraft
                            if comp_name in enabled_components:
                                new_lines.append(line)
                            else:
                                print(f"[orchestrator] Removing {comp_name} from startup script (not enabled for {spacecraft})")
                        else:
                            new_lines.append(line)
                    else:
                        new_lines.append(line)
                else:
                    new_lines.append(line)
            with open(startup_scr_path, "w") as f:
                f.writelines(new_lines)
            print(f"[orchestrator] Updated {startup_scr_path} to only include enabled spacecraft components: {sorted(enabled_components)}")
        else:
            print(f"[orchestrator] {startup_scr_path} not found, skipping manipulation.")

if __name__ == "__main__":
    main()
