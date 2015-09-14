module Liftoff
  class JSONHelper
    def initialize()
      
    end

  #####
  # Taken from Github API Services
  # https://github.com/github/github-services/blob/f3bb3dd780feb6318c42b2db064ed6d481b70a1f/lib/service.rb
  #####

  def generate_json(body)
    JSON.generate(clean_for_json(body))
  end

  def clean_hash_for_json(hash)
    new_hash = {}
    hash.keys.each do |key|
      new_hash[key] = clean_for_json(hash[key])
    end
    new_hash
  end

  def clean_array_for_json(array)
    array.map { |value| clean_for_json(value) }
  end

  # overridden in Hookshot for proper UTF-8 transcoding with CharlockHolmes
  def clean_string_for_json(str)
    str.to_s.force_encoding(Service::UTF8)
  end

  def clean_for_json(value)
    case value
    when Hash then clean_hash_for_json(value)
    when Array then clean_array_for_json(value)
    when String then clean_string_for_json(value)
    else value
    end
  end
	end
end