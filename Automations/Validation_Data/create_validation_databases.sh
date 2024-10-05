#!/bin/bash

PROFILES="low low_2 med high"

for profile in $PROFILES; do
  mkdir -pv "../../Kieker_ETL/TeaStoreLogs/Validation_Data/$profile-intensity"
  cp -v Kieker_logs_*/*-"$profile"-*.dat "../../Kieker_ETL/TeaStoreLogs/Validation_Data/$profile-intensity"
done

# move to Kieker_ETL project
cd ../../Kieker_ETL

for profile in $PROFILES; do
  ./gradlew run --args="TeaStoreLogs/Validation_Data/$profile-intensity"

  mkdir -pv "../ML_ETL/TeaStoreLogs/Validation_Data/$profile-intensity" && mv -v TeaStoreLogs/Validation_Data/"$profile"-intensity/teastore-cmd_*.log "../ML_ETL/TeaStoreLogs/Validation_Data/$profile-intensity"
done

# move to ML_ETL project
cd ../ML_ETL

# Activate the virtual environment
source venv/bin/activate

# Check if the virtual environment was activated successfully
if [ $? -eq 0 ]; then
    echo "Virtual environment 'venv' activated successfully."
else
    echo "Failed to activate the virtual environment 'venv'. Exiting."
    exit 1
fi

# move to Logfiles directory
cd Logfiles

for profile in $PROFILES; do
  python GSLogToLocustConverter.py -d "../TeaStoreLogs/Validation_Data/$profile-intensity"

  python LogToDbETL.py "../TeaStoreLogs/Validation_Data/$profile-intensity/" "../db/Validation_Data/$profile-intensity"

  mkdir -pv ../../Automations/Validation_Data/Databases && mv -v ../db/Validation_Data/"$profile"-intensity/trainingdata_*.db "../../Automations/Validation_Data/Databases/validationdata_$profile-intensity.db"
done

# move to root folder
cd ../../

# delete intermediate results

cd ML_ETL
rm -rv TeaStoreLogs/Validation_Data/*
rm -rv db/Validation_Data/*

cd ../Kieker_ETL
rm -rv TeaStoreLogs/Validation_Data/*

