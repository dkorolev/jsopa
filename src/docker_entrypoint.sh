#!/bin/bash
#
# NOTE(dkorolev): This is an internal script, designed to be run from within a Docker container.
#                 It does work outside that container too if you have OPA installed :-) but that's not the intended usage.

if [ "$1" == "asbyrgi_version" ] ; then
  echo "Asbyrgi version: __ASBYRGI_VERSION_SET_BY_GITHUB_ACTION_CONTAINER_BUILDER__"
elif [ "$1" == "rego2ir" ] ; then
  if [ $# == 3 ] ; then
    if ! opa build /dev/stdin -e "$2"/"$3" -t plan -o /dev/stdout | gunzip | tar x -O plan.json 2>/dev/null ; then
      echo 'OPA run failed.' >/dev/stderr
      exit 1
    fi
    exit 0
  else
    echo 'Usage: cat policy.rego | docker run -i $ASBYRGI_CONTAINER_ID rego2ir myapi result | jq .'
    echo 'The above command would generate the IR for the rule `result` from the package `myapi` of `policy.rego`.'
    echo 'Easiest way to obtain `ASBYRGI_CONTAINER_ID`: run `export ASBYRGI_CONTAINER_ID=$(docker build -q .)` from this repo.'
    exit 1
  fi
elif [ "$1" == "rego2dsl" ] ; then
  if [ $# == 3 ] ; then
    if ! opa build /dev/stdin -e "$2"/"$3" -t plan -o /dev/stdout | gunzip | tar x -O plan.json >/tmp/ir.json 2>/dev/null ; then
      echo 'OPA run failed.' >/dev/stderr
      exit 1
    fi
    if ! [ -s /tmp/ir.json ] ; then
      echo 'No IR generated.' >/dev/stderr
      exit 1
    fi
    # TODO(dkorolev): Pass "$2" and "$3" to the script.
    /src/ir2dsl.js /tmp/ir.json
    rm -f /tmp/ir.json
    exit 0
  else
    echo 'Usage: cat policy.rego | docker run -i $ASBYRGI_CONTAINER_ID rego2dsl myapi result'
    echo 'The above command would generate the DSL for the rule `result` from the package `myapi` of `policy.rego`.'
    echo 'Easiest way to obtain `ASBYRGI_CONTAINER_ID`: run `export ASBYRGI_CONTAINER_ID=$(docker build -q .)` from this repo.'
    exit 1
  fi
elif [ "$1" == "rego2js" ] ; then
  if [ $# == 3 ] ; then
    if ! opa build /dev/stdin -e "$2"/"$3" -t plan -o /dev/stdout | gunzip | tar x -O plan.json >/tmp/ir.json 2>/dev/null ; then
      echo 'OPA run failed.' >/dev/stderr
      exit 1
    fi
    if ! [ -s /tmp/ir.json ] ; then
      echo 'No IR generated.' >/dev/stderr
      exit 1
    fi
    # TODO(dkorolev): Pass "$2" and "$3" to the script.
    (cat /src/preprocess.inl.js; /src/ir2dsl.js /tmp/ir.json) | ucpp | grep -v '^#' | grep -v '^$'
    rm -f /tmp/ir.json
    exit 0
  else
    echo 'Usage: cat policy.rego | docker run -i $ASBYRGI_CONTAINER_ID rego2js myapi result'
    echo 'The above command would generate the JavaScript for the rule `result` from the package `myapi` of `policy.rego`.'
    echo 'Easiest way to obtain `ASBYRGI_CONTAINER_ID`: run `export ASBYRGI_CONTAINER_ID=$(docker build -q .)` from this repo.'
    exit 1
  fi
elif [ "$1" == "rego2cpp" ] ; then
  if [ $# == 3 ] ; then
    if ! opa build /dev/stdin -e "$2"/"$3" -t plan -o /dev/stdout | gunzip | tar x -O plan.json >/tmp/ir.json 2>/dev/null ; then
      echo 'OPA run failed.' >/dev/stderr
      exit 1
    fi
    if ! [ -s /tmp/ir.json ] ; then
      echo 'No IR generated.' >/dev/stderr
      exit 1
    fi
    # TODO(dkorolev): Pass "$2" and "$3" to the script.
    (cat /src/preprocess.inl.h; /src/ir2dsl.js /tmp/ir.json) | ucpp | grep -v '^#' | grep -v '^$'
    rm -f /tmp/ir.json
    exit 0
  else
    echo 'Usage: cat policy.rego | docker run -i $ASBYRGI_CONTAINER_ID rego2cpp myapi result'
    echo 'The above command would generate the C++ source for the rule `result` from the package `myapi` of `policy.rego`.'
    echo 'Easiest way to obtain `ASBYRGI_CONTAINER_ID`: run `export ASBYRGI_CONTAINER_ID=$(docker build -q .)` from this repo.'
    exit 1
  fi
elif [ "$1" == "evalterm" ] ; then
  if [ $# == 2 ] ; then
    if ! opa eval --data /dev/stdin --input /dev/null "$2" | jq -r .result[0].expressions[0].value ; then
      echo 'OPA run failed.' >/dev/stderr
      exit 1
    fi
    exit 0
  else
    echo 'Usage: cat policy.rego | docker run -i $ASBYRGI_CONTAINER_ID evalterm data.${PACKAGE}.${TERM}'
    exit 1
  fi
elif [ "$1" == "rego2kt" ] ; then
  if [ $# == 4 ] ; then
    if ! opa build /dev/stdin -e "$2"/"$3" -t plan -o /dev/stdout | gunzip | tar x -O plan.json >/tmp/ir.json 2>/dev/null ; then
      echo 'OPA run failed.' >/dev/stderr
      exit 1
    fi
    if ! [ -s /tmp/ir.json ] ; then
      echo 'No IR generated.' >/dev/stderr
      exit 1
    fi
    # TODO(dkorolev): Pass "$2" and "$3" to the script.
    echo "// WARNING: The code below, for the function \`$4\`, is autogenerated. DO NOT EDIT!"
    echo
    (cat /src/preprocess.inl.kt; /src/ir2dsl.js /tmp/ir.json) | ucpp | grep -v '^#' | grep -v '^\s*$' | sed 's/__INSERT_NEWLINE__/\n/g' | sed "s/__KOTLIN_EXPORT_NAME__/$4/g" >/tmp/AutogenPolicy.kt
    ktlint --format /tmp/AutogenPolicy.kt
    cat /tmp/AutogenPolicy.kt
    rm -f /tmp/ir.json /tmp/AutogenPolicy.kt
    exit 0
  else
    echo 'Usage: cat policy.rego | docker run -i $ASBYRGI_CONTAINER_ID rego2kt myapi result KotlinClassName'
    echo 'The above command would generate the JavaScript for the rule `result` from the package `myapi` of `policy.rego`.'
    echo 'Easiest way to obtain `ASBYRGI_CONTAINER_ID`: run `export ASBYRGI_CONTAINER_ID=$(docker build -q .)` from this repo.'
    exit 1
  fi
elif [ "$1" == "gengolden" ] ; then
  if [ $# == 5 ] ; then
    opa build /input/"$2"
    opa run --server bundle.tar.gz -l error >/dev/null 2>dev/null &
    OPA_PID=$!
    sleep 0.5  # TODO(dkorolev): I would love to check `localhost:8181/health`, but it just returns `{}`, w/o HTTP code or body.
    while read -r QUERY ; do
      curl -s -d "{\"input\":$QUERY}" localhost:8181/v1/data | jq -c .result.$3.$4
    done < /input/"$5"
    kill $OPA_PID
    wait
    exit 0
  else
    echo 'Recommended synopsis: `docker run -v "$PWD"/input $ASBYRGI_CONTAINER_ID gengolden policy.rego myapi result tests.json`.'
    echo 'This requires `policy.rego` and `tests.json` in the current directory. The tests should be one JSON per line.'
    echo 'Easiest way to obtain `ASBYRGI_CONTAINER_ID`: run `export ASBYRGI_CONTAINER_ID=$(docker build -q .)` from this repo.'
    exit 1
  fi
elif [ "$1" == "kt_test.tar.gz" ] ; then
  cat kt_test.tar.gz
  # Can also `docker run ${ASBYRGI_CONTAINER_ID} kt_test.tar.bz2 | tar xzO kt_test/src/main/kotlin/RegoEngine.kt`.
elif [ "$1" == "compose_kt_test" ] ; then
  if [ $# == 2 ] ; then
    node src/compose_kt_test.js $2
  else
    echo 'The `compose_kt_test` command needs one argument, some `KotlinFunctionName`, and then'
    echo 'it converts the stream of tab-separated "INPUT OUTPUT" fields into a ready-to-run Kotlin test.'
    exit 1
  fi
elif [ "$1" == "ktRunTests" ] ; then
  (cd kt_test; gradle test -Dtestlogger.logLevel=quiet)
else
  opa $*
  if [ "$*" == "" ] ; then
    echo
    echo 'Last but not least: This is the Asbyrgi container, not just the OPA binary.'
    echo 'Thus, it has a lot more commands, including, but not limited to, rego2ir, rego2dsl, rego2kt, etc.'
  fi
fi
