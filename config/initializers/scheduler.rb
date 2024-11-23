require 'rufus-scheduler'

ENV['TZ'] = 'America/Caracas'

scheduler = Rufus::Scheduler.new

# ----- Update daily exchange task
scheduler.cron '0 8 * * *' do
  Shared::Exchange.create(
    automatic: true
  )
end

# ----- Verify winners scheduler every 15 minutes
scheduler.every '15m' do
  puts Time.now
end

puts "
+--------------------------+
|           RUFUS          |
+--------------------------+
|    SCHEDULERS ACTIVOS    |
+--------------------------+
|       Daily currency     |
|  Verify triples winners  |
+--------------------------+
"