function create_and_activate_venv_in_current_dir {
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
  source venv/bin/activate

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
}

# move to root folder
cd ../../

echo "Automations:"
cd Automations
create_and_activate_venv_in_current_dir

# move to root folder
cd ..

echo "ML_ETL:"
cd ML_ETL
create_and_activate_venv_in_current_dir

# move to root folder
cd ..

echo "Regression-Analysis_Workload-Characterization:"
cd Regression-Analysis_Workload-Characterization
create_and_activate_venv_in_current_dir

# move to root folder
cd ..

echo "locust_scripts:"
cd locust_scripts
create_and_activate_venv_in_current_dir

echo "All Python virtual environments created and requirements installed."