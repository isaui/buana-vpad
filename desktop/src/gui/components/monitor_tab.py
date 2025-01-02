from PyQt6.QtWidgets import (
    QWidget, QVBoxLayout, QHBoxLayout, 
    QLabel, QFrame, QGridLayout, QSizePolicy
)
from PyQt6.QtCore import Qt, QSize
from PyQt6.QtGui import QResizeEvent

from src.utils.server_events import server_events

class ResponsiveControllerVisual(QWidget):
    def __init__(self):
        super().__init__()
        self.base_width = 400
        self.base_height = 300
        self.aspect_ratio = self.base_width / self.base_height
        self.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Expanding)
        
    def resizeEvent(self, event: QResizeEvent):
        super().resizeEvent(event)
        parent_width = self.parent().width() if self.parent() else self.width()
        parent_height = self.parent().height() if self.parent() else self.height()
        
        # Calculate size while maintaining aspect ratio
        if parent_width / parent_height > self.aspect_ratio:
            # Width is too wide, scale based on height
            new_height = min(parent_height, self.base_height)
            new_width = new_height * self.aspect_ratio
        else:
            # Height is too tall, scale based on width
            new_width = min(parent_width, self.base_width)
            new_height = new_width / self.aspect_ratio
            
        self.setFixedSize(int(new_width), int(new_height))

