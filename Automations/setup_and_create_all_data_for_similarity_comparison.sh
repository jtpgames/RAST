#!/bin/bash

# Function to display the help message
show_help() {
  echo -e "\e[32mThis script sets up and executes an experiment with RAST using TeaStore. The execution of the experiment takes approximately 2-3 hours.\nAt the end of the script, the calculated similarities between TeaStore and RAST's Simulator are stored in the file: Similarity_Comparison/similarity_scores.csv\e[0m\n"
  echo -e "Usage: $0 [OPTION]\n"
  echo "Options:"
  echo "  -c, --clean-start    Remove result directories and files before starting."
  echo "                       This results in a fresh start of the experiment, ensuring no previous data interferes."
  echo "  -h, --help           Display this help message and exit."
}

# Function to clean directories
clean_start() {
  echo "Cleaning directories..."
  rm -rv Training_Data/Kieker_logs_*
  rm -rv Training_Data/Predictive_Models
  rm -rv Validation_Data/Kieker_logs_*
  rm -rv Validation_Data/Databases
  rm -rv Prediction_Data/Simulator_Logs
  rm -rv Similarity_Comparison/TeaStoreResultComparisonData
  rm -rv Similarity_Comparison/requests_count.txt
  rm -rv Similarity_Comparison/similarity_scores.csv
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
  cd ../
}

# Function to collect data for similarity comparison
collect_similarity_comparison_data() {
  mkdir -pv Similarity_Comparison/TeaStoreResultComparisonData
  cp -rv Validation_Data/Databases/* Similarity_Comparison/TeaStoreResultComparisonData/
  cp -rv Prediction_Data/Simulator_Logs/* Similarity_Comparison/TeaStoreResultComparisonData/
}

# Function to calculate similarities
calculate_similarities() {
  cd ../Regression-Analysis_Workload-Characterization

  source venv/bin/activate
  python ResultComparer.py ../Automations/Similarity_Comparison/TeaStoreResultComparisonData

  mv -v similarity_scores.csv ../Automations/Similarity_Comparison/
  cd ../Automations
}

# Execute the functions
run_setup
run_training_data
run_validation_data
run_prediction_data
collect_similarity_comparison_data
calculate_similarities