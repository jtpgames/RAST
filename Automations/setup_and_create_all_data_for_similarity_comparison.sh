#!/bin/bash

# Function to display the help message
show_help() {
  echo -e "\e[32mThis script sets up and executes an experiment with RAST using TeaStore. The execution of the experiment takes approximately 1-2 hours.\nAt the end of the script, the calculated similarities between TeaStore and RAST's Simulator are stored in the file: Similarity_Comparison/similarity_scores.csv\e[0m\n"
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
  mv -v requests_count.txt ../Automations/Similarity_Comparison/
  cd ../Automations
}

# Function to format and print elapsed time
print_time() {
  local elapsed_time=$1
  local formatted_time=$(date -u -d @"$elapsed_time" +"%T")
  echo "$formatted_time"
}

# Function to capture start and end time for a given function call
time_function() {
  local function_name=$1
  local start_time=$(date +%s)

  # Call the function
  $function_name

  local end_time=$(date +%s)
  local elapsed_time=$((end_time - start_time))

  # Store the elapsed time in a global associative array
  times[$function_name]=$elapsed_time
}

# Declare an associative array to store function names and their execution times
declare -A times

# Capture the start time of the whole script
script_start_time=$(date +%s)

# List of functions to be executed
functions=(
  "run_setup"
  "run_training_data"
  "run_validation_data"
  "run_prediction_data"
  "collect_similarity_comparison_data"
  "calculate_similarities"
)

# Execute each function and track its execution time
for func in "${functions[@]}"
do
  time_function $func
done

# Capture the end time of the whole script
script_end_time=$(date +%s)
script_elapsed_time=$((script_end_time - script_start_time))

# Define colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Print the header of the table
printf "${CYAN}%-40s %-20s${NC}\n" "Function" "Time Taken"

# Print the time taken for each function
for func in "${functions[@]}"
do
  printf "%-40s %-20s\n" "$func" "$(print_time ${times[$func]})"
done

# Print the total time taken for the whole script
printf "\n${GREEN}%-40s %-20s${NC}\n" "Total execution time" "$(print_time $script_elapsed_time)"


