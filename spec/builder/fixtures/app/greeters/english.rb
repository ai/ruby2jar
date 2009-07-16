class EnglishGreeter
  def initialize(name)
    @name = name.capitalize
  end
  def salute
    puts "Hello #{@name}!"
  end
end
