from jinja2 import Environment, FileSystemLoader
#!/usr/bin/env python3
"""
Orchestrator for tryspace-lab configuration.
Loads global, mission, and scenario YAMLs, merges them, and writes to active.yaml.
"""
import sys
import os
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
        active = {"mission": mission, "scenario": scenario}
        with open(ACTIVE_PATH, "w") as f:
            yaml.safe_dump(active, f)
        print(f"[orchestrator] Created {ACTIVE_PATH} with defaults: mission={mission}, scenario={scenario}")

    mission = active.get("mission")
    scenario = active.get("scenario", "nominal")

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

    # Merge configs (minimal: just collect for now)
    merged = {
        "mission": mission,
        "scenario": scenario,
        "global": global_cfg,
        "mission_cfg": mission_cfg,
        "scenario_cfg": scenario_cfg,
    }

    # Write merged config to build.yaml
    with open(BUILD_PATH, "w") as f:
        yaml.safe_dump(merged, f)
    print(f"[orchestrator] Merged config written to {BUILD_PATH}")

    # Render config files for all components defined in the mission config
    components = merged["mission_cfg"].get("components", [])
    for comp in components:
        comp_name = comp.get("name")
        if not comp_name:
            continue

        # Full cascading merge: fallback -> global -> mission -> scenario -> scenario overrides
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

        # 4. Scenario config
        scenario_cfg_comp = merged["scenario_cfg"].get(comp_name, {})
        comp_cfg.update(scenario_cfg_comp)

        # 5. Scenario-level 'overrides' dict
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


if __name__ == "__main__":
    main()
