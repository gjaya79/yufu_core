module Order
  class Written
    class EventsService
      def initialize(order)
        @order = order
      end

      def after_paid_order
        OrderWrittenQueueFactoryWorker.new.perform @order.id, I18n.locale

        # if @order.translation_language.is_chinese
        #   if (Profile::Translator.approved.chinese.support_written_order(@order)).count > 0
        #     OrderWrittenQueueFactoryWorker.new.perform @order.id, I18n.locale
        #     # OrderWrittenWorkflowWorker.perform_in 1.minutes, @order.id, 'confirmation_order_in_30'
        #   else
        #     if (Profile::Translator.approved.support_written_order(@order).where(:'profile_steps_service.hsk_level'.gt => 4)).count > 0
        #       OrderWrittenQueueFactoryWorker.new.perform @order.id, I18n.locale
        #       # MAIL to TR - NEW ORDER AVAIL
        #       # wait translation
        #     else
        #       @order.notify_about_cancellation_by_yufu
        #     end
        #   end
        # else
        #   if (Profile::Translator.approved.support_written_order(@order).where(:'profile_steps_service.hsk_level'.gt => 4)).count > 0
        #     OrderWrittenQueueFactoryWorker.new.perform @order.id, I18n.locale
        #     # @order.notify_about_new_order_available
        #     # MAIL to TR - NEW ORDER AVAIL
        #     # wait translation
        #   else
        #     @order.notify_about_cancellation_by_yufu
        #   end
        # end
      end

      def after_proof_reading
        # 70 / 40 to proof reader
        # qc
      end

      def after_translate_order
        if @order.translation_language.is_chinese
          if @order.assignee.chinese?
            # 70% to tr
            if @order.need_proof_reading?
              Support::Ticket.create text: 'written order', theme: Support::Theme.first,
                  subject: 'some subject'
              # wait proofreading by BO
            else
              # qc
            end
          else#обязательно пруф ридинг тк переводил не китаец
            Support::Ticket.create text: 'written order', theme: Support::Theme.first,
                                   subject: 'some subject'
            # 60% to tr
            # wait proofreading by BO
          end
        else# from ch to any
          # 70% to tr
          if @order.need_proof_reading?
            if @order.assignee.can_proof_read? @order.translation_language
              @order.proof_reader = @order.assignee
              @order.correct
              #transition to state proof_read
            else
              # ГОНКА ЗА ПРУФ РИДИНГ
              # MAIL to TR - NEW ORDER AVAIL
            end
          else
            @order.control
            # qc
          end
        end


      end

      def confirmation_order_in_30
        if @order.assignee.present?
          # wait translation
        else
          if (Profile::Translator.approved.support_written_order(@order).where(:'profile_steps_service.hsk_level'.gt => 4)).count > 0
            OrderWrittenQueueFactoryWorker.new.perform @order.id, I18n.locale
            # MAIL to TR - NEW ORDER AVAIL
            # wait translation
          else
            @order.notify_about_cancellation_by_yufu
          end
        end

      end
    end
  end
end
