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

run_experiment() {
  echo "${functions[@]}"

  # Capture the start time of the whole script
  script_start_time=$(date +%s)

  # Execute each function and track its execution time
  for func in "${functions[@]}"
  do
    echo "BEGIN $func"
    time_function $func
    echo "END $func"
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
}