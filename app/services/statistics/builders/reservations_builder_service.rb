# frozen_string_literal: true

# Generate statistics indicators about reservations
class Statistics::Builders::ReservationsBuilderService
  include Statistics::Concerns::HelpersConcern

  class << self
    def build(options = default_options)
      # machine/space/training list
      %w[machine space training event].each do |category|
        Statistics::FetcherService.send("reservations_#{category}_list", options).each do |r|
          %w[booking hour].each do |type|
            stat = "Stats::#{category.capitalize}"
                   .constantize
                   .new({ date: format_date(r[:date]),
                          type: type,
                          subType: r["#{category}_type".to_sym],
                          ca: r[:ca],
                          name: r["#{category}_name".to_sym],
                          reservationId: r[:reservation_id] }.merge(user_info_stat(r)))
            stat[:stat] = (type == 'booking' ? 1 : r[:nb_hours])
            stat["#{category}Id".to_sym] = r["#{category}_id".to_sym]

            stat = add_custom_attributes(category, stat, r)
            stat.save
          end
        end
      end
    end

    def add_custom_attributes(category, stat, reservation_data)
      stat = add_event_attributes(category, stat, reservation_data)
      add_training_attributes(category, stat, reservation_data)
    end

    def add_event_attributes(category, stat, reservation_data)
      return stat unless category == 'event'

      stat[:eventDate] = reservation_data[:event_date]
      stat[:eventTheme] = reservation_data[:event_theme]
      stat[:ageRange] = reservation_data[:age_range]

      stat
    end

    def add_training_attributes(category, stat, reservation_data)
      return stat unless category == 'training'

      stat[:trainingDate] = reservation_data[:training_date]

      stat
    end
  end
end
