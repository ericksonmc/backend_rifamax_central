class GranjitaService
  def self.results(hour = 'ALL')
    response = data_results
    results = JSON.parse(response.body)

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

    sorteo_actual = results.find { |b| b['lottery']['name'] == "LA GRANJITA #{hour}" }
    return { status: 404, error: 'no hay sorteo en esta hora' } if sorteo_actual.nil?

    res_a, res_s = sorteo_actual['result'].split('-')
    { status: 200, data: [res_a, res_s] }
  end

  def self.data_results
    require 'net/http'
    date = Time.now.strftime('%Y-%m-%d')
    url = URI.parse("https://ep443.premierpluss.com/loteries/results3?since=#{date}&product=1")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Get.new(url.path, { 'Content-Type' => 'application/json' })
    http.request(request)
  end
end
