from ultralytics import YOLO
import cv2
import cvzone
import math
import easyocr  # Import EasyOCR for serial number recognition
from firestoresdk import db # Import Firestore database client from firestoresdk.py
from djitellopy import tello
import KeyPressModule as kp



# Initialize the Tello Drone
Drone = tello.Tello()
Drone.connect()
print(f'Drone Battery: {Drone.get_battery()}%')
Drone.streamoff()  # Ensure the stream is turned off before starting it again
Drone.streamon()

model = YOLO("best (1).pt")

# Initialize EasyOCR Reader
reader = easyocr.Reader(['en'])  # Assuming serial numbers are in English

# Class names for detected objects
classNames = ['clean', 'cracks', 'dust']

# File to save serial numbers for panels with cracks or dust
serial_numbers_file = "serial_numbers.txt"

# Empty the serial_numbers.txt file and reset the existing_serial_numbers set
with open(serial_numbers_file, "w") as file:
    pass  # Opening in write mode without writing anything will clear the file
existing_serial_numbers = set()  # Reinitialize the set to be empty

# Function to reset the StartInspectionTimer field in Firestore
def reset_start_inspection_timer(user_id):
    user_ref = db.collection('users').document(user_id)
    user_ref.update({"StartInspectionTimer": False})
    print(f"StartInspectionTimer reset to False for user {user_id}.")

# Function to find the user with StartInspectionTimer set to true
def find_inspecting_user():
    users_ref = db.collection('users')
    users = users_ref.stream()

    for user in users:
        user_data = user.to_dict()
        if user_data.get('StartInspectionTimer'):
            # Found a user with an inspection in progress
            return user.id, user_data
    return None, None

# Function to update the InspectionStarted field in Firestore to True
def update_inspection_status_to_true(user_id, farm_doc_id):
    farm_doc_ref = db.collection('users').document(user_id).collection('farms').document(farm_doc_id)
    farm_doc_ref.update({"InspectionStarted": True})
    print(f"InspectionStarted status set to True for farm {farm_doc_id} of user {user_id}.")

def update_panel_status(user_id, farm_doc_id, serial_number):
    # Reference to the panels collection
    panels_ref = db.collection('users').document(user_id).collection('farms').document(farm_doc_id).collection('panels')

    # Query for the panel with the matching serial number
    panel_query = panels_ref.where('serialNumber', '==', serial_number).get()
    for panel in panel_query:
        # Update the panelStatus to false
        panel.reference.update({'panelStatus': False})
        print(f"Panel {serial_number} status updated to False.")

def check_serial_numbers_and_update_status(user_id, farm_doc_id):
    # Read serial numbers from the file
    with open(serial_numbers_file, "r") as file:
        serial_numbers = file.read().splitlines()

    for serial_number in serial_numbers:
        update_panel_status(user_id, farm_doc_id, serial_number)

kp.init()
def getKeyboardInput():
    lr, fb, ud, yv = 0, 0, 0, 0
    speed = 50

    if kp.getKey("LEFT"):
        lr = -speed
    elif kp.getKey("RIGHT"):
        lr = speed

    if kp.getKey("UP"):
        fb = speed
    elif kp.getKey("DOWN"):
        fb = -speed

    if kp.getKey("w"):
        ud = speed
    elif kp.getKey("s"):
        ud = -speed

    if kp.getKey("a"):
        yv = speed
    elif kp.getKey("d"):
        yv = -speed

    if kp.getKey("q"):
        Drone.land()
    if kp.getKey("e"):
        Drone.takeoff()

    return [lr, fb, ud, yv]

# Define frame skipping parameters
frame_skip = 5  # Process every 5th frame
frame_count = 0
while True:

    vals = getKeyboardInput()
    Drone.send_rc_control(vals[0], vals[1], vals[2], vals[3])

    frame_count += 1
    # Check if the current frame should be skipped
    if frame_count % frame_skip != 0:
        # Skip this frame
        # Proceed to the next iteration of the loop
        # This will continue to the next frame without executing the processing code below
        continue
    # Read frame from the Tello drone
    img = Drone.get_frame_read().frame
    results = model(img, stream=True)

    # Check if detected panels have cracks or dust and then apply OCR
    for r in results:
        boxes = r.boxes
        for box in boxes:
            cls = int(box.cls[0])  # Class index
            # Proceed if class is 'cracks' or 'dust'
            if cls in [1, 2]:  # Assuming you want to include 'cracks' and 'dust'
                ocr_result = reader.readtext(img)
                for (bbox, text, prob) in ocr_result:
                    # Ensure serial number detection confidence is 0.90 or higher before saving
                    if prob >= 0.90 and text not in existing_serial_numbers:  # Check for uniqueness
                        print(f'Potential Serial Number Detected: {text} with confidence {prob}')
                        existing_serial_numbers.add(text)  # Add to the set to avoid future duplicates
                        with open(serial_numbers_file, "a") as file:
                            file.write(f"{text}\n")  # Write the unique serial number to the file

                        top_left = tuple(map(int, [bbox[0][0], bbox[0][1]]))
                        bottom_right = tuple(map(int, [bbox[2][0], bbox[2][1]]))
                        cv2.rectangle(img, top_left, bottom_right, (0, 255, 0), 2)
                        cv2.putText(img, text, top_left, cv2.FONT_HERSHEY_SIMPLEX, 0.9, (0, 255, 0), 2)

            # Draw bounding boxes and class names for all detected objects
            x1, y1, x2, y2 = box.xyxy[0]
            x1, y1, x2, y2 = int(x1), int(y1), int(x2), int(y2)
            w, h = x2 - x1, y2 - y1
            cvzone.cornerRect(img, (x1, y1, w, h))
            conf = math.ceil((box.conf[0] * 100)) / 100
            print(conf)
            cvzone.putTextRect(img, f'{classNames[cls]} {conf}', (max(0, x1), max(35, y1)), 1, thickness=2)

    cv2.imshow("Image", img)


    # Inspect if a key was pressed
    key = cv2.waitKey(50) & 0xFF
    if key == ord('q'):  # Press 'q' to quit the program
        break
    elif key == ord('l'):  # Press 'l' for landing and to update Firestore
        inspecting_user_id, user_data = find_inspecting_user()
        if inspecting_user_id:
            # Get the first farm ID for the inspecting user
            farm_ref = db.collection('users').document(inspecting_user_id).collection('farms')
            farms = farm_ref.limit(1).stream()
            for farm in farms:
                farm_id = farm.id
                check_serial_numbers_and_update_status(inspecting_user_id, farm_id)
                update_inspection_status_to_true(inspecting_user_id, farm_id)
                reset_start_inspection_timer(inspecting_user_id)  # Reset the StartInspectionTimer
                print(f"Updated inspection data for user {inspecting_user_id} and farm {farm_id}.")
                # Assuming only one farm per user, break after processing
                break
        else:
            print("No user is currently inspecting.")
        # Uncomment the line below to break the loop and end the program
        # break

Drone.streamoff()
cv2.destroyAllWindows()