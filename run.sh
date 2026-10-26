#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Runs the complete Terraform workflow and saves every step as a log file in ./logs
#
#   bash run.sh              -> runs everything and pauses before "terraform destroy"
#                               (so that you can take screenshots)
#   bash run.sh --no-pause   -> runs everything without pausing
# ---------------------------------------------------------------------------
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p logs

PAUSE=true
[[ "${1:-}" == "--no-pause" ]] && PAUSE=false

# step <log-file-name> <command...> : prints the command, runs it and saves the output
step() {
  local name="$1"; shift
  echo
  echo "=================================================================="
  echo ">>> $*"
  echo "=================================================================="
  { echo "\$ $*"; "$@" 2>&1; } | tee "logs/${name}.log"
}

# Checks that the container is healthy and answers over HTTP
verify() {
  local name url status
  name="$(terraform output -raw container_name)"
  url="$(terraform output -raw web_url)"
  echo "--- docker ps"
  docker ps --filter "name=${name}"
  echo
  echo "--- waiting for the container health check"
  for i in $(seq 1 20); do
    status="$(docker inspect -f '{{.State.Health.Status}}' "${name}")"
    echo "health status: ${status}"
    [[ "${status}" == "healthy" ]] && break
    sleep 3
  done
  echo
  echo "--- HTTP test: ${url}"
  curl -sS -o /dev/null -w "HTTP status: %{http_code}\n" "${url}"
  curl -sS "${url}" | head -n 12
}

# Shows that nothing is left after terraform destroy
after_destroy() {
  echo "--- docker containers named ${CONTAINER_NAME} (should be empty):"
  docker ps -a --filter "name=${CONTAINER_NAME}"
  echo
  echo "--- docker networks named ${CONTAINER_NAME}-net (should be empty):"
  docker network ls --filter "name=${CONTAINER_NAME}-net"
  echo
  echo "--- terraform state list (should print nothing):"
  terraform state list || true
}

step 00-versions       bash -c 'terraform version && echo && docker --version'
step 01-init           terraform init -no-color
step 02-fmt            terraform fmt -recursive
step 03-validate       terraform validate -no-color
step 04-plan           terraform plan -no-color -out=tfplan
step 05-apply          terraform apply -no-color tfplan
step 06-state-list     terraform state list
step 07-state-show     terraform state show -no-color docker_container.web
step 08-outputs        terraform output
step 09-verify         verify
step 10-plan-again     terraform plan -no-color
step 11-graph          terraform graph

CONTAINER_NAME="$(terraform output -raw container_name)"

if $PAUSE && [ -t 0 ]; then
  echo
  echo "Infrastructure is running. Take your screenshots now:"
  echo "  - docker ps"
  echo "  - browser: $(terraform output -raw web_url)"
  read -r -p "Press Enter to run terraform destroy... " _
fi

step 12-destroy        terraform destroy -auto-approve -no-color
step 13-after-destroy  after_destroy

echo
echo "Done. All execution logs are saved in the ./logs folder:"
ls -1 logs
