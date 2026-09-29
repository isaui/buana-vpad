import builtins
import importlib.util
import sys
import types
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).parents[1] / "src" / "core" / "controller_manager.py"


def load_controller_manager():
    fake_events_module = types.ModuleType("src.utils.server_events")
    fake_events_module.server_events = object()

    old_modules = {
        key: sys.modules.get(key)
        for key in ("src", "src.utils", "src.utils.server_events")
    }

    sys.modules.setdefault("src", types.ModuleType("src"))
    sys.modules.setdefault("src.utils", types.ModuleType("src.utils"))
    sys.modules["src.utils.server_events"] = fake_events_module

    try:
        spec = importlib.util.spec_from_file_location(
            "test_controller_manager_module", MODULE_PATH
        )
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module
    finally:
        for key, value in old_modules.items():
            if value is None:
                sys.modules.pop(key, None)
            else:
                sys.modules[key] = value


class ControllerManagerTests(unittest.TestCase):
    def test_create_gamepad_reports_missing_vigembus(self):
        module = load_controller_manager()
        real_import = builtins.__import__

        def failing_import(name, *args, **kwargs):
            if name == "vgamepad":
                raise RuntimeError("VIGEM_ERROR_BUS_NOT_FOUND")
            return real_import(name, *args, **kwargs)

        builtins.__import__ = failing_import
        try:
            with self.assertRaisesRegex(
                RuntimeError,
                r"ViGEmBus is not available\. Install the ViGEmBus driver",
            ):
                module.ControllerManager._create_gamepad()
        finally:
            builtins.__import__ = real_import

    def test_create_gamepad_uses_backend_without_touching_it_at_import(self):
        module = load_controller_manager()
        fake_vgamepad = types.ModuleType("vgamepad")

        class Buttons:
            XUSB_GAMEPAD_A = 1

        class FakeGamepad:
            pass

        fake_vgamepad.XUSB_BUTTON = Buttons
        fake_vgamepad.VX360Gamepad = FakeGamepad
        sys.modules["vgamepad"] = fake_vgamepad
        try:
            gamepad, backend = module.ControllerManager._create_gamepad()
            self.assertIsInstance(gamepad, FakeGamepad)
            self.assertIs(backend, fake_vgamepad)
        finally:
            sys.modules.pop("vgamepad", None)


if __name__ == "__main__":
    unittest.main()
