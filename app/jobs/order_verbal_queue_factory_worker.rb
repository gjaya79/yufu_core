class OrderVerbalQueueFactoryWorker < ActiveJob::Base
  queue_as :default

  def perform(order_id, locale = 'en')
    I18n.locale = locale
    order = Order::Verbal.find order_id
    date_iterator = DateTime.now
    create_queue = proc do |queue_name|
      build_method = "create_#{queue_name}_queue"
      queue = Order::Verbal::TranslatorsQueue.send build_method, order, date_iterator
      if queue.present?
        queue.lock_to <= DateTime.now ? queue.notify_about_create :
            ActivateVerbalTranslationQueueJob.set(wait: 30.minutes).perform_later(queue.id.to_s)
        date_iterator += 30.minutes
        true
      else
        false
      end
    end

    create_queue.call 'native'
    create_queue.call 'agent'
    create_queue.call 'senior'
    create_queue.call 'without_surcharge'
    create_queue.call 'with_surcharge'
  end

end
