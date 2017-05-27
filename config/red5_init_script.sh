#!/bin/sh
### BEGIN INIT INFO
# Provides:          red5
# Required-Start:    $remote_fs
# Required-Stop:     $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start daemon at boot time
# Description:       Red5 Flash Streaming Server
### END INIT INFO

PROG=red5
USER=red5
RED5_HOME=/usr/local/red5
DAEMON=$RED5_HOME/$PROG.sh
PIDFILE=/var/run/$PROG.pid

# Source function library
. /lib/lsb/init-functions

[ -r /etc/sysconfig/red5 ] && . /etc/sysconfig/red5

RETVAL=0

case "$1" in
start)
echo -n $"Starting $PROG: "
cd $RED5_HOME
TMPPID=/tmp/$$.$PROG.pid
runuser $USER -s /bin/bash -c "$DAEMON >/dev/null 2>/dev/null & echo \$! > $TMPPID"
RETVAL=$?
if [ $RETVAL -eq 0 ]; then
    mv  $TMPPID $PIDFILE
    touch /var/lock/subsys/$PROG
fi
rm -f $TMPPID
[ $RETVAL -eq 0 ] && log_success_msg || log_failure_msg
echo
;;
stop)
echo -n $"Shutting down $PROG: "
killproc -p $PIDFILE
RETVAL=$?
echo
[ $RETVAL -eq 0 ] && rm -f /var/lock/subsys/$PROG
;;
restart)
$0 stop
$0 start
;;
status)
status $PROG -p $PIDFILE
RETVAL=$?
;;
*)
echo $"Usage: $0 {start|stop|restart|status}"
RETVAL=1
esac

exit $RETVAL
