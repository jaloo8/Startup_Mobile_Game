#!/usr/bin/env python3
"""
Backend smoke validator for Venture content and backend contracts.

Runs fast structural checks that do not require the Godot runtime.
Use this as a pre-flight pass before manual in-editor smoke testing.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Dict, Iterable, List, Set, Tuple


ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT / "src" / "data"
PRODUCT_OVERVIEW_PATH = ROOT / "src" / "ui" / "product" / "product_overview.gd"
GAME_STATE_PATH = ROOT / "src" / "autoload" / "game_state.gd"
FUNDRAISING_PATH = ROOT / "src" / "engine" / "fundraising_engine.gd"
EVENT_ENGINE_PATH = ROOT / "src" / "engine" / "event_engine.gd"

FEATURE_TYPES = {"saas", "consumer", "marketplace", "dev_tools"}
FOCUS_TYPES = {"saas", "consumer", "marketplace", "dev_tools"}
COMPANY_SIZES = {"startup", "growth", "enterprise"}
VC_TIERS = {"elite", "top", "mid", "emerging"}
HEADLINE_PLACEHOLDERS = {
    "competitor",
    "economy_label",
    "type_label",
    "company_name",
    "users",
    "total_quarters",
    "year",
    "quarter",
}
KNOWN_EFFECT_KEYS = {
    "ux_bonus",
    "stability_bonus",
    "churn_reduction",
    "revenue_mult",
    "user_growth_bonus",
    "reputation_bonus",
    "dau_bonus",
}


def _load_json(path: Path) -> object:
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def _require_file(path: Path, errors: List[str]) -> bool:
    if not path.exists():
        errors.append(f"missing file: {path.relative_to(ROOT)}")
        return False
    return True


def validate_features(data: object) -> Tuple[List[str], Set[str]]:
    errors: List[str] = []
    all_feature_ids: Set[str] = set()
    if not isinstance(data, dict):
        return ["features.json root must be an object"], all_feature_ids

    keys = set(data.keys())
    missing_types = FEATURE_TYPES - keys
    if missing_types:
        errors.append(f"features.json missing company types: {sorted(missing_types)}")

    for ctype in FEATURE_TYPES:
        entries = data.get(ctype, [])
        if not isinstance(entries, list):
            errors.append(f"features.{ctype} must be an array")
            continue
        if len(entries) < 10:
            errors.append(f"features.{ctype} has only {len(entries)} entries (expected at least 10)")

        ids_for_type: Set[str] = set()
        for idx, entry in enumerate(entries):
            pfx = f"features.{ctype}[{idx}]"
            if not isinstance(entry, dict):
                errors.append(f"{pfx} must be an object")
                continue

            fid = entry.get("id")
            if not isinstance(fid, str) or not fid.strip():
                errors.append(f"{pfx}.id must be a non-empty string")
                continue
            if fid in ids_for_type:
                errors.append(f"duplicate feature id in {ctype}: {fid}")
            ids_for_type.add(fid)
            all_feature_ids.add(fid)

            name = entry.get("name")
            if not isinstance(name, str) or not name.strip():
                errors.append(f"{pfx}.name must be a non-empty string")

            cost = entry.get("cost")
            if not isinstance(cost, (int, float)) or cost <= 0:
                errors.append(f"{pfx}.cost must be > 0")

            effects = entry.get("effects", {})
            if not isinstance(effects, dict):
                errors.append(f"{pfx}.effects must be an object")
            else:
                unknown_effects = set(effects.keys()) - KNOWN_EFFECT_KEYS
                if unknown_effects:
                    errors.append(f"{pfx}.effects has unknown keys: {sorted(unknown_effects)}")

            prereqs = entry.get("prerequisites", [])
            if not isinstance(prereqs, list):
                errors.append(f"{pfx}.prerequisites must be an array")
            else:
                for req in prereqs:
                    if not isinstance(req, str):
                        errors.append(f"{pfx}.prerequisites must contain strings only")

        # prerequisite integrity check within type
        for idx, entry in enumerate(entries):
            if not isinstance(entry, dict):
                continue
            fid = entry.get("id")
            if not isinstance(fid, str):
                continue
            prereqs = entry.get("prerequisites", [])
            if not isinstance(prereqs, list):
                continue
            for req in prereqs:
                if req not in ids_for_type:
                    errors.append(f"feature {ctype}:{fid} has unknown prerequisite: {req}")

    return errors, all_feature_ids


def validate_events(data: object) -> List[str]:
    errors: List[str] = []
    if not isinstance(data, list):
        return ["events.json root must be an array"]
    if not data:
        return ["events.json is empty"]

    ids: Set[str] = set()
    for idx, ev in enumerate(data):
        pfx = f"events[{idx}]"
        if not isinstance(ev, dict):
            errors.append(f"{pfx} must be an object")
            continue
        eid = ev.get("id")
        if not isinstance(eid, str) or not eid.strip():
            errors.append(f"{pfx}.id must be a non-empty string")
            continue
        if eid in ids:
            errors.append(f"duplicate event id: {eid}")
        ids.add(eid)

        title = ev.get("title")
        if not isinstance(title, str) or not title.strip():
            errors.append(f"{pfx}.title must be a non-empty string")

        choices = ev.get("choices", [])
        if not isinstance(choices, list) or not choices:
            errors.append(f"{pfx}.choices must be a non-empty array")
            continue
        for cidx, choice in enumerate(choices):
            cpfx = f"{pfx}.choices[{cidx}]"
            if not isinstance(choice, dict):
                errors.append(f"{cpfx} must be an object")
                continue
            label = choice.get("label")
            if not isinstance(label, str) or not label.strip():
                errors.append(f"{cpfx}.label must be a non-empty string")
            effects = choice.get("effects", {})
            if not isinstance(effects, dict):
                errors.append(f"{cpfx}.effects must be an object")

        weight = ev.get("weight", 1.0)
        if not isinstance(weight, (int, float)) or float(weight) <= 0.0:
            errors.append(f"{pfx}.weight must be > 0")

        cooldown = ev.get("cooldown_quarters", 0)
        if not isinstance(cooldown, int) or cooldown < 0:
            errors.append(f"{pfx}.cooldown_quarters must be an integer >= 0")

    return errors


def _find_placeholders(text: str) -> Set[str]:
    return set(re.findall(r"\{([a-zA-Z0-9_]+)\}", text))


def validate_headlines(data: object) -> List[str]:
    errors: List[str] = []
    if not isinstance(data, list):
        return ["headlines.json root must be an array"]
    if not data:
        return ["headlines.json is empty"]

    for idx, item in enumerate(data):
        pfx = f"headlines[{idx}]"
        if not isinstance(item, dict):
            errors.append(f"{pfx} must be an object")
            continue
        template = item.get("template", "")
        if not isinstance(template, str) or not template.strip():
            errors.append(f"{pfx}.template must be a non-empty string")
            continue

        econ = item.get("economy", None)
        if econ is not None and econ not in {"bull", "bear", "neutral"}:
            errors.append(f"{pfx}.economy must be one of bull/bear/neutral")

        placeholders = _find_placeholders(template)
        unknown = placeholders - HEADLINE_PLACEHOLDERS
        if unknown:
            errors.append(f"{pfx}.template has unknown placeholders: {sorted(unknown)}")

        variations = item.get("variations", [])
        if variations:
            if not isinstance(variations, list):
                errors.append(f"{pfx}.variations must be an array")
            else:
                for vidx, v in enumerate(variations):
                    if not isinstance(v, str) or not v.strip():
                        errors.append(f"{pfx}.variations[{vidx}] must be a non-empty string")
                    else:
                        unknown_v = _find_placeholders(v) - HEADLINE_PLACEHOLDERS
                        if unknown_v:
                            errors.append(
                                f"{pfx}.variations[{vidx}] has unknown placeholders: {sorted(unknown_v)}"
                            )

    return errors


def validate_glossary(data: object) -> List[str]:
    errors: List[str] = []
    if not isinstance(data, dict):
        return ["glossary.json root must be an object"]
    if not data:
        return ["glossary.json is empty"]

    for key, val in data.items():
        pfx = f"glossary[{key}]"
        if not isinstance(val, dict):
            errors.append(f"{pfx} must be an object")
            continue
        for field in ("term", "short", "tip"):
            fval = val.get(field)
            if not isinstance(fval, str) or not fval.strip():
                errors.append(f"{pfx}.{field} must be a non-empty string")
    return errors


def validate_vcs(data: object) -> List[str]:
    errors: List[str] = []
    if not isinstance(data, dict):
        return ["vcs.json root must be an object"]
    firms = data.get("firms", [])
    if not isinstance(firms, list) or not firms:
        return ["vcs.json.firms must be a non-empty array"]

    names: Set[str] = set()
    for idx, firm in enumerate(firms):
        pfx = f"vcs.firms[{idx}]"
        if not isinstance(firm, dict):
            errors.append(f"{pfx} must be an object")
            continue
        name = firm.get("name", "")
        if not isinstance(name, str) or not name.strip():
            errors.append(f"{pfx}.name must be a non-empty string")
        elif name in names:
            errors.append(f"duplicate VC firm name: {name}")
        else:
            names.add(name)

        tier = firm.get("tier", "mid")
        if tier not in VC_TIERS:
            errors.append(f"{pfx}.tier invalid: {tier}")

        prefs = firm.get("preferred_focus", [])
        if not isinstance(prefs, list):
            errors.append(f"{pfx}.preferred_focus must be an array")
        else:
            bad = [x for x in prefs if x not in FOCUS_TYPES]
            if bad:
                errors.append(f"{pfx}.preferred_focus has invalid values: {bad}")

        cmin = firm.get("check_min", 0)
        cmax = firm.get("check_max", 0)
        if not isinstance(cmin, (int, float)) or cmin < 0:
            errors.append(f"{pfx}.check_min must be >= 0")
        if not isinstance(cmax, (int, float)) or cmax < 0:
            errors.append(f"{pfx}.check_max must be >= 0")
        if cmin and cmax and cmin > cmax:
            errors.append(f"{pfx}.check_min cannot exceed check_max")
    return errors


def validate_competitors(data: object) -> List[str]:
    errors: List[str] = []
    if not isinstance(data, dict):
        return ["competitors.json root must be an object"]
    rows = data.get("competitors", [])
    if not isinstance(rows, list) or not rows:
        return ["competitors.json.competitors must be a non-empty array"]

    names: Set[str] = set()
    focus_counts = {k: 0 for k in FOCUS_TYPES}
    for idx, row in enumerate(rows):
        pfx = f"competitors[{idx}]"
        if not isinstance(row, dict):
            errors.append(f"{pfx} must be an object")
            continue
        name = row.get("name", "")
        if not isinstance(name, str) or not name.strip():
            errors.append(f"{pfx}.name must be a non-empty string")
            continue
        if name in names:
            errors.append(f"duplicate competitor name: {name}")
        names.add(name)

        focus = row.get("focus", "")
        if focus:
            if focus not in FOCUS_TYPES:
                errors.append(f"{pfx}.focus invalid: {focus}")
            else:
                focus_counts[focus] += 1

        size = row.get("size", "")
        if size and size not in COMPANY_SIZES:
            errors.append(f"{pfx}.size invalid: {size}")

    for focus, count in focus_counts.items():
        if count == 0:
            errors.append(f"no competitors tagged with focus '{focus}'")

    return errors


def _extract_visual_preset_ids(source: str) -> Set[str]:
    marker = "const VISUAL_PRESET_FEATURES := {"
    start = source.find(marker)
    if start == -1:
        return set()
    brace_start = source.find("{", start)
    if brace_start == -1:
        return set()
    depth = 0
    end = -1
    for i in range(brace_start, len(source)):
        ch = source[i]
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                end = i
                break
    if end == -1:
        return set()
    block = source[brace_start : end + 1]
    tokens = set(re.findall(r'"([a-z][a-z0-9_]+)"', block))
    return {t for t in tokens if "_" in t and t not in FEATURE_TYPES}


def validate_visual_presets(feature_ids: Set[str]) -> List[str]:
    errors: List[str] = []
    if not PRODUCT_OVERVIEW_PATH.exists():
        return [f"missing file: {PRODUCT_OVERVIEW_PATH.relative_to(ROOT)}"]
    src = PRODUCT_OVERVIEW_PATH.read_text(encoding="utf-8")
    ids = _extract_visual_preset_ids(src)
    if not ids:
        return ["could not extract VISUAL_PRESET_FEATURES IDs from product_overview.gd"]
    missing = sorted(i for i in ids if i not in feature_ids)
    if missing:
        errors.append(f"visual preset IDs missing in features.json: {missing}")
    return errors


def validate_difficulty_contracts() -> List[str]:
    errors: List[str] = []
    required_mult_keys = {
        "cash_mult",
        "churn_mult",
        "competitor_mult",
        "fundraise_amount_mult",
        "fundraise_threshold_shift",
        "event_pressure_mult",
    }

    if not GAME_STATE_PATH.exists():
        return [f"missing file: {GAME_STATE_PATH.relative_to(ROOT)}"]
    gs = GAME_STATE_PATH.read_text(encoding="utf-8")
    for difficulty in ("sandbox", "normal", "hardcore"):
        if f'"{difficulty}"' not in gs:
            errors.append(f"DIFFICULTY_MULTS missing '{difficulty}' block in game_state.gd")
    for key in required_mult_keys:
        if f'"{key}"' not in gs:
            errors.append(f"DIFFICULTY_MULTS missing key '{key}' in game_state.gd")

    if not FUNDRAISING_PATH.exists():
        errors.append(f"missing file: {FUNDRAISING_PATH.relative_to(ROOT)}")
    else:
        fr = FUNDRAISING_PATH.read_text(encoding="utf-8")
        if 'difficulty_mult("fundraise_amount_mult")' not in fr:
            errors.append("fundraising_engine.gd does not use difficulty_mult('fundraise_amount_mult')")
        if 'difficulty_mult("fundraise_threshold_shift")' not in fr:
            errors.append("fundraising_engine.gd does not use difficulty_mult('fundraise_threshold_shift')")

    if not EVENT_ENGINE_PATH.exists():
        errors.append(f"missing file: {EVENT_ENGINE_PATH.relative_to(ROOT)}")
    else:
        ee = EVENT_ENGINE_PATH.read_text(encoding="utf-8")
        if 'difficulty_mult("event_pressure_mult")' not in ee:
            errors.append("event_engine.gd does not use difficulty_mult('event_pressure_mult')")

    return errors


def main() -> int:
    errors: List[str] = []

    paths = {
        "features": DATA_DIR / "features.json",
        "events": DATA_DIR / "events.json",
        "headlines": DATA_DIR / "headlines.json",
        "glossary": DATA_DIR / "glossary.json",
        "vcs": DATA_DIR / "vcs.json",
        "competitors": DATA_DIR / "competitors.json",
    }
    for p in paths.values():
        _require_file(p, errors)
    if errors:
        for e in errors:
            print(f"[FAIL] {e}")
        return 1

    try:
        features_data = _load_json(paths["features"])
        events_data = _load_json(paths["events"])
        headlines_data = _load_json(paths["headlines"])
        glossary_data = _load_json(paths["glossary"])
        vcs_data = _load_json(paths["vcs"])
        competitors_data = _load_json(paths["competitors"])
    except Exception as exc:
        print(f"[FAIL] JSON load error: {exc}")
        return 1

    feature_errors, feature_ids = validate_features(features_data)
    errors.extend(feature_errors)
    errors.extend(validate_events(events_data))
    errors.extend(validate_headlines(headlines_data))
    errors.extend(validate_glossary(glossary_data))
    errors.extend(validate_vcs(vcs_data))
    errors.extend(validate_competitors(competitors_data))
    errors.extend(validate_visual_presets(feature_ids))
    errors.extend(validate_difficulty_contracts())

    if errors:
        print("Backend smoke check FAILED")
        for e in errors:
            print(f"[FAIL] {e}")
        print(f"Total failures: {len(errors)}")
        return 1

    print("Backend smoke check PASSED")
    print("Validated: features/events/headlines/glossary/vcs/competitors + visual presets + difficulty wiring")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
