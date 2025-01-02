from PyQt6.QtCore import QObject, pyqtSignal
import queue
from typing import Optional

class ServerEvents(QObject):
    # Define signals
    server_started = pyqtSignal()
    server_stopped = pyqtSignal()
    server_error = pyqtSignal(str)
    log_received = pyqtSignal(str)
    client_connected = pyqtSignal(str, str)  # device_id, device_name
    client_disconnected = pyqtSignal(str)  # device_id
    update_controller_card = pyqtSignal(dict) 
    controller_input = pyqtSignal(str, dict)
    
    def __init__(self):
        super().__init__()
        self.log_queue = queue.Queue()
        self.is_server_running = False
        
    def emit_server_start(self):
        self.is_server_running = True
        self.server_started.emit()
        self.emit_log("Server started")
        
    def emit_server_stop(self):
        self.is_server_running = False
        self.server_stopped.emit()
        self.emit_log("Server stopped")
        
    def emit_server_error(self, error: str):
        self.server_error.emit(error)
        self.emit_log(f"Error: {error}", level="ERROR")
        
    def emit_log(self, message: str, level: str = "INFO"):
        self.log_queue.put((level, message))
        self.log_received.emit(f"[{level}] {message}")
        
    def emit_client_connected(self, device_id: str, device_name: str):
        self.client_connected.emit(device_id, device_name)
        self.emit_log(f"Client connected: {device_name} ({device_id})")
        
    def emit_client_disconnected(self, device_id: str, device_name: str):
        self.client_disconnected.emit(device_id)
        self.emit_log(f"Client disconnected: {device_name} ({device_id})")
        
    def emit_controller_update(self, controller_info: dict):
        self.update_controller_card.emit(controller_info)

    def emit_controller_input(self, device_id: str, input_data: dict):
        formatted_data = {}
        
        # Handle button states
        button_states = input_data.get("buttonStates", {})
        formatted_buttons = {}
        for button_id, state in button_states.items():
            # Format: "_A", "_B", dst sesuai yang diharapkan ControllerVisual 
            formatted_buttons[f"_{button_id.upper()}"] = {
                "isPressed": state.get("isPressed", False), 
                "value": state.get("value", 0)
            }
        formatted_data["buttonStates"] = formatted_buttons
        
        # Handle dpad
        dpad = input_data.get("dpadState", {})
        formatted_data["dpadState"] = {
            "upPressed": dpad.get("upPressed", False),
            "rightPressed": dpad.get("rightPressed", False),
            "downPressed": dpad.get("downPressed", False),
            "leftPressed": dpad.get("leftPressed", False)
        }
        
        # Handle joysticks - format sudah sesuai
        formatted_data["leftJoystickState"] = input_data.get("leftJoystickState", {})
        formatted_data["rightJoystickState"] = input_data.get("rightJoystickState", {})
        
        self.controller_input.emit(device_id, formatted_data)

# Global instance
server_events = ServerEvents()