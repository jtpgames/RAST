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
cd ../

mkdir -p ../ML_ETL/GS_Logs/Training_Data && rsync -auv --include '*/' --include '*.log' --exclude '*' --progress GS_Alarmsystem_Logs/ ../ML_ETL/GS_Logs/Training_Data/

# move to ML_ETL project
cd ../ML_ETL

activate_venv_in_current_dir

# move to Logfiles directory
cd Logfiles

logsDirToUse="Test_Data"

python ARSLogConverter.py -d "../GS_Logs/$logsDirToUse/"

python WSLogFixer.py -d "../GS_Logs/$logsDirToUse/"

python LogMerger.py -d "../GS_Logs/$logsDirToUse/"

python RequestLogToCLF.py -d "../GS_Logs/$logsDirToUse/" --force

python LogToDbETL.py "../GS_Logs/$logsDirToUse/"

# move back to project folder
cd ../

mkdir -p db/Training_Data && mv -v db/trainingdata_*.db db/Training_Data/trainingdata.db

# move to RegressionAnalysis project
cd ../Regression-Analysis_Workload-Characterization

activate_venv_in_current_dir

python RegressionAnalysis.py ../ML_ETL/db/Training_Data/trainingdata.db Ridge
python RegressionAnalysis.py ../ML_ETL/db/Training_Data/trainingdata.db DT

mkdir -pv ../Automations/Training_Data_Alarm_System/Predictive_Models && mv -v regression_analysis_results/* ../Automations/Training_Data_Alarm_System/Predictive_Models

# delete intermediate results

cd ../ML_ETL
rm -v db/Training_Data/trainingdata.db

find GS_Logs/ -type f -name "Merged_*.log" -exec rm -v -f {} \;
find GS_Logs/ -type f -name "Conv_*.log" -exec rm -v -f {} \;
find GS_Logs/ -type f -name "request_statistics_*.json" -exec rm -v -f {} \;
