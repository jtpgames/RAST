#!/bin/bash

# Function to display the help message
show_help() {
  echo "Usage: $0 [OPTION]"
  echo "Options:"
  echo "  -c, --clean-start    Remove result directories and files before starting, resulting in a fresh start of the experiment"
  echo "  -h, --help           Display this help message and exit"
}

# Function to clean directories
clean_start() {
  echo "Cleaning directories..."
  rm -rv Training_Data/Kieker_logs_*
  rm -rv Training_Data/Predictive_Models
  rm -rv Validation_Data/Kieker_logs_*
  rm -rv Validation_Data/Databases
  rm -rv Prediction_Data/Simulator_Logs
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
  cd Setup_TeaStore
  ./setup.sh
  cd ../

  cd Setup_Python
  ./setup.sh
  cd ../
}

# Function to run training data scripts
run_training_data() {
  cd Training_Data
  ./launch_all.sh
  ./create_predictive_model.sh
  ./copy_models_to_simulator.sh
  cd ../
}

# Function to run validation data scripts
run_validation_data() {
  cd Validation_Data
  ./launch_teastore_loadtest.sh
  ./create_validation_databases.sh
  cd ../
}

# Function to run prediction data scripts
run_prediction_data() {
  cd Prediction_Data
  ./launch_all.sh
}

# Execute the functions
run_setup
run_training_data
run_validation_data
run_prediction_data
