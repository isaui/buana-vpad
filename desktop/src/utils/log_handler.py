import logging
from src.utils.server_events import server_events

class GUILogHandler(logging.Handler):
    def __init__(self):
        super().__init__()
        self.setFormatter(logging.Formatter('%(levelname)s: %(message)s'))
        
    def emit(self, record):
        try:
            msg = self.format(record)
            server_events.emit_log(msg, record.levelname)
        except Exception:
            self.handleError(record)

def setup_logging():
    # Get root logger
    root = logging.getLogger()
    root.setLevel(logging.INFO)
    
    # Remove existing handlers
    root.handlers = []
    
    # Add GUI handler
    gui_handler = GUILogHandler()
    root.addHandler(gui_handler)
    