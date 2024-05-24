#!/bin/bash

PROFILES="low low_2 med high"

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

  export KEEP_TEASTORE_LOGS=True
  export LOAD_INTENSITY_PROFILE=$profile
  ./start_teastore_loadtest.sh

  echo "*** Starting next load test in 30 seconds\n"
  sleep 30

  # move back to root folder
  cd ../

done

echo "*** All load intensity profiles have been executed\n"
echo "******* Remember to download the logfiles before exiting *******\n"
echo "*** Navigate to http://localhost:8081/logs/index to download them\n"
echo "Press any key to continue..."

# -s: Do not echo input coming from a terminal
# -n 1: Read one character
read -s -n 1

cd Automations
source venv/bin/activate
./shutdown_teastore.sh
