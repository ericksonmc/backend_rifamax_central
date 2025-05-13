module X100
  class AvailableSeriesChannel < ApplicationCable::Channel
    def subscribed
      @raffle_id = params[:raffle_id]
      return reject unless @raffle_id.present?

      stream_from "x100_available_series_#{@raffle_id}"

      broadcast_series_available
    end

    def unsubscribed
      stop_all_streams
    end

    private

    def broadcast_series_available
      series_data = X100::Raffle.series_available(@raffle_id)
      ActionCable.server.broadcast("x100_available_series_#{@raffle_id}", series_data)
    end
  end
end