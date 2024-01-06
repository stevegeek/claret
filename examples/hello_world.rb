# examples/hello_world.rb

class HelloWorld
  def initialize(String name = "world")
    @name = name
  end

  def say_it_to(String name = @name, (Integer | Float) age = (1 + 2)) => String
    "Hello #{name}! You are #{age.to_i} years old."
  end

  def test => void
    puts "test"
  end
end

puts HelloWorld.new.say_it_to

puts HelloWorld.new.say_it_to("bob", 42)
