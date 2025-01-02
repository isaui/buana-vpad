from PyQt6.QtCore import QUrl
from PyQt6.QtGui import QDesktopServices
from PyQt6.QtWidgets import QGroupBox, QLabel, QPushButton
from PyQt6.QtWidgets import (
    QWidget, QVBoxLayout,
    QLabel
)
from PyQt6.QtCore import Qt

class AuthorTab(QWidget):
    def __init__(self):
        super().__init__()
        self.init_ui()
        
    def init_ui(self):
        layout = QVBoxLayout(self)
        layout.setContentsMargins(20, 20, 20, 20)
        layout.setSpacing(20)
        
        # Author info
        author_group = QGroupBox("About The Author")
        author_group.setStyleSheet("""
            QGroupBox {
                background-color: #1a1a1a;
                border: 2px solid #333333;
                border-radius: 8px;
                margin-top: 12px;
                padding: 15px;
                font-weight: bold;
            }
            QGroupBox::title {
                subcontrol-origin: margin;
                padding: 0 5px;
                margin-left: 10px;
            }
        """)
        
        author_layout = QVBoxLayout(author_group)
        
        # Profile
        profile_label = QLabel("Isa Citra Buana")
        profile_label.setStyleSheet("font-size: 24px; font-weight: bold;")
        author_layout.addWidget(profile_label)
        
        # Links
        links = [
            ("🔗 LinkedIn", "https://linkedin.com/in/isacitra"),
            ("📦 GitHub Profile", "https://github.com/isaui"),
            ("🚀 Project Repository", "https://github.com/isaui/buana-vpad")
        ]
        
        for title, url in links:
            link_btn = QPushButton(title)
            link_btn.setCursor(Qt.CursorShape.PointingHandCursor)
            link_btn.setStyleSheet("""
                QPushButton {
                    background-color: #2d2d2d;
                    border: none;
                    padding: 12px;
                    border-radius: 6px;
                    color: white;
                    font-weight: bold;
                    text-align: left;
                }
                QPushButton:hover {
                    background-color: #3d3d3d;
                }
            """)
            link_btn.clicked.connect(lambda checked, url=url: QDesktopServices.openUrl(QUrl(url)))
            author_layout.addWidget(link_btn)
        
        # Add stretches for layout
        layout.addWidget(author_group)
        layout.addStretch()