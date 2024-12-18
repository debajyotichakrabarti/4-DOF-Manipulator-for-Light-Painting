#### this code autonamtically goes to all of the points in a row
import os
import time

if os.name == 'nt':
    import msvcrt
    def getch():
        return msvcrt.getch().decode()
else:
    import sys, tty, termios
    fd = sys.stdin.fileno()
    old_settings = termios.tcgetattr(fd)
    def getch():
        try:
            tty.setraw(sys.stdin.fileno())
            ch = sys.stdin.read(1)
        finally:
            termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)
        return ch

from dynamixel_sdk import * # Uses Dynamixel SDK library
import numpy as np # import numpy

#********* DYNAMIXEL Model definition *********
MY_DXL = 'MX_SERIES'    # MX series with 2.0 firmware update.

# Control table address
if MY_DXL == 'MX_SERIES':
    ADDR_TORQUE_ENABLE          = 64
    ADDR_GOAL_POSITION          = 116
    ADDR_PRESENT_POSITION       = 132
    DXL_MINIMUM_POSITION_VALUE  = 1050        # Refer to the Minimum Position Limit of product eManual
    DXL_MAXIMUM_POSITION_VALUE  = 3050      # Refer to the Maximum Position Limit of product eManual
    BAUDRATE                    = 57600

PROTOCOL_VERSION            = 2.0

# Factory default ID of all DYNAMIXEL is 1
DXL_ID                      = np.array((1,2,3,4))

# Use the actual port assigned to the U2D2.
# ex) Windows: "COM*", Linux: "/dev/ttyUSB*", Mac: "/dev/tty.usbserial-*"
DEVICENAME                  = '/dev/tty.usbserial-FT3FSNI8'

TORQUE_ENABLE               = 1     # Value for enabling the torque
TORQUE_DISABLE              = 0     # Value for disabling the torque
DXL_MOVING_STATUS_THRESHOLD = 100    # Dynamixel moving status threshold

# Angle conversion factors
DEGREE_TO_COUNT = 4096 / 360           # 11.3777 counts per degree
ANGLE_OFFSET = 180                     # Offset to map angles to 90° to 270°

# Get joint data from MATLAB
import scipy.io as sio

mat_contents = sio.loadmat('/Users/benjaminforbes/Desktop/heart.mat') # Need to set this to your .mat file of angles
angles_deg = np.array(mat_contents['anglesMat']) # set this to what the variable name is for the angles matrix

mapped_angles_deg = angles_deg + ANGLE_OFFSET

goal_positions = np.round(mapped_angles_deg * DEGREE_TO_COUNT).astype(int)

print(goal_positions)
i = 0
j = 0

# Initialize PortHandler instance
# Set the port path
# Get methods and members of PortHandlerLinux or PortHandlerWindows
portHandler = PortHandler(DEVICENAME)

# Initialize PacketHandler instance
# Set the protocol version
# Get methods and members of Protocol1PacketHandler or Protocol2PacketHandler
packetHandler = PacketHandler(PROTOCOL_VERSION)

# Open port
if portHandler.openPort():
    print("Succeeded to open the port")
else:
    print("Failed to open the port")
    print("Press any key to terminate...")
    getch()
    quit()

# Set port baudrate
if portHandler.setBaudRate(BAUDRATE):
    print("Succeeded to change the baudrate")
else:
    print("Failed to change the baudrate")
    print("Press any key to terminate...")
    getch()
    quit()

for i in DXL_ID:
    # Enable Dynamixel Torque
    dxl_comm_result, dxl_error = packetHandler.write1ByteTxRx(portHandler, DXL_ID[i-1], ADDR_TORQUE_ENABLE, TORQUE_ENABLE)
    if dxl_comm_result != COMM_SUCCESS:
        print("%s" % packetHandler.getTxRxResult(dxl_comm_result))
    elif dxl_error != 0:
        print("%s" % packetHandler.getRxPacketError(dxl_error))
    else:
        print("Dynamixel has been successfully connected")

