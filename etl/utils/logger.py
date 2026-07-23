import logging
import logging.config
import yaml
from pathlib import Path

def setup_logging(config_path: str = "config/logging.yaml", default_level: int = logging.INFO) -> logging.Logger:
    """Setup logging configuration from a YAML file."""
    path = Path(__file__).parent.parent / config_path
    
    # Ensure logs directory exists
    log_dir = Path(__file__).parent.parent / "logs"
    log_dir.mkdir(exist_ok=True)
    
    if path.exists():
        with open(path, 'rt') as f:
            config = yaml.safe_load(f.read())
        logging.config.dictConfig(config)
    else:
        logging.basicConfig(level=default_level)
        logging.warning(f"Logging configuration file not found at {path}. Using defaults.")
        
    return logging.getLogger("smap_etl")

logger = setup_logging()
