# Fungi Growth Simulation Using FSR Sensors

This project simulates the growth of fungal mycelium based on real-time data captured from Force-Sensitive Resistor (FSR) sensors. The system collects sensor data, processes it, and generates a simulation of the growth of mycelium.

## Overview

The simulation uses data from FSR sensors to monitor environmental variables (such as pressure or touch) and simulate the behavior of mycelium. The code in this repository is designed to be run in the [Processing](https://processing.org/) environment, where it generates real-time visualizations of fungal growth based on the data received from connected FSR sensors.

## Features

- Real-time monitoring of sensor data.
- Visualization of mycelium growth based on sensor inputs.
- Dynamic simulation that adapts to changes in input data.

## Installation

To run this project, follow these steps:

### 1. Install Processing

If you haven't already, [download and install Processing](https://processing.org/download/) on your computer.

### 2. Set Up the FSR Sensors

Connect your FSR sensors to the appropriate pins on your microcontroller (e.g., Arduino, ESP32, etc.).

### 3. Upload the Code

- Open the `sketch_250516b.pde` file in Processing.
- Make sure your microcontroller is connected and set up properly to send data to Processing.

### 4. Run the Simulation

After uploading the code to Processing, the program will start receiving sensor data and simulate the growth of mycelium in real time.

## Usage

Once the program is running, you will see a graphical representation of fungal growth that updates dynamically as new data is received from the FSR sensors.

## Contributing

If you'd like to contribute to this project, feel free to fork the repository and submit a pull request with any improvements or bug fixes. We welcome contributions from the community!

## License

This project is open-source and available under the MIT License. See the [LICENSE](LICENSE) file for more details.
