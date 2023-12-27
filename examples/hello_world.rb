# examples/hello_world.rb

class HelloWorld
  def initialize(String @name = "world")
  end

  def say_it_to(String name = @name, (Integer | Float) age = (1 + 2))
    puts "Hello #{name}! You are #{age} years old."
  end

  def test
    puts "test"
  end
end

HelloWorld.new.say_it_to

HelloWorld.new.say_it_to("bob", 42)
