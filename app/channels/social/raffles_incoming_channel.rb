class Social::RafflesIncomingChannel < ApplicationCable::Channel
  def subscribed
    @user = Shared::User.find_by(id: params[:id])

    reject unless @user

    stream_from "social_raffles_incoming_#{@user.id}"
    
    transmit Social::Raffle.raffle_emergents_count(@user)
  end

  def unsubscribed
  end
end
