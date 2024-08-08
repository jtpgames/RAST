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

echo "Copying training data to ML_ETL ..."

mkdir -p ../ML_ETL/GS_Logs/Training_Data && rsync -auv --include '*/' --include '*.log' --exclude '*' --progress GS_Alarmsystem_Logs/ ../ML_ETL/GS_Logs/Training_Data/

# move to ML_ETL project
cd ../ML_ETL

logsDirToUse="Training_Data"

# Path to the file
db_path="db/Training_Data/trainingdata.db"

# Check if the database file does not exist
if [ ! -f "$db_path" ]; then

  activate_venv_in_current_dir

  # move to Logfiles directory
  cd Logfiles

  echo "Starting ETL process ..."

  python ARSLogConverter.py -d "../GS_Logs/$logsDirToUse/"

  python WSLogFixer.py -d "../GS_Logs/$logsDirToUse/"

  python LogMerger.py -d "../GS_Logs/$logsDirToUse/"

  python WorkloadExtractor.py -d "../GS_Logs/$logsDirToUse/"

  python RequestLogToCLF.py -d "../GS_Logs/$logsDirToUse/" --force

  python LogToDbETL.py "../GS_Logs/$logsDirToUse/"

  # move back to project folder
  cd ../

  echo "Copying extracted workload ..."
  mkdir -pv ../Automations/Training_Data_Alarm_System/Extracted_Workload

  find GS_Logs/ -type f -name "Request_Names.log" -exec mv -v {} ../Automations/Training_Data_Alarm_System/Extracted_Workload \;
  find GS_Logs/ -type f -name "Requests_per_time_unit_*.log" -exec mv -v {} ../Automations/Training_Data_Alarm_System/Extracted_Workload \;

  echo "Copying database to Training_Data folder ..."
  mkdir -p db/Training_Data && mv -v db/trainingdata_*.db "$db_path"

else
  echo "$db_path already exists"
fi

echo "Starting Regression Analysis ..."

# move to RegressionAnalysis project
cd ../Regression-Analysis_Workload-Characterization

activate_venv_in_current_dir

python RegressionAnalysis.py "../ML_ETL/$db_path" Ridge
python RegressionAnalysis.py "../ML_ETL/$db_path" DT

mkdir -pv ../Automations/Training_Data_Alarm_System/Predictive_Models && mv -v regression_analysis_results/* ../Automations/Training_Data_Alarm_System/Predictive_Models

# delete intermediate results

cd ../ML_ETL
rm -v db/Training_Data/trainingdata.db

find GS_Logs/ -type f -name "Merged_*.log" -exec rm -v -f {} \;
find GS_Logs/ -type f -name "Conv_*.log" -exec rm -v -f {} \;
find GS_Logs/ -type f -name "request_statistics_*.json" -exec rm -v -f {} \;
