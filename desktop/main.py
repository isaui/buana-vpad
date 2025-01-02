# main.py
import sys
import asyncio
import uvicorn
from PyQt6.QtWidgets import QApplication
from PyQt6.QtCore import QEventLoop
from src.api.app import app
from src.utils.config import settings
from src.gui.main_window import MainWindow
from src.utils.server_events import server_events
import qasync

class UvicornServer:
    def __init__(self):
        self.config = None
        self.server = None
        self._serve_task = None
        
    def _create_config(self):
        """Create fresh config with current settings"""
        return uvicorn.Config(
            app=app,
            host=settings.HOST,
            port=settings.PORT,
            reload=False,
            loop="asyncio"
        )
        
    async def start(self):
        """Start server"""
        if not self._serve_task:
            try:
                self.config = self._create_config()
                self.server = uvicorn.Server(self.config)
                self._serve_task = asyncio.create_task(self.server.serve())
                server_events.emit_server_start()
            except Exception as e:
                server_events.emit_server_error(str(e))
    
    async def stop(self):
        """Stop server"""
        if self._serve_task:
            try:
                if self.server:
                    self.server.should_exit = True
                    try:
                        await self.server.shutdown()
                        await asyncio.sleep(0.5)  # Give some time for cleanup
                    except Exception:
                        pass

                if not self._serve_task.done():
                    self._serve_task.cancel()
                    try:
                        await asyncio.wait_for(self._serve_task, timeout=2.0)
                    except (asyncio.CancelledError, asyncio.TimeoutError):
                        pass

            except Exception as e:
                server_events.emit_server_error(str(e))
            finally:
                # Clean up resources
                self._serve_task = None
                if hasattr(self, 'server'):
                    self.server = None
                if hasattr(self, 'config'):
                    self.config = None
                server_events.emit_server_stop()

async def main():
    # Create Qt Application
    app = QApplication.instance() or QApplication(sys.argv)
    
    # Create event loop
    loop = qasync.QEventLoop(app)
    asyncio.set_event_loop(loop)
    
    # Create server
    server = UvicornServer()
    
    # Create and show main window
    window = MainWindow(server)
    window.show()
    
    # Run event loop
    with loop:
        return await loop.run_forever()

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        pass
    finally:
        sys.exit(0)