class ControllerCard(QFrame):
    def __init__(self, slot_number: int):
        super().__init__()
        self.slot_number = slot_number
        self.init_ui()
        
    def init_ui(self):
        # Set frame style dan size policy untuk responsive scaling
        self.setFrameStyle(QFrame.Shape.Box | QFrame.Shadow.Plain)
        self.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Expanding)
        # Minimum size yang lebih kecil untuk mendukung responsive layout
        self.setMinimumSize(400, 400)  # Sesuaikan dengan ukuran minimum controller
        
        # Dark theme styling
        self.setStyleSheet("""
            QFrame {
                background: #1a1a1a;
                border: 2px solid #333333;
                border-radius: 15px;
            }
            QLabel {
                color: #ffffff;
                font-family: 'Segoe UI', Arial, sans-serif;
            }
            QLabel[status="disconnected"] {
                color: #ff4d4d;
                font-weight: bold;
                padding: 5px 10px;
                background: rgba(255, 77, 77, 0.1);
                border-radius: 10px;
            }
            QLabel[status="connected"] {
                color: #4dff4d;
                font-weight: bold;
                padding: 5px 10px;
                background: rgba(77, 255, 77, 0.1);
                border-radius: 10px;
            }
            QLabel[type="device"] {
                color: #999999;
                font-style: italic;
                padding: 5px;
                background: rgba(153, 153, 153, 0.1);
                border-radius: 5px;
            }
            QLabel[type="header"] {
                color: #ffffff;
                font-size: 18px;
                font-weight: bold;
                padding: 5px;
            }
        """)
        
        # Main vertical layout with dynamic margins
        layout = QVBoxLayout(self)
        layout.setContentsMargins(15, 15, 15, 15)
        layout.setSpacing(10)
        
        # Header container
        header_container = QWidget()
        header_layout = QHBoxLayout(header_container)
        header_layout.setContentsMargins(0, 0, 0, 0)
        
        # Header with slot number and status
        header = QLabel(f"Controller #{self.slot_number}")
        header.setProperty("type", "header")
        
        self.status_label = QLabel("Disconnected")
        self.status_label.setProperty("status", "disconnected")
        
        header_layout.addWidget(header)
        header_layout.addStretch()
        header_layout.addWidget(self.status_label)
        
        # Device info container
        device_container = QWidget()
        device_layout = QHBoxLayout(device_container)
        device_layout.setContentsMargins(0, 0, 0, 0)
        
        self.device_name = QLabel("No Device")
        self.device_name.setProperty("type", "device")
        device_layout.addWidget(self.device_name)
        device_layout.addStretch()
        
        # Add header and device containers
        layout.addWidget(header_container)
        layout.addWidget(device_container)
        
        # Controller visual container with centering
        visual_container = QWidget()
        visual_container.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Expanding)
        visual_layout = QVBoxLayout(visual_container)
        visual_layout.setContentsMargins(0, 0, 0, 0)
        
        # Add responsive controller visual
        from src.gui.components.controller_visual import ControllerVisual
        self.controller_visual = ControllerVisual()
        self.controller_visual.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Expanding)
        
        visual_layout.addWidget(self.controller_visual, 0, Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(visual_container, 1)  # Give it more stretch
        
    def resizeEvent(self, event):
        super().resizeEvent(event)
        # Recalculate margins based on size
        width = event.size().width()
        height = event.size().height()
        margin = min(width, height) // 30  # Dynamic margin scaling
        self.layout().setContentsMargins(margin, margin, margin, margin)
        
    def update_status(self, connected: bool, device_name: str = "", device_id: str = ""):
        if connected:
            self.status_label.setText("Connected")
            self.status_label.setProperty("status", "connected")
            self.device_name.setText(device_name)
        else:
            self.status_label.setText("Disconnected")
            self.status_label.setProperty("status", "disconnected")
            self.device_name.setText("No Device")
            self.controller_visual.reset_states()
        
        # Force style refresh
        self.status_label.style().unpolish(self.status_label)
        self.status_label.style().polish(self.status_label)
            
    def update_button(self, button_id: str, pressed: bool, value: float = 1.0):
        self.controller_visual.update_button(button_id, pressed, value)
        
    def update_stick(self, stick: str, dx: float, dy: float):
        self.controller_visual.update_stick(stick, dx, dy)
        
    def update_dpad(self, up: bool, right: bool, down: bool, left: bool):
        self.controller_visual.update_dpad(up, right, down, left)

class ConnectionsMonitorTab(QWidget):
    def __init__(self):
        super().__init__()
        self.controller_cards = []
        self.active_cards = {} 
        self.init_ui()
        self.connect_events()

    def connect_events(self):
        # Connect to server events
        server_events.update_controller_card.connect(self.handle_controller_update)
        server_events.server_stopped.connect(self.handle_server_stopped)
        server_events.controller_input.connect(self.handle_controller_input)

    def handle_controller_input(self, device_id: str, input_data: dict):
        """Handle input dari controller specific device"""
        if device_id not in self.active_cards:
            return
        card = self.controller_cards[self.active_cards[device_id]]
        # Update buttons
        button_states = input_data.get("buttonStates", {})
        for button_id, state in button_states.items():
            card.update_button(
                button_id, 
                state.get("isPressed", False),
                state.get("value", 1.0)
            )
        
        # Update sticks
        left_joy = input_data.get("leftJoystickState", {})
        if left_joy:
            card.update_stick(
                "left",
                left_joy.get("dx", 0),
                left_joy.get("dy", 0)
            )
            
        right_joy = input_data.get("rightJoystickState", {})
        if right_joy:
            card.update_stick(
                "right",
                right_joy.get("dx", 0),
                right_joy.get("dy", 0)
            )
        
        # Update DPAD
        dpad = input_data.get("dpadState", {})
        if dpad:
            card.update_dpad(
                dpad.get("upPressed", False),
                dpad.get("rightPressed", False),
                dpad.get("downPressed", False),
                dpad.get("leftPressed", False)
            )

    def handle_server_stopped(self):
        """Reset all controller cards when server stops"""
        # Reset semua card ke status disconnected
        for card in self.controller_cards:
            card.update_status(False)
        
        # Clear tracking active cards
        self.active_cards.clear()

    def handle_controller_update(self, controller_info: dict):
        """Handle controller card updates"""
        device_id = controller_info.get("device_id", "")
        connected = controller_info.get("connected", False)
        
        if connected:
            # Jika belum ada di active_cards, cari index yang available
            if device_id not in self.active_cards:
                # Cek index mana yang masih kosong
                used_indices = set(self.active_cards.values())
                available_indices = [i for i in range(len(self.controller_cards)) if i not in used_indices]
                
                if available_indices:
                    index = available_indices[0]
                    self.active_cards[device_id] = index
                else:
                    return  # Tidak ada slot tersedia
            
            index = self.active_cards[device_id]
        else:
            # Jika disconnect, ambil indexnya lalu hapus dari tracking
            if device_id not in self.active_cards:
                return
            index = self.active_cards[device_id]
            del self.active_cards[device_id]
        
        # Update card di index tersebut
        self.controller_cards[index].update_status(
            connected,
            controller_info.get("device_name", ""),
            device_id
        )
        
    def init_ui(self):
        # Dark theme for main widget
        self.setStyleSheet("""
            QWidget {
                background: #121212;
            }
            QScrollBar:vertical {
                background: #2a2a2a;
                width: 12px;
                margin: 0px;
            }
            QScrollBar::handle:vertical {
                background: #404040;
                border-radius: 6px;
                min-height: 20px;
                margin: 2px;
            }
            QScrollBar::handle:vertical:hover {
                background: #4a4a4a;
            }
            QScrollBar::add-line:vertical, QScrollBar::sub-line:vertical {
                height: 0px;
            }
            QScrollBar::add-page:vertical, QScrollBar::sub-page:vertical {
                background: none;
            }
        """)

        # Create scroll area untuk vertical scrolling
        from PyQt6.QtWidgets import QScrollArea
        scroll = QScrollArea(self)
        scroll.setWidgetResizable(True)
        scroll.setHorizontalScrollBarPolicy(Qt.ScrollBarPolicy.ScrollBarAlwaysOff)
        scroll.setVerticalScrollBarPolicy(Qt.ScrollBarPolicy.ScrollBarAsNeeded)
        scroll.setStyleSheet("QScrollArea { border: none; }")

        # Container untuk grid
        container = QWidget()
        scroll.setWidget(container)

        # Main layout untuk scroll area
        main_layout = QVBoxLayout(self)
        main_layout.setContentsMargins(0, 0, 0, 0)
        main_layout.addWidget(scroll)
        
        # Grid layout untuk cards
        self.grid = QGridLayout(container)
        self.grid.setSpacing(15)
        self.grid.setContentsMargins(15, 15, 15, 15)
        
        # Create 4 controller cards
        for i in range(4):
            card = ControllerCard(i + 1)
            self.controller_cards.append(card)
            # Initial placement will be updated in resizeEvent
            self.grid.addWidget(card, i, 0)
    
    def resizeEvent(self, event):
        super().resizeEvent(event)
        width = event.size().width()
        
        # Reorganize grid based on width
        # Jika width cukup besar (>1000px), gunakan 2 kolom
        # Jika tidak, gunakan 1 kolom
        use_two_columns = width > 1000
        
        # Remove semua widget dari grid
        for card in self.controller_cards:
            self.grid.removeWidget(card)
        
        # Reassign widgets ke grid dengan layout baru
        for i, card in enumerate(self.controller_cards):
            if use_two_columns:
                row, col = divmod(i, 2)
                self.grid.addWidget(card, row, col)
            else:
                self.grid.addWidget(card, i, 0)
        
        # Update stretching
        if use_two_columns:
            for i in range(2):
                self.grid.setColumnStretch(i, 1)
        else:
            self.grid.setColumnStretch(0, 1)
            if self.grid.columnCount() > 1:
                self.grid.setColumnStretch(1, 0)
            
    def update_controller(self, slot: int, connected: bool, device_name: str = "", device_id: str = ""):
        if 0 <= slot < len(self.controller_cards):
            self.controller_cards[slot].update_status(connected, device_name, device_id)
            
    def update_input(self, slot: int, input_data: dict):
        if 0 <= slot < len(self.controller_cards):
            card = self.controller_cards[slot]
            
            # Update buttons
            button_states = input_data.get("buttonStates", {})
            for button_id, state in button_states.items():
                card.update_button(
                    button_id, 
                    state.get("isPressed", False),
                    state.get("value", 1.0)
                )
            
            # Update sticks
            left_joy = input_data.get("leftJoystickState", {})
            if left_joy:
                card.update_stick(
                    "left",
                    left_joy.get("dx", 0),
                    -left_joy.get("dy", 0)  # Invert Y
                )
                
            right_joy = input_data.get("rightJoystickState", {})
            if right_joy:
                card.update_stick(
                    "right",
                    right_joy.get("dx", 0),
                    -right_joy.get("dy", 0)  # Invert Y
                )
            
            # Update DPAD
            dpad = input_data.get("dpadState", {})
            if dpad:
                card.update_dpad(
                    dpad.get("upPressed", False),
                    dpad.get("rightPressed", False),
                    dpad.get("downPressed", False),
                    dpad.get("leftPressed", False)
                )