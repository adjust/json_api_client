module JsonApiClient
  class Scope
    attr_reader :klass, :params

    def initialize(klass)
      @klass = klass
      @params = {}
    end

    def where(conditions = {})
      @params.merge!(filter: conditions)
      self
    end

    def sort(conditions)
      @params.merge!(sort: conditions)
      self
    end
    alias order sort

    def includes(*tables)
      @params[:includes] ||= []
      @params[:includes] += tables.flatten
      self
    end

    def page(number)
      set_page(:number, number)
      self
    end

    def per(size)
      set_page(:size, size)
      self
    end

    def first
      paginate(page: 1, per_page: 1).to_a.first
    end

    def build
      klass.new(params)
    end

    def to_a
      @to_a ||= klass.find(params)
    end
    alias all to_a

    def method_missing(method_name, *args, &block)
      to_a.send(method_name, *args, &block)
    end

    private

    def set_page(option, number)
      @params[:page] ||= {}
      @params[:page][option] = number
    end
  end
end
