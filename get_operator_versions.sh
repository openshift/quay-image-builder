#!/bin/bash -e

OCP_MAJ_VER=${OCP_MAJ_VER:-4.11}
INDEX=${INDEX:-redhat}

IMG="registry.redhat.io/redhat/${INDEX}-operator-index:v${OCP_MAJ_VER}"

echo IMG=${IMG}

echo "Creating new imageset-config.yaml..."
rm -f imageset-config.yaml.processed
cp imageset-config.yaml imageset-config.yaml.processed

for op in $(yq -r '.mirror.operators[0].packages[].name' imageset-config.yaml)
do
  echo "Processing operator: ${op}..."

  DEF_CHANNEL=$(oc-mirror list operators \
                  --catalog=${IMG} \
                  --package=${op} \
                  | grep -A 1 'DEFAULT CHANNEL' | tail -1 | awk '{print $NF}')

  LATEST_VER=$(oc-mirror list operators \
                 --catalog=${IMG} --package=${op} \
                 --channel=${DEF_CHANNEL} 2>/dev/null | grep -v VERSIONS | tail -1)

  sed -i "s|${op}-CHANNEL|${DEF_CHANNEL}|" imageset-config.yaml.processed
  sed -i "s|${op}-VERSION|${LATEST_VER}|" imageset-config.yaml.processed

done

echo "Processing complete. Created imageset-config.yaml.processed"
