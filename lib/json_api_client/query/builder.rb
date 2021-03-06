module JsonApiClient
  module Query
    class Builder

      attr_reader :klass

      def initialize(klass)
        @klass = klass
        @pagination_params = {}
        @filters = {}
        @includes = []
        @orders = []
        @fields = []
      end

      def where(conditions = {})
        @filters.merge!(conditions)
        self
      end

      def order(*args)
        @orders += parse_orders(*args)
        self
      end

      def includes(*tables)
        @includes += parse_related_links(*tables)
        self
      end

      def select(fields)
        @fields += fields.split(",").map(&:strip)
        self
      end

      def paginate(conditions = {})
        @pagination_params.merge!(conditions.slice(:page, :per_page))
        self
      end

      def page(number)
        @pagination_params[:page] = number
        self
      end

      def first
        paginate(page: 1, per_page: 1).to_a.first
      end

      def build
        klass.new(params)
      end

      def params
        filter_params
          .merge(pagination_params)
          .merge(includes_params)
          .merge(order_params)
          .merge(select_params)
      end

      def to_a
        @to_a ||= klass.find(params)
      end
      alias all to_a

      def method_missing(method_name, *args, &block)
        to_a.send(method_name, *args, &block)
      end

      private

      attr_reader :pagination_params

      def includes_params
        @includes.empty? ? {} : {include: @includes.join(",")}
      end

      def filter_params
        @filters.empty? ? {} : {filter: @filters}
      end

      def order_params
        @orders.empty? ? {} : {sort: @orders.join(",")}
      end

      def select_params
        @fields.empty? ? {} : {fields: {klass.table_name => @fields.join(",")}}
      end

      def parse_related_links(*tables)
        tables.map do |table|
          case table
          when Hash
            table.map do |k, v|
              parse_related_links(*v).map do |sub|
                "#{k}.#{sub}"
              end
            end
          when Array
            table.map do |v|
              parse_related_links(*v)
            end
          else
            table
          end
        end.flatten
      end

      def parse_orders(*args)
        args.map do |arg|
          case arg
          when Hash
            arg.map do |k, v|
              operator = (v == :desc ? "-" : "+")
              "#{operator}#{k}"
            end
          else
            "+#{arg}"
          end
        end.flatten
      end

    end
  end
end
