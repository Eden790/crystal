module Crystal
  abstract class Type
    def self.merge(types)
      types = types.compact
      return nil if types.empty?
      first = types.first
      raise "Bug found!" unless first
      first.program.type_merge(types)
    end
  end

  class ContainedType < Type
    getter :container
    getter :types

    def initialize(@container)
      @types = {} of String => Type
    end

    def program
      container.program
    end
  end

  module DefContainer
    def defs
      @defs ||= {} of String => Def
    end

    def add_def(a_def)
      defs[a_def.name] = a_def
    end
  end

  abstract class ModuleType < ContainedType
    include DefContainer

    getter :name
    getter :parents

    def initialize(container, @name)
      super(container)
      @parents = [] of Type
    end

    def to_s
      @name
    end
  end

  class NonGenericModuleType < ModuleType
  end

  module InheritableClass
    def add_subclass(subclass)
      subclasses << subclass
      notify_subclass_added
      @superclass.notify_subclass_added if @superclass
    end

    def notify_subclass_added
      # if @subclass_observers
      #   @subclass_observers.each do |observer|
      #     observer.on_new_subclass
      #   end
      # end
    end
  end

  abstract class ClassType < ModuleType
    include InheritableClass

    getter :superclass
    getter :subclasses
    getter :depth
    property :abstract

    def initialize(container, name, @superclass, add_subclass = true)
      super(container, name)
      if superclass
        @depth = superclass.depth + 1
      else
        @depth = 0
      end
      @subclasses = [] of Type
      @parents.push superclass if superclass
      force_add_subclass if add_subclass
    end

    def force_add_subclass
      @superclass.add_subclass(self) if @superclass
    end
  end

  class NonGenericClassType < ClassType
  end

  class PrimitiveType < ClassType
    getter :llvm_type
    getter :llvm_size

    def initialize(container, name, superclass, @llvm_type, @llvm_size)
      super(container, name, superclass)
    end

    def llvm_name
      name
    end
  end

  class IntegerType < PrimitiveType
    getter :rank

    def initialize(container, name, superclass, llvm_type, llvm_size, @rank)
      super(container, name, superclass, llvm_type, llvm_size)
    end
  end

  class FloatType < PrimitiveType
    getter :rank

    def initialize(container, name, superclass, llvm_type, llvm_size, @rank)
      super(container, name, superclass, llvm_type, llvm_size)
    end
  end

  class NilType < PrimitiveType
  end

  class ValueType < NonGenericClassType
    def value?
      true
    end
  end
end