# Main loop
while 1:
    print("Press any key to continue! (or press ESC to quit!)")
    if getch() == chr(0x1b):
        break

    for i in range(0, np.size(goal_positions,0)):
        # Write goal position for all of the motors at once
        flag = 1
        print(f"new goal!")
        dxl_goal_position = goal_positions[i,:] # get the row of the data containing all of the joint angles for that position
        for j in DXL_ID: 

            if (goal_positions[i,j-1] <= 0):
                print(f"Skipping row {i} due to NaN values")
                i =+ i 
                flag = 0
                time.sleep(5.0)
                break

            if (goal_positions[i,j-1] >= 3400):
                goal_positions[i,j-1] = 3400
                print(f"Changing row {i} due to large values")

            if (goal_positions[i,j-1] <= 1023):
                goal_positions[i,j-1] = 1023
                print(f"Changing row {i} due to small values")

            if (j == 2):
                dxl_goal_position[1] = 3600 -(dxl_goal_position[1]- 1024)

        if flag == 1:
            dxl_comm_result, dxl_error = packetHandler.write4ByteTxRx(portHandler, DXL_ID[0], ADDR_GOAL_POSITION, dxl_goal_position[0])
            if dxl_comm_result != COMM_SUCCESS:
                print("%s" % packetHandler.getTxRxResult(dxl_comm_result))
            elif dxl_error != 0:
                print("%s" % packetHandler.getRxPacketError(dxl_error))

            dxl_comm_result, dxl_error = packetHandler.write4ByteTxRx(portHandler, DXL_ID[1], ADDR_GOAL_POSITION, dxl_goal_position[1])
            if dxl_comm_result != COMM_SUCCESS:
                print("%s" % packetHandler.getTxRxResult(dxl_comm_result))
            elif dxl_error != 0:
                print("%s" % packetHandler.getRxPacketError(dxl_error))

            dxl_comm_result, dxl_error = packetHandler.write4ByteTxRx(portHandler, DXL_ID[2], ADDR_GOAL_POSITION, dxl_goal_position[2])
            if dxl_comm_result != COMM_SUCCESS:
                print("%s" % packetHandler.getTxRxResult(dxl_comm_result))
            elif dxl_error != 0:
                print("%s" % packetHandler.getRxPacketError(dxl_error))

            dxl_comm_result, dxl_error = packetHandler.write4ByteTxRx(portHandler, DXL_ID[3], ADDR_GOAL_POSITION, dxl_goal_position[3])
            if dxl_comm_result != COMM_SUCCESS:
                print("%s" % packetHandler.getTxRxResult(dxl_comm_result))
            elif dxl_error != 0:
                print("%s" % packetHandler.getRxPacketError(dxl_error))


            while 1:
                # Read present position of first motor
                dxl_present_position_1, dxl_comm_result, dxl_error = packetHandler.read4ByteTxRx(portHandler, DXL_ID[0], ADDR_PRESENT_POSITION)

                if dxl_comm_result != COMM_SUCCESS:
                    print("%s" % packetHandler.getTxRxResult(dxl_comm_result))
                elif dxl_error != 0:
                    print("%s" % packetHandler.getRxPacketError(dxl_error))

                print("[ID:%03d] GoalPos:%03d  PresPos:%03d" % (DXL_ID[0], dxl_goal_position[0], dxl_present_position_1))

                # Read present position of second motor
                dxl_present_position_2, dxl_comm_result, dxl_error = packetHandler.read4ByteTxRx(portHandler, DXL_ID[1], ADDR_PRESENT_POSITION)

                if dxl_comm_result != COMM_SUCCESS:
                    print("%s" % packetHandler.getTxRxResult(dxl_comm_result))
                elif dxl_error != 0:
                    print("%s" % packetHandler.getRxPacketError(dxl_error))

                print("[ID:%03d] GoalPos:%03d  PresPos:%03d" % (DXL_ID[1], dxl_goal_position[1], dxl_present_position_2))

                # Read present position of third motor
                dxl_present_position_3, dxl_comm_result, dxl_error = packetHandler.read4ByteTxRx(portHandler, DXL_ID[2], ADDR_PRESENT_POSITION)

                if dxl_comm_result != COMM_SUCCESS:
                    print("%s" % packetHandler.getTxRxResult(dxl_comm_result))
                elif dxl_error != 0:
                    print("%s" % packetHandler.getRxPacketError(dxl_error))

                print("[ID:%03d] GoalPos:%03d  PresPos:%03d" % (DXL_ID[2], dxl_goal_position[2], dxl_present_position_3))

                # Read present position of fourth motor
                dxl_present_position_4, dxl_comm_result, dxl_error = packetHandler.read4ByteTxRx(portHandler, DXL_ID[3], ADDR_PRESENT_POSITION)

                if dxl_comm_result != COMM_SUCCESS:
                    print("%s" % packetHandler.getTxRxResult(dxl_comm_result))
                elif dxl_error != 0:
                    print("%s" % packetHandler.getRxPacketError(dxl_error))

                print("[ID:%03d] GoalPos:%03d  PresPos:%03d" % (DXL_ID[3], dxl_goal_position[3], dxl_present_position_4))

                if (abs(dxl_goal_position[3] - dxl_present_position_4) <= DXL_MOVING_STATUS_THRESHOLD) and (abs(dxl_goal_position[2] - dxl_present_position_3) <= DXL_MOVING_STATUS_THRESHOLD) and (abs(dxl_goal_position[1] - dxl_present_position_2) <= DXL_MOVING_STATUS_THRESHOLD) and (abs(dxl_goal_position[0] - dxl_present_position_1) <= DXL_MOVING_STATUS_THRESHOLD):
                    break


# Disable Dynamixel Torque
dxl_comm_result, dxl_error = packetHandler.write1ByteTxRx(portHandler, DXL_ID, ADDR_TORQUE_ENABLE, TORQUE_DISABLE)
if dxl_comm_result != COMM_SUCCESS:
    print("%s" % packetHandler.getTxRxResult(dxl_comm_result))
elif dxl_error != 0:
    print("%s" % packetHandler.getRxPacketError(dxl_error))

# Close port
portHandler.closePort()