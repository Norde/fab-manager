# frozen_string_literal: true

# A machine reservation added to the shopping cart
class CartItem::MachineReservation < CartItem::Reservation
  # @param plan {Plan} a subscription bought at the same time of the reservation OR an already running subscription
  # @param new_subscription {Boolean} true is new subscription is being bought at the same time of the reservation
  def initialize(customer, operator, machine, slots, plan: nil, new_subscription: false)
    raise TypeError unless machine.is_a? Machine

    super(customer, operator, machine, slots)
    @plan = plan
    @new_subscription = new_subscription
  end

  def to_object
    ::Reservation.new(
      reservable_id: @reservable.id,
      reservable_type: Machine.name,
      slots_reservations_attributes: slots_params,
      statistic_profile_id: StatisticProfile.find_by(user: @customer).id
    )
  end

  def type
    'machine'
  end

  def valid?(all_items)
    @slots.each do |slot|
      same_hour_slots = SlotsReservation.joins(:reservation).where(
        reservations: { reservable: @reservable },
        slot_id: slot[:slot_id],
        canceled_at: nil
      ).count
      if same_hour_slots.positive?
        @errors[:slot] = 'slot is reserved'
        return false
      end
    end

    super
  end

  protected

  def credits
    return 0 if @plan.nil?

    machine_credit = @plan.machine_credits.find { |credit| credit.creditable_id == @reservable.id }
    credits_hours(machine_credit, new_plan_being_bought: @new_subscription)
  end
end
