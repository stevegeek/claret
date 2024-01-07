# claret

Ruby + RBS = claret

```ruby
# examples/hello_world.rb

class HelloWorld
  def initialize(String @name = "world")
  end

  def say_it_to(String name = @name, (Integer | Float) age = (1 + 2)) => String
    "Hello #{name}! You are #{age} years old."
  end
end

# 42 should be an Integer or Float
puts HelloWorld.new.say_it_to("bob", "42")
```

```
$ ./exe/claret start examples/hello_world.rb
--- steep output ---
# Type checking files:

............................................................................F........

lib/examples/hello_world.rb:18:37: [error] Cannot pass a value of type `::String` as an argument of type `(::Integer | ::Float)`
│   ::String <: (::Integer | ::Float)
│     ::String <: ::Integer
│       ::Object <: ::Integer
│         ::BasicObject <: ::Integer
│
│ Diagnostic ID: Ruby::ArgumentTypeMismatch
│
└ puts HelloWorld.new.say_it_to("bob", "42")
                                       ~~~~

Detected 1 problem from 1 file
--- End steep output ---
🚨 Something went wrong with steep!
```


### `claret` is:

- an attempt at creating a **typed Ruby syntax** that incorporates RBS like **types directly into the Ruby source**
- A **CLI that transpiles the typed Ruby to pure Ruby and an RBS** file, thus allowing the existing Ruby runtime and type checker steep to do the heavy lifting

### `claret` aims to be

- **optional**: you can type only some parts of your application (similarly to RBS) and mix typed and not typed code
- **debugging friendly**: runtime error source locations will map relatively well to their typed source counterpart
- **runtime friendly**: claret is built with Ruby-next meaning transpilation can happen at runtime too using the ruby-next require hook
- **escape-able**: you can use the CLI to erase the type information and emit the pure Ruby code should you wish to stop using it

### `claret` future directions:

- build an AST based parser allowing for more accurate transpilation
- Ability to also emit Crystal code allowing for the possibility to create single code base Ruby/Crystal projects (assuming you only use language features which are comparable to both languages)

## Warning: Experimental Tool

Please note that claret is currently an experimental tool, and as such, it is subject to change or may never reach a stable release. The syntax for inline type signatures could also evolve, potentially causing compatibility issues with certain Ruby codebases. Proceed with caution and be prepared for possible adjustments in the future.

## Alternative "Types in Ruby" implementations

