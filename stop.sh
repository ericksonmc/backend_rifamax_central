#!/bin/bash

PID_FILE="tmp/pids/server.pid"

if [ -f $PID_FILE ]; then
  PID=$(cat $PID_FILE)
  echo "Deteniendo servidor con PID $PID..."
  kill -9 $PID
  rm -f $PID_FILE
  echo "Servidor detenido."
else
  echo "No se encontró el archivo $PID_FILE. ¿Seguro que el servidor está corriendo con -d?"
fi
