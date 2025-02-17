# frozen_string_literal:true

class MigrateProfileToStatisticProfile < ActiveRecord::Migration[4.2]
  def up
    User.all.each do |u|
      p = u.profile
      Rails.logger.warn "User #{u.id} has no profile" and next unless p

      StatisticProfile.create!(
        user: u,
        group: u.group,
        role: u.roles.first,
        gender: p.gender,
        birthday: p.birthday,
        created_at: u.created_at
      )
    end
  end

  def down
    StatisticProfile.all.each do |sp|
      p = sp.user.profile
      Rails.logger.warn "User #{sp.user_id} has no profile" and next unless p

      p.update_attributes(
        gender: sp.gender,
        birthday: sp.birthday
      )
    end
  end
end
