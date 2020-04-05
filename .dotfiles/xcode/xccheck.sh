#!/bin/bash
#-------------------------------------------------------------------------------
#
# xcode/xccheck.sh
# Validate Xcode application binary integrity using `spctl`
#
#-------------------------------------------------------------------------------

app_dirs=(
  "/Applications"
  "${HOME}/Applications"
  "/Volumes/Thunderbay/Applications"
)

for app_dir in "${app_dirs[@]}"
do
  for xcode_version in "${app_dir}"/Xcode*.app
  do
    echo "Checking integrity of ${xcode_version}"
    /usr/sbin/spctl --assess --verbose "${xcode_version}"
  done
done
