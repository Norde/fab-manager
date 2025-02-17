# frozen_string_literal: true

# Machine is an hardware equipment hosted in the Fablab that is available for reservation to the members
class Machine < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  has_one :machine_image, as: :viewable, dependent: :destroy
  accepts_nested_attributes_for :machine_image, allow_destroy: true
  has_many :machine_files, as: :viewable, dependent: :destroy
  accepts_nested_attributes_for :machine_files, allow_destroy: true, reject_if: :all_blank

  has_many :projects_machines, dependent: :destroy
  has_many :projects, through: :projects_machines

  has_many :machines_availabilities, dependent: :destroy
  has_many :availabilities, through: :machines_availabilities

  has_many :trainings_machines, dependent: :destroy
  has_many :trainings, through: :trainings_machines

  validates :name, presence: true, length: { maximum: 50 }
  validates :description, presence: true

  has_many :prices, as: :priceable, dependent: :destroy
  has_many :prepaid_packs, as: :priceable, dependent: :destroy

  has_many :reservations, as: :reservable, dependent: :destroy
  has_many :credits, as: :creditable, dependent: :destroy
  has_many :plans, through: :credits

  has_one :payment_gateway_object, as: :item, dependent: :destroy

  has_many :machines_products, dependent: :destroy
  has_many :products, through: :machines_products

  after_create :create_statistic_subtype
  after_create :create_machine_prices
  after_create :update_gateway_product
  after_update :update_gateway_product, if: :saved_change_to_name?
  after_update :update_statistic_subtype, if: :saved_change_to_name?
  after_destroy :remove_statistic_subtype

  def not_subscribe_price(group_id)
    prices.find_by(plan_id: nil, group_id: group_id)
  end

  def prices_by_group(group_id, plan_id = nil)
    prices.where.not(plan_id: plan_id).where(group_id: group_id)
  end

  def create_statistic_subtype
    index = StatisticIndex.where(es_type_key: 'machine')
    StatisticSubType.create!(statistic_types: index.first.statistic_types, key: slug, label: name)
  end

  def update_statistic_subtype
    index = StatisticIndex.where(es_type_key: 'machine')
    subtype = StatisticSubType.joins(statistic_type_sub_types: :statistic_type)
                              .where(key: slug, statistic_types: { statistic_index_id: index.first.id })
                              .first
    subtype.label = name
    subtype.save!
  end

  def remove_statistic_subtype
    subtype = StatisticSubType.where(key: slug).first
    subtype.destroy!
  end

  def create_machine_prices
    Group.find_each do |group|
      Price.create(priceable: self, group: group, amount: 0)
    end

    Plan.includes(:group).find_each do |plan|
      Price.create(group: plan.group, plan: plan, priceable: self, amount: 0)
    end
  end

  def destroyable?
    reservations.empty?
  end

  def soft_destroy!
    update(deleted_at: DateTime.current)
  end

  def packs?(user)
    prepaid_packs.where(group_id: user.group_id)
                 .where(disabled: [false, nil])
                 .count
                 .positive?
  end

  private

  def update_gateway_product
    PaymentGatewayService.new.create_or_update_product(Machine.name, id)
  end
end
