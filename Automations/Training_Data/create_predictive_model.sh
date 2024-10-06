#!/bin/bash

set -e

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

mkdir -pv ../../Kieker_ETL/TeaStoreLogs/Training_Data

cp -v Kieker_logs_*/*.dat ../../Kieker_ETL/TeaStoreLogs/Training_Data

# move to Kieker_ETL project
cd ../../Kieker_ETL

./gradlew run --args='TeaStoreLogs/Training_Data'

mkdir -pv ../ML_ETL/TeaStoreLogs/Training_Data && mv -v TeaStoreLogs/Training_Data/teastore-cmd_*.log ../ML_ETL/TeaStoreLogs/Training_Data

# move to ML_ETL project
cd ../ML_ETL

activate_venv_in_current_dir

# move to Logfiles directory
cd Logfiles

python GSLogToLocustConverter.py -d ../TeaStoreLogs/Training_Data

python LogToDbETL.py ../TeaStoreLogs/Training_Data

# move back to project folder
cd ../

mkdir -p db/Training_Data && mv -v db/trainingdata_*.db db/Training_Data/trainingdata.db

# move to RegressionAnalysis project
cd ../Regression-Analysis_Workload-Characterization

activate_venv_in_current_dir

python RegressionAnalysis.py ../ML_ETL/db/Training_Data/trainingdata.db Ridge
python RegressionAnalysis.py ../ML_ETL/db/Training_Data/trainingdata.db DT

mkdir -pv ../Automations/Training_Data/Predictive_Models && mv -v regression_analysis_results/* ../Automations/Training_Data/Predictive_Models

# delete intermediate results

cd ../ML_ETL
rm -v db/Training_Data/trainingdata.db
rm -v TeaStoreLogs/Training_Data/*

cd ../Kieker_ETL
rm -v TeaStoreLogs/Training_Data/*.dat