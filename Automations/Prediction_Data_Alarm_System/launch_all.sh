#!/bin/bash

function activate_venv_in_current_dir {
  # Check if the "venv" folder exists
  if [ ! -d "venv" ]; then
    echo "The 'venv' folder does not exist. Exiting."
    exit 1
  fi

  # Activate the virtual environment
  source venv/bin/activate

  # Check if the virtual environment was activated successfully
  if [ $? -eq 0 ]; then
    echo "Virtual environment 'venv' activated successfully."
  else
    echo "Failed to activate the virtual environment 'venv'. Exiting."
    exit 1
  fi
}

# Load environment variables from the .env file
if [[ -f .env ]]; then
    source .env
else
    echo "Error: .env file not found! Create it and store your PASSWORD in it, e.g., echo 'PASSWORD=your_password_here' > .env"
    exit 1
fi

# Check if PASSWORD is set
if [[ -z "$PASSWORD" ]]; then
    echo "Error: PASSWORD variable is not set in the .env file!"
    exit 1
fi

# move to root folder
cd ../../

# build simulator
echo "Building ARS Simulator ..."
cd Simulators
./gradlew shadowJar -PmainClass=ArsKt
cd ../

for corr_max_value in {1..2}; do
  for model_number_in_simulator in {1..2}; do

    if (( $model_number_in_simulator == 1 )); then
      model="gs_model_Ridge"
    elif (( $model_number_in_simulator == 2)); then
      model="gs_model_DT"
    else
      echo "unknown model number"
      exit 2
    fi

    echo "move to locust folder and clean old results"
    cd locust_scripts
    ./delete_results.sh

    echo "move to the mininet folder and launch the mininet environment including the load test"
    cd mininet
    COMMAND="screen -S currentscreen -d -m ./start_mininet.sh -d ../Simulators -m $model_number_in_simulator -c $corr_max_value"
    echo "$PASSWORD" | sudo -S $COMMAND
    # sleep a bit to wait for the environment to be ready, this can take some time and even then,
    # the performance test won't be finished within a few minutes, so we can sleep for some minutes.
    echo "Launched mininet, waiting for 60 seconds ..."
    sleep 60
    cd ../

    echo "Begin polling the locust-parameter-variation.log to check if the load test was finished ('Finished performance test.')"

    file_path="locust-parameter-variation.log"

    # Loop until the last line contains "Finished performance test"
    while true; do
      last_line=""

      # Check if the file exists
      if [[ ! -f "$file_path" ]]; then
        echo "Error: File '$file_path' does not exist."
      else
        # Read the last line of the file
        last_line=$(tail -n 1 "$file_path")
      fi

      # Check if the last line contains the desired text
      if [[ "$last_line" == *"Finished performance test"* ]]; then
        echo $last_line
        break
      fi

      # Sleep for a short period to avoid busy-waiting
      sleep 10
    done

    echo "stop the load test and exit the mininet session"
    COMMAND="screen -S currentscreen -X stuff stopworkloads\n"
    echo "$PASSWORD" | sudo -S $COMMAND
    sleep 1
    COMMAND="screen -S currentscreen -X stuff exit\n"
    echo "$PASSWORD" | sudo -S $COMMAND
    sleep 5

    echo "collect the results"

    # Set the destination log folder based on the correction value
    dst_log_folder="$model/"
    if (( $corr_max_value == 0 )); then
      dst_log_folder+="No correction"
    elif (( $corr_max_value == 1)); then
      dst_log_folder+="One correction"
    elif (( $corr_max_value == 2)); then
      dst_log_folder+="Two corrections"
    else
      dst_log_folder+="More corrections"
    fi

    echo "from load tester"

    ./extract_connection_errors.sh
    ./export_sysstats.sh alarm_system.sar
    ./export_sysstats.sh arc.sar

    echo "$PASSWORD" | sudo -S chmod 666 *.log
    echo "$PASSWORD" | sudo -S chmod 666 *.sar

    mkdir -p "$dst_log_folder"
    mv -v *.log "$dst_log_folder/"
    mv -v *.out "$dst_log_folder/"
    mv -v *.sar "$dst_log_folder/"
    mv -v *.svg "$dst_log_folder/"

    echo "from Simulator"
    cd ../Simulators

    # Create the destination folder and move the log file
    mkdir -p "$dst_log_folder" && mv -v ars_simulation.log "$dst_log_folder/gs_simulation.log"

    # move back to root folder
    cd ../

  done
done

echo "move to locust folder and clean old results"
cd locust_scripts
./delete_results.sh
cd ../

echo "Moving all log files to Automations/Prediction_Data_Alarm_System ..."

mkdir -pv Automations/Prediction_Data_Alarm_System/LoadTester_Logs
mv -v "locust_scripts/gs_model_Ridge" Automations/Prediction_Data_Alarm_System/LoadTester_Logs/
mv -v "locust_scripts/gs_model_DT" Automations/Prediction_Data_Alarm_System/LoadTester_Logs/

mkdir -pv Automations/Prediction_Data_Alarm_System/Simulator_Logs
mv -v "Simulators/gs_model_Ridge" Automations/Prediction_Data_Alarm_System/Simulator_Logs/
mv -v "Simulators/gs_model_DT" Automations/Prediction_Data_Alarm_System/Simulator_Logs/
