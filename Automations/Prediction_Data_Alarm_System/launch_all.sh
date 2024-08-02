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

# move to root folder
cd ../../

for corr_max_value in {0..1}; do
  for model_number_in_simulator in {1..2}; do

    if (( $model_number_in_simulator == 1 )); then
      model="gs_model_Ridge_T_PR_1_3"
    elif (( $model_number_in_simulator == 2)); then
      model="gs_model_DT_T_PR_1_3"
    else
      echo unknown model number
      exit 2
    fi

    echo "move to locust folder and clean old results"
    cd locust_scripts
    ./delete_results.sh


    echo "move to the mininet folder and launch the mininet environment including the load test"
    cd mininet
    screen -S currentscreen -d -m ./start_mininet.sh -d ../Simulators -m $model_number_in_simulator -c $corr_max_value
    # sleep a bit to wait for the environment to be ready, this can take some time and even then,
    # the performance test won't be finished within a few minutes, so we can sleep for some minutes.
    sleep 10
    cd ../

    # poll the locust-parameter-variation.log to check if the load test was finished ("Finished performance test.")

    file_path="locust-parameter-variation.log"

    # Loop until the last line contains "Finished performance test"
    while true; do
      last_line=""

      # Check if the file exists
      if [[ ! -f "$file_path" ]]; then
          echo "Error: File '$file_path' does not exist."
      fi

      # Read the last line of the file
      last_line=$(tail -n 1 "$file_path")

      # Check if the last line contains the desired text
      if [[ "$last_line" == *"Finished performance test"* ]]; then
          echo $last_line
          break
      fi

      # Sleep for a short period to avoid busy-waiting
      sleep 10
    done

    # kill the simulator when the test ends
    screen -S currentscreen -X stopworkloads
    sleep 1
    screen -S currentscreen -X exit
    sleep 5
    screen -S currentscreen -X quit

    echo "collect the results"
    cd ../Simulators

    # Set the destination log folder based on the correction value
    dst_log_folder="$model/"
    if (( $corr_max_value == 0 )); then
      dst_log_folder+="No correction"
    elif (( $corr_max_value == 1)); then
      dst_log_folder+="One correction"
    else
      dst_log_folder+="More corrections"
    fi

    # Create the destination folder and move the log file
    mkdir -p "$dst_log_folder" && mv ars_simulation.log "$dst_log_folder/gs_simulation.log"

    # move back to root folder
    cd ../

  done
done

# move all log files to Automations/Prediction_Data_Alarm_System

mkdir -pv Automations/Prediction_Data_Alarm_System/Simulator_Logs
mv -v "Simulators/gs_model_Ridge_T_PR_1_3" Automations/Prediction_Data_Alarm_System/Simulator_Logs/
mv -v "Simulators/gs_model_DT_T_PR_1_3" Automations/Prediction_Data_Alarm_System/Simulator_Logs/