* [myrb](https://github.com/camertron/myrb) by [Cameron Dutro](https://github.com/camertron)

Also see my list of [related projects](https://github.com/stars/stevegeek/lists/typed-ruby).

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add claret

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install claret

## Usage

```
claret help
Commands:
  claret check [SCRIPT]  # Check the given file for type errors, or all files if none given
  claret execute SCRIPT  # Run the typed Ruby SCRIPT
  claret help [COMMAND]  # Describe available commands or one specific command
  claret remove          # Remove all type annotations from the project
  claret ruby SCRIPT     # [Alias of 'execute']
  claret start SCRIPT    # Run type checking and then execute the SCRIPT
  claret steep [SCRIPT]  # [Alias of 'check']

Options:
  [--debug], [--no-debug]  
                           # Default: false
  [--quiet], [--no-quiet]  
                           # Default: false
  [--time], [--no-time]    
                           # Default: false
```

## Supported Syntax

Here's a brief summary of the state of support for the key features of RBS. ✅ means supported, 🚧 means partial support, 🔴 means not supported

-   🚧 **Type Definitions:** Allows defining class, module, and interface types.
-   ✅ **Typed Method Arguments:** Specifies types for method arguments.
-   ✅ **Return Types:** Declares the type of value a method returns.
-   🚧 **Variable Types:** Type annotations for instance, class, and global variables.
-   🔴 **Block Parameters and Types:** Specifies types for block parameters and return values.
-   🔴 **Generics:** Support for generic classes and modules with type parameters.
-   🔴 **Type Aliases:** Defining aliases for complex types.
-   🔴 **Literal Types:** Defining types using literal values.
-   🔴 **Tuple and Record Types:** Tuple types for fixed-size arrays and record types for hash-like objects.

we also aim to support some of `steep` directives directly in `claret`:

-   🔴 typed local variables
-   🔴 Type casting

For a complete and detailed overview of the syntax, please refer to the [RBS Syntax Documentation](https://github.com/ruby/rbs/blob/master/docs/syntax.md).

### Future features:

-   merge RBS into Ruby to produce `claret` dialect Ruby automatically
-   Export RBS and pure Ruby (eg so you can package in a gem)
-   Much quicker processing!

## Syntax Documentation

### Methods

In claret's typed Ruby syntax, types are specified directly before the argument name (optionally enclosed in parentheses).
For return types, an fat arrow (=>) is used after the method definition, followed by the type.

Here are a couple of examples to demonstrate this syntax:

```ruby
def my_method(Integer a, String b = "hi") => String
  # method body
end

def another_method(untyped kwarg1:, (Alice | Bob[String]) kwarg2: nil)
  # method body, note return type is implicitly untyped
end
```

In the first example, `my_method` takes two arguments: an `Integer` named `a`, and a `String` named `b` with a
default value of "hi". The method returns a `String`.

The second example, `another_method`, has two keyword arguments: an untyped argument named `kwarg1`, and
an argument named `kwarg2` that can be either an instance of class `Alice` or a generic instance of class
`Bob` with its type parameter set to `String`. The default value for `kwarg2` is set to nil.

**Notes**:

1) No return type means an implicit `void` return type.

2) when specifying method argument types in claret's typed Ruby syntax, you must enclose the type information in
parentheses if it consists of more than a single simple type. This is especially relevant when creating
union types or other complex type constructs.


### Instance Variable Setting Short Hand Syntax

In `claret`'s typed Ruby syntax, you can simplify the process of setting instance variables from method arguments by
using a shorthand syntax inspired by Crystal lang. By prefixing the argument name with an `@` symbol in the
method definition, the corresponding instance variable will be automatically set to the argument value upon
method call.

Here's a Box example demonstrating this shorthand syntax:

```ruby
class Box
  def initialize(String @item) => void
  end
  attr_reader :item: String
end

puts Box.new("Hello").item # “Hello”
```

In this example, we've modified the `initialize` method definition to use the shorthand syntax for setting
the `@item` instance variable. By writing `String @item`, we're telling claret the type of `@item`, and to
automatically set `@item` to the value passed as an argument when calling the `initialize` method. This
eliminates the need for explicitly assigning `@item = item` within the method body.

**Note**:

This syntax will add one or more lines to the start of your `initialize` method and as such will
change line numbers between the output Ruby and your original typed Ruby source. Thus, your debugging
experience will be worse as error source line numbers will not map back to your original typed Ruby source file.



## Future Syntax (not yet supported)


## TODO: 

- ivars typing
- Generics

In claret's typed Ruby syntax, generic types are included after types in a similar manner to RBS. The type parameters are enclosed within square brackets `[ ]` and separated by commas.&#x20;

Here's an example demonstrating the use of generic types:

```ruby
def process_data(Array[Integer] numbers) => Hash[String, Integer]
  # method body
end
```

In this example, `process_data` takes an argument named `numbers`, which is an `Array` of `Integer` elements. The method returns a `Hash` with keys of type `String` and values of type `Integer`.


Class Definitions with Generics

To define a class with generic types in claret's typed Ruby syntax, include the type parameters after the class name, enclosed within square brackets `[ ]`. Here's an example demonstrating this:

```ruby
class Box[ItemType]
  @item: ItemType
  def initialize(ItemType item) => void
    @item = item
  end
end

my_box = Box[String].new("Hello")
```

In this example, we define a `Box` class with a generic type parameter `ItemType`. The instance variable and `initialize` method uses the generic type to ensure that the box can only store and return items of a specific type. When creating an instance of the `Box` class, we specify the desired type within square brackets, as seen with `Box[String].new("Hello")`.


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/claret. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/claret/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Claret project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/claret/blob/master/CODE_OF_CONDUCT.md).
