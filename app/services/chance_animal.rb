class ChanceAnimal
  hours_to_parsed = {
    '09:00': '09:00 AM',
    '10:00': '10:00 AM',
    '11:00': '11:00 AM',
    '12:00': '12:00 PM',
    '13:00': '01:00 PM',
    '14:00': '02:00 PM',
    '15:00': '03:00 PM',
    '16:00': '04:00 PM',
    '17:00': '05:00 PM',
    '18:00': '06:00 PM',
    '19:00': '07:00 PM'
  }

  def self.results(hour = 'ALL', date = Time.now)
    results = fetch_results(date)
    return { error: 'no hay sorteo en esta fecha', data: [] } if results.nil?

    if hour == 'ALL'
      sorted_results = results.map do |item|
        res_a, res_s = Base64.decode64(item['simA']).split(' ')
        {
          number: res_a,
          animal: res_s,
          hour: item['horSorteo']
        }
      end

      sorted_results.sort_by! { |result| time_to_24h(result[:hour]) }

      { message: "Lotto Rey: #{date} #{hour}", data: sorted_results }
    else
      hour_parsed = hours_to_parsed[hour.to_sym]
      return { error: 'Hora inválida', data: [] } if hour_parsed.nil?

      sorteo_actual = results.find { |b| b['desSorteo'] == "CHANCE ANIMALITO #{hour_parsed}" }
      return { error: 'No hay sorteo en esta hora', data: [] } if sorteo_actual.nil?

      res_a, res_s = Base64.decode64(sorteo_actual['simA']).split(' ')
      {
        message: "Lotto Rey: #{date.strftime('%d/%m/%y')} #{hour}",
        data: [
          {
            number: res_a,
            animal: res_s,
            hour: hour_parsed
          }
        ]
      }
    end
  end

  def self.fetch_results(date)
    response = data_results(date)
    results = JSON.parse(response.body)
    return nil if results['mensaje']['codigo'] == '012'

    results['datos']
  end

  def self.data_results(date = Time.now)
    require 'net/http'
    fecha = date.beginning_of_day.to_i
    url = URI.parse("https://maquinaazul.com:8443/servicelotteryresults/ServicioResultados.svc/ServicioResultados/ConsultarResultadoSorteo/Qy5BTklNQUxJVE8=/#{fecha}")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(url.path, { 'Content-Type' => 'application/json' })
    http.request(request)
  end

  def self.time_to_24h(time)
    Time.parse(time).strftime('%H:%M')
  rescue ArgumentError
    nil
  end
end
