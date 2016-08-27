require "csv"
require 'sunlight/congress'
require 'erb'

Sunlight::Congress.api_key = "e179a6973728c4dd3fb1204283aaccb5"

def clean_zipcode(zipcode)
	zipcode.to_s.rjust(5,"0")[0..4]
end

def legislators_by_zipcode(zipcode)
	Sunlight::Congress::Legislator.by_zipcode(zipcode)
end

def clean_phone_numbers(phone)
	phone = phone.gsub(/\D/, '')
	if phone.length ==  11 && phone[0] = "1"
		phone = phone[1..10]
	elsif phone.length == 10
		phone
	else
		phone = "0000000000"
	end
end

def save_thank_you_letters(id,form_letter)
	Dir.mkdir("output") unless Dir.exists? "output"
	filename = "output/thanks_#{id}.html"
	File.open(filename,'w') do |file|
		file.puts form_letter
	end
end

def time_targeting(hour_hash)
	hours = hour_hash.select do |hour, times|
		times == hour_hash.values.max
	end
	hours.keys.join(", ")
end

def day_of_week_targeting(day_hash)
	weekdays = %w{Sunday Monday Tuesday Wednesday Thursday Friday Saturday}
	days = day_hash.select do |days, times|
		times == day_hash.values.max
	end
	days.keys.map{ |day| weekdays[day] }.join(", ")
end
puts "EventManager Initialized!"

template_letter = File.read("../form_letter.erb.html")
contents = CSV.open("event_attendees.csv", headers: true, header_converters: :symbol)
erb_template = ERB.new(template_letter)

hour_hash = Hash.new(0)
day_hash = Hash.new(0)

contents.each do |row|
	id = row[0]
	name = row[:first_name]
	zipcode = clean_zipcode(row[:zipcode])
	phone = clean_phone_numbers(row[:homephone])

	reg_date = DateTime.strptime(row[:regdate], "%m/%d/%y %k:%M")
	hour_hash[reg_date.hour] +=1
	day_hash[reg_date.wday] +=1

	legislators = legislators_by_zipcode(zipcode)

	form_letter = erb_template.result(binding)
	save_thank_you_letters(id,form_letter)


end

puts "Most popular hours: #{time_targeting(hour_hash)}"
puts "Most popular days: #{day_of_week_targeting(day_hash)}"
