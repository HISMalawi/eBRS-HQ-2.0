class GlobalPropertyController < ApplicationController
  def paper
    @property = GlobalProperty.new
  end

  def signature
    @property = GlobalProperty.new
  end

  def set_paper
  end

  def set_signature
  end

  def update_paper
  end

  def update_signature
  end
end
