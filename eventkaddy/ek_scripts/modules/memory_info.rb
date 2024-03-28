module MemoryInfo

  def self.stats msg
    size = `ps -o rss= #{$$}`.strip.to_i
    puts 'MemoryInfo'
    puts msg if msg
    puts size
  end

end
