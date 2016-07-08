require "ruby_gp_parser/version"
require 'rubygems'
require 'bundler/setup'
require 'json'

module RubyGpParser

  def load_cat(uri, opts)
    uri = URI.parse(uri)
    res = Net::HTTP.post_form(uri, opts)
    doc = Nokogiri::HTML(res.body)
    doc.css('.card').map { |card| card['data-docid'] }
  end

  def deep_load_cat(uri, page_count = 1, num = 100)
    opts =  {
      start: 0,
      num: num,
      numChildren: 0,
      cctcss: 'square-cover',
      cllayout: 'NORMAL',
      ipf: '1',
      xhr: '1',
    }
    (0...page_count).map do |current_page|
      opts['start'] = current_page * num - num
      load_cat(uri, opts)
    end.flatten
  end

  def get_cts_pkgs(cats, page_count)
    for cat, uri in cats
      pkgs = deep_load_cat(uri, page_count)
      IO.write("#{cat}-pkgs.yml", YAML.dump(pkgs))
    end
  end

  def open_uri(uri)
    uri = URI.parse(uri)
    req = Net::HTTP::Get.new(uri.to_s)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.request(req).body
  end

  def details_pkg_load(id, lang = 'en')
    uri = "https://play.google.com/store/apps/details?id=#{id}&hl=#{lang}"
    file = open_uri(uri)
    doc = Nokogiri::HTML(file)

    {
      file_url:        uri,
      title:           doc.css('.id-app-title').text,
      rating:          doc.css('.score').text.to_f,
      description:     doc.css('div[itemprop=description]').text,
      categories:      doc.css('span[itemprop=genre]').map {|item| item.text.mb_chars.downcase },
      android_version: doc.css('div[itemprop=softwareVersion]').text.strip.to_f,
      size:            doc.css('div[itemprop=fileSize]').text.strip.to_f,
      screenshots:     doc.css('img.full-screenshot').map {|item| item[:src]},
      icon:            doc.css('img.cover-image').first['src']
    }

  end

  def load_categories()
    data = open_uri('https://play.google.com/store/apps?hl=en')
    doc = Nokogiri::HTML(data)
    cats = doc.css('ul.submenu-item-wrapper').map do |item|
      item.css('.child-submenu-link').map { |item| item.text.mb_chars.downcase }
    end.flatten
  end

  def load_content_of_cat(uri, page_count = 1, num = 100)

    pkgs = deep_load_cat(uri, page_count, num)

    IO.write('content.json', JSON.pretty_generate(data))

  end

end
