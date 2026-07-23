import yaml
from pathlib import Path

def load_config(config_path: str = "config/config.yaml") -> dict:
    path = Path(__file__).parent.parent / config_path
    if not path.exists():
        raise FileNotFoundError(f"Config file not found: {path}")
        
    with open(path, 'r') as f:
        return yaml.safe_load(f)
