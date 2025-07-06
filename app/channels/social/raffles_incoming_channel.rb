class Social::RafflesIncomingChannel < ApplicationCable::Channel
  def subscribed
    @user = Shared::User.find(params[:id])

    reject if @user.nil?

    stream_from "social_raffles_incoming_#{id}"

    ActionCable.server.broadcast("social_raffles_incoming_#{id}", Social::Raffle.raffle_emergents_count(user))
  end

  def unsubscribed
  end
end
