set :environment, :test
configure :test do
  $log.level = Logger::WARN
end
