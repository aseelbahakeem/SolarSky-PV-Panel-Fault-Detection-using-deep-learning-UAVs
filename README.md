![Technology-animation-gif](https://github.com/aseelbahakeem/SolarSky-PV-Panel-Fault-Detection-using-deep-learning-UAVs/blob/main/solarSkyLogoheader.gif)
# SolarSky: PV Panel Fault Detection using Deep Learning and UAVs

All work for my senior project completing courses COCS 498 and COCS 499 during the first and last semesters of 2024, with the guidance of my advisor and colleagues at King AbdulAziz University for my Computer Science undergraduate degree.

## Overview

SolarSky is a cutting-edge system developed to enhance the efficiency and accuracy of PV panel inspections through the integration of three key components: the application, the UAV (Unmanned Aerial Vehicle), and two AI models. This system empowers homeowners to maximize the benefits of their solar panels by providing a comprehensive and automated inspection solution.

## System Components

- **Application**: A mobile interface for users to interact with the SolarSky system.
- **UAV**: An unmanned aerial vehicle equipped with cameras to capture images of PV panels.
- **AI Models**:
  - The first AI model processes images in real-time to detect faults in PV panels.
  - The second AI model, an OCR (Optical Character Recognition) model, extracts serial numbers of faulty panels.

## How It Works

1. The UAV takes off and captures images of the PV panels.
2. Images are sent to the AI model for real-time processing.
3. The AI model checks each panel's status and identifies faults.
4. Faulty panels' serial numbers are extracted and saved.
5. After landing, the UAV updates the status of all panels in the virtual farm and generates an inspection report.

## Development Environment

The development of SolarSky utilized a variety of tools across different categories:

### IDEs and Code Editors

- **Visual Studio Code (VS Code)**
- **PyCharm**: For UAV programming and integration.
- **Android Studio**: For running the SolarSky mobile application on an Android emulator.

### Programming Languages

- **Dart**: Used for the SolarSky mobile application.
- **Python**: For UAV integration, model training, and application integration.

### Development Frameworks

- **Flutter**: For mobile application development.
- **PyTorch**: For AI model development and training.

### Cloud-based Tools

- **Figma**: For UI design and prototyping.
- **Firebase**: For database management.
- **Roboflow**: For dataset annotation and pre-processing.
- **Google Colab**: For model training in a cloud-based Jupyter Notebook environment.

## Dataset

The SolarSky dataset comprises three classes of faults: "Clean", "Dust", and "Cracks", with a total of 2552 images. It was divided into 80% for training, 10% for validation, and 10% for testing. The dataset was collected from various sources and manually annotated to ensure accuracy.

## Installation

To install the SolarSky mobile application, download the APK from the following Google Drive link:

[Download SolarSky APK](https://drive.google.com/drive/u/1/folders/1dGXQyH6EInksFijNjATw3PMPjgClveM-)

## Acknowledgements

I would like to express my gratitude to my advisor, colleagues at King AbdulAziz University, and everyone who contributed to the SolarSky project.

## Contact

For more information or for the demo and detailed project report, please contact me to gain access to the Google Drive folder.
