#!/bin/bash

ROOT_FOLDER=$PWD
PROTOBUFFET_FOLDER=$(cd "$(dirname "$0")" && pwd -P)
echo "Found proto-buffet folder at '$PROTOBUFFET_FOLDER'"

if [ -z $1 ]; then
  PYTHON_FOLDER=${ROOT_FOLDER}
else
  PYTHON_FOLDER=${ROOT_FOLDER}/$1
fi

GENERATED_FOLDER=$PYTHON_FOLDER/vivacity
echo "Generating python protobuf meta classes in '$GENERATED_FOLDER'"

if [ -d $GENERATED_FOLDER ]; then
  find $GENERATED_FOLDER -name "*_pb2.py" -type f -exec rm {} \;
  find $GENERATED_FOLDER -name "*_pb2_grpc.py" -type f -exec rm {} \;
fi
mkdir -p $GENERATED_FOLDER

PROTO_FILES=($(find ${PROTOBUFFET_FOLDER} -type f -name "*.proto" ! -path "${PROTOBUFFET_FOLDER}/vivacity/*"))

for PROTO_FILE in "${PROTO_FILES[@]}"
do
  DESTINATION="${PROTO_FILE/$PROTOBUFFET_FOLDER/$GENERATED_FOLDER}"
  mkdir -p $(dirname $DESTINATION) && cp $PROTO_FILE $DESTINATION
done

PROTO_FOLDERS=($(find ${GENERATED_FOLDER} -type f -name "*.proto" -exec dirname {} \; | sort | uniq))

for PROTO_FOLDER in "${PROTO_FOLDERS[@]}"
do
  touch ${PROTO_FOLDER}/__init__.py
  cat <<EOF > ${PROTO_FOLDER}/__init__.py
from os.path import dirname, basename, isfile, join, abspath
import glob
import importlib

modules = glob.glob(join(dirname(__file__), "*_pb2.py"))
modules = [basename(f)[:-3] for f in modules if isfile(f) and not f.endswith('__init__.py')]

module_path = dirname(__file__).replace(abspath("."), "")[1:].replace("/", ".", -1)
# This code tries to import all of the protobuf class names into the vivacity module
# so that they can be created using e.g. vivacity.core.DetectorTrackerFrame()
all_exports = []
for module in modules:
    mod = importlib.import_module(module_path+"."+module)

    for k in dir(mod):
        if not k.startswith("_") and k != "DESCRIPTOR" and k[0].isupper():
            globals()[k] = mod.__dict__[k]
            all_exports.append(k)

__all__ = all_exports
EOF
  MYPY_ARG=""
  if pip list 2>&1 | grep mypy-protobuf > /dev/null; then
    echo "mypy-protobuf python package found"
    MYPY_ARG=" --mypy_out=quiet:${PYTHON_FOLDER}"
  else
    echo "mypy-protobuf python package NOT found - consider running: 'pip install mypy-protobuf' for a better devX"
  fi
  if python3 -c "import grpc_tools" &> /dev/null; then
    echo "grpc_tools python package found"
    python3 -m grpc_tools.protoc -I=${PYTHON_FOLDER} --python_out=${PYTHON_FOLDER} $MYPY_ARG --grpc_python_out=${PYTHON_FOLDER} $PROTO_FOLDER/*.proto
  else
    echo "could not find grpc_tools python package. Using protoc"
    protoc -I=${PYTHON_FOLDER} --python_out=${PYTHON_FOLDER} $MYPY_ARG $PROTO_FOLDER/*.proto
  fi
done
echo "Files generated in '$GENERATED_FOLDER'"
