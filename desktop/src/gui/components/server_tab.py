from PyQt6.QtWidgets import (
    QWidget, QVBoxLayout, QHBoxLayout, 
    QPushButton, QLabel, QTextEdit,
    QGroupBox, QSpinBox, QMessageBox,
    QScrollArea
)
from PyQt6.QtCore import Qt
from PyQt6.QtGui import QFont, QPalette, QColor
from src.utils.config import settings
import socket
from src.utils.server_events import server_events
import asyncio

class DarkGroupBox(QGroupBox):
    def __init__(self, title="", parent=None):
        super().__init__(title, parent)
        self.setStyleSheet("""
            QGroupBox {
                background-color: #1a1a1a;
                border: 2px solid #333333;
                border-radius: 8px;
                margin-top: 12px;
                padding-top: 10px;
                font-weight: bold;
                color: #ffffff;
            }
            QGroupBox::title {
                subcontrol-origin: margin;
                subcontrol-position: top left;
                padding: 0 5px;
                margin-left: 10px;
                background-color: #1a1a1a;
            }
        """)

class ServerControlTab(QWidget):
    def __init__(self, main_window):
        super().__init__()
        self.main_window = main_window
        self.server_running = False
        self.init_ui()
        self.connect_events()
        self.setup_styles()
        
    def setup_styles(self):
        # Main widget dark theme
        self.setStyleSheet("""
            QWidget {
                background-color: #121212;
                color: #ffffff;
                font-family: 'Segoe UI', Arial, sans-serif;
            }
            QLabel {
                color: #ffffff;
                padding: 2px;
            }
            QLabel[type="header"] {
                font-size: 16px;
                font-weight: bold;
                color: #ffffff;
            }
            QLabel[type="status"] {
                padding: 5px 10px;
                border-radius: 5px;
                font-weight: bold;
            }
            QLabel[status="running"] {
                background-color: rgba(77, 255, 77, 0.1);
                color: #4dff4d;
            }
            QLabel[status="stopped"] {
                background-color: rgba(255, 77, 77, 0.1);
                color: #ff4d4d;
            }
            QLabel[type="info"] {
                color: #999999;
            }
            QLabel[type="note"] {
                color: #666666;
                font-style: italic;
            }
            QPushButton {
                background-color: #2d2d2d;
                border: none;
                padding: 8px 16px;
                border-radius: 5px;
                color: white;
                font-weight: bold;
                min-width: 100px;
            }
            QPushButton:hover {
                background-color: #3d3d3d;
            }
            QPushButton:pressed {
                background-color: #404040;
            }
            QPushButton:disabled {
                background-color: #1a1a1a;
                color: #666666;
            }
            QPushButton#start {
                background-color: #2d5a27;
            }
            QPushButton#start:hover {
                background-color: #367032;
            }
            QPushButton#stop {
                background-color: #802020;
            }
            QPushButton#stop:hover {
                background-color: #993333;
            }
            QSpinBox {
                background-color: #2d2d2d;
                border: 1px solid #404040;
                border-radius: 4px;
                padding: 4px;
                color: white;
            }
            QSpinBox:disabled {
                background-color: #1a1a1a;
                color: #666666;
            }
            QTextEdit {
                background-color: #1a1a1a;
                border: 2px solid #333333;
                border-radius: 8px;
                padding: 8px;
                color: #cccccc;
                font-family: 'Consolas', 'Courier New', monospace;
            }
            QScrollBar:vertical {
                background-color: #1a1a1a;
                width: 12px;
                margin: 0px;
            }
            QScrollBar::handle:vertical {
                background-color: #404040;
                border-radius: 6px;
                min-height: 20px;
                margin: 2px;
            }
            QScrollBar::handle:vertical:hover {
                background-color: #4d4d4d;
            }
            QScrollBar::add-line:vertical, QScrollBar::sub-line:vertical {
                height: 0px;
            }
            QScrollBar::add-page:vertical, QScrollBar::sub-page:vertical {
                background: none;
            }
        """)
        
    def connect_events(self):
        server_events.server_started.connect(self.handle_server_started)
        server_events.server_stopped.connect(self.handle_server_stopped)
        server_events.server_error.connect(self.handle_server_error)
        server_events.log_received.connect(self.log_message)
        
    def init_ui(self):
        # Create main scroll area
        scroll = QScrollArea(self)
        scroll.setWidgetResizable(True)
        scroll.setHorizontalScrollBarPolicy(Qt.ScrollBarPolicy.ScrollBarAlwaysOff)
        scroll.setStyleSheet("QScrollArea { border: none; }")

        # Main container for scrollable content
        container = QWidget()
        scroll.setWidget(container)
        
        # Main layout
        main_layout = QVBoxLayout(self)
        main_layout.setContentsMargins(0, 0, 0, 0)
        main_layout.addWidget(scroll)
        
        layout = QVBoxLayout(container)
        layout.setSpacing(15)
        layout.setContentsMargins(20, 20, 20, 20)
        
        # Server status section
        status_group = DarkGroupBox("Server Status")
        status_layout = QHBoxLayout()
        
        status_header = QLabel("Current Status:")
        status_header.setProperty("type", "header")
        self.status_label = QLabel("Stopped")
        self.status_label.setProperty("type", "status")
        self.status_label.setProperty("status", "stopped")
        
        status_layout.addWidget(status_header)
        status_layout.addWidget(self.status_label)
        status_layout.addStretch()
        status_group.setLayout(status_layout)
        
        # Port configuration section
        port_group = DarkGroupBox("Port Configuration")
        port_layout = QHBoxLayout()
        
        port_label = QLabel("Port Number:")
        port_label.setProperty("type", "info")
        self.port_spinbox = QSpinBox()
        self.port_spinbox.setRange(1024, 65535)
        self.port_spinbox.setValue(settings.PORT)
        self.port_spinbox.valueChanged.connect(self.port_changed)
        
        port_layout.addWidget(port_label)
        port_layout.addWidget(self.port_spinbox)
        port_layout.addStretch()
        port_group.setLayout(port_layout)
        
        # Connection information section
        info_group = DarkGroupBox("Connection Information")
        info_layout = QVBoxLayout()
        
        # Instructions
        instructions = QLabel("To connect from your device, use any of these addresses:")
        instructions.setProperty("type", "info")
        instructions.setWordWrap(True)
        info_layout.addWidget(instructions)
        
        # Network interfaces
        interfaces = self.get_network_interfaces()
        if interfaces:
            for interface_name, ip in interfaces.items():
                interface_container = QWidget()
                interface_layout = QHBoxLayout(interface_container)
                interface_layout.setContentsMargins(0, 5, 0, 5)
                
                icon = "🌐" if "WiFi" in interface_name else "🔌"
                interface_label = QLabel(f"{icon} {interface_name}")
                interface_label.setProperty("type", "header")
                ip_label = QLabel(ip)
                ip_label.setProperty("type", "info")
                
                interface_layout.addWidget(interface_label)
                interface_layout.addWidget(ip_label)
                interface_layout.addStretch()
                
                info_layout.addWidget(interface_container)
        
        # Port information
        port_info = QLabel(f"Port: {settings.PORT}")
        port_info.setProperty("type", "info")
        info_layout.addWidget(port_info)
        
        # Network note
        note = QLabel("Note: Your device must be on the same network as this computer to connect.")
        note.setProperty("type", "note")
        note.setWordWrap(True)
        info_layout.addWidget(note)
        
        info_group.setLayout(info_layout)
        
        # Control buttons
        button_group = DarkGroupBox("Server Control")
        button_layout = QHBoxLayout()
        
        self.start_button = QPushButton("Start Server")
        self.start_button.setObjectName("start")
        self.stop_button = QPushButton("Stop Server")
        self.stop_button.setObjectName("stop")
        self.stop_button.setEnabled(False)
        
        button_layout.addWidget(self.start_button)
        button_layout.addWidget(self.stop_button)
        button_layout.addStretch()
        button_group.setLayout(button_layout)
        
        # Log viewer
        log_group = DarkGroupBox("Server Log")
        log_layout = QVBoxLayout()
        
        self.log_viewer = QTextEdit()
        self.log_viewer.setReadOnly(True)
        self.log_viewer.setMinimumHeight(150)
        
        log_layout.addWidget(self.log_viewer)
        log_group.setLayout(log_layout)
        
        # Add all sections to main layout
        layout.addWidget(status_group)
        layout.addWidget(port_group)
        layout.addWidget(info_group)
        layout.addWidget(button_group)
        layout.addWidget(log_group)
        layout.addStretch()
        
        # Connect button signals
        self.start_button.clicked.connect(self.start_server)
        self.stop_button.clicked.connect(self.stop_server)

    def handle_server_started(self):
        self.server_running = True
        self.status_label.setText("Running")
        self.status_label.setProperty("status", "running")
        self.start_button.setEnabled(False)
        self.stop_button.setEnabled(True)
        self.port_spinbox.setEnabled(False)
        self.log_message("Server started successfully")
        self.status_label.style().unpolish(self.status_label)
        self.status_label.style().polish(self.status_label)
        
    def handle_server_stopped(self):
        self.server_running = False
        self.status_label.setText("Stopped")
        self.status_label.setProperty("status", "stopped")
        self.start_button.setEnabled(True)
        self.stop_button.setEnabled(False)
        self.port_spinbox.setEnabled(True)
        self.log_message("Server stopped")
        self.status_label.style().unpolish(self.status_label)
        self.status_label.style().polish(self.status_label)
        
    def handle_server_error(self, error: str):
        self.log_message(f"Server Error: {error}")
        self.handle_server_stopped()
        
    def port_changed(self, new_port: int):
        if self.server_running:
            return
            
        if new_port < 1024:
            QMessageBox.warning(self, "Invalid Port", "Port number must be above 1024!")
            self.port_spinbox.setValue(settings.PORT)
            return
            
        settings.PORT = new_port
        self.log_message(f"Port changed to: {new_port}")
        
    def start_server(self):
        if not self.server_running:
            self.log_message("Starting server...")
            asyncio.create_task(self.main_window.start_server())
        
    def stop_server(self):
        if self.server_running:
            self.log_message("Stopping server...")
            asyncio.create_task(self.main_window.stop_server())
        
    def log_message(self, message: str):
        self.log_viewer.append(message)
        # Auto-scroll to bottom
        scrollbar = self.log_viewer.verticalScrollBar()
        scrollbar.setValue(scrollbar.maximum())
        
    def get_network_interfaces(self) -> dict:
        import psutil
        interfaces = {}
        
        try:
            for iface, addrs in psutil.net_if_addrs().items():
                for addr in addrs:
                    if addr.family == socket.AF_INET and not addr.address.startswith('127.'):
                        stats = psutil.net_if_stats().get(iface)
                        if stats and stats.isup:
                            if "VMware" in iface or "VirtualBox" in iface:
                                continue
                            if "Ethernet" in iface:
                                clean_name = "Ethernet (LAN)"
                            elif "Wi-Fi" in iface or "Wireless" in iface:
                                clean_name = "WiFi"
                            else:
                                clean_name = iface.replace("(", "").replace(")", "")
                            interfaces[clean_name] = addr.address
        except Exception as e:
            self.log_message(f"Error getting network interfaces: {e}")
            
        return interfaces