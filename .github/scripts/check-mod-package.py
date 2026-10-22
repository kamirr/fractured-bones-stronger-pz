from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
MOD_ID = "FracturedBonesStronger"
MOD_DIR = ROOT / "Contents" / "mods" / MOD_ID
INFO = MOD_DIR / "mod.info"
SANDBOX_OPTIONS = MOD_DIR / "media" / "sandbox-options.txt"
GAMEPLAY_SCRIPT = MOD_DIR / "media" / "lua" / "shared" / "FractureProtection.lua"
SANDBOX_TRANSLATIONS = MOD_DIR / "media" / "lua" / "shared" / "Translate" / "EN" / "Sandbox_EN.txt"


def main() -> None:
    if not INFO.is_file():
        raise SystemExit(f"Missing mod metadata: {INFO.relative_to(ROOT)}")

    fields: dict[str, str] = {}
    for line_number, raw_line in enumerate(INFO.read_text(encoding="utf-8").splitlines(), 1):
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if "=" not in line:
            raise SystemExit(f"Invalid mod.info line {line_number}: expected key=value")
        key, value = (part.strip() for part in line.split("=", 1))
        if not key or not value:
            raise SystemExit(f"Invalid mod.info line {line_number}: key and value are required")
        if key in fields:
            raise SystemExit(f"Duplicate mod.info field on line {line_number}: {key}")
        fields[key] = value

    for required in ("name", "id", "description"):
        if not fields.get(required):
            raise SystemExit(f"mod.info is missing required field: {required}")
    if fields["id"] != MOD_ID:
        raise SystemExit(f"mod.info id must match its folder name ({MOD_ID})")
    for required_file in (SANDBOX_OPTIONS, GAMEPLAY_SCRIPT, SANDBOX_TRANSLATIONS):
        if not required_file.is_file():
            raise SystemExit(f"Missing mod file: {required_file.relative_to(ROOT)}")

    sandbox_options = SANDBOX_OPTIONS.read_text(encoding="utf-8")
    expected_option = (
        "option FracturedBonesStronger.PreventionChance",
        "type = integer,",
        "default = 50,",
        "min = 0,",
        "max = 100,",
    )
    if not all(value in sandbox_options for value in expected_option):
        raise SystemExit("PreventionChance must be an integer sandbox option from 0 to 100, defaulting to 50")
    expected_test_option = (
        "option FracturedBonesStronger.EnableTestCommands",
        "type = boolean,",
        "default = false,",
    )
    if not all(value in sandbox_options for value in expected_test_option):
        raise SystemExit("EnableTestCommands must be a default-off boolean sandbox option")
    translations = SANDBOX_TRANSLATIONS.read_text(encoding="utf-8")
    for key in (
        "Sandbox_FBS_Page",
        "Sandbox_FBS_PreventionChance",
        "Sandbox_FBS_PreventionChance_tooltip",
        "Sandbox_FBS_EnableTestCommands",
        "Sandbox_FBS_EnableTestCommands_tooltip",
    ):
        if key not in translations:
            raise SystemExit(f"Missing sandbox translation: {key}")

    print(f"Validated Project Zomboid package: {fields['name']} ({fields['id']})")


if __name__ == "__main__":
    main()
