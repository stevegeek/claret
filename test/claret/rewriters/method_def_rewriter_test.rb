# frozen_string_literal: true

require "test_helper"
require "claret/rewriters/1_method_def_rewriter"

class MethodDefRewriterTest < Minitest::Test
  def setup
    @rewriter = Claret::Rewriters::MethodDefRewriter.new(RubyNext::Language::TransformContext.new)
  end

  def test_rewrites_a_arity_0_method
    new_source = @rewriter.rewrite(<<~RUBY)
      class Test
        def test
        end
      end
    RUBY

    assert_equal(<<~RUBY, new_source)
      class Test
        def test # @sig () -> void
        end
      end
    RUBY
  end

  def test_rewrites_a_arity_0_method_with_inline_comment
    # The comment is removed by normalizer when using #rewrite
    new_source = @rewriter.rewrite(<<~RUBY)
      class Test
        def test # inline comment
        end
      end
    RUBY

    assert_equal(<<~RUBY, new_source)
      class Test
        def test # A1Я # @sig () -> void
        end
      end
    RUBY

    # but not when using #safe_rewrite
    new_source = @rewriter.safe_rewrite(<<~RUBY)
      class Test
        def test # inline comment
        end
      end
    RUBY

    assert_equal(<<~RUBY, new_source)
      class Test
        def test # inline comment # @sig () -> void
        end
      end
    RUBY
  end

  def test_rewrites_a_arity_0_method_with_return_type
    new_source = @rewriter.rewrite(<<~RUBY)
      class Test
        def test => String
          "test"
        end
      end
    RUBY
    assert_equal(<<~RUBY, new_source)
      class Test
        def test           # @sig () -> String
          "test"
        end
      end
    RUBY
  end

  def test_rewrites_a_arity_0_method_with_commented_out_return_type
    new_source = @rewriter.safe_rewrite(<<~RUBY)
      class Test
        def test # -> String
          "test"
        end
      end
    RUBY
    assert_equal(<<~RUBY, new_source)
      class Test
        def test # -> String # @sig () -> void
          "test"
        end
      end
    RUBY
  end

  def test_rewrites_a_arity_1_method
    new_source = @rewriter.rewrite(<<~RUBY)
      class Test
        def test(String name)
        end
      end
    RUBY

    assert_equal(<<~RUBY, new_source)
      class Test
        def test(       name) # @sig (String name) -> void
        end
      end
    RUBY
  end

  def test_rewrites_a_arity_1_method_with_inline_comment
    # The comment is removed by normalizer when using #rewrite
    new_source = @rewriter.rewrite(<<~RUBY)
      class Test
        def test(String name) # inline comment
        end
      end
    RUBY

    assert_equal(<<~RUBY, new_source)
      class Test
        def test(       name) # A1Я # @sig (String name) -> void
        end
      end
    RUBY

    # but not when using #safe_rewrite
    new_source = @rewriter.safe_rewrite(<<~RUBY)
      class Test
        def test(String name) # inline comment
        end
      end
    RUBY

    assert_equal(<<~RUBY, new_source)
      class Test
        def test(       name) # inline comment # @sig (String name) -> void
        end
      end
    RUBY
  end

  def test_rewrites_a_arity_1_method_with_return_type
    new_source = @rewriter.rewrite(<<~RUBY)
      class Test
        def test(String name) => String
          name
        end
      end
    RUBY
    assert_equal(<<~RUBY, new_source)
      class Test
        def test(       name)           # @sig (String name) -> String
          name
        end
      end
    RUBY
  end
end
