#!/bin/bash

latest_ridge_file="$(find Predictive_Models -iname "*_Ridge_*.pmml" -printf "\n%AD %AT %p" | sort | tail -n 1 | awk '{print $3}')"
latest_ridge_mapping_file_dir="$(find Predictive_Models -type d -iname "*Ridge*" -printf "\n%AD %AT %p" | sort | tail -n 1 | awk '{print $3}')"
latest_ridge_mapping_file="$(find $latest_ridge_mapping_file_dir -iname "requests_mapping_*.json")"
latest_dt_file="$(find Predictive_Models -iname "*_DT_*.pmml" -printf "\n%AD %AT %p" | sort | tail -n 1 | awk '{print $3}')"
latest_dt_mapping_file_dir="$(find Predictive_Models -type d -iname "*DT*" -printf "\n%AD %AT %p" | sort | tail -n 1 | awk '{print $3}')"
latest_dt_mapping_file="$(find $latest_dt_mapping_file_dir -iname "requests_mapping_*.json")"

echo $latest_ridge_file
echo $latest_ridge_mapping_file
echo $latest_dt_file
echo $latest_dt_mapping_file

cp ${latest_ridge_file} ../../Simulators/src/main/resources/teastore_model_Ridge_T_PR_1_3.pmml
cp ${latest_ridge_mapping_file} ../../Simulators/src/main/resources/teastore_requests_mapping_LR_ordinal_encoding.json
cp ${latest_dt_file} ../../Simulators/src/main/resources/teastore_model_DT_T_PR_1_3.pmml
cp ${latest_dt_mapping_file} ../../Simulators/src/main/resources/teastore_requests_mapping_DT_ordinal_encoding.json
