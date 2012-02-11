class PhoneObserver < Mongoid::Observer

  def after_save(phone)
    phone.number_in_observer = phone.number
  end
end
