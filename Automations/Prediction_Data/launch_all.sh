#!/bin/bash

set -e

PROFILES="low low_2 med high"

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
  for model_number_in_simulator in {0..1}; do

    if (( $model_number_in_simulator == 0 )); then
      model="teastore_model_DT_T-PR_1_3"
    elif (( $model_number_in_simulator == 1)); then
      model="teastore_model_Ridge_T_PR_1_3"
    else
      echo unknown model number
      exit
    fi

    for profile in $PROFILES; do

      echo "move to locust folder and clean old results"
      cd locust_scripts
      ./delete_results.sh


      echo "move to the simulator folder and launch a simulator with model=$model, corr_max=$corr_max_value"
      cd ../Simulators
      screen -S currentscreen -d -m ./gradlew run --args="-m $model_number_in_simulator -c $corr_max_value"
      echo "wait for 30 seconds for the simulator to be ready"
      sleep 30

      echo "launch the test with profile=$profile"
      cd ../locust_scripts

      activate_venv_in_current_dir

      export LOAD_INTENSITY_PROFILE=$profile
      ./start_teastore_loadtest.sh

      # kill the simulator when the test ends
      screen -S currentscreen -X quit
      echo "shutting down simulator and waiting for 10 seconds"
      sleep 10

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
      mkdir -p "$dst_log_folder" && mv teastore_simulation.log "$dst_log_folder/teastore_simulation_${profile}-intensity.log"

      # move back to root folder
      cd ../

    done
  done
done

# move all log files to Automations/Prediction_Data

mkdir -pv "Automations/Prediction_Data/Simulator_Logs"
mv -v "Simulators/teastore_model_Ridge_T_PR_1_3" Automations/Prediction_Data/Simulator_Logs/
mv -v "Simulators/teastore_model_DT_T-PR_1_3" Automations/Prediction_Data/Simulator_Logs/
