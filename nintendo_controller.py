import board, busio, uinput, time
from adafruit_seesaw.seesaw import Seesaw
from adafruit_seesaw.digitalio import DigitalIO
from adafruit_seesaw.analoginput import AnalogInput

i2c = busio.I2C(board.SCL, board.SDA)

left  = Seesaw(i2c, addr=0x50)
right = Seesaw(i2c, addr=0x51)

events = (
    uinput.ABS_X + (0,255,0,0),
    uinput.ABS_Y + (0,255,0,0),
    uinput.ABS_RX + (0,255,0,0),
    uinput.ABS_RY + (0,255,0,0),
    uinput.BTN_A, uinput.BTN_B,
    uinput.BTN_X, uinput.BTN_Y,
    uinput.BTN_START, uinput.BTN_SELECT,
)

device = uinput.Device(events, name="Nintendo I2C Controller")

buttons = {
    uinput.BTN_A: DigitalIO(right, 0),
    uinput.BTN_B: DigitalIO(right, 1),
    uinput.BTN_X: DigitalIO(right, 2),
    uinput.BTN_Y: DigitalIO(right, 3),
    uinput.BTN_SELECT: DigitalIO(left, 0),
    uinput.BTN_START:  DigitalIO(right, 4),
}

for b in buttons.values():
    b.direction = DigitalIO.INPUT
    b.pull = DigitalIO.PULLUP

lx, ly = AnalogInput(left,2),  AnalogInput(left,3)
rx, ry = AnalogInput(right,2), AnalogInput(right,3)

def norm(v): return int((v/65535.0)*255)
prev = {}

while True:
    for k,p in buttons.items():
        s = not p.value
        if prev.get(k)!=s:
            device.emit(k,s); prev[k]=s

    axes = {
        uinput.ABS_X: norm(lx.value),
        uinput.ABS_Y: norm(ly.value),
        uinput.ABS_RX: norm(rx.value),
        uinput.ABS_RY: norm(ry.value),
    }

    for a,v in axes.items():
        if prev.get(a)!=v:
            device.emit(a,v); prev[a]=v

    time.sleep(0.008)
