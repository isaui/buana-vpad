from PyQt6.QtWidgets import QWidget
from PyQt6.QtCore import Qt, QRect, QPoint, QRectF
from PyQt6.QtGui import QPainter, QColor, QPen, QBrush, QPainterPath, QFont

class ControllerVisual(QWidget):
    def __init__(self):
        super().__init__()
        self.setMinimumSize(400, 300)
        self.reset_states()
        
    def reset_states(self):
        """Reset semua state ke default"""
        self.states = {
            'dpad_up': False,
            'dpad_right': False,
            'dpad_down': False,
            'dpad_left': False,
            'button_a': {'pressed': False, 'value': 0},
            'button_b': {'pressed': False, 'value': 0},
            'button_x': {'pressed': False, 'value': 0},
            'button_y': {'pressed': False, 'value': 0},
            'bumper_l': {'pressed': False, 'value': 0},
            'bumper_r': {'pressed': False, 'value': 0},
            'trigger_l': {'pressed': False, 'value': 0},
            'trigger_r': {'pressed': False, 'value': 0},
            'stick_l': {'x': 0, 'y': 0},
            'stick_r': {'x': 0, 'y': 0},
            'button_start': {'pressed': False, 'value': 0},
            'button_select': {'pressed': False, 'value': 0}
        }
        self.update()
        
    def paintEvent(self, event):
        painter = QPainter(self)
        painter.setRenderHint(QPainter.RenderHint.Antialiasing)
        
        # Setup colors
        BLACK = QColor('#202020')
        GRAY = QColor('#404040')
        HIGHLIGHT = QColor('#606060')
        
        # Setup fonts
        small_font = QFont()
        small_font.setPointSize(6)
        
        normal_font = QFont()
        normal_font.setPointSize(8)
        
        # Draw controller body
        path = QPainterPath()
        
        # Base rectangle with rounded corners
        body_rect = QRectF(50, 50, 300, 180)
        path.addRoundedRect(body_rect, 40, 40)
        
        # Add grip extensions
        grip_left = QPainterPath()
        grip_left.moveTo(50, 140)
        grip_left.cubicTo(20, 140, 20, 180, 50, 180)
        
        grip_right = QPainterPath()
        grip_right.moveTo(350, 140)
        grip_right.cubicTo(380, 140, 380, 180, 350, 180)
        
        painter.setBrush(QBrush(BLACK))
        painter.setPen(QPen(GRAY, 2))
        painter.drawPath(path)

        # Draw Start and Select buttons
        for button, pos in [
            ('SELECT', (170, 115)),
            ('START', (210, 115))
        ]:
            state = self.states[f'button_{button.lower()}']
            color = QColor(min(80 + int(175*state['value']), 255), 64, 64) if state['pressed'] else GRAY
            painter.setBrush(QBrush(color))
            painter.drawRoundedRect(pos[0]-15, pos[1]-5, 30, 10, 5, 5)
            
            # Draw button label
            painter.setPen(Qt.GlobalColor.white)
            painter.setFont(small_font)
            painter.drawText(QRect(pos[0]-15, pos[1]-7, 30, 14),
                            Qt.AlignmentFlag.AlignCenter, button)
            painter.setPen(QPen(GRAY, 2))
        
        # Draw D-Pad (moved to left side)
        dpad_center = QPoint(150, 180)
        dpad_size = 15
        
        # D-Pad background
        painter.setBrush(QBrush(BLACK))
        painter.drawEllipse(dpad_center, 25, 25)
        
        # D-Pad left
        painter.setBrush(QBrush(GRAY)) 
        if self.states['dpad_left']:
            painter.setBrush(QBrush(HIGHLIGHT))
        painter.drawRect(dpad_center.x() - dpad_size*2, 
                        dpad_center.y() - dpad_size//2,
                        dpad_size*2,  
                        dpad_size)

        # D-Pad right
        painter.setBrush(QBrush(GRAY))  
        if self.states['dpad_right']:
            painter.setBrush(QBrush(HIGHLIGHT))
        painter.drawRect(dpad_center.x(), 
                        dpad_center.y() - dpad_size//2,
                        dpad_size*2,  
                        dpad_size)
                        
        # D-Pad up
        painter.setBrush(QBrush(GRAY))  
        if self.states['dpad_up']:
            painter.setBrush(QBrush(HIGHLIGHT))
        painter.drawRect(dpad_center.x() - dpad_size//2, 
                        dpad_center.y() - dpad_size*2,
                        dpad_size,
                        dpad_size*2)  

        # D-Pad down
        painter.setBrush(QBrush(GRAY))   
        if self.states['dpad_down']:
            painter.setBrush(QBrush(HIGHLIGHT))
        painter.drawRect(dpad_center.x() - dpad_size//2, 
                        dpad_center.y(),
                        dpad_size,
                        dpad_size*2)
        
        # Draw face buttons (moved to right side)
        button_positions = {
            'Y': (280, 90),
            'B': (310, 120),
            'A': (280, 150),
            'X': (250, 120)
        }
        
        button_states = {
            'Y': self.states['button_y'],
            'B': self.states['button_b'],
            'A': self.states['button_a'],
            'X': self.states['button_x']
        }
        
        # Draw button background circle
        painter.setBrush(QBrush(BLACK))
        painter.drawEllipse(QPoint(280, 120), 35, 35)
        
        for label, pos in button_positions.items():
            state = button_states[label]
            color = QColor(min(80 + int(175*state['value']), 255), 64, 64) if state['pressed'] else GRAY
            painter.setBrush(QBrush(color))
            painter.drawEllipse(QPoint(pos[0], pos[1]), 12, 12)
            
            # Draw button label
            painter.setPen(Qt.GlobalColor.white)
            painter.drawText(QRect(pos[0]-6, pos[1]-6, 12, 12), 
                            Qt.AlignmentFlag.AlignCenter, label)
            painter.setPen(QPen(GRAY, 2))
            
        # Draw bumpers with curved shape and labels
        for i, (state, x, label) in enumerate([
            (self.states['bumper_l'], 80, 'LB'),
            (self.states['bumper_r'], 220, 'RB')
        ]):
            color = QColor(min(80 + int(175*state['value']), 255), 64, 64) if state['pressed'] else GRAY
            
            bumper_path = QPainterPath()
            bumper_path.moveTo(x, 60)
            bumper_path.cubicTo(x+30, 60, x+60, 60, x+100, 60)
            bumper_path.lineTo(x+100, 70)
            bumper_path.cubicTo(x+60, 70, x+30, 70, x, 70)
            bumper_path.closeSubpath()
            
            painter.setBrush(QBrush(color))
            painter.drawPath(bumper_path)
            
            # Draw bumper label
            painter.setPen(Qt.GlobalColor.white)
            painter.setFont(normal_font)
            painter.drawText(QRect(x+40, 55, 20, 20),
                            Qt.AlignmentFlag.AlignCenter, label)
            painter.setPen(QPen(GRAY, 2))
            
        # Draw triggers with angled shape and labels
        for i, (state, x, label) in enumerate([
            (self.states['trigger_l'], 80, 'LT'),
            (self.states['trigger_r'], 220, 'RT')
        ]):
            color = QColor(min(80 + int(175*state['value']), 255), 64, 64) if state['pressed'] else GRAY
            
            trigger_path = QPainterPath()
            trigger_path.moveTo(x+20, 40)
            trigger_path.lineTo(x+80, 40)
            trigger_path.lineTo(x+90, 55)
            trigger_path.lineTo(x+10, 55)
            trigger_path.closeSubpath()
            
            painter.setBrush(QBrush(color))
            painter.drawPath(trigger_path)
            
            # Draw trigger label
            painter.setPen(Qt.GlobalColor.white)
            painter.setFont(normal_font)
            painter.drawText(QRect(x+40, 40, 20, 15),
                            Qt.AlignmentFlag.AlignCenter, label)
            painter.setPen(QPen(GRAY, 2))
            
        # Draw analog sticks with larger bases and labels
        for stick, base_pos, label in [
            ('stick_l', (120, 120), 'L'),
            ('stick_r', (250, 180), 'R')
        ]:
            state = self.states[stick]
            x = base_pos[0] + int(state['x'] * 20)
            y = base_pos[1] + int(state['y'] * 20)
            
            # Draw stick base
            painter.setBrush(QBrush(BLACK))
            painter.drawEllipse(QPoint(base_pos[0], base_pos[1]), 20, 20)
            
            # Draw stick position
            painter.setBrush(QBrush(HIGHLIGHT))
            painter.drawEllipse(QPoint(x, y), 15, 15)
            
            # Draw stick label
            painter.setPen(Qt.GlobalColor.white)
            painter.setFont(normal_font)
            painter.drawText(QRect(x-6, y-6, 12, 12),
                            Qt.AlignmentFlag.AlignCenter, label)
            painter.setPen(QPen(GRAY, 2))

    def update_button(self, button_id: str, pressed: bool, value: int = 1):
        """Update button state"""
        button_map = {
            '_A': 'button_a',
            '_B': 'button_b',
            '_X': 'button_x',
            '_Y': 'button_y',
            '_LB': 'bumper_l',
            '_RB': 'bumper_r',
            '_LT': 'trigger_l',
            '_RT': 'trigger_r',
            '_START': 'button_start',
            '_SELECT': 'button_select'
        }
        
        for suffix, state_key in button_map.items():
            if button_id.endswith(suffix):
                self.states[state_key] = {'pressed': pressed, 'value': value}
                self.update()
                break
                
    def update_stick(self, stick: str, dx: int, dy: int):
        """Update stick position"""
        if stick == 'left':
            self.states['stick_l'] = {'x': dx, 'y': dy}
        elif stick == 'right':
            self.states['stick_r'] = {'x': dx, 'y': dy}
        self.update()
        
    def update_dpad(self, up: bool, right: bool, down: bool, left: bool):
        """Update d-pad state"""
        self.states['dpad_up'] = up
        self.states['dpad_right'] = right
        self.states['dpad_down'] = down
        self.states['dpad_left'] = left
        # Add logs
        if any([up, right, down, left]):
            direction = []
            if up: direction.append("Up")
            if right: direction.append("Right") 
            if down: direction.append("Down")
            if left: direction.append("Left")
            print(f"DPAD pressed: {', '.join(direction)}")

        self.update()