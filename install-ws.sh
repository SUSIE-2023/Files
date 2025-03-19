#!/bin/bash

# อัปเดตแพ็กเกจ
apt update -y && apt upgrade -y

# ติดตั้งแพ็กเกจที่จำเป็น
apt install -y python3 python3-pip screen dropbear

# ตั้งค่า Dropbear ให้ใช้พอร์ต 442 (สำหรับ SSH WebSocket)
echo "NO_START=0" > /etc/default/dropbear
echo "DROPBEAR_PORT=442" >> /etc/default/dropbear
echo "DROPBEAR_EXTRA_ARGS='-p 442 -p 22'" >> /etc/default/dropbear
systemctl restart dropbear

# ติดตั้ง WebSocket Proxy ที่พอร์ต 2086
cat <<EOF > /root/ws-python.py
import asyncio
import websockets
import subprocess

async def handler(websocket, path):
    process = subprocess.Popen(["nc", "127.0.0.1", "442"], stdin=subprocess.PIPE, stdout=subprocess.PIPE)
    try:
        while True:
            data = await websocket.recv()
            process.stdin.write(data.encode())
            process.stdin.flush()
            response = process.stdout.read(1024)
            await websocket.send(response.decode())
    except:
        process.kill()

start_server = websockets.serve(handler, "0.0.0.0", 2086)
asyncio.get_event_loop().run_until_complete(start_server)
asyncio.get_event_loop().run_forever()
EOF

# รัน WebSocket Proxy
screen -dmS ws-python python3 /root/ws-python.py

echo "✅ ติดตั้งเสร็จสิ้น! ใช้งาน SSH WebSocket ที่พอร์ต 2086"