#!/bin/bash

# Uso: ./start_server.sh [puerto]
PORT=${1:-3000}

echo "Iniciando servidor Rails en puerto $PORT..."

# Corre el servidor en background y guarda el PID en tmp/pids/server.pid
RAILS_ENV=production bundle exec rails server -p $PORT -b 192.168.100.11 -d
nohup bundle exec ruby daemon_expired.rb > log/daemon_expired.log 2>&1 &

echo "Servidor iniciado. PID guardado en tmp/pids/server.pid"
