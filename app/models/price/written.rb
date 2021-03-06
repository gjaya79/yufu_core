module Price
  class Written < Base

    field :increase_price, type: BigDecimal, default: 1.4
    field :value_ch,  type: BigDecimal
    field :min_order, type: Integer

    belongs_to :written_type, class_name: 'Order::Written::WrittenType'

    validates :level, presence: true, inclusion: Order::Written::TYPES
  end
end
