require 'net/http'
require 'uri'
require 'date'
require 'open-uri'
require 'nokogiri'

module Exchanges
  module Rates
    NBP = 'http://www.nbp.pl/kursy/xml/'

    @@date = Date.today

    def date
      @@date
    end

    def date=(at_date)
      @@date = at_date
    end

    def codes
      xml.xpath("//pozycja/kod_waluty/text()").map {|c| c.to_s }
    end

    def rates(currency)
      rate = {}
      rate[:symbol] = xml.xpath("//pozycja[kod_waluty='#{currency}']/kod_waluty/text()").to_s
      rate[:name] = xml.xpath("//pozycja[kod_waluty='#{currency}']/nazwa_waluty/text()").to_s
      rate[:base] = xml.xpath("//pozycja[kod_waluty='#{currency}']/przelicznik/text()").to_s
      rate[:average_rate] = xml.xpath("//pozycja[kod_waluty='#{currency}']/kurs_sredni/text()").to_s.gsub(',', '.').to_f
      rate
    end

    def published_at
      Date.parse(xml.xpath("//tabela_kursow/data_publikacji/text()").to_s)
    end

    private
    def filename
      # according to: http://www.nbp.pl/home.aspx?f=/kursy/instrukcja_pobierania_kursow_walut.html
      index = Net::HTTP.get(URI.parse(NBP + 'dir.txt'))

      while index[/(a[0-9][0-9][0-9]z#{@@date.strftime("%y%m%d")}+)/, 1].nil? do
        @@date -= 1
      end
      index[/(a[0-9][0-9][0-9]z#{@@date.strftime("%y%m%d")}+)/, 1]
    end

    def url
      File.join(NBP, filename + '.xml') if filename
    end

    def xml
      begin
        doc = open(url)
      rescue Exception => e
        puts e.message
        puts e.backtrace.inspect
      end

      Nokogiri::HTML(doc) if doc
    end
  end
end
