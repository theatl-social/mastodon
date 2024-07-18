# frozen_string_literal: true

class ListPolicy < ApplicationPolicy
  def push?(target_user)
    user.role == 'superbot' || (owned? && user == target_user)
  end
end
