from typing import Dict, Optional, Tuple

from src.utils.server_events import server_events


class ControllerManager:
    def __init__(self):
        self.controllers: Dict[str, dict] = {}  # {device_id: {gamepad, name, backend}}
        self.max_clients = 4

    @staticmethod
    def _create_gamepad() -> Tuple[object, object]:
        """Load the ViGEm backend only when a client actually connects.

        vgamepad initializes the ViGEmBus connection when it is imported, so importing
        it during application startup makes a missing driver crash the whole desktop UI.
        """
        try:
            import vgamepad as vg
        except Exception as exc:
            if "VIGEM_ERROR_BUS_NOT_FOUND" in str(exc):
                raise RuntimeError(
                    "ViGEmBus is not available. Install the ViGEmBus driver and restart BuanaVPad."
                ) from exc
            raise RuntimeError(
                f"Unable to load the virtual gamepad backend: {exc}"
            ) from exc

        try:
            return vg.VX360Gamepad(), vg
        except Exception as exc:
            if "VIGEM_ERROR_BUS_NOT_FOUND" in str(exc):
                raise RuntimeError(
                    "ViGEmBus is not available. Install the ViGEmBus driver and restart BuanaVPad."
                ) from exc
            raise RuntimeError(
                f"Unable to create the virtual gamepad: {exc}"
            ) from exc

    async def add_client(self, device_id: str, device_name: str) -> Optional[dict]:
        if len(self.controllers) >= self.max_clients:
            raise Exception("Maximum controllers reached")

        if device_id in self.controllers:
            raise Exception("Device already connected")

        gamepad, backend = self._create_gamepad()
        client = {
            "gamepad": gamepad,
            "name": device_name,
            "backend": backend,
        }

        controller_info = {
            "device_name": device_name,
            "device_id": device_id,
            "connected": True,
        }
        self.controllers[device_id] = client
        print(f"Client connected: {device_name} ({device_id})")
        server_events.emit_client_connected(device_id, device_name)
        server_events.emit_controller_update(controller_info=controller_info)
        return client

    async def remove_client(self, device_id: str):
        if device_id in self.controllers:
            client = self.controllers[device_id]
            print(f"Client disconnected: {client['name']} ({device_id})")
            controller_info = {
                "device_name": client['name'],
                "device_id": device_id,
                "connected": False,
            }
            server_events.emit_controller_update(controller_info=controller_info)
            server_events.emit_client_disconnected(device_id, client['name'])
            del self.controllers[device_id]

    async def handle_input(self, device_id: str, data: dict):
        if device_id not in self.controllers:
            return

        client = self.controllers[device_id]
        gamepad = client["gamepad"]
        backend = client["backend"]

        try:
            server_events.emit_controller_input(device_id, data)
            button_states = data.get("buttonStates", {})
            for button_id, state in button_states.items():
                self._handle_button(gamepad, backend, button_id, state)

            left_joy = data.get("leftJoystickState", {"dx": 0.0, "dy": 0.0})
            right_joy = data.get("rightJoystickState", {"dx": 0.0, "dy": 0.0})

            gamepad.left_joystick_float(
                x_value_float=left_joy.get("dx", 0.0),
                y_value_float=-left_joy.get("dy", 0.0)
            )

            gamepad.right_joystick_float(
                x_value_float=right_joy.get("dx", 0.0),
                y_value_float=-right_joy.get("dy", 0.0)
            )

            dpad = data.get("dpadState", {})
            self._handle_dpad(gamepad, backend, dpad)
            gamepad.update()

        except Exception as exc:
            print(f"Error processing input: {exc}")
            raise

    @staticmethod
    def _handle_button(gamepad, backend, button_id: str, state: dict):
        actual_button_id = button_id.split('_')[-1]

        button_mapping = {
            'A': backend.XUSB_BUTTON.XUSB_GAMEPAD_A,
            'B': backend.XUSB_BUTTON.XUSB_GAMEPAD_B,
            'X': backend.XUSB_BUTTON.XUSB_GAMEPAD_X,
            'Y': backend.XUSB_BUTTON.XUSB_GAMEPAD_Y,
            'LB': backend.XUSB_BUTTON.XUSB_GAMEPAD_LEFT_SHOULDER,
            'RB': backend.XUSB_BUTTON.XUSB_GAMEPAD_RIGHT_SHOULDER,
            'Start': backend.XUSB_BUTTON.XUSB_GAMEPAD_START,
            'Select': backend.XUSB_BUTTON.XUSB_GAMEPAD_BACK,
        }

        if actual_button_id in button_mapping:
            if state.get("isPressed"):
                gamepad.press_button(button=button_mapping[actual_button_id])
            else:
                gamepad.release_button(button=button_mapping[actual_button_id])
        elif actual_button_id == 'LT':
            gamepad.left_trigger_float(value_float=state.get("value", 0.0))
        elif actual_button_id == 'RT':
            gamepad.right_trigger_float(value_float=state.get("value", 0.0))

    @staticmethod
    def _handle_dpad(gamepad, backend, dpad_state: dict):
        if dpad_state.get("upPressed"):
            gamepad.press_button(button=backend.XUSB_BUTTON.XUSB_GAMEPAD_DPAD_UP)
        else:
            gamepad.release_button(button=backend.XUSB_BUTTON.XUSB_GAMEPAD_DPAD_UP)

        if dpad_state.get("downPressed"):
            gamepad.press_button(button=backend.XUSB_BUTTON.XUSB_GAMEPAD_DPAD_DOWN)
        else:
            gamepad.release_button(button=backend.XUSB_BUTTON.XUSB_GAMEPAD_DPAD_DOWN)

        if dpad_state.get("leftPressed"):
            gamepad.press_button(button=backend.XUSB_BUTTON.XUSB_GAMEPAD_DPAD_LEFT)
        else:
            gamepad.release_button(button=backend.XUSB_BUTTON.XUSB_GAMEPAD_DPAD_LEFT)

        if dpad_state.get("rightPressed"):
            gamepad.press_button(button=backend.XUSB_BUTTON.XUSB_GAMEPAD_DPAD_RIGHT)
        else:
            gamepad.release_button(button=backend.XUSB_BUTTON.XUSB_GAMEPAD_DPAD_RIGHT)
