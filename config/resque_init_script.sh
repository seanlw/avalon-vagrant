#!/bin/bash
### BEGIN INIT INFO
# Provides:          resque
# Required-Start:    $remote_fs
# Required-Stop:     $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start daemon at boot time
# Description:       Resque Scheduler and Worker
### END INIT INFO

RAILS_ROOT="/var/www/avalon"
ENV="development"

case "$1" in
  start)
  echo -n "Starting Resque Scheduler and Worker: "
  su - avalon -c "cd $RAILS_ROOT && RAILS_ENV=$ENV BACKGROUND=yes bundle exec rake resque:scheduler &" >> $RAILS_ROOT/log/resque_scheduler.log 2>&1
  su - avalon -c "cd $RAILS_ROOT && RAILS_ENV=$ENV BACKGROUND=yes QUEUE=* bundle exec rake resque:work &" >> $RAILS_ROOT/log/resque_worker.log 2>&1
  echo "done."
  ;;
  stop)
  echo -n "Stopping Resque Scheduler and Worker: "
  ps -ef | grep "resque-scheduler" | head -n1 | awk '{ print $2 }' | xargs kill >> $RAILS_ROOT/log/resque_scheduler.log 2>&1
  ps -ef | grep "resque-1" | head -n1 | awk '{ print $2 }' | xargs kill >> $RAILS_ROOT/log/resque_worker.log 2>&1
  echo "done."
  ;;
  *)
  echo "Usage: $N {start|stop}" >&2
  exit 1
  ;;
esac

exit 0
