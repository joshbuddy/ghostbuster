#!/bin/bash

bundle exec thin --port 4567 -P thin.pid -d -R config.ru stop
