#!/bin/bash
for recipe in $(ls -d conda/*/ | xargs -I {} basename {}); do
  if [[ "$recipe" = "zipline" ]]; then continue; fi

  conda build conda/$recipe --python=$CONDA_PY --numpy=$CONDA_NPY --skip-existing --old-build-string -c quantopian -c quantopian/label/ci
#  RECIPE_OUTPUT=$(conda build conda/$recipe --python=$CONDA_PY --numpy=$CONDA_NPY --old-build-string --output)
#  if [[ -f "$RECIPE_OUTPUT" && "$DO_UPLOAD" = "true" ]]; then anaconda -t $ANACONDA_TOKEN upload "$RECIPE_OUTPUT" -u quantopian --label ci; fi
done
