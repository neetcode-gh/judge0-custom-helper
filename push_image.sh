#!/bin/bash

JUDGE_VERSION="${1:-1.13.0}"
sudo docker push registry.gitlab.com/edgar-group/judge0:${JUDGE_VERSION}
