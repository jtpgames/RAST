#!/bin/bash

PROFILES="LOW LOW_2 MED HIGH"
model="teastore_model_Ridge_T_PR_1_3"

# move to root folder
cd ../../

for profile in $PROFILES; do


  #move to locust folder and clean old results
  cd locust_scripts
  ./delete_results.sh


  export LOAD_INTENSITY_PROFILE=$profile

#  #create official teastore locust file by copying the template and replacing the @PROFILEVALUE@ string
#  cp locust/official_teastore_locustfile.py.tmpl locust/official_teastore_locustfile.py
#  sed -i "s/@PROFILEVALUE@/$profile/g" locust/official_teastore_locustfile.py


  #move to the simulator folder and launch a simulator
  cd ../Simulators
  screen -S currentscreen -d -m ./gradlew run
  # sleep a bit to wait that the simulator is ready
  sleep 10

  #launch the test
  cd ../Locust_Scripts
  ./start_teastore_loadtest.sh

  #kill the simulator when the test ends
  screen -S currentscreen -X quit


  #collect the results
  cd ../Simulators
  mv teastore_simulation.log $model-$profile-teastore_simulation.log

done
