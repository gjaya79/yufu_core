class Order::Verbal::Event
  include Mongoid::Document

  field :name, type: String
  field :is_complete, type: Mongoid::Boolean, default: false

  embedded_in :events_manager, class_name: 'Order::Verbal::EventsManager'

  def run
    Order::Verbal::EventsService.new(events_manager.order_verbal).send name
    self.is_complete = true
    events_manager.save!
  end
end