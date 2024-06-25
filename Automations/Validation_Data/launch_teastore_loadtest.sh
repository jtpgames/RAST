#!/bin/bash

PROFILES="low low_2 med high"
run_all_test='false'

START_TIME="$(date +"%FT%T")"

while getopts :a flag
do
    case "${flag}" in
        a) run_all_test='true';;
    esac
done

case $run_all_test in
  (true)    echo "Running all load intensity profiles without stops (Producing Training Data)";;
  (false)   echo "Running all load intensity profiles but stopping between each (Producing Validation Data)";;
esac

# move to automations folder
cd ../

chmod +x launch_teastore.sh
chmod +x shutdown_teastore.sh

# Check if the "venv" folder exists
if [ ! -d "venv" ]; then
    echo "The 'venv' folder does not exist. Creating a virtual environment..."
    # Create a virtual environment named "venv"
    python3 -m venv venv

    # Check if the virtual environment was created successfully
    if [ $? -eq 0 ]; then
        echo "Virtual environment 'venv' created successfully."
    else
        echo "Failed to create virtual environment 'venv'. Exiting."
        exit 1
    fi
else
    echo "The 'venv' folder already exists."
fi

source venv/bin/activate

pip install wheel
pip install docker

./launch_teastore.sh

curl "localhost:8080/tools.descartes.teastore.webui/status"
curl "localhost:8080/tools.descartes.teastore.webui/"
curl "localhost:8080/tools.descartes.teastore.webui/login"
curl "localhost:8080/tools.descartes.teastore.webui/category?category=2&page=1"
curl "localhost:8080/tools.descartes.teastore.webui/product?id=7"

# reset logs so that the following logs only contain request logs from requests caused by the load test.
curl "localhost:8081/logs/reset"

# move to root folder
cd ../

for profile in $PROFILES; do
  echo $profile

  echo "move to locust folder and clean old results"
  cd locust_scripts
  ./delete_results.sh

  # Check if the "venv" folder exists
  if [ ! -d "venv" ]; then
      echo "The 'venv' folder does not exist. Creating a virtual environment..."
      # Create a virtual environment named "venv"
      python3 -m venv venv

      # Check if the virtual environment was created successfully
      if [ $? -eq 0 ]; then
          echo "Virtual environment 'venv' created successfully."
      else
          echo "Failed to create virtual environment 'venv'. Exiting."
          exit 1
      fi
  else
      echo "The 'venv' folder already exists."
  fi

  # Activate the virtual environment
  source activate_venv.sh

  echo "installing python requirements"
  pip install wheel
  pip install -r requirements.txt

  # Check if the virtual environment was activated successfully
  if [ $? -eq 0 ]; then
      echo "Virtual environment 'venv' activated successfully."
  else
      echo "Failed to activate the virtual environment 'venv'. Exiting."
      exit 1
  fi

  case $run_all_test in
    (true)
    echo "Keeping teastore logs between tests"
    export KEEP_TEASTORE_LOGS=True
    ;;
  esac

  export LOAD_INTENSITY_PROFILE=$profile
  ./start_teastore_loadtest.sh

  case $run_all_test in
    (true)
    echo "*** Starting next load test in 30 seconds\n"
    sleep 30
    ;;
    (false)
    echo "*** Load test finished. Download the logfiles before continuing\”"
    echo "*** Navigate to http://localhost:8081/logs/index to download them\n"
    echo "Press any key to continue..."

    target_directory="../Automations/Validation_Data/Kieker_logs_${START_TIME}"
    wget http://localhost:8081/logs/ -A *.dat -r -nH -P "${target_directory}"
    find "${target_directory}" -type f -name '*-UTC-*.dat' -print0 | xargs --null -I{} mv {} "${target_directory}/teastore_kieker-${profile}-intensity.dat"
    rm -rf "${target_directory}/logs"

    # -s: Do not echo input coming from a terminal
    # -n 1: Read one character
#    read -s -n 1
    ;;
  esac

  # move back to root folder
  cd ../

done

echo "*** All load intensity profiles have been executed\n"
echo "******* Remember to download the logfiles before exiting *******\n"
echo "*** Navigate to http://localhost:8081/logs/index to download them\n"
echo "Press any key to continue..."

# -s: Do not echo input coming from a terminal
# -n 1: Read one character
#read -s -n 1

cd Automations

case $run_all_test in
  (true)
  target_directory="Training_Data/Kieker_logs_${START_TIME}"
  profile="low-to-high"
  wget http://localhost:8081/logs/ -A *.dat -r -nH -P "${target_directory}"
  find "${target_directory}" -type f -name '*-UTC-*.dat' -print0 | xargs --null -I{} mv {} "${target_directory}/teastore_kieker-${profile}-intensity.dat"
  rm -rf "${target_directory}/logs"
  ;;
esac

source venv/bin/activate
./shutdown_teastore.sh
