import uuid
from fastapi import FastAPI, WebSocket
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from src.core.controller_manager import ControllerManager
from src.utils.config import settings
import socket
import asyncio

controller_manager = ControllerManager()
DEVICE_ID = str(uuid.uuid4())

@asynccontextmanager
async def lifespan(app: FastAPI):
   # UDP broadcast logic
   global udp_sockets, is_broadcasting
   udp_sockets = []

   try:
       network_interfaces = socket.getaddrinfo(socket.gethostname(), None)
       ip_addresses = set()

       # Filter untuk IPv4 addresses
       for info in network_interfaces:
           addr = info[4][0]
           if addr and not addr.startswith('127.') and ':' not in addr:
               ip_addresses.add(addr)

       print(f"Found network interfaces: {ip_addresses}")

       # Setup UDP sockets
       for ip in ip_addresses:
           try:
               sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
               sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
               sock.bind((ip, 0))
               udp_sockets.append(sock)
           except Exception as e:
               print(f"Failed to bind to {ip}: {e}")

       if not udp_sockets:
           raise Exception("No usable network interface found")

       is_broadcasting = True
       asyncio.create_task(broadcast_presence())
       yield

   except Exception as e:
       print(f"Setup error: {e}")
       raise
   finally:
       is_broadcasting = False
       for sock in udp_sockets:
           sock.close()
       udp_sockets.clear()

async def broadcast_presence():
   global udp_sockets, is_broadcasting
   message = f"{settings.APP_NAME}|{settings.PORT}|{DEVICE_ID}"

   while is_broadcasting:
       try:
           for sock in udp_sockets:
               sock.sendto(
                   message.encode(),
                   ('255.255.255.255', settings.BROADCAST_PORT)
               )
           await asyncio.sleep(2)
       except Exception as e:
           print(f"Broadcasting error: {e}")
           await asyncio.sleep(2)

app = FastAPI(title=settings.APP_NAME, lifespan=lifespan)

# CORS middleware
app.add_middleware(
   CORSMiddleware,
   allow_origins=["*"],
   allow_credentials=True,
   allow_methods=["*"],
   allow_headers=["*"],
)

@app.get("/")
async def root():
   return {"status": "running"}

@app.websocket("/ws/controller/{device_id}")
async def controller_endpoint(websocket: WebSocket, device_id: str):
   await websocket.accept()
   client = None
   
   try:
       # Wait for initial connect message
       initial_data = await websocket.receive_json()
       if initial_data.get("type") == "connect":
           device_name = initial_data.get("device_name", "Unknown Device")
           
           try:
               client = await controller_manager.add_client(device_id, device_name)
               await websocket.send_json({
                   "type": "connect_success"
               })
           except Exception as e:
               await websocket.send_json({
                   "type": "connect_error",
                   "message": str(e)
               })
               return

       while True:
           data = await websocket.receive_json()
           
           if data.get("type") == "ping":
               await websocket.send_json({"type": "pong"})
               
           elif data.get("type") == "controller_input" and client:
               try:
                   await controller_manager.handle_input(
                       device_id,
                       data.get("data", {})
                   )
               except Exception as e:
                   print(f"Error handling input: {e}")
                   
   except Exception as e:
       print(f"Error in websocket: {e}")
   finally:
       if client:
           await controller_manager.remove_client(device_id)