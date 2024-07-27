#!/bin/bash

prefix="teastore"
model_dir="Predictive_Models"

if [ ! -z "$1" ]; then
    prefix="$1"
fi

if [ ! -z "$2" ]; then
    model_dir="$2"
fi

latest_ridge_file="$(find "$model_dir" -iname "*_Ridge_*.pmml" -printf "\n%AD %AT %p" | sort | tail -n 1 | awk '{print $3}')"
latest_ridge_mapping_file_dir="$(find "$model_dir" -type d -iname "*Ridge*" -printf "\n%AD %AT %p" | sort | tail -n 1 | awk '{print $3}')"
latest_ridge_mapping_file="$(find $latest_ridge_mapping_file_dir -iname "requests_mapping_*.json")"
latest_dt_file="$(find "$model_dir" -iname "*_DT_*.pmml" -printf "\n%AD %AT %p" | sort | tail -n 1 | awk '{print $3}')"
latest_dt_mapping_file_dir="$(find "$model_dir" -type d -iname "*DT*" -printf "\n%AD %AT %p" | sort | tail -n 1 | awk '{print $3}')"
latest_dt_mapping_file="$(find $latest_dt_mapping_file_dir -iname "requests_mapping_*.json")"

echo $latest_ridge_file
echo $latest_ridge_mapping_file
echo $latest_dt_file
echo $latest_dt_mapping_file

cp "${latest_ridge_file}" "../../Simulators/src/main/resources/${prefix}_model_Ridge_T_PR_1_3.pmml"
cp "${latest_ridge_mapping_file}" "../../Simulators/src/main/resources/${prefix}_requests_mapping_LR_ordinal_encoding.json"
cp "${latest_dt_file}" "../../Simulators/src/main/resources/${prefix}_model_DT_T_PR_1_3.pmml"
cp "${latest_dt_mapping_file}" "../../Simulators/src/main/resources/${prefix}_requests_mapping_DT_ordinal_encoding.json"
