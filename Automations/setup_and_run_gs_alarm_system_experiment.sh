#!/bin/bash

# Function to display the help message
show_help() {
  echo -e "\e[32mThis script sets up and executes an experiment with RAST using the GS Alarm System Production Logs. The execution of the experiment takes approximately x hours.\n\e[0m\n"
  echo -e "Usage: $0 [OPTION]\n"
  echo "Options:"
  echo "  -c, --clean-start    Remove result directories and files before starting."
  echo "                       This results in a fresh start of the experiment, ensuring no previous data interferes."
  echo "  -h, --help           Display this help message and exit."
}

# Function to clean directories
clean_start() {
  echo "Cleaning directories..."
  rm -rv Training_Data_Alarm_System/Predictive_Models
  rm -rv Training_Data_Alarm_System/Extracted_Workload
  rm -rv Prediction_Data_Alarm_System/Simulator_Logs
  rm -rv Prediction_Data_Alarm_System/LoadTester_Logs
}

# Check for the -c, --clean-start, -h, or --help flag
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  show_help
  exit 0
elif [[ "$1" == "-c" || "$1" == "--clean-start" ]]; then
  clean_start
fi

# Function to execute setup scripts
run_setup() {
  cd Setup_Python
  ./setup.sh
  cd ../
}

# Function to run training data scripts
run_training_data() {
  cd Training_Data_Alarm_System
  ./create_predictive_model.sh
  ./copy_models_to_simulator.sh
  ./copy_workload_info_to_load_tester.sh
  cd ../
}

# Function to run prediction data scripts
run_prediction_data() {
  cd Prediction_Data_Alarm_System
  ./launch_all.sh
  cd ../
}

# List of functions to be executed
functions=(
  "run_setup"
  "run_training_data"
  "run_prediction_data"
)

source run_experiment.sh

run_experiment
