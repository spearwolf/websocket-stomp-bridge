namespace :start do

  desc "Run ActiveMQ message broker with Stomp protocol enabled"
  task :activemq do
    exec "cd ../netsrc/apache-activemq-5.4.1 && ./bin/activemq console xbean:conf/activemq-stomp.xml"
  end
end
