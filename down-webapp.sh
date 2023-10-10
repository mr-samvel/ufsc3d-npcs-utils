port=8080
pid=`ps ax | grep gunicorn | grep $port | awk '{split($0,a," "); print a[1]}' | head -n 1`
if [ -z "$pid" ]; then
    echo "Nao foi possivel derrubar webserver da porta $port (processo nao encontrado)"
else
    kill $pid
    echo "Webserver da porta $port derrubado. PID: $pid"
fi